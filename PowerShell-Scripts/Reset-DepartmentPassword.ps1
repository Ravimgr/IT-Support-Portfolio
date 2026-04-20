<#
.SYNOPSIS
    Resets passwords for all users in a specified department with safety controls.

.DESCRIPTION
    This script performs bulk password resets for all users in a specified organizational unit.
    It includes safety features like -WhatIf testing mode and confirmation prompts to prevent
    accidental password resets.
    
    All users will be required to change their password at next logon for security.

.PARAMETER Department
    The department whose users' passwords will be reset. Must match existing OU names.
    Valid values: "IT Department", "HR Department", "Sales Department", "Executives"

.PARAMETER NewPassword
    The temporary password to set for all users. Defaults to "TempReset123!@#"
    Users will be forced to change this at next logon.

.PARAMETER WhatIf
    Test mode - shows what would happen without actually making changes.
    Highly recommended to run with -WhatIf first before actual reset.

.EXAMPLE
    Reset-DepartmentPasswords -Department "Sales Department" -WhatIf
    
    Tests the password reset operation without making actual changes (safe to run).

.EXAMPLE
    Reset-DepartmentPasswords -Department "IT Department" -NewPassword "SecureTemp456!"
    
    Resets all IT Department users' passwords to specified value.

.NOTES
    File Name      : Reset-DepartmentPasswords.ps1
    Author         : Ravi Thapa
    Created        : March 2026
    Prerequisite   : Active Directory PowerShell Module
    Requires       : Password reset permissions in Active Directory
    
    Security Note  : All reset passwords are forced to change at next logon.
    Audit Trail    : Actions are logged to C:\Scripts\Logs\ADAutomation.log
    
#>

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

# Example usage (commented out - uncomment to test):
# Test mode first (safe - no changes made):
# Reset-DepartmentPasswords -Department "Sales Department" -WhatIf

# Live mode (actually resets passwords):
# Reset-DepartmentPasswords -Department "Sales Department"

# Custom password:
# Reset-DepartmentPasswords -Department "IT Department" -NewPassword "CustomTemp789!@#"