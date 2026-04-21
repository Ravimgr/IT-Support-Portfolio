<#
.SYNOPSIS
    Company Active Directory Tools - Reusable PowerShell Module

.DESCRIPTION
    This module contains a collection of functions for Active Directory administration,
    user management, reporting, and automation tasks. All functions include comprehensive
    error handling, logging, and validation.
    
    Functions included:
    - New-CompanyADUser: Automated user creation
    - Get-ADUserReport: Comprehensive user reporting
    - Reset-DepartmentPasswords: Bulk password reset tool
    - Find-InactiveUsers: Security audit for stale accounts
    - Write-Log: Centralized logging function
    
.NOTES
    Module Name    : CompanyADTools
    Author         : Ravi Thapa
    Created        : March-April 2026
    Version        : 1.0
    Prerequisite   : Active Directory PowerShell Module
    Domain         : testlab.local
    
.EXAMPLE
    Import-Module .\CompanyADTools.psm1
    Get-Command -Module CompanyADTools
    
    Imports the module and lists all available functions.
#>

# Module initialization message
Write-Verbose "Loading CompanyADTools module..."

#region Write-Log Function
# Centralized logging function - used by all other functions in this module
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile = "C:\Scripts\Logs\ADAutomation.log"
    )

    function Write-Log {
    [CmdletBinding()]
    param(
        # The message to log - this is the actual log content
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Message,
        
        # Severity level - determines color coding and categorization
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        # Path to log file - defaults to standard location
        [Parameter(Mandatory=$false)]
        [string]$LogFile = "C:\Scripts\Logs\ADAutomation.log"
    )
    
    # Create log directory if it doesn't exist
    # Split-Path extracts the directory portion from the full file path
    $logDir = Split-Path -Path $LogFile -Parent
    
    if (-not (Test-Path $logDir)) {
        try {
            # Create directory with -Force to create parent directories if needed
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            Write-Verbose "Created log directory: $logDir"
        }
        catch {
            Write-Error "Failed to create log directory: $($_.Exception.Message)"
            return
        }
    }
    
    # Build timestamped log entry
    # Format: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    # Using Add-Content instead of Out-File to append to existing file
    try {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to write to log file: $($_.Exception.Message)"
        # Continue execution even if file write fails (show in console at least)
    }
    
    # Determine console color based on severity level
    # This provides visual feedback when viewing logs in real-time
    $color = switch ($Level) {
        "INFO"    { "White" }      # Standard information - white text
        "WARNING" { "Yellow" }     # Warnings - yellow text
        "ERROR"   { "Red" }        # Errors - red text
        "SUCCESS" { "Green" }      # Success messages - green text
        default   { "White" }      # Fallback to white
    }
    
    # Display log entry to console with appropriate color
    Write-Host $logEntry -ForegroundColor $color
}

}
#endregion

