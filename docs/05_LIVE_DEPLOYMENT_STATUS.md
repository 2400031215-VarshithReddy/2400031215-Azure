# Azure Virtual Desktop Project - Phase 1 to 6 Implementation Complete

## Executive Status Summary

| Phase | Description | Status | Live Azure Resource Details |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Live Audit** | **COMPLETED** | Verified VNet `vnet-avd-lab`, Subnet `snet-avd`, Storage `stavdprofiles260916`, File Share `fslogix`. Browser recording captured. |
| **Phase 2** | **Resource Providers** | **COMPLETED** | `Microsoft.Compute` and `Microsoft.DesktopVirtualization` registered successfully. |
| **Phase 3** | **Network Security** | **COMPLETED** | Created `nsg-avd-lab` with tailored outbound rules (AVD HTTPS 443, Storage SMB 445/443, KMS 1688) and associated with `snet-avd`. |
| **Phase 4** | **AVD Control Plane** | **COMPLETED** | Created Host Pool `hp-avd-engineering-lab`, Desktop App Group `dag-avd-engineering-lab`, and Workspace `ws-avd-engineering-lab`. |
| **Phase 5** | **Entra User/Group RBAC** | **COMPLETED** | Created security group `AVD-Engineering-Lab-Students`, added `2400031215@kluniversity.in`, and assigned `Desktop Virtualization User` role on DAG. |
| **Phase 6** | **Resource Lock** | **COMPLETED** | Applied `CanNotDelete` lock `lock-storage-prevent-delete` on `stavdprofiles260916`. |
| **Phase 7** | **Session Host VM** | **PENDING APPROVAL** | **STOPPED BEFORE PROVISIONING**. Quota and cost analysis prepared below. |

---

## 1. Verified Live Azure Resources

### 1.1 Networking & Security
* **Network Security Group**: `nsg-avd-lab`
  * Scope: `/subscriptions/8193a60a-4094-422b-b1ac-d72335007187/resourceGroups/rg-avd-engineering-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-avd-lab`
  * Associated Subnet: `vnet-avd-lab/subnets/snet-avd`
  * Custom Outbound Rules:
    1. `Allow-AVD-Traffic-Outbound` (Priority 100): TCP 443 to `AzureCloud`
    2. `Allow-Azure-Storage-Outbound` (Priority 110): TCP 443, 445 to `Storage`
    3. `Allow-KMS-Outbound` (Priority 120): TCP 1688 to `Internet`

### 1.2 AVD Control Plane (Zero Compute Cost)
* **Host Pool**: `hp-avd-engineering-lab`
  * Host Pool Type: `Pooled`
  * Load Balancing: `BreadthFirst`
  * Max Session Limit: `5` concurrent sessions
  * Region: `centralindia` (Official AVD metadata anchor for India)
* **Desktop Application Group**: `dag-avd-engineering-lab`
  * Type: `Desktop`
  * Friendly Name: `Engineering Lab Desktops`
* **AVD Workspace**: `ws-avd-engineering-lab`
  * Friendly Name: `Engineering Software Lab`
  * Associated App Group: `dag-avd-engineering-lab`

### 1.3 Entra ID & RBAC
* **Security Group**: `AVD-Engineering-Lab-Students` (ID: `24e47a1a-3990-4b1c-8635-9aeb85f35af7`)
* **Members**: `2400031215@kluniversity.in` (`c073ab84-45fc-44b5-affa-7c08774dde18`)
* **Role Assignment**: `Desktop Virtualization User` assigned to the security group on `dag-avd-engineering-lab`.

### 1.4 Protection & Storage
* **Resource Lock**: `lock-storage-prevent-delete` (`CanNotDelete`) on Storage Account `stavdprofiles260916`.

---

## 2. Phase 7: Compute Quota Audit & VM Sizing Comparison

### 2.1 Critical Quota Discovery in `indiasouthcentral`
A live query of your `Azure for Students` subscription quotas revealed:
* `Total Regional vCPUs` Limit: **6**
* `Standard Dv5 Family vCPUs` Limit: **0** *(The originally proposed Standard_D4s_v5 cannot be deployed due to a zero quota limit in this student subscription)*
* `Standard Dv4 Family vCPUs` Limit: **4**
* `Standard BS Family vCPUs` Limit: **4**

### 2.2 Viable VM Candidates

| Parameter | Option A (Recommended for Cost): `Standard_B4ms` | Option B (Recommended for Sustained Load): `Standard_D4s_v4` |
| :--- | :--- | :--- |
| **vCPUs / RAM** | 4 vCPUs / 16 GiB RAM | 4 vCPUs / 16 GiB RAM |
| **Architecture** | Burstable performance | Dedicated compute |
| **Regional Quota** | 4 vCPUs (Available: 4) | 4 vCPUs (Available: 4) |
| **Hourly Run Cost** | **\~\$0.166 / hour** (\~₹13.8 / hr) | **\~\$0.192 / hour** (\~₹16.0 / hr) |
| **Cost for 2-hour test** | **\~\$0.33** (\~₹27) | **\~\$0.38** (\~₹32) |
| **Deallocated Cost** | **\$0.00 compute** | **\$0.00 compute** |
| **OS Disk Cost** | 128 GB Standard SSD: \~\$9.60/month (\~\$0.32/day) | 128 GB Standard SSD: \~\$9.60/month (\~\$0.32/day) |
| **Suitability** | Best budget option for 1–3 user validation | Ideal for testing sustained multi-user loads (3–5 users) |

---

## 3. Cost Safeguards Codified for Phase 8

When the VM is approved for creation, the following safeguards will be applied immediately:
1. **Quantity**: Exactly **ONE (1)** session host (`vm-avd-sh-0`).
2. **Auto-Shutdown Schedule**: Automatically shuts down and deallocates every evening at 18:00 UTC (23:30 IST) via Azure DevTestLabs schedule.
3. **Power Management**: The VM will be stopped and deallocated immediately upon concluding each test session.
