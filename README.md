<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%">

<div align="center">
  
# VM with GitHub Actions

**This repository contains scripts and workflows for the initial setup of Github Runner VMs and configuration of servers for various operating systems. These scripts are designed to automate the pre-installation process, ensuring a consistent and reliable environment for our applications.**

[Overview](#overview) • [How it works](#how-it-works) • [Installation](#installation) • [How to use](#how-to-use) • [Workflow Inputs](#workflow-inputs) • [Secrets Configuration](#secrets-configuration) • [Google Drive Setup](#google-drive-setup)

</div> </div>

## 🚀 Quick Start

1. **Fork this repository** → Click "Fork" button above
2. **Add secrets** → Go to Settings → Secrets and variables → Actions
   - Add `USER_PASSWORD` (your VM password)  
   - Add `NGROK_AUTH_TOKEN` (from [ngrok.com](https://dashboard.ngrok.com/get-started/your-authtoken))
   - Add `GOOGLE_SERVICE_ACCOUNT_JSON` (optional, for Windows persistence)
3. **Run workflow** → Actions tab → "Main Entrypoint" → Run workflow
4. **Connect** → Use connection details from workflow logs with RDP/VNC client

> [!TIP]
> **First time?** Use Windows with default settings for the best experience!

## <a name="overview"></a>Overview

> [!WARNING]
> **macOS and Ubuntu versions are currently not being maintained and may cause crashes. Please use Windows for stable operation.**

> [!NOTE]
> **Windows includes Google Drive integration for persistent storage!** Your files, browser sessions, and app settings are automatically backed up and restored between sessions.

**Free virtual machines via GitHub Actions** - Get instant access to Windows, macOS, or Ubuntu desktops with remote access, software installation, and persistent storage (Windows only).

## How it works

This project uses GitHub Actions to provide free virtual machines with remote desktop access:

### 🚀 **Workflow Process**

1. **🎯 Trigger**: Run workflow from **Actions** tab → Select OS and configuration
2. **⚡ Provision**: GitHub creates fresh VM (Windows/Ubuntu/macOS) 
3. **🔧 Setup**: Installs software, creates user account, enables remote access
4. **🌐 Tunnel**: Creates secure tunnel (ngrok/cloudflare) to VM desktop
5. **💾 Restore** *(Windows only)*: Restores your data from Google Drive/GitHub artifacts
6. **🖥️ Connect**: Use RDP/VNC client with connection details from logs
7. **💾 Backup** *(Windows only)*: Multi-layered backup system:
   - Every 30 minutes during session
   - 5 minutes before timeout (with desktop notification)
   - At session end (final backup)
   - Emergency backup on unexpected termination

### ⏱️ **Session Lifecycle**

- **Duration**: Up to 6 hours maximum
- **Persistence**: 
  - **Windows**: Full data persistence via Google Drive
  - **macOS/Ubuntu**: Temporary (data lost after session)
- **Access**: Immediate remote desktop connection via secure tunnel

### 🔒 **Security Features**

- Encrypted tunnels (ngrok/cloudflare)
- Isolated VM environment  
- Automatic cleanup after session
- Secure credential handling via GitHub secrets

## Persistent Storage with Google Drive (Windows Server 2025)

**NEW**: Windows Server 2025 sessions now support persistent storage through Google Drive API integration:

- **Automatic Backup**: Your user data (Desktop, Documents, Downloads, AppData, SSH keys, Git config) is automatically backed up to Google Drive when the session ends
- **Automatic Restore**: When you start a new session, your previous data is automatically restored from Google Drive
- **Periodic Backups**: Data is backed up every 30 minutes during active sessions
- **Pre-Timeout Backup**: Automatic backup 5 minutes before session timeout
- **Emergency Backup**: Backup on unexpected session termination
- **Manual Control**: Desktop shortcuts allow you to manually backup, restore, or check backup status
- **2TB Storage**: Utilizes your Google Drive storage (2TB for 1 year as mentioned)

### What Gets Backed Up:

#### User Data:
- Desktop, Documents, Downloads, Pictures, Videos, Music folders
- All user-created files and folders

#### Browser Data (Complete Profiles):
- **Chrome**: Login sessions, bookmarks, extensions, settings, passwords (encrypted)
- **Edge**: Complete profile data including login sessions
- **Firefox**: Profile data and settings (if installed)

#### Development Tools:
- **VS Code**: Settings, extensions, workspace configurations
- **Git**: Configuration files and SSH keys
- **Android Studio**: Settings and configurations
- **JetBrains IDEs**: Settings for IntelliJ, PyCharm, WebStorm, etc.
- **Node.js**: Global packages and npm configuration
- **Python**: pip configuration and settings
- **Docker**: Desktop settings and configurations

#### Text Editors & IDEs:
- Notepad++ settings and plugins
- Sublime Text settings and packages
- PowerShell profiles and configurations
- Windows Terminal settings

#### Communication & Productivity:
- Slack settings and workspaces
- Discord settings
- Zoom settings
- Microsoft Teams settings
- Postman collections and settings

#### System Configurations:
- SSH keys and configuration
- Application data (AppData/Roaming)
- User-installed application settings

## Installation

1.  **Fork this repository**: Click the "Fork" button at the top-right of this page to create your own copy.
2.  **Add secrets**: Go to your forked repository's `Settings` > `Secrets and variables` > `Actions` and add the necessary secrets as described in the "Secrets Configuration" section below.
3.  **Run workflow**: Go to the "Actions" tab of your repository, select the desired workflow, and run it.

## <a name="how-to-use"></a>How to use

Once the GitHub Actions workflow is running, you need to find the connection details from the logs and use a remote desktop client to connect.

**Step 1: Get Connection Details from Workflow Logs**
1.  Go to the **Actions** tab in your repository and click on the running workflow.
2.  Look for the **Display Connection Details** step in the logs.
3.  You will find the connection address (e.g., `0.tcp.ngrok.io`) and port (e.g., `12345`).

**Step 2: Connect to the VM**
You will need a remote desktop client to connect to the VM.

*   **For RDP (Windows & Ubuntu):**
    *   We recommend using the [Windows App](https://play.google.com/store/apps/details?id=com.microsoft.rdc.androidx) client.
    *   Enter the address and port from the logs.
    *   Use the username you provided and the password you set in the `USER_PASSWORD` secret.

*   **For VNC (macOS):**
    *   We recommend using the [VNC Viewer](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) client.
    *   Enter the address and port from the logs.
    *   Use the username you provided and the password you set in the `USER_PASSWORD` secret.

**Step 3: Using Google Drive Persistence (Windows Server 2025 only)**

Once connected to your Windows RDP session, you'll find three shortcuts on the desktop:

- **"Backup to Google Drive.bat"** - Manually create a backup of your current session
- **"Restore from Google Drive.bat"** - Manually restore data from your latest backup  
- **"Check Backup Status.bat"** - View information about your current backup

These shortcuts provide manual control over the backup system, in addition to the automatic backups that occur every 30 minutes and at session end.

## <a name="workflow-inputs"></a>Workflow Inputs

Customize your VM when running the workflow from the **Actions** tab:

### 🖥️ Basic Configuration

| Input | Description | Type | Default | Platforms |
| :--- | :--- | :--- | :--- | :--- |
| `os` | Operating system to use | Choice | `windows-latest` | All |
| `username` | Username for the VM account | String | **Required** | All |
| `timeout` | Session duration in minutes (max 360) | String | `360` | All |

### 🌐 Network & Access

| Input | Description | Type | Default | Platforms |
| :--- | :--- | :--- | :--- | :--- |
| `tunnel_provider` | Tunnel service (`ngrok` or `cloudflare`) | Choice | `ngrok` | All |
| `region` | Ngrok region (`us`, `eu`, `ap`, `au`, `sa`, `jp`, `in`) | Choice | `in` | ngrok only |

> [!NOTE]
> **Windows supports ngrok only**. Cloudflare tunnels work on macOS and Ubuntu.

### 📦 Software Installation

| Input | Description | Type | Default | Platforms |
| :--- | :--- | :--- | :--- | :--- |
| `install_apps` | Comma-separated app list | String | `''` | All |
| `install_virtual_sound_card` | Audio driver installation | Boolean | `false` | All |
| `install_github_desktop` | GitHub Desktop app | Boolean | `false` | Windows, macOS |
| `install_vscode` | Visual Studio Code | Boolean | `false` | All |
| `install_android_studio` | Android Studio IDE | Boolean | `false` | Windows |
| `install_browseros` | BrowserOS (experimental) | Boolean | `false` | Windows |
| `install_void_editor` | Void Editor (experimental) | Boolean | `false` | Windows |
| `set_default_browser` | Default browser (`chrome` or `browseros`) | String | `chrome` | Windows |

### 💾 Persistence (Windows Only)

| Input | Description | Type | Default | Platforms |
| :--- | :--- | :--- | :--- | :--- |
| `enable_google_drive_persistence` | Backup/restore user data via Google Drive | Boolean | `true` | Windows |

**Available Apps for `install_apps`:**
`virtual_sound_card`, `github_desktop`, `browseros`, `void_editor`, `android_studio`, `vscode`

**Example:** `virtual_sound_card,vscode,github_desktop`

## <a name="secrets-configuration"></a>Secrets Configuration

Add these secrets to your repository: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### 🔑 Required Secrets (All Platforms)

| Secret | Description | Example |
| :--- | :--- | :--- |
| `USER_PASSWORD` | **Always Required**. Password for the VM user account. Use a strong password. | `MySecurePassword123!` |
| `NGROK_AUTH_TOKEN` | **Required for ngrok** (default tunnel provider). Get from [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken). | `2aBcDeFgHiJkLmNoPqRsTuVwXyZ_123456789` |

### 🌐 Tunnel Provider Secrets (Platform-Specific)

| Platform | Secret | When Required | Description |
| :--- | :--- | :--- | :--- |
| **Windows** | `NGROK_AUTH_TOKEN` | Default (ngrok) | Works with both ngrok and cloudflare tunnels |
| **macOS** | `NGROK_AUTH_TOKEN` | For ngrok | Required when `tunnel_provider` = `ngrok` |
| **macOS** | `CF_TUNNEL_TOKEN` | For cloudflare | Required when `tunnel_provider` = `cloudflare` |
| **Ubuntu** | `NGROK_AUTH_TOKEN` | For ngrok | Required when `tunnel_provider` = `ngrok` |
| **Ubuntu** | `CF_TUNNEL_TOKEN` | For cloudflare | Required when `tunnel_provider` = `cloudflare` |

> [!NOTE]
> **Windows only supports ngrok tunnels**. Cloudflare tunnel support is available for macOS and Ubuntu only.

### 💾 Google Drive Persistence (Windows Only)

**Required only if `enable_google_drive_persistence` = `true` (default)**

Choose **ONE** authentication method:

#### ✅ Option 1: Service Account (Recommended)

| Secret | Description |
| :--- | :--- |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | **Full functionality**. Complete JSON from Google Service Account key file. Enables upload/download, automatic folder creation. [Setup Guide](#google-drive-setup) |

#### ⚠️ Option 2: API Key (Limited)

| Secret | Description |
| :--- | :--- |
| `GOOGLE_DRIVE_API_KEY` | **Limited functionality**. Can only search files, no upload/download. Local backups only. | `AIzaSyBcDeFgHiJkLmNoPqRsTuVwXyZ123456789` |

### 🎯 Quick Setup Checklist

**For Windows (Recommended):**
- ✅ `USER_PASSWORD` 
- ✅ `NGROK_AUTH_TOKEN`
- ✅ `GOOGLE_SERVICE_ACCOUNT_JSON` (for persistence)

**For macOS/Ubuntu:**
- ✅ `USER_PASSWORD`
- ✅ `NGROK_AUTH_TOKEN` OR `CF_TUNNEL_TOKEN`

> [!IMPORTANT]
> **Google Drive persistence is Windows-only**. macOS and Ubuntu sessions are temporary and data will be lost after 6 hours.

## Optional Pre-installed Software and Configurations

You can choose to install additional software using the workflow inputs. The following table details the available software for each operating system:

| Operating System | Optional Software/Configuration |
| :--- | :--- |
| **macOS** | - **Virtual Sound Card**: Installs BlackHole 2ch, a virtual audio driver. <br> - **GitHub Desktop**: Installs the GitHub Desktop application. <br> - **VS Code**: Installs Visual Studio Code. |
| **Ubuntu** | - **Virtual Sound Card**: Installs and loads the `snd-aloop` kernel module. <br> - **VS Code**: Installs Visual Studio Code. |
| **Windows** | - **Virtual Sound Card**: Installs VB-CABLE and enables necessary audio services. <br> - **GitHub Desktop**: Installs the GitHub Desktop application. <br> - **BrowserOS**: Installs BrowserOS (placeholder). <br> - **Void Editor**: Installs Void Editor (placeholder). <br> - **Android Studio**: Installs Android Studio. <br> - **VS Code**: Installs Visual Studio Code. <br> - **Set Default Browser**: Sets the default browser to Chrome or BrowserOS. |

In addition to the optional software, the following base configurations are always applied:

| Operating System | Base Configuration |
| :--- | :--- |
| **All** | - A new user account is created with the specified username and password. <br> - The user is granted administrative/sudo privileges. <br> - Remote access (RDP/VNC) is enabled. |

---

## Disclaimer

| Limitation | Details |
| :--- | :--- |
| **Max Runtime** | Each job can run for a maximum of 6 hours. |
| **Persistency** | - **Windows Server 2025**: Full data persistence via Google Drive integration <br> - **macOS/Ubuntu**: All your work will be gone when the job is complete (no persistence) |
| **Usage Limits (Free Tier)** | - **Public Repositories**: Unlimited minutes/month. <br> - **Private Repositories**: 2000 minutes/month. <br> *(These limits may be higher on paid tiers)*. |
| **Storage Requirements** | **Windows Server 2025**: Requires Google Drive authentication (Service Account recommended) and uses your Google Drive storage quota |

## <a name="google-drive-setup"></a>Google Drive Setup

For persistent storage on Windows Server 2025, you need to set up Google Drive API access. We **strongly recommend using Service Account authentication** for full functionality.

### Quick Setup Links

- 📋 **[Complete Setup Guide](GOOGLE_DRIVE_SETUP.md)** - Detailed step-by-step instructions
- 🔗 **[Google Cloud Console](https://console.cloud.google.com/)** - Create your project and Service Account
- 🔗 **[Google Drive API Library](https://console.cloud.google.com/apis/library/drive.googleapis.com)** - Enable the API
- 🔗 **[ngrok Dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)** - Get your tunnel token

### Authentication Methods Comparison

| Method | Upload/Download | Folder Management | Recommended |
| :--- | :---: | :---: | :---: |
| **Service Account** | ✅ Full support | ✅ Full support | ✅ **Yes** |
| **API Key** | ❌ Local only | ❌ Limited | ❌ No |

### Service Account Benefits

- ✅ **Full Google Drive integration** - Upload, download, and manage files
- ✅ **Automatic folder creation** - Creates backup folders automatically  
- ✅ **Secure authentication** - Uses OAuth2 with private keys
- ✅ **No manual sharing required** - Works with dedicated backup folders
- ✅ **Better error handling** - Comprehensive logging and fallbacks

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
| :--- | :--- |
| **"Secret not found" error** | Check secret names are exact: `USER_PASSWORD`, `NGROK_AUTH_TOKEN`, etc. |
| **Tunnel connection fails** | Verify ngrok token is valid and has sufficient quota |
| **Google Drive auth fails** | Ensure `GOOGLE_SERVICE_ACCOUNT_JSON` contains complete JSON |
| **Workflow times out** | Reduce `timeout` value or check if VM is overloaded |
| **Can't connect to RDP/VNC** | Wait 2-3 minutes after "Connection Details" appear in logs |

### Getting Help

1. **Check workflow logs** for detailed error messages
2. **Verify secrets** are properly configured  
3. **Test with minimal configuration** first
4. **Review [Google Drive Setup Guide](GOOGLE_DRIVE_SETUP.md)** for persistence issues

---

## ⚠️ Important Disclaimers

### Usage Policy
- ✅ **Allowed**: Development, testing, learning, productivity work
- ❌ **Prohibited**: Cryptocurrency mining, gaming, illegal activities, resource abuse
- ⚠️ **Risk**: Account suspension for policy violations

### Limitations
- **Runtime**: 6 hours maximum per session
- **Resources**: Shared GitHub Actions runners (limited CPU/RAM)
- **Network**: Standard GitHub Actions network policies apply
- **Storage**: Google Drive quota limits (Windows persistence)

### Data Responsibility
- **Windows**: Your data is backed up to YOUR Google Drive account
- **macOS/Ubuntu**: All data is permanently lost after session ends
- **Security**: You are responsible for securing your own secrets and data

**Use responsibly and in compliance with GitHub's Terms of Service.**