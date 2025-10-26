<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%">

  # VM with GitHub Actions

  **This repository provides scripts and workflows to set up temporary virtual machines (Windows, macOS, and Ubuntu) using GitHub Actions, with remote desktop access and optional persistence.**

  [Overview](#overview) • [Getting Started](#getting-started) • [How it Works](#how-it-works) • [Persistence Options](#persistence-options) • [Available Software](#available-software) • [Project Structure](#project-structure) • [Workflow Inputs](#workflow-inputs) • [Secrets Configuration](#secrets-configuration) • [Troubleshooting](#troubleshooting)

</div>

## <a name="overview"></a>🚀 Overview

This project allows you to create free virtual machines directly from your GitHub repository using GitHub Actions. Get instant access to a full desktop environment for development, testing, or any other task.

> [!WARNING]
> **macOS and Ubuntu versions are currently not being maintained and may be unstable. Please use Windows for the best experience.**

### ✨ Features

- **Cross-Platform**: Windows, macOS, and Ubuntu VMs.
- **Remote Access**: Connect via RDP (Windows/Ubuntu) or VNC (macOS).
- **Persistent Storage**: (Windows only) Full data persistence using Google Drive. Your files, browser sessions, and app settings are automatically backed up and restored.
- **Customizable**: Install a variety of software and configure your VM using workflow inputs.
- **Secure**: Uses encrypted tunnels (ngrok/Cloudflare) and GitHub secrets to protect your credentials.
- **Free**: Leverages the free tier of GitHub Actions.

## <a name="getting-started"></a>🏁 Getting Started

Follow these steps to get your VM up and running in minutes.

### 1. Fork the Repository

Click the **Fork** button at the top-right of this page to create your own copy of this repository.

### 2. Configure Secrets

Go to your forked repository's `Settings` > `Secrets and variables` > `Actions` and add the following secrets:

| Secret                        | Description                                                                                             |
| :---------------------------- | :------------------------------------------------------------------------------------------------------ |
| `USER_PASSWORD`               | **Required**. The password for your VM user account.                                                     |
| `NGROK_AUTH_TOKEN`            | **Required for ngrok**. See the [ngrok setup guide](NGROK_SETUP.md). |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | **Optional (Windows only)**. Required for Google Drive persistence. See the [setup guide](GOOGLE_DRIVE_SETUP.md). |
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
4.  Enter the connection details, your username, and the password you set in the `USER_PASSWORD` secret.

## <a name="how-it-works"></a>⚙️ How it Works

This project leverages GitHub Actions to automate the provisioning of virtual machines.

1.  **Trigger**: The `Main Entrypoint` workflow is manually triggered.
2.  **Provision**: GitHub creates a fresh VM based on your selected OS.
3.  **Setup**: A pre-installation script runs to:
    *   Create a user account.
    *   Install selected software.
    *   Enable remote access (RDP/VNC).
4.  **Tunnel**: A secure tunnel is created using ngrok or Cloudflare to expose the remote desktop port to the internet.
5.  **Persistence (Windows only)**: If enabled, user data is restored from Google Drive at the start of the session and backed up periodically and at the end.
6.  **Connection**: You connect to the VM using the details provided in the workflow logs.
7.  **Cleanup**: The VM is automatically destroyed when the workflow finishes (after the timeout, max 6 hours).

## <a name="persistence-options"></a>💾 Persistence Options

For Windows VMs, you can choose how your data is persisted between sessions.

| Option         | Description                                                                                                                                                             | Setup                                                                                                                            |
| :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------- |
| **Google Drive** | **Recommended**. Automatically backs up and restores your user profile to your Google Drive. Provides full persistence for files, settings, and application data. | Requires `GOOGLE_SERVICE_ACCOUNT_JSON` secret. See the [Google Drive Setup Guide](GOOGLE_DRIVE_SETUP.md). Storage is limited by your Google account (e.g., 15GB for free accounts). |
| **GitHub Artifacts** | Backs up your data as a GitHub artifact. Data can be restored in the next session, but artifacts expire after a set number of days. | No extra setup required, but less seamless than Google Drive.                                                                    |
| **None**       | No data is saved. The VM is ephemeral, and all changes are lost when the session ends.                                                                                    | This is the default for macOS and Ubuntu.                                                                                         |

### What Gets Backed Up (with Google Drive)

- **User Data**: Desktop, Documents, Downloads, etc.
- **Browser Data**: Complete profiles for Chrome, Edge, and Firefox.
- **Application Settings**: Data from `AppData/Roaming`.

## <a name="available-software"></a>📦 Available Software

You can choose to install the following software using the `install_apps` workflow input.

| Software              | Windows | macOS | Ubuntu | Description                                     |
| :-------------------- | :-----: | :---: | :----: | :---------------------------------------------- |
| Virtual Sound Card    |    ✅    |   ✅   |   ✅    | Provides virtual audio drivers.                 |

## <a name="project-structure"></a>📁 Project Structure

`
.
├── .github/workflows/   # GitHub Actions workflows
│   ├── entrypoint.yml   # Main workflow that calls OS-specific workflows
│   ├── windows.yml      # Workflow for Windows VMs
│   ├── macos.yml        # Workflow for macOS VMs
│   └── ubuntu.yml       # Workflow for Ubuntu VMs
├── scripts/             # Installation and utility scripts
│   ├── preinstall-windows.ps1
│   ├── preinstall-mac.sh
│   ├── preinstall-ubuntu.sh
│   └── google-drive-sync.ps1 # and other helper scripts
└── README.md            # This file
`

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

**Example:** `virtual_sound_card`

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


## <a name="troubleshooting"></a>🔧 Troubleshooting

### Common Issues

| Issue | Solution |
| :--- | :--- |
| **"Secret not found" error** | Check secret names are exact: `USER_PASSWORD`, `NGROK_AUTH_TOKEN`, etc. |
| **Tunnel connection fails** | Verify ngrok token is valid and has sufficient quota |
| **Google Drive auth fails** | Ensure `GOOGLE_SERVICE_ACCOUNT_JSON` contains complete JSON |
| **Workflow times out** | Reduce `timeout` value or check if VM is overloaded |
| **Can't connect to RDP/VNC** | Wait 2-3 minutes after "Connection Details" appear in logs |


## <a name="disclaimer"></a>⚠️ Disclaimer & Usage Policy

- **Usage**: This project is intended for development, testing, and learning purposes. Do not use it for cryptocurrency mining, gaming, or any illegal activities. Misuse may result in your GitHub account being suspended.
- **Limitations**:
    - **Runtime**: 6 hours maximum per session.
    - **Resources**: VMs run on standard GitHub Actions runners with limited CPU and RAM.
- **Data Responsibility**: You are responsible for the data you store. For Windows, data is backed up to your own Google Drive account. For macOS and Ubuntu, all data is lost after the session ends.

**Use this project responsibly and in compliance with GitHub's Terms of Service.**
