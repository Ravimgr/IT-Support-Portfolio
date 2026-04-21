# PowerShell Automation Scripts

Collection of PowerShell scripts developed for Active Directory administration, user management, and system automation.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?style=flat-square&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](../LICENSE)

---

## 📋 Overview

This collection demonstrates automated user management, reporting, and system administration tasks for Windows Server and Active Directory environments. All scripts include comprehensive error handling, parameter validation, and detailed logging.

**Total Functions:** 6 core functions + 1 PowerShell module  
**Lines of Code:** ~800+ lines  
**Testing Environment:** Windows Server 2022 / company.local domain  
**PowerShell Version:** 5.1+

---

## 📂 Repository Contents

```
PowerShell-Scripts/
├── README.md (this file)
├── New-CompanyADUser.ps1
├── Get-ADUserReport.ps1
├── Reset-DepartmentPasswords.ps1
├── Find-InactiveUsers.ps1
├── Write-Log.ps1
└── CompanyADTools/
    ├── CompanyADTools.psm1
    └── README.md
```

---

## 🚀 Scripts Included

### 1. New-CompanyADUser.ps1
**Purpose:** Automated Active Directory user account creation with validation and error handling.

**Features:**
- ✅ Parameter validation (mandatory fields, ValidateSet for departments)
- ✅ Automatic username generation (firstname.lastname format)
- ✅ Duplicate user checking before creation
- ✅ Default password assignment with forced change on first login
- ✅ Automatic OU placement based on department
- ✅ Automatic security group assignment
- ✅ Comprehensive error handling with detailed messages
- ✅ Professional console output with color coding

**Parameters:**
- `FirstName` (Mandatory): User's first name
- `LastName` (Mandatory): User's last name
- `Department` (Mandatory): Must be one of: IT Department, HR Department, Sales Department, Executives
- `JobTitle` (Optional): Defaults to "Employee"

**Usage Example:**
```powershell
# Create single user
New-CompanyADUser -FirstName "John" -LastName "Smith" -Department "IT Department" -JobTitle "IT Technician"

# Output:
# ✓ SUCCESS: Created user john.smith
#   Full Name: John Smith
#   Department: IT Department
#   Job Title: IT Technician
#   Email: john.smith@testlab.local
#   Temp Password: Welcome123!@#
#   ✓ Added to group: IT Support Team
```

**Skills Demonstrated:**
- Function development with parameters
- Parameter validation (Mandatory, ValidateSet)
- Try/Catch error handling
- Active Directory cmdlet usage
- Automated username generation
- Security group management

---

### 2. Get-ADUserReport.ps1
**Purpose:** Generate comprehensive reports of all Active Directory users with CSV export.

**Features:**
- ✅ Retrieves all user properties in one query
- ✅ Group membership enumeration for each user
- ✅ Password age calculation
- ✅ Last logon date tracking
- ✅ Account status (enabled/disabled)
- ✅ CSV export for Excel analysis
- ✅ Automatic report file opening
- ✅ Summary statistics (total, enabled, disabled users)

**Parameters:**
- `OutputPath` (Optional): CSV file path (defaults to dated filename)

**Usage Example:**
```powershell
# Generate report with default filename
Get-ADUserReport

# Output file: C:\Scripts\Reports\UserReport_2026-04-22.csv
# Opens automatically in Excel

# Custom output path
Get-ADUserReport -OutputPath "C:\Reports\Users_April.csv"
```

**Report Includes:**
- Username
- Display Name
- Email Address
- Department
- Job Title
- Enabled Status
- Password Age (in days)
- Password Never Expires setting
- Last Logon Date
- Account Creation Date
- Group Memberships
- OU Location

**Skills Demonstrated:**
- Advanced Get-ADUser queries
- CSV export operations
- Custom object creation (PSCustomObject)
- Bulk data processing
- String manipulation
- Report generation

---

### 3. Reset-DepartmentPasswords.ps1
**Purpose:** Bulk password reset tool with safety controls and testing mode.

