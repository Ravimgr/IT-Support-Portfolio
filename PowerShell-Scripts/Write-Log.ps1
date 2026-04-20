<#
.SYNOPSIS
    Writes log entries to file and console with timestamp and severity levels.

.DESCRIPTION
    This function provides centralized logging capability for all scripts. It writes
    timestamped log entries to a file while also displaying them in the console with
    color coding based on severity level.
    
    Supports multiple severity levels (INFO, WARNING, ERROR, SUCCESS) and automatically
    creates the log directory if it doesn't exist.

.PARAMETER Message
    The log message to write. This is the actual content that will be logged.

.PARAMETER Level
    The severity level of the log entry. Valid values are:
    - INFO: General information (default)
    - WARNING: Warning messages
    - ERROR: Error messages
    - SUCCESS: Success confirmations
    
    Default is INFO if not specified.

.PARAMETER LogFile
    The full path to the log file. If not specified, defaults to
    C:\Scripts\Logs\ADAutomation.log

.EXAMPLE
    Write-Log -Message "Script started" -Level "INFO"
    
    Writes an informational message to the log.

.EXAMPLE
    Write-Log -Message "User created successfully" -Level "SUCCESS"
    
    Writes a success message to the log with green color in console.

.EXAMPLE
    Write-Log -Message "Failed to connect to domain controller" -Level "ERROR"
    
    Writes an error message to the log with red color in console.

.NOTES
    File Name      : Write-Log.ps1
    Author         : Ravi Thapa
    Created        : March 2026
    Prerequisite   : None
    
    Log Format     : [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
    Default Path   : C:\Scripts\Logs\ADAutomation.log
#>

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

# Example usage (commented out - uncomment to test):
# Information message:
# Write-Log -Message "Script execution started" -Level "INFO"

# Success message:
# Write-Log -Message "User account created successfully" -Level "SUCCESS"

# Warning message:
# Write-Log -Message "Low disk space detected on server" -Level "WARNING"

# Error message:
# Write-Log -Message "Failed to connect to domain controller" -Level "ERROR"

# Using pipeline input:
# "Processing user account" | Write-Log -Level "INFO"

# Custom log file location:
# Write-Log -Message "Custom log entry" -Level "INFO" -LogFile "C:\CustomLogs\MyScript.log"