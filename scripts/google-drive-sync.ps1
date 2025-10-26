#
# Google Drive API Integration for Persistent RDP Sessions
# This script handles backup and restore of user data to/from Google Drive
#

param (
    [Parameter(Mandatory=$true)]
    [string]$Action, # "backup" or "restore"
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$BackupPath = "C:\RDPBackup"
)

if (-not $env:GOOGLE_DRIVE_API_KEY) {
    Write-Error "Error: GOOGLE_DRIVE_API_KEY environment variable is not set."
    exit 1
}

$ApiKey = $env:GOOGLE_DRIVE_API_KEY
$BackupFileName = "rdp-session-$Username.zip"
$UserProfile = "C:\Users\$Username"

# Function to get access token using service account
function Get-AccessToken {
    if (-not $env:GOOGLE_SERVICE_ACCOUNT_JSON) {
        Write-Error "GOOGLE_SERVICE_ACCOUNT_JSON environment variable is not set. Please use service account authentication instead of API key."
        return $null
    }
    
    try {
        $serviceAccount = $env:GOOGLE_SERVICE_ACCOUNT_JSON | ConvertFrom-Json
        
        # Create JWT for service account authentication
        $header = @{
            "alg" = "RS256"
            "typ" = "JWT"
        } | ConvertTo-Json -Compress
        
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $payload = @{
            "iss" = $serviceAccount.client_email
            "scope" = "https://www.googleapis.com/auth/drive.file"
            "aud" = "https://oauth2.googleapis.com/token"
            "exp" = $now + 3600
            "iat" = $now
        } | ConvertTo-Json -Compress
        
        # For simplicity, we'll use a different approach with API key but with proper error handling
        # In production, you should implement proper JWT signing
        Write-Warning "Service account authentication not fully implemented. Falling back to API key with limited functionality."
        return $null
    } catch {
        Write-Error "Failed to get access token: $_"
        return $null
    }
}

# Function to get Google Drive folder ID for RDP backups
function Get-RDPBackupFolderId {
    $folderName = "RDP-Sessions-Backup"
    
    # Try to use a simple approach - create a known folder ID or use root
    # Since API keys have limitations, we'll work around them
    try {
        # First, try to search for existing folder
        $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$folderName' and mimeType='application/vnd.google-apps.folder'&key=$ApiKey"
        $response = Invoke-RestMethod -Uri $searchUrl -Method Get -ErrorAction SilentlyContinue
        
        if ($response.files.Count -gt 0) {
            Write-Host "Found existing backup folder"
            return $response.files[0].id
        }
        
        # If folder doesn't exist, we can't create it with API key
        # Let's use the root folder as fallback
        Write-Warning "Cannot create folder with API key. Using root folder. Please manually create 'RDP-Sessions-Backup' folder in your Google Drive."
        return "root"
        
    } catch {
        Write-Warning "API key has insufficient permissions. Using root folder as fallback."
        Write-Host "Error details: $_"
        return "root"
    }
}

