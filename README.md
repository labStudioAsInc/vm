# VM with GitHub Actions

This repository contains scripts for the initial setup and configuration of servers for various operating systems. These scripts are designed to automate the pre-installation process, ensuring a consistent and reliable environment for our applications.

## How it Works

This project leverages GitHub Actions to provide you with a temporary, free virtual machine. Here's the basic workflow:

1.  **Triggering the Action**: When you run a workflow in the "Actions" tab, GitHub provisions a fresh virtual machine (VM) with the operating system you choose (Windows, Ubuntu, or macOS).
2.  **Running the Script**: The action then executes one of the pre-installation scripts from this repository on the new VM.
3.  **Setting up Remote Access**: The script installs the necessary software for remote access (RDP for Windows, VNC for macOS/Ubuntu) and creates a new user account with the password you provide in the `USER_PASSWORD` secret.
4.  **Creating a Secure Tunnel**: The script then installs `ngrok` and uses your `NGROK_AUTH_TOKEN` to create a secure tunnel from the public internet to the remote desktop port on the VM.
5.  **Accessing the VM**: The unique ngrok URL for your session is printed in the GitHub Actions logs. You can use this URL with any standard RDP or VNC client to connect to your temporary VM.

Since the VM is part of a GitHub Actions job, it is temporary and will be destroyed once the job finishes (after a maximum of 6 hours).

## Installation

1.  **Fork this repository**: Click the "Fork" button at the top-right of this page to create your own copy.
2.  **Add secrets**: Go to your forked repository's `Settings` > `Secrets and variables` > `Actions` and add the necessary secrets as described in the "Secrets Configuration" section below.
3.  **Run workflow**: Go to the "Actions" tab of your repository, select the desired workflow, and run it.

## Secrets Configuration

The following secrets must be added to your repository for the scripts to function correctly.

| Secret | Description | Example |
| :--- | :--- | :--- |
| `NGROK_AUTH_TOKEN` | **Required**. Your authentication token from the [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken). This is needed to create the secure tunnel to your VM. | `2aBcDeFgHiJkLmNoPqRsTuVwXyZ_123456789` |
| `USER_PASSWORD` | **Required**. The password for the new user account that will be created on the VM. | `your-strong-password` |

## Available Images

| Image | YAML Label | Included Software |
| --------------------|---------------------|--------------------|
| Ubuntu 24.04 | `ubuntu-latest` or `ubuntu-24.04` | [ubuntu-24.04] |
| Ubuntu 22.04 | `ubuntu-22.04` | [ubuntu-22.04] |
| macOS 26 Arm64 `beta` | `macos-26` or `macos-26-xlarge` | [macOS-26-arm64] |
| macOS 15 | `macos-latest-large`, `macos-15-large`, or `macos-15-intel` | [macOS-15] |
| macOS 15 Arm64 | `macos-latest`, `macos-15`, or `macos-15-xlarge` | [macOS-15-arm64] |
| macOS 14 | `macos-14-large`| [macOS-14] |
| macOS 14 Arm64 | `macos-14` or `macos-14-xlarge`| [macOS-14-arm64] |
| macOS 13 ![Deprecated](https://img.shields.io/badge/-Deprecated-red) | `macos-13` or `macos-13-large` | [macOS-13] |
| macOS 13 Arm64 ![Deprecated](https://img.shields.io/badge/-Deprecated-red) | `macos-13-xlarge` | [macOS-13-arm64] |
| Windows Server 2025 | `windows-2025` | [windows-2025] |
| Windows Server 2022 | `windows-latest` or `windows-2022` | [windows-2022] |
| Windows Server 2019 ![Deprecated](https://img.shields.io/badge/-Deprecated-red) | `windows-2019` | [windows-2019] |

## System Configuration

The hardware specifications for GitHub-hosted runners vary depending on whether the repository is public or private.

### Standard Runners for Public Repositories

| Virtual Machine | Processor (CPU) | Memory (RAM) | Storage (SSD) |
| :--- | :--- | :--- | :--- |
| Linux | 4 Cores | 16 GB | ≈ 250 GB |
| Windows | 4 Cores | 16 GB | ≈ 250 GB |
| macOS (Intel) | 4 Cores | 14 GB | ≈ 250 GB |
| macOS (ARM, M1) | 3 Cores | 7 GB | ≈ 250 GB |

### Standard Runners for Private Repositories

| Virtual Machine | Processor (CPU) | Memory (RAM) | Storage (SSD) |
| :--- | :--- | :--- | :--- |
| Linux | 2 Cores | 7 GB | ≈ 250 GB |
| Windows | 2 Cores | 7 GB | ≈ 250 GB |
| macOS (Intel) | 4 Cores | 14 GB | ≈ 250 GB |
| macOS (ARM, M1) | 3 Cores | 7 GB | ≈ 250 GB |

*Note: The `large` and `xlarge` runners listed in the "Available Images" table have different specifications. For more details, please refer to the official [GitHub Larger Runners documentation](https://docs.github.com/en/actions/using-github-hosted-runners/about-larger-runners).*

## Pre-installed Software and Configurations

The following table details the software and configurations that are pre-installed by the scripts for each operating system:

| Operating System | Pre-installed Software/Configuration |
| :--- | :--- |
| **macOS** | - **BlackHole 2ch**: A virtual audio driver for routing audio between applications. <br> - **New Admin User**: A new user account with administrative privileges is created. <br> - **Remote Management**: Screen sharing and remote management are enabled for the new user. |
| **Ubuntu** | - **snd-aloop**: A kernel module for creating loopback audio devices. <br> - **New Sudo User**: A new user account with `sudo` privileges is created. |
| **Windows** | - **VB-CABLE**: A virtual audio cable for routing audio. <br> - **New Admin User**: A new user account is created and added to the Administrators group. <br> - **Windows Audio Services**: The `Audiosrv` and `AudioEndpointBuilder` services are enabled and started. <br> - **RDP Audio Redirection**: Group policies are configured to allow audio capture over RDP. <br> - **Google Chrome**: Set as the default web browser. |

## Connecting to your VM

Once the GitHub Actions workflow is running, you need to find the connection details from the logs.

1.  **Open the workflow logs**: Go to the "Actions" tab in your repository and click on the running workflow.
2.  **Find the ngrok URL**: Look through the logs for lines that look like `url=tcp://0.tcp.ngrok.io:12345`. This is your connection address.
3.  **Connect using an RDP or VNC client**:
    *   **Windows (RDP)**: Use a Remote Desktop client with the address and port provided by ngrok (e.g., `0.tcp.ngrok.io` and port `12345`).
    *   **Ubuntu/macOS (VNC)**: Use a VNC client (like RealVNC, TightVNC, or Screen Sharing on macOS) to connect to the address and port provided by ngrok.

Your username is the one you provided during the setup, and the password is the one you set in the `USER_PASSWORD` secret.

---

## Disclaimer

| Limitation | Details |
| :--- | :--- |
| **Max Runtime** | Each job can run for a maximum of 6 hours. |
| **Persistency** | All your work will be gone when the job is complete. There is no data persistence. |
| **Usage Limits (Free Tier)** | - **Public Repositories**: Unlimited minutes/month. <br> - **Private Repositories**: 2000 minutes/month. <br> *(These limits may be higher on paid tiers)*. |

**Do not use these VMs for mining cryptocurrency, gaming, or any other unethical tasks. Your GitHub account may be flagged or permanently suspended.**

---

*This repository is maintained by StudioAs Inc.*
*aiaccess.pro*