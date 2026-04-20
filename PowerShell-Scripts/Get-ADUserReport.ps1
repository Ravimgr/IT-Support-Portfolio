<#
.SYNOPSIS
    Generates a comprehensive report of all Active Directory users with detailed information.

.DESCRIPTION
    This script creates a detailed report of all user accounts in Active Directory including
    account status, password information, group memberships, and last logon data. The report
    is exported to CSV format for analysis in Excel or other tools.
    
    Useful for security audits, compliance reporting, and user account management.

.PARAMETER OutputPath
    The file path where the CSV report will be saved. If not specified, defaults to
    C:\Scripts\Reports\UserReport_YYYY-MM-DD.csv with current date.

.EXAMPLE
    Get-ADUserReport
    
    Generates report with default filename including today's date and opens it automatically.

.EXAMPLE
    Get-ADUserReport -OutputPath "C:\Reports\Users_April2026.csv"
    
    Generates report with custom filename and location.

.NOTES
    File Name      : Get-ADUserReport.ps1
    Author         : Ravi Thapa
    Created        : March 2026
    Prerequisite   : Active Directory PowerShell Module
    Requires       : Read permissions on Active Directory
    
    Output Format  : CSV (Comma-Separated Values)
    Opens in       : Excel or default CSV handler
    
#>

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

# Example usage (commented out - uncomment to test):
# Get-ADUserReport
# Get-ADUserReport -OutputPath "C:\Reports\MyUserReport.csv"