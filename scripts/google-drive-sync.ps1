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

# Function to get Google Drive folder ID for RDP backups
function Get-RDPBackupFolderId {
    $folderName = "RDP-Sessions-Backup"
    $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$folderName' and mimeType='application/vnd.google-apps.folder'&key=$ApiKey"
    
    try {
        $response = Invoke-RestMethod -Uri $searchUrl -Method Get
        if ($response.files.Count -gt 0) {
            return $response.files[0].id
        } else {
            # Create folder if it doesn't exist
            $createFolderUrl = "https://www.googleapis.com/drive/v3/files?key=$ApiKey"
            $folderMetadata = @{
                name = $folderName
                mimeType = "application/vnd.google-apps.folder"
            } | ConvertTo-Json
            
            $headers = @{
                "Content-Type" = "application/json"
            }
            
            $newFolder = Invoke-RestMethod -Uri $createFolderUrl -Method Post -Body $folderMetadata -Headers $headers
            return $newFolder.id
        }
    } catch {
        Write-Error "Failed to get/create backup folder: $_"
        return $null
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
        $uploadUrl = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&key=$ApiKey"
        
        $metadata = @{
            name = $BackupFileName
            parents = @($folderId)
        } | ConvertTo-Json
        
        $boundary = [System.Guid]::NewGuid().ToString()
        $fileBytes = [System.IO.File]::ReadAllBytes($zipPath)
        
        $bodyLines = @(
            "--$boundary",
            "Content-Type: application/json; charset=UTF-8",
            "",
            $metadata,
            "--$boundary",
            "Content-Type: application/zip",
            "",
            [System.Text.Encoding]::Latin1.GetString($fileBytes),
            "--$boundary--"
        )
        
        $body = $bodyLines -join "`r`n"
        $bodyBytes = [System.Text.Encoding]::Latin1.GetBytes($body)
        
        $headers = @{
            "Content-Type" = "multipart/related; boundary=$boundary"
        }
        
        $response = Invoke-RestMethod -Uri $uploadUrl -Method Post -Body $bodyBytes -Headers $headers
        Write-Host "Backup uploaded successfully. File ID: $($response.id)"
        
        # Cleanup
        Remove-Item -Path $zipPath -Force
        Remove-Item -Path $BackupPath -Recurse -Force
        
        return $true
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
    
    # Search for backup file
    $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName' and parents in '$folderId'&key=$ApiKey"
    try {
        $response = Invoke-RestMethod -Uri $searchUrl -Method Get
        if ($response.files.Count -eq 0) {
            Write-Warning "No backup found for user: $Username. This might be the first run."
            return $true
        }
        
        $fileId = $response.files[0].id
        Write-Host "Found backup file. Downloading..."
        
        # Download backup
        $downloadUrl = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$ApiKey"
        $zipPath = "$env:TEMP\$BackupFileName"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
        Write-Host "Backup downloaded successfully"
        
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