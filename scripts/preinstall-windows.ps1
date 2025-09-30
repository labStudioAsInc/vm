#
# This script contains pre-installation steps for Windows.
# It should be run with Administrator privileges.
#

param (
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [bool]$InstallVirtualSoundCard = $false,
    [bool]$InstallGitHubDesktop = $false,
    [bool]$InstallBrowserOS = $false,
    [bool]$InstallVoidEditor = $false,
    [bool]$InstallAndroidStudio = $false,
    [bool]$InstallVSCode = $false,
    [string]$SetDefaultBrowser = 'none'
)

if (-not $env:USER_PASSWORD) {
    Write-Error "Error: USER_PASSWORD environment variable is not set."
    exit 1
}

if (-not $env:NGROK_AUTH_TOKEN) {
    Write-Error "Error: NGROK_AUTH_TOKEN environment variable is not set."
    exit 1
}

Write-Host "Starting Windows pre-install steps..."

# 1. Create a new user with a static password
Write-Host "Step 1: Creating new user '$Username'..."
try {
    $Password = ConvertTo-SecureString $env:USER_PASSWORD -AsPlainText -Force
    New-LocalUser -Name $Username -Password $Password -FullName $Username -Description "Dynamic user account." -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $Username
    Write-Host "Successfully created user '$Username' and added to Administrators group."
} catch {
    Write-Error "Failed to create user: $_"
}

# 2. Optional Installations
if ($InstallVirtualSoundCard) {
    Write-Host "Installing and configuring virtual audio..."
    try {
        Write-Host "Installing VB-CABLE Virtual Audio Device using Chocolatey..."
        choco install vb-cable -y --force

        Write-Host "Enabling Windows Audio Services..."
        Set-Service -Name Audiosrv -StartupType Automatic -PassThru | Start-Service
        Set-Service -Name AudioEndpointBuilder -StartupType Automatic -PassThru | Start-Service

        Write-Host "Configuring Group Policy for RDP Audio Redirection..."
        if (-not (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services')) {
            New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Force | Out-Null
        }
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "fEnableAudioCapture" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "fDisableAudioCapture" -Value 0 -Type DWord -Force
        Write-Host "Audio setup is complete."
    } catch {
        Write-Error "Failed to set up virtual audio: $_"
    }
}

if ($InstallGitHubDesktop) {
    Write-Host "Installing GitHub Desktop..."
    try {
        choco install github-desktop -y --force
        Write-Host "GitHub Desktop installed successfully."
    } catch {
        Write-Error "Failed to install GitHub Desktop: $_"
    }
}

if ($InstallBrowserOS) {
    Write-Host "Installing BrowserOS..."
    try {
        # Assuming a Chocolatey package exists. If not, this will need to be updated.
        choco install browseros -y --force
        Write-Host "BrowserOS installed successfully."
    } catch {
        Write-Error "Failed to install BrowserOS: $_"
    }
}

if ($InstallVoidEditor) {
    Write-Host "Installing Void Editor..."
    try {
        # Assuming a Chocolatey package exists.
        choco install void-editor -y --force
        Write-Host "Void Editor installed successfully."
    } catch {
        Write-Error "Failed to install Void Editor: $_"
    }
}

if ($InstallAndroidStudio) {
    Write-Host "Installing Android Studio..."
    try {
        choco install android-studio -y --force
        Write-Host "Android Studio installed successfully."
    } catch {
        Write-Error "Failed to install Android Studio: $_"
    }
}

if ($InstallVSCode) {
    Write-Host "Installing VS Code..."
    try {
        choco install vscode -y --force
        Write-Host "VS Code installed successfully."
    } catch {
        Write-Error "Failed to install VS Code: $_"
    }
}


# 3. Set Default Browser
if ($SetDefaultBrowser -ne 'none') {
    Write-Host "Setting default browser to $SetDefaultBrowser..."
    $progId = ""
    $appName = ""

    if ($SetDefaultBrowser -eq 'chrome') {
        $progId = "ChromeHTML"
        $appName = "Google Chrome"
    } elseif ($SetDefaultBrowser -eq 'browseros') {
        # This ProgId is a placeholder and may need to be corrected
        $progId = "BrowserOSHTML"
        $appName = "BrowserOS"
    }

    if ($progId) {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".htm" ProgId="$progId" ApplicationName="$appName" />
  <Association Identifier=".html" ProgId="$progId" ApplicationName="$appName" />
  <Association Identifier="http" ProgId="$progId" ApplicationName="$appName" />
  <Association Identifier="https" ProgId="$progId" ApplicationName="$appName" />
</DefaultAssociations>
"@
        $xmlPath = "$env:TEMP\DefaultApps.xml"
        try {
            $xmlContent | Out-File -FilePath $xmlPath -Encoding utf8
            Write-Host "Applying default browser association..."
            Dism.exe /Online /Import-DefaultAppAssociations:$xmlPath
            Write-Host "Default browser association applied."
        } catch {
            Write-Error "Failed to set default browser: $_"
        } finally {
            if (Test-Path $xmlPath) {
                Remove-Item -Path $xmlPath -Force
            }
        }
    }
}

# 4. Enable Remote Desktop
Write-Host "Step 4: Enabling Remote Desktop..."
try {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Write-Host "Remote Desktop enabled."
} catch {
    Write-Error "Failed to enable Remote Desktop: $_"
}

Write-Host "Windows pre-install steps completed."