#region New-CompanyADUser Function
# Automated user creation with validation and group assignment
function New-CompanyADUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("IT Department", "HR Department", "Sales Department", "Executives")]
        [string]$Department,
        
        [Parameter(Mandatory=$false)]
        [string]$JobTitle = "Employee"
    )

    function New-CompanyADUser {
    [CmdletBinding()]
    param(
        # User's first name - used for display name and username generation
        [Parameter(Mandatory=$true, HelpMessage="Enter the user's first name")]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        
        # User's last name - used for display name and username generation
        [Parameter(Mandatory=$true, HelpMessage="Enter the user's last name")]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,
        
        # Department - must match existing OU structure in Active Directory
        [Parameter(Mandatory=$true, HelpMessage="Select the user's department")]
        [ValidateSet("IT Department", "HR Department", "Sales Department", "Executives")]
        [string]$Department,
        
        # Job title - optional parameter with default value
        [Parameter(Mandatory=$false)]
        [string]$JobTitle = "Employee"
    )
    
    # Import Active Directory module - required for AD cmdlets
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Verbose "Active Directory module loaded successfully"
    }
    catch {
        Write-Error "Failed to load Active Directory module. Ensure RSAT tools are installed."
        return
    }
    
    # Generate username using standard naming convention: firstname.lastname
    # Convert to lowercase for consistency
    $Username = "$($FirstName.ToLower()).$($LastName.ToLower())"
    Write-Verbose "Generated username: $Username"
    
    # Check if user already exists to prevent duplicates
    # Using SilentlyContinue to suppress errors if user doesn't exist
    Write-Host "`nChecking for existing user account..." -ForegroundColor Yellow
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue
    
    if ($existingUser) {
        Write-Host "✗ ERROR: User '$Username' already exists in Active Directory!" -ForegroundColor Red
        Write-Host "  Distinguished Name: $($existingUser.DistinguishedName)" -ForegroundColor Gray
        return
    }
    
    # Generate temporary password
    # In production, consider using secure password generation or random passwords
    $TempPassword = "Welcome123!@#"
    $SecurePassword = ConvertTo-SecureString $TempPassword -AsPlainText -Force
    Write-Verbose "Temporary password generated"
    
    # Build OU path based on department
    # Organizational Units must exist in Active Directory prior to running this script
    $OUPath = "OU=$Department,DC=company,DC=local"
    Write-Verbose "Target OU: $OUPath"
    
    # Create the user account with all required attributes
    Write-Host "Creating new user account..." -ForegroundColor Cyan
    
    try {
        # New-ADUser creates the user object in Active Directory
        # All parameters are explicitly defined for clarity and auditability
        New-ADUser `
            -Name "$FirstName $LastName" `                      
            -GivenName $FirstName `                             
            -Surname $LastName `                                
            -SamAccountName $Username `                         
            -UserPrincipalName "$Username@testlab.local" `      
            -EmailAddress "$Username@testlab.local" `           
            -Title $JobTitle `                                  
            -Department $Department `                           
            -Path $OUPath `                                     
            -AccountPassword $SecurePassword `                  
            -Enabled $true `                                   
            -ChangePasswordAtLogon $true `                      
            -PasswordNeverExpires $false `                      
            -ErrorAction Stop                                 
        
        # Success message with user details
        Write-Host "`n✓ SUCCESS: User account created successfully!" -ForegroundColor Green
        Write-Host "  ──────────────────────────────────────────" -ForegroundColor Green
        Write-Host "  Full Name      : $FirstName $LastName"
        Write-Host "  Username       : $Username"
        Write-Host "  Department     : $Department"
        Write-Host "  Job Title      : $JobTitle"
        Write-Host "  Email          : $Username@testlab.local"
        Write-Host "  UPN            : $Username@testlab.local"
        Write-Host "  OU Location    : $OUPath"
        Write-Host "  ──────────────────────────────────────────" -ForegroundColor Green
        Write-Host "  Temp Password  : $TempPassword" -ForegroundColor Yellow
        Write-Host "  Password Change: Required at first logon" -ForegroundColor Yellow
        Write-Host "  ──────────────────────────────────────────" -ForegroundColor Green
        
        # Add user to appropriate security group based on department
        # Security groups control access to resources
        Write-Host "`nAdding user to security group..." -ForegroundColor Cyan
        
        # Map department to appropriate security group
        $GroupName = switch ($Department) {
            "IT Department"    { "IT Support Team" }
            "HR Department"    { "HR Team" }
            "Sales Department" { "Sales Team" }
            "Executives"       { "Executive Team" }
        }
        
        # Add user to the determined group
        # Using SilentlyContinue in case group doesn't exist (non-critical failure)
        try {
            Add-ADGroupMember -Identity $GroupName -Members $Username -ErrorAction Stop
            Write-Host "  ✓ Added to group: $GroupName" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Warning: Could not add user to group '$GroupName'" -ForegroundColor Yellow
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
        
        # Log the action for audit purposes
        # In production, this should write to a central log file
        Write-Verbose "User creation completed: $Username on $(Get-Date)"
        
    }
    catch {
        # Comprehensive error handling with detailed error message
        Write-Host "`n✗ ERROR: Failed to create user account" -ForegroundColor Red
        Write-Host "  Error Details: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host "`nCommon issues:" -ForegroundColor Yellow
        Write-Host "  - OU path doesn't exist: $OUPath"
        Write-Host "  - Insufficient permissions"
        Write-Host "  - Domain controller unreachable"
        Write-Host "  - Invalid characters in username"
    }
}
}
#endregion

#region Get-ADUserReport Function
# Comprehensive user reporting with CSV export
function Get-ADUserReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "C:\Scripts\Reports\UserReport_$(Get-Date -Format 'yyyy-MM-dd').csv"
    )

    function Get-ADUserReport {
    [CmdletBinding()]
    param(
        # Output file path - defaults to Reports folder with date-stamped filename
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "C:\Scripts\Reports\UserReport_$(Get-Date -Format 'yyyy-MM-dd').csv"
    )
    
    # Import Active Directory module
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load Active Directory module."
        return
    }
    
    # Display script header
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Active Directory User Report Generator" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Report will be saved to:" -ForegroundColor Yellow
    Write-Host "  $OutputPath" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Create reports directory if it doesn't exist
    $reportDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path $reportDir)) {
        Write-Host "Creating reports directory: $reportDir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    # Get all users with comprehensive property list
    # Specifying properties ensures they're retrieved in one query (more efficient)
    Write-Host "Retrieving user accounts from Active Directory..." -ForegroundColor Cyan
    
    try {
        $users = Get-ADUser -Filter * -Properties `
            DisplayName,          
            EmailAddress,         
            Department,           
            Title,              
            Enabled,            
            PasswordLastSet,    
            PasswordNeverExpires,
            LastLogonDate,       
            WhenCreated,         
            DistinguishedName    
        
        Write-Host "  Found $($users.Count) user accounts`n" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve users from Active Directory: $($_.Exception.Message)"
        return
    }
    
    # Initialize array to store report data
    # Using ArrayList for better performance with large datasets
    $report = @()
    
    # Counter for progress display
    $currentUser = 0
    $totalUsers = $users.Count
    
    # Process each user account
    foreach ($user in $users) {
        $currentUser++
        
        # Display progress every 10 users
        if ($currentUser % 10 -eq 0) {
            Write-Host "  Processing user $currentUser of $totalUsers..." -ForegroundColor Gray
        }
        
        # Get group memberships for this user
        # This requires a separate query per user (can be slow for large environments)
        try {
            $groups = (Get-ADPrincipalGroupMembership -Identity $user.SamAccountName -ErrorAction SilentlyContinue | 
                      Select-Object -ExpandProperty Name) -join "; "
        }
        catch {
            $groups = "Error retrieving groups"
        }
        
        # Calculate password age in days
        # Handle cases where password has never been set
        if ($user.PasswordLastSet) {
            $passwordAge = (New-TimeSpan -Start $user.PasswordLastSet -End (Get-Date)).Days
        } else {
            $passwordAge = "Never set"
        }
        
        # Extract OU from Distinguished Name
        # DN format: CN=User Name,OU=Department,DC=testlab,DC=local
        # We want just the OU portion
        if ($user.DistinguishedName -match 'OU=') {
            $ouPath = ($user.DistinguishedName -split ',',2)[1]
        } else {
            $ouPath = "Default container"
        }
        
        # Build custom object with all user information
        # PSCustomObject provides structured data for CSV export
        $userReport = [PSCustomObject]@{
            "Username"                = $user.SamAccountName
            "Display Name"            = $user.DisplayName
            "Email"                   = $user.EmailAddress
            "Department"              = $user.Department
            "Job Title"               = $user.Title
            "Enabled"                 = $user.Enabled
            "Password Age (Days)"     = $passwordAge
            "Password Never Expires"  = $user.PasswordNeverExpires
            "Last Logon"              = if ($user.LastLogonDate) { $user.LastLogonDate } else { "Never" }
            "Created Date"            = $user.WhenCreated
            "Groups"                  = $groups
            "OU Location"             = $ouPath
        }
        
        # Add to report collection
        $report += $userReport
    }
    
    # Export report to CSV file
    # -NoTypeInformation prevents PowerShell from adding type data to first line
    Write-Host "`nExporting report to CSV..." -ForegroundColor Cyan
    
    try {
        $report | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
        
        # Display summary statistics
        Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✓ Report Generated Successfully!" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  File Location : $OutputPath" -ForegroundColor White
        Write-Host "  ───────────────────────────────────────────────────" -ForegroundColor Green
        Write-Host "  Total Users   : $($users.Count)" -ForegroundColor Yellow
        Write-Host "  Enabled       : $($users | Where-Object {$_.Enabled -eq $true} | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
        Write-Host "  Disabled      : $($users | Where-Object {$_.Enabled -eq $false} | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Green
        
        # Open the CSV file in default application (usually Excel)
        Write-Host "Opening report..." -ForegroundColor Cyan
        Invoke-Item $OutputPath
    }
    catch {
        Write-Error "Failed to export report: $($_.Exception.Message)"
    }
}

}
#endregion

