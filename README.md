<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%">

<div align="center">
  
# VM with GitHub Actions

**This repository contains scripts and workflows for the initial setup of Github Runner VMs and configuration of servers for various operating systems. These scripts are designed to automate the pre-installation process, ensuring a consistent and reliable environment for our applications.**

[Overview](#overview) • [How it works](#how-it-works) • [Installation](#installation) • [How to use](#how-to-use) • [Secrets Configuration](#secrets-configuration)

</div> </div>

## <a name="overview"></a>Overview

> [!WARNING]
> **macOS and Ubuntu versions are currently not being maintained and may cause crashes. Please use Windows Server 2025 for stable operation.**

This project leverages GitHub Actions to provide you with a temporary, free virtual machine. The workflows and scripts in this repository automate the initial setup of GitHub Runner VMs, including the configuration of servers for Windows, macOS, and Ubuntu.

## How it works

This project leverages GitHub Actions to provide you with a temporary, free virtual machine. Here's the basic workflow:

1.  **Triggering the Action**: When you run a workflow in the "Actions" tab, GitHub provisions a fresh virtual machine (VM) with the operating system you choose (Windows, Ubuntu, or macOS).
2.  **Running the Script**: The action then executes one of the pre-installation scripts from this repository on the new VM.
3.  **Setting up Remote Access**: The script installs the necessary software for remote access (RDP for Windows/Ubuntu, VNC for macOS) and creates a new user account with the password you provide in the `USER_PASSWORD` secret.
4.  **Creating a Secure Tunnel**: The script then installs `ngrok` and uses your `NGROK_AUTH_TOKEN` to create a secure tunnel from the public internet to the remote desktop port on the VM.
5.  **Accessing the VM**: The unique ngrok URL for your session is printed in the GitHub Actions logs. You can use this URL with any standard RDP or VNC client to connect to your temporary VM.

Since the VM is part of a GitHub Actions job, it is temporary and will be destroyed once the job finishes (after a maximum of 6 hours).

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

## <a name="workflow-inputs"></a>Workflow Inputs

When running a workflow, you can customize the VM setup using the following inputs:

| Input | Description | Type | Default |
| :--- | :--- | :--- | :--- |
| `username` | The username for the new user account. | `string` | **Required** |
| `tunnel_provider` | The tunneling service to use. Can be `ngrok` or `cloudflare`. | `string` | `ngrok` |
| `region` | The ngrok tunnel region to use (e.g., `us`, `eu`, `ap`). | `string` | `us` |
| `timeout` | The session timeout in minutes (max 360). | `string` | `360` |
| `install_virtual_sound_card` | Install a virtual sound card. | `boolean` | `false` |
| `install_github_desktop` | Install GitHub Desktop (Windows/macOS only). | `boolean` | `false` |
| `install_browseros` | Install BrowserOS (Windows only, placeholder). | `boolean` | `false` |
| `install_void_editor` | Install Void Editor (Windows only, placeholder). | `boolean` | `false` |
| `install_android_studio` | Install Android Studio (Windows only). | `boolean` | `false` |
| `install_vscode` | Install Visual Studio Code. | `boolean` | `false` |
| `set_default_browser` | Set the default browser (Windows only). Can be `chrome` or `browseros`. | `string` | `chrome` |

## <a name="secrets-configuration"></a>Secrets Configuration

The following secrets must be added to your repository for the scripts to function correctly. We are using "USER_PASSWORD" as a GitHub environment secret.

| Secret | Description | Example |
| :--- | :--- | :--- |
| `NGROK_AUTH_TOKEN` | Your authentication token from the [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken). Required if `tunnel_provider` is `ngrok`. | `2aBcDeFgHiJkLmNoPqRsTuVwXyZ_123456789` |
| `CF_TUNNEL_TOKEN` | Your Cloudflare Tunnel token. Required if `tunnel_provider` is `cloudflare`. | `your-long-cloudflare-token` |
| `USER_PASSWORD` | **Required**. The password for the new user account that will be created on the VM. | `your-strong-password` |

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
| **Persistency** | All your work will be gone when the job is complete. There is no data persistence. |
| **Usage Limits (Free Tier)** | - **Public Repositories**: Unlimited minutes/month. <br> - **Private Repositories**: 2000 minutes/month. <br> *(These limits may be higher on paid tiers)*. |

**Do not use these VMs for mining cryptocurrency, gaming, or any other unethical tasks. Your GitHub account may be flagged or permanently suspended.**