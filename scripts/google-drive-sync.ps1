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

# Check for authentication method
if (-not $env:GOOGLE_DRIVE_API_KEY -and -not $env:GOOGLE_SERVICE_ACCOUNT_JSON) {
    Write-Error "Error: Neither GOOGLE_DRIVE_API_KEY nor GOOGLE_SERVICE_ACCOUNT_JSON environment variable is set."
    exit 1
}

$ApiKey = $env:GOOGLE_DRIVE_API_KEY
$UseServiceAccount = $env:GOOGLE_SERVICE_ACCOUNT_JSON -ne $null
$BackupFileName = "rdp-session-$Username.zip"
$UserProfile = "C:\Users\$Username"

# Function to get access token using service account
function Get-AccessToken {
    if (-not $UseServiceAccount) {
        return $null
    }
    
    try {
        $serviceAccount = $env:GOOGLE_SERVICE_ACCOUNT_JSON | ConvertFrom-Json
        
        # Create JWT assertion for service account
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        
        # Create the JWT header
        $header = @{
            "alg" = "RS256"
            "typ" = "JWT"
        }
        
        # Create the JWT payload
        $payload = @{
            "iss" = $serviceAccount.client_email
            "scope" = "https://www.googleapis.com/auth/drive.file"
            "aud" = "https://oauth2.googleapis.com/token"
            "exp" = $now + 3600
            "iat" = $now
        }
        
        # Convert to Base64URL encoding
        $headerJson = $header | ConvertTo-Json -Compress
        $payloadJson = $payload | ConvertTo-Json -Compress
        
        $headerBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($headerJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        $payloadBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        
        # Create the signature (simplified approach using .NET crypto)
        $privateKeyPem = $serviceAccount.private_key
        
        # Remove PEM headers and decode
        $privateKeyPem = $privateKeyPem -replace "-----BEGIN PRIVATE KEY-----", ""
        $privateKeyPem = $privateKeyPem -replace "-----END PRIVATE KEY-----", ""
        $privateKeyPem = $privateKeyPem -replace "\s", ""
        
        $privateKeyBytes = [Convert]::FromBase64String($privateKeyPem)
        
        # Create RSA provider and sign
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportPkcs8PrivateKey($privateKeyBytes, [ref]$null)
        
        $dataToSign = "$headerBase64.$payloadBase64"
        $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($dataToSign)
        $signature = $rsa.SignData($dataBytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $signatureBase64 = [Convert]::ToBase64String($signature).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        
        $jwt = "$headerBase64.$payloadBase64.$signatureBase64"
        
        # Exchange JWT for access token
        $tokenRequest = @{
            grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
            assertion = $jwt
        }
        
        $tokenResponse = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" -Method Post -Body $tokenRequest -ContentType "application/x-www-form-urlencoded"
        
        Write-Host "Successfully obtained access token"
        return $tokenResponse.access_token
        
    } catch {
        Write-Error "Failed to get access token: $_"
        Write-Host "Error details: $($_.Exception.Message)"
        return $null
    }
}

# Function to get Google Drive folder ID for RDP backups
function Get-RDPBackupFolderId {
    param($AccessToken)
    
    $folderName = "RDP-Sessions-Backup"
    
    try {
        if ($UseServiceAccount -and $AccessToken) {
            # Use service account with access token
            $headers = @{
                "Authorization" = "Bearer $AccessToken"
                "Content-Type" = "application/json"
            }
            $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$folderName' and mimeType='application/vnd.google-apps.folder'"
            $response = Invoke-RestMethod -Uri $searchUrl -Method Get -Headers $headers
            
            if ($response.files.Count -gt 0) {
                Write-Host "Found existing backup folder: $($response.files[0].name)"
                return $response.files[0].id
            }
            
            # Create folder if it doesn't exist
            Write-Host "Creating backup folder: $folderName"
            $createFolderBody = @{
                name = $folderName
                mimeType = "application/vnd.google-apps.folder"
            } | ConvertTo-Json
            
            $createResponse = Invoke-RestMethod -Uri "https://www.googleapis.com/drive/v3/files" -Method Post -Headers $headers -Body $createFolderBody
            Write-Host "Created backup folder with ID: $($createResponse.id)"
            return $createResponse.id
            
        } elseif ($ApiKey) {
            # Use API key (limited functionality)
            $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$folderName' and mimeType='application/vnd.google-apps.folder'&key=$ApiKey"
            $response = Invoke-RestMethod -Uri $searchUrl -Method Get -ErrorAction SilentlyContinue
            
            if ($response.files.Count -gt 0) {
                Write-Host "Found existing backup folder"
                return $response.files[0].id
            }
            
            Write-Warning "Cannot create folder with API key. Using root folder. Please manually create '$folderName' folder in your Google Drive."
            return "root"
        }
        
    } catch {
        Write-Warning "Failed to get/create backup folder: $_"
        Write-Host "Error details: $($_.Exception.Message)"
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
    $accessToken = $null
    if ($UseServiceAccount) {
        $accessToken = Get-AccessToken
        if (-not $accessToken) {
            Write-Warning "Failed to get access token. Falling back to local backup."
        }
    }
    
    $folderId = Get-RDPBackupFolderId -AccessToken $accessToken
    if (-not $folderId) {
        Write-Error "Failed to get backup folder ID"
        return $false
    }
    
    # Always save locally as backup
    $localBackupDir = "C:\RDPBackups"
    if (-not (Test-Path $localBackupDir)) {
        New-Item -ItemType Directory -Path $localBackupDir -Force | Out-Null
    }
    
    $localBackupPath = "$localBackupDir\$BackupFileName"
    Copy-Item -Path $zipPath -Destination $localBackupPath -Force
    Write-Host "Backup saved locally: $localBackupPath"
    
    # Try to upload to Google Drive
    if ($UseServiceAccount -and $accessToken) {
        try {
            Write-Host "Uploading backup to Google Drive..."
            
            # Check if backup already exists and delete it
            $headers = @{
                "Authorization" = "Bearer $accessToken"
            }
            
            $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName' and parents in '$folderId'"
            $existingFiles = Invoke-RestMethod -Uri $searchUrl -Method Get -Headers $headers
            
            foreach ($file in $existingFiles.files) {
                $deleteUrl = "https://www.googleapis.com/drive/v3/files/$($file.id)"
                Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers
                Write-Host "Deleted existing backup: $($file.name)"
            }
            
            # Upload new backup using multipart upload
            $boundary = [System.Guid]::NewGuid().ToString()
            $metadata = @{
                name = $BackupFileName
                parents = @($folderId)
            } | ConvertTo-Json
            
            $fileBytes = [System.IO.File]::ReadAllBytes($zipPath)
            
            $bodyLines = @(
                "--$boundary",
                "Content-Type: application/json; charset=UTF-8",
                "",
                $metadata,
                "",
                "--$boundary",
                "Content-Type: application/zip",
                "",
                [System.Text.Encoding]::Latin1.GetString($fileBytes),
                "--$boundary--"
            )
            
            $body = $bodyLines -join "`r`n"
            $bodyBytes = [System.Text.Encoding]::Latin1.GetBytes($body)
            
            $uploadHeaders = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type" = "multipart/related; boundary=$boundary"
                "Content-Length" = $bodyBytes.Length
            }
            
            $uploadUrl = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
            $response = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $bodyBytes
            
            Write-Host "Successfully uploaded backup to Google Drive: $($response.name) (ID: $($response.id))"
            Remove-Item -Path $BackupPath -Recurse -Force
            return $true
            
        } catch {
            Write-Warning "Failed to upload to Google Drive: $_"
            Write-Host "Error details: $($_.Exception.Message)"
            Write-Host "Backup is still available locally at: $localBackupPath"
        }
    } elseif ($ApiKey) {
        Write-Warning "API key authentication has limited functionality. Cannot upload files to Google Drive."
        Write-Host "Please use Service Account authentication for full Google Drive integration."
    }
    
    # Keep temp file for artifact upload
    Write-Host "Backup also available at: $zipPath"
    Remove-Item -Path $BackupPath -Recurse -Force
    
    return $true  # Return true since local backup succeeded
}

# Function to restore user data from Google Drive
function Restore-UserData {
    Write-Host "Starting restore process for user: $Username"
    
    $accessToken = $null
    if ($UseServiceAccount) {
        $accessToken = Get-AccessToken
        if (-not $accessToken) {
            Write-Warning "Failed to get access token. Will try local backup only."
        }
    }
    
    $folderId = Get-RDPBackupFolderId -AccessToken $accessToken
    if (-not $folderId) {
        Write-Warning "No backup folder found. This might be the first run."
        return $true
    }
    
    $zipPath = "$env:TEMP\$BackupFileName"
    $foundBackup = $false
    
    # Try to download from Google Drive first (if using service account)
    if ($UseServiceAccount -and $accessToken) {
        try {
            Write-Host "Searching for backup in Google Drive..."
            $headers = @{
                "Authorization" = "Bearer $accessToken"
            }
            
            $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName' and parents in '$folderId'"
            $response = Invoke-RestMethod -Uri $searchUrl -Method Get -Headers $headers
            
            if ($response.files.Count -gt 0) {
                $fileId = $response.files[0].id
                Write-Host "Found backup in Google Drive: $($response.files[0].name)"
                
                # Download the file
                $downloadUrl = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media"
                Invoke-RestMethod -Uri $downloadUrl -Method Get -Headers $headers -OutFile $zipPath
                Write-Host "Downloaded backup from Google Drive"
                $foundBackup = $true
            }
        } catch {
            Write-Warning "Failed to download from Google Drive: $_"
            Write-Host "Error details: $($_.Exception.Message)"
        }
    }
    
    # Fallback to local backup if Google Drive failed or not available
    if (-not $foundBackup) {
        $localBackupDir = "C:\RDPBackups"
        $localBackupPath = "$localBackupDir\$BackupFileName"
        
        if (Test-Path $localBackupPath) {
            Write-Host "Found local backup file: $localBackupPath"
            Copy-Item -Path $localBackupPath -Destination $zipPath -Force
            Write-Host "Using local backup for restore"
            $foundBackup = $true
        } elseif ($ApiKey) {
            # Try Google Drive search with API key (limited functionality)
            try {
                $searchUrl = "https://www.googleapis.com/drive/v3/files?q=name='$BackupFileName'&key=$ApiKey"
                $response = Invoke-RestMethod -Uri $searchUrl -Method Get -ErrorAction SilentlyContinue
                
                if ($response.files.Count -eq 0) {
                    Write-Warning "No backup found for user: $Username. This might be the first run."
                    return $true
                }
                
                Write-Warning "Found backup in Google Drive, but API key cannot download private files."
                Write-Warning "Please use Service Account authentication for full Google Drive integration."
                return $true
            } catch {
                Write-Warning "Failed to search Google Drive with API key: $_"
            }
        }
    }
    
    if (-not $foundBackup) {
        Write-Warning "No backup found for user: $Username. This might be the first run."
        return $true
    }
    
    # Verify the backup file exists and is valid
    if (-not (Test-Path $zipPath)) {
        Write-Warning "Backup file not found at: $zipPath"
        return $true
    }
    
    try {
        
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