# PowerShell Automation Scripts

Collection of PowerShell scripts developed for Active Directory 
administration and automation tasks.

## Overview

These scripts demonstrate automated user management, reporting, and 
system administration tasks for Windows Server and Active Directory 
environments.

**Total Scripts:** 6 functions + 1 module  
**Lines of Code:** ~500 lines  
**Testing:** All tested in home lab environment

## Scripts Included

### 1. New-CompanyADUser.ps1
Automated user account creation with validation and error handling.

**Features:**
- Parameter validation (mandatory fields, ValidateSet for departments)
- Duplicate user checking
- Automatic username generation
- Default password assignment with forced change on first login
- Automatic security group assignment based on department
- Comprehensive error handling

**Usage:**
```powershell
New-CompanyADUser -FirstName "John" -LastName "Smith" -Department "IT Department" -JobTitle "Technician"
```

---

### 2. Get-ADUserReport.ps1
Generate comprehensive user status reports exported to CSV.

**Features:**
- All user properties extracted
- Group membership enumeration
- Password age calculation
- Last logon date tracking
- Enabled/disabled status
- CSV export for analysis

**Usage:**
```powershell
Get-ADUserReport -OutputPath "C:\Reports\UserReport.csv"
```

---

### 3. Reset-DepartmentPasswords.ps1
Bulk password reset tool with safety features.

**Features:**
- Department-based targeting
- -WhatIf parameter for testing before execution
- Confirmation prompts
- Automatic "change password at next login" setting
- Comprehensive logging

**Usage:**
```powershell
# Test mode
Reset-DepartmentPasswords -Department "Sales Department" -WhatIf

# Actual execution
Reset-DepartmentPasswords -Department "Sales Department"
```

---

### 4. Find-InactiveUsers.ps1
Security audit tool for identifying inactive accounts.

**Features:**
- Configurable inactivity threshold (days)
- Identifies users who never logged in
- CSV export of inactive accounts
- Helps maintain security compliance

**Usage:**
```powershell
Find-InactiveUsers -DaysInactive 90 -ExportCSV
```

---

### 5. Write-Log.ps1
Centralized logging function for all scripts.

**Features:**
- Timestamp on all entries
- Severity levels (INFO, WARNING, ERROR, SUCCESS)
- Automatic log directory creation
- Console output with color coding

**Usage:**
```powershell
Write-Log -Message "User created successfully" -Level "SUCCESS"
```

---

### 6. CompanyADTools Module
Reusable PowerShell module containing all functions.

**Location:** `./CompanyADTools/CompanyADTools.psm1`

**Usage:**
```powershell
Import-Module .\CompanyADTools\CompanyADTools.psm1
Get-Command -Module CompanyADTools
```

## Technical Concepts Demonstrated

- Function development with parameters
- Parameter validation (Mandatory, ValidateSet)
- Try/Catch error handling
- Specific exception handling
- Switch parameters (-Force, -WhatIf)
- Return values and objects
- Logging and audit trails
- CSV import/export
- Active Directory module usage
- PowerShell best practices

## Sample Output

*[Include screenshot of script running or output]*

## Future Enhancements

- Add email notifications for administrative actions
- Implement scheduled task integration
- Add more advanced reporting features
- Create GUI wrapper for non-technical users

## Related Projects

- [Active Directory Lab](../Active-Directory-Lab/) - Where these scripts run
- [IT Support Simulations](../IT-Support-Simulations/)

---

[Back to Main Portfolio](../README.md)