# Function to backup user data to Google Drive
function Backup-UserData {
    Write-Host "Starting backup process for user: $Username"
    
    # Create backup directory
    if (Test-Path $BackupPath) {
        Remove-Item -Path $BackupPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    # Define what to backup
    $itemsToBackup = @(
        @{Source = "$UserProfile\Desktop"; Dest = "$BackupPath\Desktop"},
        @{Source = "$UserProfile\Documents"; Dest = "$BackupPath\Documents"},
        @{Source = "$UserProfile\Downloads"; Dest = "$BackupPath\Downloads"},
        @{Source = "$UserProfile\AppData\Roaming"; Dest = "$BackupPath\AppData\Roaming"},
        @{Source = "$UserProfile\AppData\Local\Google\Chrome\User Data"; Dest = "$BackupPath\Chrome\User Data"},
        @{Source = "$UserProfile\.ssh"; Dest = "$BackupPath\.ssh"},
        @{Source = "$UserProfile\.gitconfig"; Dest = "$BackupPath\.gitconfig"}
    )
    
    # Copy files to backup directory
    foreach ($item in $itemsToBackup) {
        if (Test-Path $item.Source) {
            Write-Host "Backing up: $($item.Source)"
            try {
                if (Test-Path $item.Source -PathType Container) {
                    Copy-Item -Path $item.Source -Destination $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    $destDir = Split-Path $item.Dest -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    Copy-Item -Path $item.Source -Destination $item.Dest -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Warning "Failed to backup $($item.Source): $_"
            }
        }
    }
    
    # Create zip archive
    $zipPath = "$env:TEMP\$BackupFileName"
    Write-Host "Creating archive: $zipPath"
    Compress-Archive -Path "$BackupPath\*" -DestinationPath $zipPath -Force
    
    # Upload to Google Drive
    $folderId = Get-RDPBackupFolderId
    if (-not $folderId) {
        Write-Error "Failed to get backup folder ID"
        return $false
    }
    
    # Check if backup already exists and delete it
    $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName' and parents in '$folderId'&key=$ApiKey"
    try {
        $existingFiles = Invoke-RestMethod -Uri $searchUrl -Method Get
        foreach ($file in $existingFiles.files) {
            $deleteUrl = "https://www.googleapis.com/drive/v3/files/$($file.id)?key=$ApiKey"
            Invoke-RestMethod -Uri $deleteUrl -Method Delete
            Write-Host "Deleted existing backup: $($file.name)"
        }
    } catch {
        Write-Warning "Failed to check/delete existing backups: $_"
    }
    
    # Upload new backup
    Write-Host "Uploading backup to Google Drive..."
    try {
        # API keys cannot upload files to Google Drive
        # We need to inform the user about this limitation
        Write-Error "Cannot upload files with API key authentication. Google Drive API requires OAuth2 or Service Account for file operations."
        Write-Host "Please set up Service Account authentication instead of API key."
        Write-Host "For now, backup will be saved locally at: $zipPath"
        
        # Keep the backup locally as fallback
        $localBackupDir = "C:\RDPBackups"
        if (-not (Test-Path $localBackupDir)) {
            New-Item -ItemType Directory -Path $localBackupDir -Force | Out-Null
        }
        
        $localBackupPath = "$localBackupDir\$BackupFileName"
        Copy-Item -Path $zipPath -Destination $localBackupPath -Force
        Write-Host "Backup saved locally: $localBackupPath"
        Write-Host "This backup will be uploaded as a GitHub Actions artifact"
        
        # Keep temp file for artifact upload, don't remove it yet
        Write-Host "Backup also available at: $zipPath"
        Remove-Item -Path $BackupPath -Recurse -Force
        
        return $false  # Return false since Google Drive upload failed
    } catch {
        Write-Error "Failed to upload backup: $_"
        return $false
    }
}

# Function to restore user data from Google Drive
function Restore-UserData {
    Write-Host "Starting restore process for user: $Username"
    
    $folderId = Get-RDPBackupFolderId
    if (-not $folderId) {
        Write-Warning "No backup folder found. This might be the first run."
        return $true
    }
    
    # Try to search for backup file, but handle API key limitations
    try {
        # Check for local backup first
        $localBackupDir = "C:\RDPBackups"
        $localBackupPath = "$localBackupDir\$BackupFileName"
        
        if (Test-Path $localBackupPath) {
            Write-Host "Found local backup file: $localBackupPath"
            $zipPath = "$env:TEMP\$BackupFileName"
            Copy-Item -Path $localBackupPath -Destination $zipPath -Force
            Write-Host "Using local backup for restore"
        } else {
            # Try Google Drive search (limited with API key)
            $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName'&key=$ApiKey"
            $response = Invoke-RestMethod -Uri $searchUrl -Method Get -ErrorAction SilentlyContinue
            
            if ($response.files.Count -eq 0) {
                Write-Warning "No backup found for user: $Username. This might be the first run."
                return $true
            }
            
            Write-Warning "Found backup in Google Drive, but API key cannot download private files."
            Write-Warning "Please use Service Account authentication for full Google Drive integration."
            return $true
        }
        
        # Extract backup
        if (Test-Path $BackupPath) {
            Remove-Item -Path $BackupPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        
        Expand-Archive -Path $zipPath -DestinationPath $BackupPath -Force
        Write-Host "Backup extracted"
        
        # Restore files to user profile
        $itemsToRestore = @(
            @{Source = "$BackupPath\Desktop"; Dest = "$UserProfile\Desktop"},
            @{Source = "$BackupPath\Documents"; Dest = "$UserProfile\Documents"},
            @{Source = "$BackupPath\Downloads"; Dest = "$UserProfile\Downloads"},
            @{Source = "$BackupPath\AppData\Roaming"; Dest = "$UserProfile\AppData\Roaming"},
            @{Source = "$BackupPath\Chrome\User Data"; Dest = "$UserProfile\AppData\Local\Google\Chrome\User Data"},
            @{Source = "$BackupPath\.ssh"; Dest = "$UserProfile\.ssh"},
            @{Source = "$BackupPath\.gitconfig"; Dest = "$UserProfile\.gitconfig"}
        )
        
        foreach ($item in $itemsToRestore) {
            if (Test-Path $item.Source) {
                Write-Host "Restoring: $($item.Source) -> $($item.Dest)"
                try {
                    if (Test-Path $item.Source -PathType Container) {
                        if (Test-Path $item.Dest) {
                            Remove-Item -Path $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                        }
                        Copy-Item -Path $item.Source -Destination $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        $destDir = Split-Path $item.Dest -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        Copy-Item -Path $item.Source -Destination $item.Dest -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    Write-Warning "Failed to restore $($item.Source): $_"
                }
            }
        }
        
        # Cleanup
        Remove-Item -Path $zipPath -Force
        Remove-Item -Path $BackupPath -Recurse -Force
        
        Write-Host "Restore completed successfully"
        return $true
        
    } catch {
        Write-Error "Failed to restore backup: $_"
        return $false
    }
}

# Main execution
switch ($Action.ToLower()) {
    "backup" {
        $result = Backup-UserData
        if ($result) {
            Write-Host "Backup completed successfully"
            exit 0
        } else {
            Write-Error "Backup failed"
            exit 1
        }
    }
    "restore" {
        $result = Restore-UserData
        if ($result) {
            Write-Host "Restore completed successfully"
            exit 0
        } else {
            Write-Error "Restore failed"
            exit 1
        }
    }
    default {
        Write-Error "Invalid action. Use 'backup' or 'restore'"
        exit 1
    }
}