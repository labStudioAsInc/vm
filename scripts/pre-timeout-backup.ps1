#
# Pre-timeout backup script
# This script runs 5 minutes before session timeout to ensure data is saved
#

param (
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [Parameter(Mandatory=$false)]
    [int]$MinutesBeforeTimeout = 5
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🚨 ============================================== 🚨"
Write-Host "⚠️  SESSION TIMEOUT WARNING"
Write-Host "🚨 ============================================== 🚨"
Write-Host ""
Write-Host "⏰ Your session will end in approximately $MinutesBeforeTimeout minutes!"
Write-Host "📦 Creating emergency backup to preserve your work..."
Write-Host ""

# Create a desktop notification file for the user
$UserProfile = "C:\Users\$Username"
$NotificationFile = "$UserProfile\Desktop\⚠️ SESSION ENDING SOON.txt"

$NotificationContent = @"
🚨 SESSION TIMEOUT WARNING 🚨

Your RDP session will end in approximately $MinutesBeforeTimeout minutes!

📦 An emergency backup is being created automatically.
💾 Your data will be saved to:
   • Google Drive (if configured)
   • GitHub Artifacts (as fallback)
   • Local backup files

⏰ Session end time: $(Get-Date -Date (Get-Date).AddMinutes($MinutesBeforeTimeout) -Format "HH:mm:ss")

🔄 What's being backed up:
   • Desktop files and folders
   • Documents, Downloads, Pictures
   • Browser data (Chrome, Edge, Firefox)
   • Application settings and configurations
   • Development tools settings (VS Code, Git, etc.)

✅ You can continue working - the backup runs in the background.
📋 Check the GitHub Actions logs for backup status.

This file will be included in your backup.
"@

try {
    $NotificationContent | Out-File -FilePath $NotificationFile -Encoding UTF8 -Force
    Write-Host "📝 Created desktop notification: $NotificationFile"
} catch {
    Write-Warning "Failed to create desktop notification: $_"
}

# Attempt the backup with enhanced error handling
try {
    Write-Host "🔄 Starting pre-timeout backup process..."
    
    # Run the backup script
    $backupResult = & "$PSScriptRoot\google-drive-sync.ps1" -Action "backup" -Username $Username
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ ============================================== ✅"
        Write-Host "✅ PRE-TIMEOUT BACKUP COMPLETED SUCCESSFULLY"
        Write-Host "✅ ============================================== ✅"
        Write-Host ""
        Write-Host "💾 Your work has been safely backed up!"
        Write-Host "📦 Backup locations:"
        Write-Host "   • Google Drive (if configured)"
        Write-Host "   • GitHub Artifacts"
        Write-Host "   • Local files: C:\RDPBackups\"
        Write-Host ""
        Write-Host "⏰ You have approximately $MinutesBeforeTimeout minutes remaining."
        Write-Host "🔄 Continue working - a final backup will occur at session end."
        
        # Update the notification file with success
        $successContent = $NotificationContent + "`n`n✅ BACKUP COMPLETED SUCCESSFULLY at $(Get-Date -Format "HH:mm:ss")"
        $successContent | Out-File -FilePath $NotificationFile -Encoding UTF8 -Force
        
    } else {
        throw "Backup script returned exit code: $LASTEXITCODE"
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ ============================================== ❌"
    Write-Host "❌ PRE-TIMEOUT BACKUP ENCOUNTERED ISSUES"
    Write-Host "❌ ============================================== ❌"
    Write-Host ""
    Write-Warning "Backup error: $_"
    Write-Host ""
    Write-Host "🔄 Don't worry! Additional backup attempts will be made:"
    Write-Host "   • Final backup at session end"
    Write-Host "   • GitHub Artifacts as fallback"
    Write-Host "   • Local backup files"
    Write-Host ""
    Write-Host "💡 To manually backup your important files:"
    Write-Host "   • Copy files to Desktop (will be backed up)"
    Write-Host "   • Use the desktop backup shortcuts"
    Write-Host "   • Check C:\RDPBackups\ for local copies"
    
    # Update notification with error info
    $errorContent = $NotificationContent + "`n`n❌ BACKUP HAD ISSUES at $(Get-Date -Format "HH:mm:ss")`nError: $_`n`n🔄 Final backup will be attempted at session end."
    try {
        $errorContent | Out-File -FilePath $NotificationFile -Encoding UTF8 -Force
    } catch {
        Write-Warning "Could not update notification file: $_"
    }
}

Write-Host ""
Write-Host "📋 Next steps:"
Write-Host "   1. Save any open work immediately"
Write-Host "   2. Close applications gracefully"  
Write-Host "   3. Final backup will run automatically at session end"
Write-Host ""
Write-Host "⏰ Session ends in approximately $MinutesBeforeTimeout minutes."
Write-Host ""