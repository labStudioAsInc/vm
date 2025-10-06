<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%">
  <h1>VM with GitHub Actions</h1>
</div>

<div align="center">

**This repository provides scripts and workflows to create temporary Virtual Machines (VMs) using GitHub Actions, with pre-configured environments for Windows, macOS, and Ubuntu.**

</div>

---

## 📚 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [1. Fork the Repository](#1-fork-the-repository)
  - [2. Configure Secrets](#2-configure-secrets)
  - [3. Run the Workflow](#3-run-the-workflow)
- [How to Connect](#how-to-connect)
  - [Step 1: Get Connection Details](#step-1-get-connection-details)
  - [Step 2: Connect to the VM](#step-2-connect-to-the-vm)
- [Customization](#customization)
  - [Workflow Inputs](#workflow-inputs)
  - [Secrets Configuration](#secrets-configuration)
  - [Available Software](#available-software)
- [Disclaimer](#disclaimer)

---

## <a name="overview"></a>Overview

This project leverages GitHub Actions to provide you with a temporary, free virtual machine for development, testing, or exploration. The workflows and scripts in this repository automate the initial setup of GitHub Runner VMs, including the configuration of servers for Windows, macOS, and Ubuntu, and provide remote access via RDP or VNC.

> [!WARNING]
> **macOS and Ubuntu versions are currently not being maintained and may cause crashes. Please use Windows Server for stable operation.**

## <a name="how-it-works"></a>How It Works

The process is fully automated through GitHub Actions:

1.  **Trigger Workflow**: When you manually run a workflow from the "Actions" tab, GitHub provisions a fresh virtual machine.
2.  **Execute Pre-install Script**: The workflow executes a pre-installation script (`preinstall-windows.ps1`, `preinstall-mac.sh`, or `preinstall-ubuntu.sh`) on the VM.
3.  **User and Software Setup**: The script creates a new user account with your specified password and installs any optional software you selected (like VS Code or GitHub Desktop).
4.  **Enable Remote Access**: It configures the operating system for remote connections (RDP for Windows/Ubuntu, VNC for macOS).
5.  **Create Secure Tunnel**: The workflow uses `ngrok` or `Cloudflare` to create a secure tunnel from a public URL to the VM's remote desktop port.
6.  **Output Connection Details**: The public URL and port for the connection are printed in the GitHub Actions logs, allowing you to connect from anywhere.

The VM is temporary and will be destroyed when the GitHub Actions job finishes (after a maximum of 6 hours).

## <a name="repository-structure"></a>Repository Structure

```
.
├── .github/workflows/   # Contains the GitHub Actions workflow files (not visible here)
├── scripts/
│   ├── preinstall-mac.sh      # Setup script for macOS
│   ├── preinstall-ubuntu.sh   # Setup script for Ubuntu
│   └── preinstall-windows.ps1 # Setup script for Windows
├── README.md              # This file
└── Release-Notes.md       # Project release notes
```

## <a name="getting-started"></a>Getting Started

### 1. Fork the Repository

Click the **Fork** button at the top-right of this page to create your own copy of this repository.

### 2. Configure Secrets

Navigate to your forked repository's `Settings` > `Secrets and variables` > `Actions`. Add the required secrets as described in the [Secrets Configuration](#secrets-configuration) section below. At a minimum, you must set `USER_PASSWORD`.

### 3. Run the Workflow

Go to the **Actions** tab of your forked repository, select the desired OS workflow (e.g., "Windows VM"), and click **Run workflow**. You can customize the VM by filling out the input fields before running.

## <a name="how-to-connect"></a>How to Connect

### Step 1: Get Connection Details

1.  In the **Actions** tab, click on the running workflow.
2.  Wait for the job to reach the **Display Connection Details** step in the logs.
3.  The logs will show the connection **Address** (e.g., `0.tcp.ngrok.io`) and **Port** (e.g., `12345`).

### Step 2: Connect to the VM

-   **For RDP (Windows & Ubuntu):**
    -   Use any RDP client (e.g., Microsoft Remote Desktop).
    -   Enter the **Address:Port** from the logs.
    -   Use the `username` you provided and the password from your `USER_PASSWORD` secret.

-   **For VNC (macOS):**
    -   Use any VNC client (e.g., VNC Viewer).
    -   Enter the **Address:Port** from the logs.
    -   Use the `username` you provided and the password from your `USER_PASSWORD` secret.

## <a name="customization"></a>Customization

### <a name="workflow-inputs"></a>Workflow Inputs

You can customize the VM setup using the following workflow inputs:

| Input                         | Description                                                    | Type      | Default      |
| :---------------------------- | :------------------------------------------------------------- | :-------- | :----------- |
| `username`                    | The username for the new user account.                         | `string`  | **Required** |
| `tunnel_provider`             | The tunneling service to use. Can be `ngrok` or `cloudflare`.  | `string`  | `ngrok`      |
| `region`                      | The ngrok tunnel region (`us`, `eu`, `ap`, etc.).              | `string`  | `us`         |
| `timeout`                     | The session timeout in minutes (max 360).                      | `string`  | `360`        |
| `install_virtual_sound_card`  | Install a virtual sound card.                                  | `boolean` | `false`      |
| `install_github_desktop`      | Install GitHub Desktop (Windows/macOS only).                   | `boolean` | `false`      |
| `install_browseros`           | Install BrowserOS (Windows only, placeholder).                 | `boolean` | `false`      |
| `install_void_editor`         | Install Void Editor (Windows only, placeholder).               | `boolean` | `false`      |
| `install_android_studio`      | Install Android Studio (Windows only).                         | `boolean` | `false`      |
| `install_vscode`              | Install Visual Studio Code.                                    | `boolean` | `false`      |
| `set_default_browser`         | Set default browser (Windows only). Can be `chrome` or `browseros`. | `string`  | `chrome`     |

### <a name="secrets-configuration"></a>Secrets Configuration

| Secret             | Description                                                                                             | Example                               |
| :----------------- | :------------------------------------------------------------------------------------------------------ | :------------------------------------ |
| `USER_PASSWORD`    | **Required**. The password for the new user account created on the VM.                                  | `your-strong-password`                |
| `NGROK_AUTH_TOKEN` | Your auth token from the [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken). Required for the `ngrok` tunnel provider. | `2aBcDeFgHiJkLmNoPqRsTuVwXyZ_12345` |
| `CF_TUNNEL_TOKEN`  | Your Cloudflare Tunnel token. Required for the `cloudflare` tunnel provider.                             | `your-long-cloudflare-token`          |

### <a name="available-software"></a>Available Software

The following software can be installed on each OS via the workflow inputs:

| Operating System | Optional Software/Configuration                                                                                                                                                                                                                           |
| :--------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **macOS**        | **Virtual Sound Card**: Installs BlackHole 2ch. <br> **GitHub Desktop**: Installs GitHub Desktop. <br> **VS Code**: Installs Visual Studio Code.                                                                                                            |
| **Ubuntu**       | **Virtual Sound Card**: Installs and loads the `snd-aloop` kernel module. <br> **VS Code**: Installs Visual Studio Code.                                                                                                                                   |
| **Windows**      | **Virtual Sound Card**: Installs VB-CABLE. <br> **GitHub Desktop**: Installs GitHub Desktop. <br> **BrowserOS / Void Editor / Android Studio / VS Code**: Installs the respective applications. <br> **Set Default Browser**: Sets the default browser. |

---

## <a name="disclaimer"></a>Disclaimer

| Limitation      | Details                                                                                                                            |
| :-------------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| **Max Runtime** | Each job can run for a maximum of 6 hours.                                                                                         |
| **Persistency** | All data and changes will be lost when the job completes.                                                                          |
| **Usage Limits**| GitHub provides a free tier of Actions minutes for public and private repositories. Check your account plan for specific limits. |

**Responsible Use**: Do not use these VMs for cryptocurrency mining, torrenting, or any other illegal or unethical activities. Misuse may result in your GitHub account being flagged or permanently suspended.