#region Reset-DepartmentPasswords Function
# Bulk password reset with safety features
function Reset-DepartmentPasswords {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("IT Department", "HR Department", "Sales Department", "Executives")]
        [string]$Department,
        
        [Parameter(Mandatory=$false)]
        [ValidateLength(8,128)]
        [string]$NewPassword = "TempReset123!@#",
        
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )
    function Reset-DepartmentPasswords {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        # Department to target - restricted to valid OU names
        [Parameter(Mandatory=$true, HelpMessage="Select the department for password reset")]
        [ValidateSet("IT Department", "HR Department", "Sales Department", "Executives")]
        [string]$Department,
        
        # New temporary password - should meet complexity requirements
        [Parameter(Mandatory=$false)]
        [ValidateLength(8,128)]
        [string]$NewPassword = "TempReset123!@#",
        
        # WhatIf switch for testing without making changes
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )
    
    # Import Active Directory module
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load Active Directory module."
        return
    }
    
    # Build OU path for the specified department
    $OUPath = "OU=$Department,DC=company,DC=local"
    
    # Display operation header
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Bulk Password Reset Tool" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Department    : $Department" -ForegroundColor White
    Write-Host "  New Password  : $NewPassword" -ForegroundColor White
    Write-Host "  OU Path       : $OUPath" -ForegroundColor White
    
    # Display mode indicator (test vs live)
    if ($WhatIf) {
        Write-Host "  Mode          : TEST MODE (no changes will be made)" -ForegroundColor Yellow
    } else {
        Write-Host "  Mode          : LIVE MODE (passwords WILL be changed!)" -ForegroundColor Red
    }
    
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Retrieve all users in the specified OU
    Write-Host "Retrieving users from $Department..." -ForegroundColor Cyan
    
    try {
        $users = Get-ADUser -Filter * -SearchBase $OUPath -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to retrieve users from OU: $($_.Exception.Message)"
        return
    }
    
    # Verify users were found
    if ($users.Count -eq 0) {
        Write-Host "✗ No users found in $Department" -ForegroundColor Yellow
        Write-Host "  Verify the OU exists and contains user accounts.`n"
        return
    }
    
    Write-Host "  Found $($users.Count) user(s) in $Department`n" -ForegroundColor Green
    
    # Convert password to secure string (required by Set-ADAccountPassword)
    $SecurePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force
    
    # Initialize counters for summary
    $successCount = 0
    $failureCount = 0
    
    # Process each user account
    foreach ($user in $users) {
        
        # In test mode, just display what would happen
        if ($WhatIf) {
            Write-Host "  [TEST] Would reset password for: $($user.SamAccountName)" -ForegroundColor Yellow
            $successCount++
        }
        # In live mode, actually perform the password reset
        else {
            try {
                # Reset the password
                # -Reset parameter clears the old password (no verification needed)
                Set-ADAccountPassword -Identity $user.SamAccountName `
                                     -NewPassword $SecurePassword `
                                     -Reset `
                                     -ErrorAction Stop
                
                # Force user to change password at next logon (security best practice)
                Set-ADUser -Identity $user.SamAccountName `
                          -ChangePasswordAtLogon $true `
                          -ErrorAction Stop
                
                Write-Host "  ✓ Password reset successful: $($user.SamAccountName)" -ForegroundColor Green
                $successCount++
                
                # Log the action (requires Write-Log function)
                # Write-Log -Message "Password reset for $($user.SamAccountName) in $Department" -Level "SUCCESS"
                
            }
            catch {
                # Handle individual user failures without stopping entire operation
                Write-Host "  ✗ Failed to reset password: $($user.SamAccountName)" -ForegroundColor Red
                Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
                $failureCount++
                
                # Log the failure
                # Write-Log -Message "Failed to reset password for $($user.SamAccountName): $($_.Exception.Message)" -Level "ERROR"
            }
        }
    }
    
    # Display summary of operation
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Operation Summary" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Total Users   : $($users.Count)" -ForegroundColor White
    Write-Host "  Successful    : $successCount" -ForegroundColor Green
    
    if ($failureCount -gt 0) {
        Write-Host "  Failed        : $failureCount" -ForegroundColor Red
    }
    
    if ($WhatIf) {
        Write-Host "`n  This was a TEST. No changes were made." -ForegroundColor Yellow
        Write-Host "  Remove -WhatIf parameter to perform actual reset.`n" -ForegroundColor Yellow
    } else {
        Write-Host "`n  ✓ Password reset operation completed" -ForegroundColor Green
        Write-Host "  All users must change password at next logon.`n" -ForegroundColor Yellow
    }
}
}
#endregion

