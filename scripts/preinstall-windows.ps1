<#
.SYNOPSIS
    This script performs pre-installation and configuration tasks for a Windows VM.

.DESCRIPTION
    This script automates the initial setup of a Windows environment. It performs the following actions:
    - Creates a new local user with administrative privileges using credentials from the environment.
    - Optionally installs a suite of software using Chocolatey, including a virtual sound card, GitHub Desktop, VS Code, and more.
    - Optionally sets the default web browser.
    - Enables Remote Desktop Protocol (RDP) and configures firewall rules to allow connections.

    This script must be run with Administrator privileges. It also requires the following environment variables to be set:
    - USER_PASSWORD: The password for the new user account.
    - NGROK_AUTH_TOKEN: The authentication token for ngrok (required for tunnel setup, although not used directly in this script, it's part of the overall workflow).

.PARAMETER Username
    The username for the new local user account to be created. This parameter is mandatory.

.PARAMETER InstallVirtualSoundCard
    A boolean switch ('true' or 'false') to determine whether to install the VB-CABLE virtual audio device. Defaults to 'false'.

.PARAMETER InstallGitHubDesktop
    A boolean switch ('true' or 'false') to determine whether to install GitHub Desktop. Defaults to 'false'.

.PARAMETER InstallBrowserOS
    A boolean switch ('true' or 'false') to determine whether to install BrowserOS (placeholder). Defaults to 'false'.

.PARAMETER InstallVoidEditor
    A boolean switch ('true' or 'false') to determine whether to install Void Editor (placeholder). Defaults to 'false'.

.PARAMETER InstallAndroidStudio
    A boolean switch ('true' or 'false') to determine whether to install Android Studio. Defaults to 'false'.

.PARAMETER InstallVSCode
    A boolean switch ('true' or 'false') to determine whether to install Visual Studio Code. Defaults to 'false'.

.PARAMETER SetDefaultBrowser
    Specifies the default browser to set. Accepts 'chrome', 'browseros', or 'none'. Defaults to 'none'.

.EXAMPLE
    .\preinstall-windows.ps1 -Username "testuser" -InstallVSCode 'true' -SetDefaultBrowser 'chrome'

.NOTES
    Author: TheRealAshik
    Date: 2025-10-06
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$InstallVirtualSoundCard = 'false',
    [string]$InstallGitHubDesktop = 'false',
    [string]$InstallBrowserOS = 'false',
    [string]$InstallVoidEditor = 'false',
    [string]$InstallAndroidStudio = 'false',
    [string]$InstallVSCode = 'false',
    [string]$SetDefaultBrowser = 'none'
)

# Convert string input parameters to boolean types for easier handling in the script.
$InstallVirtualSoundCardBool = $InstallVirtualSoundCard.ToLower() -eq 'true'
$InstallGitHubDesktopBool = $InstallGitHubDesktop.ToLower() -eq 'true'
$InstallBrowserOSBool = $InstallBrowserOS.ToLower() -eq 'true'
$InstallVoidEditorBool = $InstallVoidEditor.ToLower() -eq 'true'
$InstallAndroidStudioBool = $InstallAndroidStudio.ToLower() -eq 'true'
$InstallVSCodeBool = $InstallVSCode.ToLower() -eq 'true'

# Check for required environment variables.
if (-not $env:USER_PASSWORD) {
    Write-Error "Error: USER_PASSWORD environment variable is not set."
    exit 1
}

if (-not $env:NGROK_AUTH_TOKEN) {
    Write-Error "Error: NGROK_AUTH_TOKEN environment variable is not set."
    exit 1
}

Write-Host "Starting Windows pre-install steps..."

# Section 1: Create a new user with a static password
# This section creates a new local user, sets their password from the USER_PASSWORD environment variable,
# and adds them to the local Administrators group.
Write-Host "Step 1: Creating new user '$Username'..."
try {
    $Password = ConvertTo-SecureString $env:USER_PASSWORD -AsPlainText -Force
    New-LocalUser -Name $Username -Password $Password -FullName $Username -Description "Dynamic user account." -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $Username
    Write-Host "Successfully created user '$Username' and added to Administrators group."
} catch {
    Write-Error "Failed to create user: $_"
}

# Section 2: Optional Software Installations
# This section installs various software based on the boolean flags passed to the script.
# All installations are performed using the Chocolatey package manager.
if ($InstallVirtualSoundCardBool) {
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
        # Allow audio capture redirection in RDP sessions.
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "fEnableAudioCapture" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "fDisableAudioCapture" -Value 0 -Type DWord -Force
        Write-Host "Audio setup is complete."
    } catch {
        Write-Error "Failed to set up virtual audio: $_"
    }
}

if ($InstallGitHubDesktopBool) {
    Write-Host "Installing GitHub Desktop..."
    try {
        choco install github-desktop -y --force
        Write-Host "GitHub Desktop installed successfully."
    } catch {
        Write-Error "Failed to install GitHub Desktop: $_"
    }
}

if ($InstallBrowserOSBool) {
    Write-Host "Installing BrowserOS..."
    try {
        # Assuming a Chocolatey package exists. If not, this will need to be updated.
        choco install browseros -y --force
        Write-Host "BrowserOS installed successfully."
    } catch {
        Write-Error "Failed to install BrowserOS: $_"
    }
}

if ($InstallVoidEditorBool) {
    Write-Host "Installing Void Editor..."
    try {
        # Assuming a Chocolatey package exists.
        choco install void-editor -y --force
        Write-Host "Void Editor installed successfully."
    } catch {
        Write-Error "Failed to install Void Editor: $_"
    }
}

if ($InstallAndroidStudioBool) {
    Write-Host "Installing Android Studio..."
    try {
        choco install android-studio -y --force
        Write-Host "Android Studio installed successfully."
    } catch {
        Write-Error "Failed to install Android Studio: $_"
    }
}

if ($InstallVSCodeBool) {
    Write-Host "Installing VS Code..."
    try {
        choco install vscode -y --force
        Write-Host "VS Code installed successfully."
    } catch {
        Write-Error "Failed to install VS Code: $_"
    }
}


# Section 3: Set Default Browser
# This section sets the default browser for HTTP and HTTPS protocols based on user input.
# It generates a default application association XML and imports it using DISM.
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

# Section 4: Enable Remote Desktop
# This section enables Remote Desktop connections by modifying the registry
# and enabling the necessary firewall rules.
Write-Host "Step 4: Enabling Remote Desktop..."
try {
    # This registry key enables RDP connections. A value of 0 means "allow".
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
    # This command enables the built-in "Remote Desktop" firewall rule group.
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Write-Host "Remote Desktop enabled."
} catch {
    Write-Error "Failed to enable Remote Desktop: $_"
}

Write-Host "Windows pre-install steps completed."