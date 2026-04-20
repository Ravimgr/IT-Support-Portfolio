<#
.SYNOPSIS
    Identifies and reports on inactive user accounts in Active Directory.

.DESCRIPTION
    This script searches for user accounts that haven't logged in for a specified number of days.
    Inactive accounts are a security risk and should be regularly audited. This tool helps identify
    accounts that may need to be disabled or deleted.
    
    The script can export results to CSV for further analysis or remediation planning.

.PARAMETER DaysInactive
    Number of days of inactivity to search for. Defaults to 90 days.
    Accounts with no logon in this period will be flagged as inactive.

.PARAMETER ExportCSV
    If specified, exports the list of inactive users to a CSV file.
    File is saved to C:\Scripts\Reports\InactiveUsers_YYYY-MM-DD.csv

.EXAMPLE
    Find-InactiveUsers -DaysInactive 90
    
    Finds all users who haven't logged in for 90 or more days.

.EXAMPLE
    Find-InactiveUsers -DaysInactive 30 -ExportCSV
    
    Finds users inactive for 30+ days and exports results to CSV.

.NOTES
    File Name      : Find-InactiveUsers.ps1
    Author         : Ravi Thapa
    Created        : March-April 2026
    Prerequisite   : Active Directory PowerShell Module
    Requires       : Read permissions on Active Directory
    
    Use Case       : Security audits, compliance reporting, account cleanup
    Best Practice  : Run monthly to identify stale accounts
#>

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

# Example usage (commented out - uncomment to test):
# Find users inactive for 90+ days:
# Find-InactiveUsers -DaysInactive 90

# Find users inactive for 30+ days and export to CSV:
# Find-InactiveUsers -DaysInactive 30 -ExportCSV

# Store results in variable for further processing:
# $inactive = Find-InactiveUsers -DaysInactive 60