#region Find-InactiveUsers Function
# Security audit tool for inactive accounts
function Find-InactiveUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,365)]
        [int]$DaysInactive = 90,
        
        [Parameter(Mandatory=$false)]
        [switch]$ExportCSV
    )
    function Find-InactiveUsers {
    [CmdletBinding()]
    param(
        # Number of days to consider a user inactive
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,365)]
        [int]$DaysInactive = 90,
        
        # Switch to export results to CSV
        [Parameter(Mandatory=$false)]
        [switch]$ExportCSV
    )
    
    # Import Active Directory module
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load Active Directory module."
        return
    }
    
    # Display search parameters
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Inactive User Account Search" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Criteria: No logon for $DaysInactive days or more" -ForegroundColor Yellow
    Write-Host "  Date Threshold: $(Get-Date (Get-Date).AddDays(-$DaysInactive) -Format 'yyyy-MM-dd')" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Calculate cutoff date
    # Users who haven't logged in since this date are considered inactive
    $cutoffDate = (Get-Date).AddDays(-$DaysInactive)
    
    # Retrieve all enabled user accounts
    # Only checking enabled accounts as disabled accounts are already known to be inactive
    Write-Host "Searching for inactive enabled user accounts..." -ForegroundColor Cyan
    
    try {
        $allUsers = Get-ADUser -Filter {Enabled -eq $true} `
                              -Properties LastLogonDate, WhenCreated, Department, Title `
                              -ErrorAction Stop
        
        Write-Host "  Retrieved $($allUsers.Count) enabled user accounts`n" -ForegroundColor White
    }
    catch {
        Write-Error "Failed to retrieve users: $($_.Exception.Message)"
        return
    }
    
    # Filter users based on last logon date
    # Include users who:
    # 1. Have never logged in (LastLogonDate is null), OR
    # 2. Last logged in before the cutoff date
    $inactiveUsers = $allUsers | Where-Object {
        ($_.LastLogonDate -eq $null) -or ($_.LastLogonDate -lt $cutoffDate)
    }
    
    # Check if any inactive users were found
    if ($inactiveUsers.Count -eq 0) {
        Write-Host "✓ No inactive users found!" -ForegroundColor Green
        Write-Host "  All enabled accounts have logged in within the last $DaysInactive days.`n"
        return
    }
    
    # Display warning about inactive accounts found
    Write-Host "⚠ Found $($inactiveUsers.Count) inactive user account(s):`n" -ForegroundColor Yellow
    
    # Initialize array for report data
    $report = @()
    
    # Process each inactive user
    foreach ($user in $inactiveUsers) {
        
        # Calculate days inactive
        # Handle case where user has never logged in
        if ($user.LastLogonDate) {
            $daysInactive = (New-TimeSpan -Start $user.LastLogonDate -End (Get-Date)).Days
            $lastLogonDisplay = $user.LastLogonDate.ToString('yyyy-MM-dd HH:mm')
        } else {
            $daysInactive = "Never logged in"
            $lastLogonDisplay = "Never"
        }
        
        # Display user information to console
        Write-Host "  ⚠ User: $($user.SamAccountName)" -ForegroundColor Yellow
        Write-Host "     Display Name  : $($user.Name)" -ForegroundColor White
        Write-Host "     Department    : $($user.Department)" -ForegroundColor White
        Write-Host "     Job Title     : $($user.Title)" -ForegroundColor White
        Write-Host "     Last Logon    : $lastLogonDisplay" -ForegroundColor White
        Write-Host "     Days Inactive : $daysInactive" -ForegroundColor Red
        Write-Host "     Created       : $($user.WhenCreated.ToString('yyyy-MM-dd'))" -ForegroundColor White
        Write-Host ""
        
        # Build report object for CSV export
        $reportEntry = [PSCustomObject]@{
            Username        = $user.SamAccountName
            DisplayName     = $user.Name
            Department      = $user.Department
            JobTitle        = $user.Title
            LastLogon       = $lastLogonDisplay
            DaysInactive    = $daysInactive
            AccountCreated  = $user.WhenCreated.ToString('yyyy-MM-dd')
            EmailAddress    = $user.UserPrincipalName
        }
        
        $report += $reportEntry
    }
    
    # Display summary
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  Summary: $($inactiveUsers.Count) inactive account(s) found" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Yellow
    
    # Export to CSV if requested
    if ($ExportCSV) {
        $csvPath = "C:\Scripts\Reports\InactiveUsers_$(Get-Date -Format 'yyyy-MM-dd').csv"
        
        # Create reports directory if it doesn't exist
        $reportDir = Split-Path -Path $csvPath -Parent
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        
        try {
            # Export report to CSV
            $report | Export-Csv -Path $csvPath -NoTypeInformation -ErrorAction Stop
            
            Write-Host "✓ Report exported to CSV" -ForegroundColor Green
            Write-Host "  File: $csvPath`n" -ForegroundColor White
            
            # Open the CSV file
            Invoke-Item $csvPath
        }
        catch {
            Write-Error "Failed to export CSV: $($_.Exception.Message)"
        }
    }
    
    # Provide recommendations
    Write-Host "Recommended Actions:" -ForegroundColor Cyan
    Write-Host "  1. Review each account to determine if still needed" -ForegroundColor White
    Write-Host "  2. Contact account owners to verify status" -ForegroundColor White
    Write-Host "  3. Disable accounts that are no longer needed" -ForegroundColor White
    Write-Host "  4. Delete disabled accounts after 30-90 day retention period`n" -ForegroundColor White
    
    # Return the collection of inactive users
    return $inactiveUsers
}
}
#endregion

# Export all functions to make them available when module is imported
# This controls which functions are publicly accessible
Export-ModuleMember -Function @(
    'New-CompanyADUser',
    'Get-ADUserReport',
    'Reset-DepartmentPasswords',
    'Find-InactiveUsers',
    'Write-Log'
)

# Module loaded message
Write-Verbose "CompanyADTools module loaded successfully. Use 'Get-Command -Module CompanyADTools' to see available functions."

# End of module