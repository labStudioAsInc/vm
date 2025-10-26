#
# Manual Google Drive Sync Helper
# This script can be run manually from within the RDP session
#

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("backup", "restore", "status")]
    [string]$Action,
    [string]$Username = $env:USERNAME
)

# Check if Google Drive API key is available
if (-not $env:GOOGLE_DRIVE_API_KEY) {
    Write-Host "Google Drive API key not found in environment variables."
    Write-Host "Please ensure GOOGLE_DRIVE_API_KEY is set in your GitHub repository secrets."
    exit 1
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SyncScript = Join-Path $ScriptPath "google-drive-sync.ps1"

if (-not (Test-Path $SyncScript)) {
    Write-Error "Google Drive sync script not found at: $SyncScript"
    exit 1
}

switch ($Action) {
    "backup" {
        Write-Host "=== Manual Backup ===" -ForegroundColor Green
        Write-Host "Starting backup for user: $Username"
        & $SyncScript -Action "backup" -Username $Username
    }
    "restore" {
        Write-Host "=== Manual Restore ===" -ForegroundColor Yellow
        Write-Host "WARNING: This will overwrite your current data with the backup from Google Drive."
        $confirm = Read-Host "Are you sure you want to continue? (y/N)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            Write-Host "Starting restore for user: $Username"
            & $SyncScript -Action "restore" -Username $Username
        } else {
            Write-Host "Restore cancelled."
        }
    }
    "status" {
        Write-Host "=== Google Drive Sync Status ===" -ForegroundColor Cyan
        Write-Host "Username: $Username"
        Write-Host "API Key: $($env:GOOGLE_DRIVE_API_KEY.Substring(0,10))..." 
        
        # Check if backup exists
        try {
            $ApiKey = $env:GOOGLE_DRIVE_API_KEY
            $BackupFileName = "rdp-session-$Username.zip"
            
            # Get folder ID
            $folderName = "RDP-Sessions-Backup"
            $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$folderName' and mimeType='application/vnd.google-apps.folder'&key=$ApiKey"
            $response = Invoke-RestMethod -Uri $searchUrl -Method Get
            
            if ($response.files.Count -gt 0) {
                $folderId = $response.files[0].id
                Write-Host "Backup folder found: $folderName"
                
                # Check for backup file
                $fileSearchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName' and parents in '$folderId'&key=$ApiKey"
                $fileResponse = Invoke-RestMethod -Uri $fileSearchUrl -Method Get
                
                if ($fileResponse.files.Count -gt 0) {
                    $backupFile = $fileResponse.files[0]
                    Write-Host "Backup found: $($backupFile.name)"
                    Write-Host "Last modified: $($backupFile.modifiedTime)"
                    Write-Host "Size: $([math]::Round($backupFile.size / 1MB, 2)) MB"
                } else {
                    Write-Host "No backup found for user: $Username" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No backup folder found" -ForegroundColor Yellow
            }
        } catch {
            Write-Error "Failed to check backup status: $_"
        }
    }
}

Write-Host ""
Write-Host "Available commands:"
Write-Host "  .\manual-sync.ps1 -Action backup    # Create backup"
Write-Host "  .\manual-sync.ps1 -Action restore   # Restore from backup"
Write-Host "  .\manual-sync.ps1 -Action status    # Check backup status"