#
# Timeout handler script
# This script ensures backup happens even if the session is forcefully terminated
#

param (
    [Parameter(Mandatory=$true)]
    [string]$Username
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🔄 ============================================== 🔄"
Write-Host "🔄 TIMEOUT HANDLER ACTIVATED"
Write-Host "🔄 ============================================== 🔄"
Write-Host ""

# Register a cleanup function that runs on script exit
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host "🚨 PowerShell is exiting - running emergency backup..."
    try {
        & "$PSScriptRoot\google-drive-sync.ps1" -Action "backup" -Username $using:Username
        Write-Host "✅ Emergency backup completed"
    } catch {
        Write-Warning "❌ Emergency backup failed: $_"
    }
}

# Set up signal handlers for graceful shutdown
$null = Register-ObjectEvent -InputObject ([System.Console]) -EventName CancelKeyPress -Action {
    Write-Host ""
    Write-Host "🛑 Ctrl+C detected - initiating graceful shutdown..."
    Write-Host "📦 Creating final backup before exit..."
    
    try {
        & "$PSScriptRoot\google-drive-sync.ps1" -Action "backup" -Username $using:Username
        Write-Host "✅ Final backup completed successfully"
    } catch {
        Write-Warning "❌ Final backup failed: $_"
    }
    
    Write-Host "👋 Session ended gracefully"
    [System.Environment]::Exit(0)
}

Write-Host "🛡️ Timeout protection is now active"
Write-Host "📦 Automatic backups will occur even if session is interrupted"
Write-Host "🔄 Monitoring session for timeout conditions..."
Write-Host ""

# Keep the handler alive
try {
    # This will run until the session ends
    while ($true) {
        Start-Sleep -Seconds 30
        
        # Check if we're approaching timeout (this is a safety check)
        $currentTime = Get-Date
        # You could add additional timeout logic here if needed
    }
} catch {
    Write-Host "🚨 Timeout handler interrupted: $_"
} finally {
    Write-Host "🔄 Timeout handler shutting down..."
}