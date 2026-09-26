# Project Requirements & Faculty Task Alignment

**Project:** Azure Virtual Desktop Pooled Host Pool for an Engineering Lab  
**Student ID:** 2400031215  
**Course / Track:** Cloud Infrastructure & Virtualization  

---

## 1. Core Technical Requirements

### 1.1 Virtual Desktop Infrastructure
* **Host Pool Type**: Pooled (multi-session).
* **Load Balancing**: Breadth-First distribution across healthy active session hosts.
* **Max Session Limit**: Conservative initial limit of 5 concurrent sessions per host during testing.
* **Operating System**: Windows 11 Enterprise Multi-Session (Build 23H2).
* **Agent Integration**: Microsoft Entra ID Join (`AADLoginForWindows`) and AVD DSC Agent auto-registration.

### 1.2 User Profile Management
* **Technology**: FSLogix Profile Containers (VHDX).
* **Storage Backend**: Azure Files provisioned SMB 3.0 share (`stavdprofiles260916/fslogix`).
* **Authentication**: Microsoft Entra Kerberos (`AADKERB`) with share-level RBAC (`Storage File Data SMB Share Contributor`).
* **Performance Baseline**: 128 GiB quota, 1026 IOPS provisioned, 63 MiB/s throughput, 5000 burst IOPS.

### 1.3 Cost Governance & Safety Constraints
* **Subscription Type**: Azure for Students ($100 budget cap).
* **Spending Policy**: Strict stop-before-spend rule. Only **ONE (1)** session host VM provisioned during initial testing.
* **Automated Deallocation**: DevTestLabs automated daily shutdown schedule configured at 18:00 UTC (23:30 IST) to eliminate idle compute charges.
* **Data Protection**: `CanNotDelete` Resource Lock on profile storage.

---

## 2. Faculty Azure Practical Tasks Mapping Matrix

This project demonstrates practical mastery across all 5 faculty lab exercises:

| Faculty Task | Prescribed Task Description | Project Implementation Evidence | Azure Resource / Artifact |
| :--- | :--- | :--- | :--- |
| **Task 1** | Start Cloud Shell PowerShell, create Resource Group, create & configure Managed Disk | Deployed project Resource Group, audited disk quotas, and configured 128 GB Standard SSD managed OS disk. | `rg-avd-engineering-lab`, `Get-AzDisk`, `Get-AzResourceGroup` |
| **Task 2** | Manage Entra users, create assigned membership group, handle guest users | Created assigned security group `AVD-Engineering-Lab-Students`, enrolled student account, assigned `Desktop Virtualization User` role. | `AVD-Engineering-Lab-Students`, `az ad group create` |
| **Task 3** | Deploy to existing RG, move resources, implement Resource Lock | Deployed all project resources into `rg-avd-engineering-lab`; created `CanNotDelete` lock on profile storage. | `lock-storage-prevent-delete`, `New-AzResourceLock` |
| **Task 4** | Create Virtual Network, deploy VM into VNet, configure private/public IPs, configure NSGs, DNS | Configured `vnet-avd-lab`, `snet-avd`, deployed NSG `nsg-avd-lab` with tailored outbound rules (443, 445, 1688). | `vnet-avd-lab`, `snet-avd`, `nsg-avd-lab` |
| **Task 5** | Deploy VM, create Storage Account, manage Blob/Files, configure storage authentication & authorization | Deployed `stavdprofiles260916`, provisioned `fslogix` share, configured Entra Kerberos and share-level RBAC. | `stavdprofiles260916`, `fslogix`, `AADKERB` |

---

## 3. Scope Boundary & Assumptions
* **Target Audience**: 50 enrolled students accessing engineering software during assigned lab periods.
* **Concurrent Concurrency Assumption**: 50 enrolled students does **not** equate to 50 simultaneous active sessions. Simultaneous concurrency is tested incrementally (1, 3, 5 users) to establish accurate scaling parameters.
