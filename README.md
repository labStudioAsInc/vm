<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%">

  # VM with GitHub Actions

  **This repository provides scripts and workflows to set up temporary virtual machines (Windows, macOS, and Ubuntu) using GitHub Actions, with remote desktop access and optional persistence.**

  [Overview](#overview) • [Getting Started](#getting-started) • [Persistence Options](#persistence-options) • [macOS VM Guidance](#macos-vm) • [Workflow Inputs](#workflow-inputs) • [Secrets Configuration](#secrets-configuration) • [Troubleshooting](#troubleshooting)

</div>

## <a name="overview"></a>🚀 Overview

This project allows you to create free virtual machines directly from your GitHub repository using GitHub Actions. Get instant access to a full desktop environment for development, testing, or any other task.


### ✨ Features

- **Cross-Platform**: Windows, macOS, and Ubuntu VMs.
- **Remote Access**: Connect via RDP (Windows/Ubuntu) or VNC (macOS).
- **Persistent Storage**: (Windows only) Full data persistence using Google Drive. Your files, browser sessions, and app settings are automatically backed up and restored.
- **Customizable**: Install a variety of software and configure your VM using workflow inputs.
- **Secure**: Uses encrypted tunnels (ngrok/Cloudflare) and GitHub secrets to protect your credentials.
- **Free**: Leverages the free tier of GitHub Actions.

## <a name="getting-started"></a>🏁 Getting Started

### 1. Fork the Repository

Click the **Fork** button at the top-right of this page to create your own copy of this repository.

### 2. Configure Secrets

Go to your forked repository's `Settings` > `Secrets and variables` > `Actions` and add the following secrets:

| Secret                        | Description                                                                                             |
| :---------------------------- | :------------------------------------------------------------------------------------------------------ |
| `USER_PASSWORD`               | **Required**. The password for your VM user account.                                                     |
| `NGROK_AUTH_TOKEN`            | **Required for ngrok**. See the [ngrok setup guide](NGROK_SETUP.md). |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | **Optional (Windows only)**. Required for Google Drive persistence. See the [setup guide](GOOGLE_DRIVE_SETUP.md). |
| `GOOGLE_SHARED_DRIVE_ID`      | **Optional (Windows only)**. The ID of the Google Shared Drive for backups. See the [setup guide](GOOGLE_DRIVE_SETUP.md). |
| `CF_TUNNEL_TOKEN`             | **Optional (macOS/Ubuntu only)**. Required for Cloudflare tunnels.                                       |

> [!TIP]
> For a quick start with Windows, you only need `USER_PASSWORD` and `NGROK_AUTH_TOKEN`.

### 3. Run the Workflow

1.  Go to the **Actions** tab in your repository.
2.  Select the **Main Entrypoint** workflow.
3.  Click **Run workflow**.
4.  Choose your desired OS and other options, then click **Run workflow**.

### 4. Connect to Your VM

1.  Once the workflow is running, click on the workflow run to view the logs.
2.  Find the **Display Connection Details** step. It will provide the address and port.
3.  Use a remote desktop client to connect:
    *   **RDP (Windows & Ubuntu)**: Use Microsoft Remote Desktop or any RDP client.
    *   **VNC (macOS)**: Use VNC Viewer or a similar client.

    See the [macOS VM Guidance](#macos-vm) for more details on VNC clients and connecting with Cloudflare.
4.  Enter the connection details, your username, and the password you set in the `USER_PASSWORD` secret.

## <a name="persistence-options"></a>💾 Persistence Options

For Windows VMs, you can choose how your data is persisted between sessions.

| Option         | Description                                                                                                                                                             |
| :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Google Drive** | **Recommended**. Automatically backs up and restores your user profile to a Google Shared Drive. Provides full persistence for files, settings, and application data. |
| **GitHub Artifacts** | Backs up your data as a GitHub artifact. Data can be restored in the next session, but artifacts expire after a set number of days. |
| **None**       | No data is saved. The VM is ephemeral, and all changes are lost when the session ends.                                                                                    |

### What Gets Backed Up (with Google Drive)

- **User Data**: Desktop, Documents, Downloads, etc.
- **Browser Data**: Complete profiles for Chrome, Edge, and Firefox.
- **Application Settings**: Data from `AppData/Roaming`.

## <a name="macos-vm"></a>macOS VM Guidance

Connecting to the macOS VM is straightforward, but there are a few platform-specific details to keep in mind.

### Connecting with VNC

The macOS runner uses the built-in VNC server. To connect, you will need a VNC client:

- **RealVNC**: A popular, multi-platform VNC client.
- **TightVNC**: Another widely used, free VNC client.
- **Screen Sharing**: The native VNC client on macOS.

When connecting, use the address and port provided in the workflow logs.

### Connecting from Android

You can also connect to the macOS VM from an Android device using a VNC client.

- **[RealVNC Viewer](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android)**: A free and popular VNC client available on the Google Play Store.

Install the app, enter the connection details from the workflow logs, and you'll be able to control your macOS VM from your Android device.

### Virtual Sound Card

The `install_apps` input now supports `virtual_sound_card` for macOS. This installs [BlackHole](https://github.com/ExistentialAudio/BlackHole), a virtual audio driver that allows you to route audio between applications.

### Cloudflare Tunnel

For macOS, you can use either `ngrok` or `cloudflare` as the tunnel provider. If you choose Cloudflare, you'll need to:

1.  **Install `cloudflared` on your local machine.** Follow the official [Cloudflare documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/) for instructions.
2.  **Authenticate with your Cloudflare account.** When you run the connection command from the workflow logs, you will be prompted to log in.

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
> **Windows supports ngrok only**. Cloudflare and ngrok are supported on macOS and Ubuntu.

### 📦 Software Installation

| Input | Description | Type | Default | Platforms |
| :--- | :--- | :--- | :--- | :--- |
| `install_apps` | Comma-separated app list | String | `''` | All |

**Supported Apps:**
- `virtual_sound_card`: Installs a virtual audio device. (Windows and macOS)

### 💾 Persistence (Windows Only)

| Input | Description | Type | Default | Platforms |
| :--- | :--- | :--- | :--- | :--- |
| `enable_google_drive_persistence` | Backup/restore user data via Google Drive | Boolean | `true` | Windows |

## <a name="secrets-configuration"></a>Secrets Configuration

Add these secrets to your repository: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### 🔑 Required Secrets (All Platforms)

| Secret | Description |
| :--- | :--- |
| `USER_PASSWORD` | **Always Required**. Password for the VM user account. Use a strong password. |
| `NGROK_AUTH_TOKEN` | **Required for ngrok** (default tunnel provider). See the [ngrok setup guide](NGROK_SETUP.md). |

### 🌐 Tunnel Provider Secrets (Platform-Specific)

| Platform | Secret | When Required | Description |
| :--- | :--- | :--- | :--- |
| **macOS/Ubuntu** | `CF_TUNNEL_TOKEN` | For Cloudflare | Required when `tunnel_provider` = `cloudflare` |

### 💾 Google Drive Persistence (Windows Only)

**Required only if `enable_google_drive_persistence` = `true` (default)**

| Secret | Description |
| :--- | :--- |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Enables full Google Drive integration. See the [Google Drive Setup Guide](GOOGLE_DRIVE_SETUP.md). |
| `GOOGLE_SHARED_DRIVE_ID` | The ID of the Google Shared Drive for backups. See the [Google Drive Setup Guide](GOOGLE_DRIVE_SETUP.md). |

## <a name="troubleshooting"></a>🔧 Troubleshooting

### Common Issues

| Issue | Solution |
| :--- | :--- |
| **"Secret not found" error** | Check secret names are exact: `USER_PASSWORD`, `NGROK_AUTH_TOKEN`, etc. |
| **Tunnel connection fails** | Verify ngrok token is valid and has sufficient quota |
| **Google Drive auth fails** | Ensure `GOOGLE_SERVICE_ACCOUNT_JSON` contains complete JSON and the `GOOGLE_SHARED_DRIVE_ID` is correct. |
| **Workflow times out** | Reduce `timeout` value or check if VM is overloaded |
| **Can't connect to RDP/VNC** | Wait 2-3 minutes after "Connection Details" appear in logs |