**Features:**
- ✅ Department-based targeting (resets all users in OU)
- ✅ `-WhatIf` parameter for safe testing
- ✅ Confirmation prompts before execution
- ✅ Automatic "change password at next login" flag
- ✅ Individual user error handling (one failure doesn't stop all)
- ✅ Success/failure counters
- ✅ Comprehensive logging
- ✅ Summary report after execution

**Parameters:**
- `Department` (Mandatory): Target department OU
- `NewPassword` (Optional): Temporary password (default: TempReset123!@#)
- `WhatIf` (Switch): Test mode - shows what would happen without making changes

**Usage Example:**
```powershell
# TEST MODE FIRST (safe - no changes made):
Reset-DepartmentPasswords -Department "Sales Department" -WhatIf

# Output:
# [TEST] Would reset password for: mike.williams
# [TEST] Would reset password for: alice.brown
# [TEST] Would reset password for: bob.davis

# LIVE MODE (actually resets passwords):
Reset-DepartmentPasswords -Department "Sales Department"

# Output:
# ✓ Password reset successful: mike.williams
# ✓ Password reset successful: alice.brown
# ✓ Password reset successful: bob.davis
# Operation Summary: 3 successful, 0 failed
```

**Skills Demonstrated:**
- WhatIf support (SupportsShouldProcess)
- Bulk operations
- Safety mechanisms
- Password management
- OU-based filtering
- Error resilience

---

### 4. Find-InactiveUsers.ps1
**Purpose:** Security audit tool for identifying inactive user accounts.

**Features:**
- ✅ Configurable inactivity threshold (days)
- ✅ Identifies users who never logged in
- ✅ Calculates days inactive for each user
- ✅ CSV export capability
- ✅ Detailed console output
- ✅ Actionable recommendations
- ✅ Summary statistics

**Parameters:**
- `DaysInactive` (Optional): Inactivity threshold in days (default: 90)
- `ExportCSV` (Switch): Export results to CSV file

**Usage Example:**
```powershell
# Find users inactive for 90+ days
Find-InactiveUsers -DaysInactive 90

# Output:
# ⚠ User: old.account
#    Last Logon: Never
#    Days Inactive: Never logged in
#    Department: IT Department

# Find and export to CSV
Find-InactiveUsers -DaysInactive 30 -ExportCSV

# Creates: C:\Scripts\Reports\InactiveUsers_2026-04-22.csv
```

**Use Cases:**
- Security compliance audits
- License optimization (disable unused accounts)
- Account cleanup projects
- Quarterly security reviews

**Skills Demonstrated:**
- Date/time calculations
- Security auditing logic
- Filtering and querying
- Null value handling
- CSV reporting

---

### 5. Write-Log.ps1
**Purpose:** Centralized logging function for all scripts.

**Features:**
- ✅ Timestamped log entries ([YYYY-MM-DD HH:MM:SS])
- ✅ Severity levels (INFO, WARNING, ERROR, SUCCESS)
- ✅ Automatic log directory creation
- ✅ Dual output (file + console)
- ✅ Color-coded console output
- ✅ Pipeline support (can pipe messages to it)

**Parameters:**
- `Message` (Mandatory): The log message
- `Level` (Optional): Severity level (default: INFO)
- `LogFile` (Optional): Log file path (default: C:\Scripts\Logs\ADAutomation.log)

**Usage Example:**
```powershell
# Simple logging
Write-Log -Message "Script started" -Level "INFO"
Write-Log -Message "User created successfully" -Level "SUCCESS"
Write-Log -Message "Low disk space" -Level "WARNING"
Write-Log -Message "Connection failed" -Level "ERROR"

# Pipeline usage
"Processing 100 users..." | Write-Log -Level "INFO"

# Custom log file
Write-Log -Message "Custom entry" -LogFile "C:\CustomLogs\MyLog.log"
```

**Log Format:**
```
[2026-04-22 14:30:15] [INFO] Script started
[2026-04-22 14:30:16] [SUCCESS] User created successfully
[2026-04-22 14:30:45] [WARNING] Low disk space detected
[2026-04-22 14:31:02] [ERROR] Failed to connect to DC
```

**Skills Demonstrated:**
- Logging best practices
- File I/O operations
- Color-coded output
- Pipeline support
- Error handling

---

### 6. CompanyADTools Module
**Purpose:** Reusable PowerShell module containing all functions.

**Location:** `./CompanyADTools/CompanyADTools.psm1`

**Features:**
- ✅ All functions packaged in single module
- ✅ Easy import and reuse
- ✅ Exported functions list
- ✅ Module manifest (metadata)
- ✅ Version control ready

**Usage:**
```powershell
# Import the module
Import-Module .\CompanyADTools\CompanyADTools.psm1

# List available functions
Get-Command -Module CompanyADTools

# Output:
# CommandType     Name
# -----------     ----
# Function        New-CompanyADUser
# Function        Get-ADUserReport
# Function        Reset-DepartmentPasswords
# Function        Find-InactiveUsers
# Function        Write-Log

# Use any function
New-CompanyADUser -FirstName "Sarah" -LastName "Wilson" -Department "HR Department"
Get-ADUserReport
Find-InactiveUsers -DaysInactive 60 -ExportCSV
```

**Skills Demonstrated:**
- PowerShell module development
- Export-ModuleMember usage
- Code organization
- Reusability patterns

---

## 💡 Key Technical Concepts

### Parameter Validation
```powershell
[Parameter(Mandatory=$true)]
[ValidateSet("IT Department", "HR Department", "Sales Department", "Executives")]
[string]$Department
```
- Ensures only valid departments can be specified
- Provides IntelliSense in PowerShell ISE
- Prevents typos and invalid input

### Error Handling Pattern
```powershell
try {
    # Attempt operation
    New-ADUser -Name $Name -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    # Handle specific exception
    Write-Log -Message "User not found" -Level "ERROR"
}
catch {
    # Handle any other exception
    Write-Log -Message $_.Exception.Message -Level "ERROR"
}
```

### Secure Password Handling
```powershell
$SecurePassword = ConvertTo-SecureString "TempPass123!" -AsPlainText -Force
Set-ADAccountPassword -Identity $User -NewPassword $SecurePassword
```
- Never store passwords as plain text
- Use SecureString for password operations

### WhatIf Support
```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param(...)

if ($PSCmdlet.ShouldProcess($Target, $Action)) {
    # Perform actual change
}
```
- Enables -WhatIf and -Confirm parameters
- Best practice for scripts that modify data

---

## 📊 Code Statistics

| Metric | Value |
|--------|-------|
| **Total Lines of Code** | ~800+ |
| **Functions** | 6 |
| **Error Handlers** | 25+ try/catch blocks |
| **Parameter Validations** | 15+ |
| **Comment Lines** | 300+ |
| **Example Usage** | 20+ examples |

---

## 🛠️ Prerequisites

### Required
- **Windows Server 2022** or 2019
- **PowerShell 5.1** or higher
- **Active Directory PowerShell Module** (RSAT tools)
- **Domain Controller** access
- **Permissions:**
  - User creation/modification rights
  - Password reset rights
  - Read access to Active Directory

### Optional
- **PowerShell ISE** (for development)
- **VS Code** with PowerShell extension
- **Git** for version control

---

## 🚀 Quick Start

### Option 1: Use Individual Scripts

```powershell
# Download the script
# Save as New-CompanyADUser.ps1

# Dot-source to load function
. .\New-CompanyADUser.ps1

# Use the function
New-CompanyADUser -FirstName "John" -LastName "Doe" -Department "IT Department"
```

### Option 2: Use the Module (Recommended)

```powershell
# Clone or download repository
git clone https://github.com/Ravimgr/IT-Support-Portfolio.git

# Navigate to module
cd IT-Portfolio/PowerShell-Scripts/CompanyADTools

# Import module
Import-Module .\CompanyADTools.psm1

# Use any function
Get-ADUserReport
Find-InactiveUsers -DaysInactive 90 -ExportCSV
```

### Option 3: Install Module Permanently

```powershell
# Copy module to PowerShell modules path
$ModulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\CompanyADTools"
New-Item -ItemType Directory -Path $ModulePath -Force
Copy-Item .\CompanyADTools.psm1 -Destination $ModulePath

# Now can import from anywhere
Import-Module CompanyADTools
```

---

## 📝 Usage Tips

### Bulk User Creation
```powershell
# Create CSV file: users.csv
# FirstName,LastName,Department,JobTitle
# John,Smith,IT Department,Technician
# Sarah,Williams,HR Department,Manager
# Mike,Johnson,Sales Department,Representative

# Import and process
Import-Csv .\users.csv | ForEach-Object {
    New-CompanyADUser -FirstName $_.FirstName `
                      -LastName $_.LastName `
                      -Department $_.Department `
                      -JobTitle $_.JobTitle
}
```

### Monthly Security Audit
```powershell
# Run on first of each month
$InactiveUsers = Find-InactiveUsers -DaysInactive 90 -ExportCSV

# Review CSV report
# Disable accounts no longer needed
# Delete disabled accounts after 30-day retention
```

### Testing Before Production
```powershell
# ALWAYS test with -WhatIf first!
Reset-DepartmentPasswords -Department "Test Department" -WhatIf

# Review output
# If looks good, run for real
Reset-DepartmentPasswords -Department "Test Department"
```

---

## ⚠️ Important Notes

### Security Considerations
- ⚠️ **Default passwords** (Welcome123!@#) should be changed in production
- ⚠️ **Log files** may contain sensitive information - secure appropriately
- ⚠️ **Least privilege:** Run scripts with minimum required permissions
- ⚠️ **Audit trail:** All actions should be logged

### Best Practices
- ✅ Always test in non-production environment first
- ✅ Use `-WhatIf` parameter before bulk operations
- ✅ Review scripts before running with elevated privileges
- ✅ Keep logs for compliance and troubleshooting
- ✅ Use version control (Git) for script changes
- ✅ Document any customizations

### Common Issues
**Issue:** "Import-Module: The specified module was not loaded"
- **Solution:** Check file path, ensure .psm1 extension

**Issue:** "Access Denied" when creating users
- **Solution:** Verify account has necessary AD permissions

**Issue:** Scripts not finding Active Directory module
- **Solution:** Install RSAT tools, import module manually

---

## 🔄 Version History

### Version 1.0 (March-April 2026)
- ✅ Initial release
- ✅ 6 core functions implemented
- ✅ PowerShell module created
- ✅ Comprehensive error handling
- ✅ Complete documentation
- ✅ Full comment-based help

### Planned Enhancements
- [ ] Add email notification functionality
- [ ] Implement scheduled task integration
- [ ] Create GUI wrapper for non-technical users
- [ ] Add more advanced reporting features
- [ ] Integration with Microsoft Graph API
- [ ] Azure AD / Entra ID support

---

## 📚 Learning Resources

### Official Documentation
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Active Directory PowerShell Module](https://docs.microsoft.com/en-us/powershell/module/activedirectory/)
- [About Comment-Based Help](https://docs.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help)

## 🔗 Related Projects

- **[Active Directory Lab](../Active-Directory-Lab/)** - Environment where these scripts run
- **[Network Lab](../Network-Lab/)** - DNS and DHCP configuration
- **[IT Support Simulations](../IT-Support-Simulations/)** - Helpdesk practice

---

## 📞 Questions or Contributions?

Found a bug? Have a suggestion? Want to contribute?

📧 **Email:** iamrtmfd@gmail.com  
💼 **LinkedIn:** [linkedin.com/in/thapa-ravi](https://www.linkedin.com/in/thapa-ravi/)  
🐛 **Issues:** [Open an issue on GitHub](https://github.com/[your-username]/IT-Portfolio/issues)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

[⬅️ Back to Main Portfolio](../README.md)
