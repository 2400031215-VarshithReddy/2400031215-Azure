# Project Abstract: Azure Virtual Desktop Pooled Host Pool for an Engineering Lab

**Project Identifier:** 2400031215-Azure  
**Student Name:** Bhimavarapu Hema Varshith Reddy  
**Student ID:** 2400031215  
**Institution:** K L University  
**Academic Program:** Cloud Computing / Azure Engineering Practical Lab  

---

## 1. Executive Summary
Modern engineering curricula increasingly require high-performance desktop applications—including computer-aided design (CAD), finite element analysis (FEA), and software development suites—that demand substantial compute, memory, and fast local disk I/O. Supplying dedicated high-spec physical workstations to every student presents prohibitive capital expenditures, administrative complexity, and rigid scheduling constraints. 

This project designs, deploys, and rigorously validates a cloud-native **Azure Virtual Desktop (AVD) pooled multi-session host pool** tailored for an engineering cohort of approximately 50 students. The environment leverages Windows 11 Enterprise Multi-Session, automated breadth-first load balancing, and a centralized **FSLogix profile container** architecture backed by Azure Files (SMB 3.0) with Microsoft Entra Kerberos authentication.

---

## 2. Problem Statement
Deploying shared virtual desktop environments for engineering workloads presents two major technical hurdles:
1. **Workload Sizing & Resource Contention**: Unlike lightweight office productivity applications, engineering tools produce unpredictable bursts of CPU, RAM, and disk utilization. Sizing session hosts based on arbitrary rules of thumb risks severe performance degradation or wasteful cloud expenditure.
2. **Profile Storage & Logon Storm Bottlenecks**: In a pooled architecture where users roam between session hosts, user state must be decoupled from individual VMs. At the start of a class period, simultaneous logons ("logon storms") generate heavy read/write operations against the storage backend. If FSLogix profile storage IOPS and bandwidth are inadequate, container mount times spike, degrading user responsiveness.

---

## 3. Project Objectives
1. **PaaS-Native Control Plane**: Implement an enterprise AVD control plane consisting of a Pooled Host Pool, Desktop Application Group, and Workspace within Azure subscription resource constraints.
2. **FSLogix Profile Decoupling**: Configure Azure Files storage (`stavdprofiles260916`) with a 128 GiB provisioned file share (`fslogix`), delivering 1026 IOPS and 63 MiB/s throughput via Microsoft Entra Kerberos authentication.
3. **Rigorous Capacity & Sizing Methodology**: Establish an empirical testing methodology (testing 1, 3, and 5 concurrent users) to measure actual CPU, memory, disk latency, and profile mount times to determine genuine capacity for 50 students.
4. **Automated Cost Control**: Apply strict cost safeguards on an *Azure for Students* subscription ($100 credit pool) via automated scheduled deallocations, single-VM initial validation, and granular Resource Locks.
5. **Practical Curriculum Alignment**: Directly map each architectural component to faculty-prescribed Azure practical tasks (Tasks 1 through 5).

---

## 4. Proposed Architecture Overview
* **Identity & Access**: Microsoft Entra ID with dedicated security group `AVD-Engineering-Lab-Students` and RBAC role `Desktop Virtualization User`.
* **Network & Security**: Dedicated Virtual Network (`vnet-avd-lab`, 10.0.0.0/16) and Subnet (`snet-avd`, 10.0.0.0/24) protected by Network Security Group `nsg-avd-lab`.
* **Compute Layer**: Windows 11 Enterprise multi-session 23H2 session hosts equipped with Entra ID join extension (`AADLoginForWindows`) and AVD DSC Agent.
* **Storage Layer**: Azure Files `StandardV2_LRS` provisioned v2 file share with Microsoft Entra Kerberos (`AADKERB`) and `Storage File Data SMB Share Contributor` RBAC permissions.
