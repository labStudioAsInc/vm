#
# This script contains pre-installation steps for Windows.
# It should be run with Administrator privileges.
#

param (
    [Parameter(Mandatory=$true)]
    [string]$Username
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

# 2. Install Virtual Sound Card and Enable Audio
Write-Host "Step 2: Installing and configuring virtual audio..."
try {
    Write-Host "Installing VB-CABLE Virtual Audio Device using Chocolatey..."
    choco install vb-cable -y --force

    Write-Host "Enabling Windows Audio Services..."
    Set-Service -Name Audiosrv -StartupType Automatic -PassThru | Start-Service
    Set-Service -Name AudioEndpointBuilder -StartupType Automatic -PassThru | Start-Service

    Write-Host "Configuring Group Policy for RDP Audio Redirection..."
    # Create the key if it doesn't exist
    if (-not (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services')) {
        New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Force | Out-Null
    }
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "fEnableAudioCapture" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "fDisableAudioCapture" -Value 0 -Type DWord -Force
    Write-Host "Audio setup is complete."
} catch {
    Write-Error "Failed to set up virtual audio: $_"
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
    if (Test-Path $xmlPath) {
        Remove-Item -Path $xmlPath -Force
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

# 5. Install and configure ngrok
Write-Host "Step 5: Installing and configuring ngrok..."
try {
    choco install ngrok -y --force
    ngrok.exe config add-authtoken $env:NGROK_AUTH_TOKEN

    Write-Host "Starting ngrok tunnel for RDP..."
    Start-Process -FilePath "ngrok.exe" -ArgumentList "tcp 3389 --log=stdout" -RedirectStandardOutput "ngrok.log" -NoNewWindow

    Write-Host "Setup is complete. Find your ngrok URL in the 'ngrok.log' artifact or the action logs."
} catch {
    Write-Error "Failed to install or configure ngrok: $_"
}


Write-Host "Windows pre-install steps completed."