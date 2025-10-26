#
# Create Desktop Shortcuts for Google Drive Sync
#

param (
    [Parameter(Mandatory=$true)]
    [string]$Username
)

$DesktopPath = "C:\Users\$Username\Desktop"
$ScriptsPath = "C:\actions-runner\_work\_temp\_github_workflow\scripts"

# Ensure desktop directory exists
if (-not (Test-Path $DesktopPath)) {
    New-Item -ItemType Directory -Path $DesktopPath -Force | Out-Null
}

# Create backup shortcut
$BackupShortcut = @"
@echo off
cd /d "$ScriptsPath"
powershell.exe -ExecutionPolicy Bypass -File "manual-sync.ps1" -Action backup
pause
"@

$BackupShortcut | Out-File -FilePath "$DesktopPath\Backup to Google Drive.bat" -Encoding ASCII

# Create restore shortcut
$RestoreShortcut = @"
@echo off
cd /d "$ScriptsPath"
powershell.exe -ExecutionPolicy Bypass -File "manual-sync.ps1" -Action restore
pause
"@

$RestoreShortcut | Out-File -FilePath "$DesktopPath\Restore from Google Drive.bat" -Encoding ASCII

# Create status shortcut
$StatusShortcut = @"
@echo off
cd /d "$ScriptsPath"
powershell.exe -ExecutionPolicy Bypass -File "manual-sync.ps1" -Action status
pause
"@

$StatusShortcut | Out-File -FilePath "$DesktopPath\Check Backup Status.bat" -Encoding ASCII

Write-Host "Desktop shortcuts created successfully at: $DesktopPath"
Write-Host "- Backup to Google Drive.bat"
Write-Host "- Restore from Google Drive.bat" 
Write-Host "- Check Backup Status.bat"