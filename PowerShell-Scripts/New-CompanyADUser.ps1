<#
.SYNOPSIS
    Creates a new Active Directory user with automated configuration and group assignment.

.DESCRIPTION
    This script automates the creation of Active Directory user accounts with standardized
    settings including automatic username generation, password policy enforcement, OU placement,
    and security group membership based on department.
    
    The script includes comprehensive error handling and validation to ensure reliable
    user provisioning in enterprise environments.

.PARAMETER FirstName
    The user's first name. This is used to generate the username and populate the GivenName attribute.
    This parameter is mandatory.

.PARAMETER LastName
    The user's last name. This is used to generate the username and populate the Surname attribute.
    This parameter is mandatory.

.PARAMETER Department
    The user's department. Must be one of: "IT Department", "HR Department", "Sales Department", "Executives"
    This determines the OU placement and security group assignment.
    This parameter is mandatory.

.PARAMETER JobTitle
    The user's job title. This is optional and defaults to "Employee" if not specified.

.EXAMPLE
    New-CompanyADUser -FirstName "John" -LastName "Smith" -Department "IT Department" -JobTitle "IT Technician"
    
    Creates a new user account for John Smith in the IT Department with the job title IT Technician.
    Username will be automatically generated as john.smith.

.EXAMPLE
    New-CompanyADUser -FirstName "Sarah" -LastName "Williams" -Department "HR Department"
    
    Creates a new user account for Sarah Williams in HR Department with default job title "Employee".

.NOTES
    File Name      : New-CompanyADUser.ps1
    Author         : Ravi Thapa
    Created        : March 2026
    Prerequisite   : Active Directory PowerShell Module
    Domain         : testlab.local
    
    Default Password: Welcome123!@#
    Users are forced to change password at first logon.
#>

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

# Example usage (commented out - uncomment to test):
# New-CompanyADUser -FirstName "Tom" -LastName "Anderson" -Department "IT Department" -JobTitle "Helpdesk Technician"
# New-CompanyADUser -FirstName "Sarah" -LastName "Wilson" -Department "HR Department" -JobTitle "HR Manager"
# New-CompanyADUser -FirstName "Mike" -LastName "Johnson" -Department "Sales Department"