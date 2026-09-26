# System Architecture: Azure Virtual Desktop Engineering Lab

**Project:** Azure Virtual Desktop Pooled Host Pool for an Engineering Lab  
**Student ID:** 2400031215  

---

## 1. High-Level Architectural Diagram

```mermaid
flowchart TD
    subgraph ClientAccessLayer ["1. Client Access Layer"]
        UserDevice["Student Client Devices<br/>(Windows App / Web Client / iOS / Android)"]
    end

    subgraph AVDControlPlane ["2. Azure Virtual Desktop Control Plane (centralindia)"]
        WS["AVD Workspace<br/><code>ws-avd-engineering-lab</code>"]
        DAG["Desktop Application Group<br/><code>dag-avd-engineering-lab</code>"]
        HP["Pooled Host Pool (Breadth-First)<br/><code>hp-avd-engineering-lab</code>"]
        Broker["AVD Web Access / Gateway / Broker<br/>(Reverse Connect over HTTPS 443)"]
    end

    subgraph IdentityLayer ["3. Microsoft Entra ID (kluniversity.in)"]
        EntraGroup["Security Group<br/><code>AVD-Engineering-Lab-Students</code>"]
        RBACUser["RBAC Assignment<br/><code>Desktop Virtualization User</code>"]
        EntraKerb["Entra Kerberos Service Principal<br/><code>[Storage Account] stavdprofiles...</code>"]
    end

    subgraph NetworkLayer ["4. Networking & Security Layer (indiasouthcentral)"]
        VNet["Virtual Network: <code>vnet-avd-lab</code> (10.0.0.0/16)"]
        Subnet["Subnet: <code>snet-avd</code> (10.0.0.0/24)"]
        NSG["Network Security Group: <code>nsg-avd-lab</code><br/>• Outbound 443 -> AzureCloud<br/>• Outbound 445/443 -> Storage<br/>• Outbound 1688 -> KMS"]
    end

    subgraph ComputeLayer ["5. Compute Layer (indiasouthcentral)"]
        VM1["Session Host VM: <code>vm-avd-sh-0</code><br/>(Windows 11 Enterprise Multi-Session 23H2)<br/>128 GB Standard SSD OS Disk"]
        Agent["AVD Agent & Geneva RDAgentBootLoader"]
        AADExt["AADLoginForWindows Extension"]
        AutoStop["DevTestLabs Auto-Shutdown Schedule<br/>(18:00 UTC Daily Shutdown)"]
    end

    subgraph StorageLayer ["6. User Profile Layer (indiasouthcentral)"]
        StorageAcc["Storage Account: <code>stavdprofiles260916</code><br/>(FileStorage / StandardV2_LRS / TLS 1.2)"]
        FileShare["Azure File Share: <code>fslogix</code><br/>(128 GiB, 1026 IOPS, 63 MiB/s)"]
        Lock["Resource Lock: <code>lock-storage-prevent-delete</code>"]
        Profiles["FSLogix Profile Containers<br/>(<code>\\stavdprofiles260916.file.core.windows.net\fslogix</code>)"]
    end

    %% Access Connections
    UserDevice -->|Outbound HTTPS / Port 443| WS
    WS --> DAG
    DAG --> HP
    EntraGroup -->|Granted Access via| RBACUser
    RBACUser -.-> DAG

    %% Broker & Session Host Connectivity
    HP --- Broker
    Broker <-->|Reverse-Connect TCP 443| Agent
    Agent --- VM1
    AADExt --- VM1
    AutoStop -.->|Enforces Deallocation| VM1

    %% Subnet and Network Protection
    Subnet --- NSG
    VM1 --- Subnet
    VNet --- Subnet

    %% Storage Integration
    VM1 ==>|Mount VHDX Profile over SMB 445 via Entra Kerberos| Profiles
    Profiles --- FileShare
    FileShare --- StorageAcc
    Lock -.-> StorageAcc
    EntraKerb -.-> StorageAcc
```

---

## 2. Component Architecture Breakdown

### 2.1 Reverse Connect Gateway Architecture
Unlike traditional remote desktop infrastructures that expose TCP port 3389 inbound to the public internet, Azure Virtual Desktop utilizes **Reverse Connect**:
* The session host agent initiates an outbound connection over **HTTPS (TCP 443)** to the nearest Azure Virtual Desktop gateway service.
* Incoming client traffic terminates at the Azure PaaS gateway.
* No public IP addresses, inbound NAT rules, or perimeter firewalls are required on individual session host virtual machines.

### 2.2 Geographically Distributed Metadata Plane
* **Control Plane Metadata**: Anchored in `centralindia` (the official Azure Virtual Desktop metadata region for the India geography).
* **Workload & Data Plane**: Session host virtual machines, virtual networks, and storage accounts remain co-located in `indiasouthcentral` to ensure ultra-low latency (<5ms) between session hosts and profile storage.

### 2.3 FSLogix Profile Decoupling
* FSLogix attaches the user profile container as an active virtual hard disk (`VHDX`) at logon.
* Applications perceive the profile as a standard local folder (`C:\Users\<username>`), ensuring native app compatibility without profile corruption across pooled sessions.
