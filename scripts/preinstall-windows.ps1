#
# This script contains pre-installation steps for Windows.
# It should be run with Administrator privileges.
#

Write-Host "Starting Windows pre-install steps..."

# 1. Create a new user with a static password
Write-Host "Step 1: Creating new user 'testuser'..."
try {
    $Password = ConvertTo-SecureString "Gck83gYShmW6IqfpNwRT" -AsPlainText -Force
    New-LocalUser "testuser" -Password $Password -FullName "Test User" -Description "Test user account." -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member "testuser"
    Write-Host "Successfully created user 'testuser' and added to Administrators group."
} catch {
    Write-Error "Failed to create user: $_"
}

# 2. Install VB-CABLE Virtual Audio Device
Write-Host "Step 2: Installing VB-CABLE virtual audio device..."
$tempDir = "$env:TEMP\vbcable_install"
$zipUrl = "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip"
$zipFile = "$tempDir\vbcable.zip"

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

try {
    Write-Host "Downloading VB-CABLE from $zipUrl..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
    Write-Host "Download complete. Extracting archive..."
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

    $setupPath = ""
    if ([System.Environment]::Is64BitOperatingSystem) {
        $setupPath = "$tempDir\VBCABLE_Setup_x64.exe"
    } else {
        $setupPath = "$tempDir\VBCABLE_Setup.exe"
    }

    if (Test-Path $setupPath) {
        Write-Host "Running installer from $setupPath..."
        # Using -ArgumentList '/S' for silent installation
        Start-Process -FilePath $setupPath -ArgumentList "/S" -Verb RunAs -Wait
        Write-Host "VB-CABLE installation process completed."
    } else {
        Write-Error "VB-CABLE setup executable not found at $setupPath."
    }
} catch {
    Write-Error "Failed to install VB-CABLE: $_"
} finally {
    # Clean up downloaded files
    if (Test-Path $tempDir) {
        Write-Host "Cleaning up temporary installation files..."
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

# 3. Set Google Chrome as the default browser
Write-Host "Step 3: Setting Google Chrome as the default browser..."
$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@

$xmlPath = "$env:TEMP\DefaultApps.xml"
try {
    $xmlContent | Out-File -FilePath $xmlPath -Encoding utf8
    Write-Host "Applying default browser association..."
    Dism.exe /Online /Import-DefaultAppAssociations:$xmlPath
    Write-Host "Default browser association applied. A reboot may be required for changes to take full effect."
} catch {
    Write-Error "Failed to set default browser: $_"
} finally {
    # Clean up the XML file
    if (Test-Path $xmlPath) {
        Remove-Item -Path $xmlPath -Force
    }
}

Write-Host "Windows pre-install steps completed."