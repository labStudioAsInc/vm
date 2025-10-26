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
        # User folders
        @{Source = "$UserProfile\Desktop"; Dest = "$BackupPath\Desktop"},
        @{Source = "$UserProfile\Documents"; Dest = "$BackupPath\Documents"},
        @{Source = "$UserProfile\Downloads"; Dest = "$BackupPath\Downloads"},
        @{Source = "$UserProfile\Pictures"; Dest = "$BackupPath\Pictures"},
        @{Source = "$UserProfile\Videos"; Dest = "$BackupPath\Videos"},
        @{Source = "$UserProfile\Music"; Dest = "$BackupPath\Music"},
        
        # Application data (Roaming - synced across devices)
        @{Source = "$UserProfile\AppData\Roaming"; Dest = "$BackupPath\AppData\Roaming"},
        
        # Chrome data (complete profile including login data, extensions, bookmarks)
        @{Source = "$UserProfile\AppData\Local\Google\Chrome\User Data"; Dest = "$BackupPath\Chrome\User Data"},
        
        # Edge data (if exists)
        @{Source = "$UserProfile\AppData\Local\Microsoft\Edge\User Data"; Dest = "$BackupPath\Edge\User Data"},
        
        # Firefox data (if exists)
        @{Source = "$UserProfile\AppData\Roaming\Mozilla\Firefox"; Dest = "$BackupPath\Firefox"},
        @{Source = "$UserProfile\AppData\Local\Mozilla\Firefox"; Dest = "$BackupPath\Firefox\Local"},
        
        # VS Code settings and extensions
        @{Source = "$UserProfile\AppData\Roaming\Code"; Dest = "$BackupPath\VSCode\Roaming"},
        @{Source = "$UserProfile\AppData\Local\Programs\Microsoft VS Code"; Dest = "$BackupPath\VSCode\Local"},
        @{Source = "$UserProfile\.vscode"; Dest = "$BackupPath\.vscode"},
        
        # Git configuration
        @{Source = "$UserProfile\.gitconfig"; Dest = "$BackupPath\.gitconfig"},
        @{Source = "$UserProfile\.gitignore_global"; Dest = "$BackupPath\.gitignore_global"},
        
        # SSH keys and configuration
        @{Source = "$UserProfile\.ssh"; Dest = "$BackupPath\.ssh"},
        
        # Windows Terminal settings
        @{Source = "$UserProfile\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"; Dest = "$BackupPath\WindowsTerminal"},
        
        # PowerShell profile
        @{Source = "$UserProfile\Documents\PowerShell"; Dest = "$BackupPath\PowerShell"},
        @{Source = "$UserProfile\Documents\WindowsPowerShell"; Dest = "$BackupPath\WindowsPowerShell"},
        
        # Android Studio settings (if exists)
        @{Source = "$UserProfile\.android"; Dest = "$BackupPath\.android"},
        @{Source = "$UserProfile\AppData\Roaming\Google\AndroidStudio2023.3"; Dest = "$BackupPath\AndroidStudio"},
        
        # JetBrains IDEs settings
        @{Source = "$UserProfile\AppData\Roaming\JetBrains"; Dest = "$BackupPath\JetBrains"},
        
        # Notepad++ settings
        @{Source = "$UserProfile\AppData\Roaming\Notepad++"; Dest = "$BackupPath\Notepad++"},
        
        # Sublime Text settings
        @{Source = "$UserProfile\AppData\Roaming\Sublime Text"; Dest = "$BackupPath\SublimeText"},
        
        # Node.js global packages info
        @{Source = "$UserProfile\AppData\Roaming\npm"; Dest = "$BackupPath\npm"},
        
        # Python pip configuration
        @{Source = "$UserProfile\AppData\Roaming\pip"; Dest = "$BackupPath\pip"},
        @{Source = "$UserProfile\.pypirc"; Dest = "$BackupPath\.pypirc"},
        
        # Docker Desktop settings (if exists)
        @{Source = "$UserProfile\AppData\Roaming\Docker"; Dest = "$BackupPath\Docker"},
        
        # Postman settings
        @{Source = "$UserProfile\AppData\Roaming\Postman"; Dest = "$BackupPath\Postman"},
        
        # Slack settings
        @{Source = "$UserProfile\AppData\Roaming\Slack"; Dest = "$BackupPath\Slack"},
        
        # Discord settings
        @{Source = "$UserProfile\AppData\Roaming\discord"; Dest = "$BackupPath\Discord"},
        
        # Zoom settings
        @{Source = "$UserProfile\AppData\Roaming\Zoom"; Dest = "$BackupPath\Zoom"},
        
        # Teams settings
        @{Source = "$UserProfile\AppData\Roaming\Microsoft\Teams"; Dest = "$BackupPath\Teams"}
    )
    
    # Copy files to backup directory
    $backupCount = 0
    $totalItems = $itemsToBackup.Count
    
    foreach ($item in $itemsToBackup) {
        if (Test-Path $item.Source) {
            $backupCount++
            Write-Host "[$backupCount/$totalItems] Backing up: $($item.Source)"
            
            try {
                $destDir = Split-Path $item.Dest -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                
                if (Test-Path $item.Source -PathType Container) {
                    # For directories, copy recursively but exclude some large/temporary files
                    $excludePatterns = @("*.tmp", "*.temp", "*.log", "Cache", "cache", "Temp", "temp", "CachedData")
                    
                    # Special handling for Chrome to avoid copying large cache files
                    if ($item.Source -like "*Chrome*" -or $item.Source -like "*Edge*") {
                        Write-Host "  → Copying browser data (excluding cache files)..."
                        robocopy $item.Source $item.Dest /E /XD "Cache" "Code Cache" "GPUCache" "ShaderCache" "Service Worker" /XF "*.tmp" "*.log" /R:1 /W:1 /NP /NDL /NFL | Out-Null
                    } else {
                        Copy-Item -Path $item.Source -Destination $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    Copy-Item -Path $item.Source -Destination $item.Dest -Force -ErrorAction SilentlyContinue
                }
                
                Write-Host "  ✓ Success"
            } catch {
                Write-Warning "  ✗ Failed to backup $($item.Source): $_"
            }
        } else {
            Write-Host "Skipping (not found): $($item.Source)"
        }
    }
    
    Write-Host "Backup summary: $backupCount items found and backed up out of $totalItems total items"
    
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
    
    # Always save locally as backup and for GitHub artifacts
    $localBackupDir = "C:\RDPBackups"
    if (-not (Test-Path $localBackupDir)) {
        New-Item -ItemType Directory -Path $localBackupDir -Force | Out-Null
    }
    
    $localBackupPath = "$localBackupDir\$BackupFileName"
    Copy-Item -Path $zipPath -Destination $localBackupPath -Force
    Write-Host "Backup saved locally: $localBackupPath"
    
    # Also save to a standard location for GitHub artifacts
    $artifactBackupPath = "$env:TEMP\github-artifact-$BackupFileName"
    Copy-Item -Path $zipPath -Destination $artifactBackupPath -Force
    Write-Host "Backup prepared for GitHub artifact: $artifactBackupPath"
    
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
            Write-Host "✅ Google Drive backup completed successfully"
            Remove-Item -Path $BackupPath -Recurse -Force
            return $true
            
        } catch {
            Write-Warning "❌ Failed to upload to Google Drive: $_"
            Write-Host "Error details: $($_.Exception.Message)"
            Write-Host "📦 Backup will be available as GitHub artifact instead"
            Write-Host "Local backup available at: $localBackupPath"
        }
    } elseif ($ApiKey) {
        Write-Warning "⚠️ API key authentication has limited functionality. Cannot upload files to Google Drive."
        Write-Host "📦 Backup will be available as GitHub artifact and locally"
        Write-Host "Please use Service Account authentication for full Google Drive integration."
    } else {
        Write-Host "ℹ️ Google Drive persistence is disabled. Using GitHub artifacts for backup."
    }
    
    # Keep temp file for artifact upload
    Write-Host "Backup also available at: $zipPath"
    Write-Host "GitHub artifact backup ready at: $artifactBackupPath"
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
        # Check for GitHub artifact backup first
        $artifactBackupPath = "$env:TEMP\github-artifact-$BackupFileName"
        if (Test-Path $artifactBackupPath) {
            Write-Host "Found GitHub artifact backup: $artifactBackupPath"
            Copy-Item -Path $artifactBackupPath -Destination $zipPath -Force
            Write-Host "Using GitHub artifact backup for restore"
            $foundBackup = $true
        } else {
            # Check for local backup
            $localBackupDir = "C:\RDPBackups"
            $localBackupPath = "$localBackupDir\$BackupFileName"
            
            if (Test-Path $localBackupPath) {
                Write-Host "Found local backup file: $localBackupPath"
                Copy-Item -Path $localBackupPath -Destination $zipPath -Force
                Write-Host "Using local backup for restore"
                $foundBackup = $true
            }
        }
        
        if (-not $foundBackup -and $ApiKey) {
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
        
        # Restore files to user profile (matching the backup structure)
        $itemsToRestore = @(
            # User folders
            @{Source = "$BackupPath\Desktop"; Dest = "$UserProfile\Desktop"},
            @{Source = "$BackupPath\Documents"; Dest = "$UserProfile\Documents"},
            @{Source = "$BackupPath\Downloads"; Dest = "$UserProfile\Downloads"},
            @{Source = "$BackupPath\Pictures"; Dest = "$UserProfile\Pictures"},
            @{Source = "$BackupPath\Videos"; Dest = "$UserProfile\Videos"},
            @{Source = "$BackupPath\Music"; Dest = "$UserProfile\Music"},
            
            # Application data
            @{Source = "$BackupPath\AppData\Roaming"; Dest = "$UserProfile\AppData\Roaming"},
            
            # Browser data
            @{Source = "$BackupPath\Chrome\User Data"; Dest = "$UserProfile\AppData\Local\Google\Chrome\User Data"},
            @{Source = "$BackupPath\Edge\User Data"; Dest = "$UserProfile\AppData\Local\Microsoft\Edge\User Data"},
            @{Source = "$BackupPath\Firefox"; Dest = "$UserProfile\AppData\Roaming\Mozilla\Firefox"},
            @{Source = "$BackupPath\Firefox\Local"; Dest = "$UserProfile\AppData\Local\Mozilla\Firefox"},
            
            # Development tools
            @{Source = "$BackupPath\VSCode\Roaming"; Dest = "$UserProfile\AppData\Roaming\Code"},
            @{Source = "$BackupPath\VSCode\Local"; Dest = "$UserProfile\AppData\Local\Programs\Microsoft VS Code"},
            @{Source = "$BackupPath\.vscode"; Dest = "$UserProfile\.vscode"},
            @{Source = "$BackupPath\.gitconfig"; Dest = "$UserProfile\.gitconfig"},
            @{Source = "$BackupPath\.gitignore_global"; Dest = "$UserProfile\.gitignore_global"},
            @{Source = "$BackupPath\.ssh"; Dest = "$UserProfile\.ssh"},
            
            # Terminal and shell
            @{Source = "$BackupPath\WindowsTerminal"; Dest = "$UserProfile\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"},
            @{Source = "$BackupPath\PowerShell"; Dest = "$UserProfile\Documents\PowerShell"},
            @{Source = "$BackupPath\WindowsPowerShell"; Dest = "$UserProfile\Documents\WindowsPowerShell"},
            
            # IDEs and editors
            @{Source = "$BackupPath\.android"; Dest = "$UserProfile\.android"},
            @{Source = "$BackupPath\AndroidStudio"; Dest = "$UserProfile\AppData\Roaming\Google\AndroidStudio2023.3"},
            @{Source = "$BackupPath\JetBrains"; Dest = "$UserProfile\AppData\Roaming\JetBrains"},
            @{Source = "$BackupPath\Notepad++"; Dest = "$UserProfile\AppData\Roaming\Notepad++"},
            @{Source = "$BackupPath\SublimeText"; Dest = "$UserProfile\AppData\Roaming\Sublime Text"},
            
            # Development environments
            @{Source = "$BackupPath\npm"; Dest = "$UserProfile\AppData\Roaming\npm"},
            @{Source = "$BackupPath\pip"; Dest = "$UserProfile\AppData\Roaming\pip"},
            @{Source = "$BackupPath\.pypirc"; Dest = "$UserProfile\.pypirc"},
            @{Source = "$BackupPath\Docker"; Dest = "$UserProfile\AppData\Roaming\Docker"},
            
            # Communication and productivity apps
            @{Source = "$BackupPath\Postman"; Dest = "$UserProfile\AppData\Roaming\Postman"},
            @{Source = "$BackupPath\Slack"; Dest = "$UserProfile\AppData\Roaming\Slack"},
            @{Source = "$BackupPath\Discord"; Dest = "$UserProfile\AppData\Roaming\discord"},
            @{Source = "$BackupPath\Zoom"; Dest = "$UserProfile\AppData\Roaming\Zoom"},
            @{Source = "$BackupPath\Teams"; Dest = "$UserProfile\AppData\Roaming\Microsoft\Teams"}
        )
        
        $restoreCount = 0
        $totalRestoreItems = $itemsToRestore.Count
        
        foreach ($item in $itemsToRestore) {
            if (Test-Path $item.Source) {
                $restoreCount++
                Write-Host "[$restoreCount/$totalRestoreItems] Restoring: $($item.Source) -> $($item.Dest)"
                
                try {
                    $destDir = Split-Path $item.Dest -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    
                    if (Test-Path $item.Source -PathType Container) {
                        # Remove existing destination to avoid conflicts
                        if (Test-Path $item.Dest) {
                            Write-Host "  → Removing existing data..."
                            Remove-Item -Path $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                        }
                        
                        # Special handling for browser data
                        if ($item.Dest -like "*Chrome*" -or $item.Dest -like "*Edge*") {
                            Write-Host "  → Restoring browser data..."
                            robocopy $item.Source $item.Dest /E /R:1 /W:1 /NP /NDL /NFL | Out-Null
                        } else {
                            Copy-Item -Path $item.Source -Destination $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    } else {
                        Copy-Item -Path $item.Source -Destination $item.Dest -Force -ErrorAction SilentlyContinue
                    }
                    
                    Write-Host "  ✓ Success"
                } catch {
                    Write-Warning "  ✗ Failed to restore $($item.Source): $_"
                }
            } else {
                Write-Host "Skipping (not in backup): $($item.Source)"
            }
        }
        
        Write-Host "Restore summary: $restoreCount items restored out of $totalRestoreItems total items"
        
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