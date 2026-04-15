# Active Directory Enterprise Lab

## Project Overview

Built a complete Windows Server 2022 Active Directory domain environment 
to simulate enterprise IT infrastructure and practice system 
administration skills.

**Duration:** March 2026  
**Environment:** VirtualBox on Windows 11 host  
**Scope:** Full domain deployment with 25+ users and enterprise policies

## Architecture
Domain: testlab.local
Domain Controller: DC01 (Windows Server 2022)
Client Machine: PC01 (Windows 11 Pro)
Network: NAT Network (10.0.2.0/24)
DNS: Integrated with AD DS
DHCP: Configured on DC01

## What I Built

### Infrastructure
- ✅ Windows Server 2022 promoted to Domain Controller
- ✅ Active Directory Domain Services installed and configured
- ✅ Integrated DNS server for domain resolution
- ✅ DHCP server for automated IP assignment
- ✅ Windows 11 Pro client successfully domain-joined

### User Management
- ✅ 25+ user accounts created
- ✅ 5 Organizational Units (IT, HR, Sales, Executives, Workstations)
- ✅ 6+ Security Groups with appropriate members
- ✅ Automated bulk user creation via PowerShell CSV import

### Group Policy Implementation

**Password Policy GPO:**
- Minimum password length: 12 characters
- Password complexity: Enabled
- Maximum password age: 90 days
- Password history: 24 passwords remembered
- Account lockout: 5 attempts, 30-minute duration

**Network Drive Mapping GPO:**
- G: Drive → \\DC01\CompanyData
- H: Drive → \\DC01\HR
- I: Drive → \\DC01\IT
- S: Drive → \\DC01\Sales
- Item-level targeting based on security groups

**Folder Redirection GPO:**
- Desktop → \\DC01\UserRedirection$\%USERNAME%\Desktop
- Documents → \\DC01\UserRedirection$\%USERNAME%\Documents
- CREATOR OWNER permissions for security

**Additional GPOs:**
- Login scripts (welcome message)
- Screen lock timeout (10 minutes)
- Desktop wallpaper enforcement
- Administrative tools for IT department

### File Services
- 4 network shares created with appropriate permissions
- NTFS and Share permissions configured
- Security group-based access control
- Folder redirection for roaming profiles

## Technical Skills Demonstrated

- Active Directory Domain Services installation and configuration
- DNS integration with Active Directory
- DHCP scope configuration
- Organizational Unit structure design
- Group Policy Object creation and deployment
- User and group management (GUI and PowerShell)
- Network share creation and permissions management
- Security policy implementation
- Troubleshooting using Event Viewer and GPO tools

## Screenshots

*[Add screenshots here - see Step 6 below]*

## Key Learnings

1. **DNS is critical** - AD DS won't function without proper DNS
2. **GPO processing order** - LSDOU (Local, Site, Domain, OU)
3. **Permissions** - NTFS permissions apply to both local and network access
4. **Folder redirection** - Requires correct CREATOR OWNER permissions
5. **PowerShell** - Automation saves massive time vs manual GUI work

## Future Enhancements

- Add second domain controller for redundancy
- Implement DHCP failover
- Configure sites and services for multi-site simulation
- Practice disaster recovery scenarios
- Implement certificate services

## Related Projects

- [PowerShell Automation Scripts](../PowerShell-Scripts/)
- [Windows Server Networking Lab](../Network-Lab/)
