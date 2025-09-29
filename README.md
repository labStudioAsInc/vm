# VM with GitHub Actions

This repository contains scripts for the initial setup and configuration of servers for various operating systems. These scripts are designed to automate the pre-installation process, ensuring a consistent and reliable environment for our applications.

## Installation

1.  **Fork this repository**: Click the "Fork" button at the top-right of this page to create your own copy.
2.  **Add secrets**: Go to your forked repository's `Settings` > `Secrets and variables` > `Actions` and add the necessary secrets as described in the "Secrets Configuration" section below.
3.  **Run workflow**: Go to the "Actions" tab of your repository, select the desired workflow, and run it.

## Secrets Configuration

The following secrets must be added to your repository for the scripts to function correctly.

| Secret | Description | Example |
| :--- | :--- | :--- |
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

## Usage

To use these scripts, you will need to run them with administrative or `sudo` privileges on the target machine.

### macOS

1.  Open a terminal.
2.  Run the script with the desired username as an argument:
    ```bash
    sudo ./scripts/preinstall-mac.sh <username>
    ```

### Ubuntu

1.  Open a terminal.
2.  Run the script with the desired username as an argument:
    ```bash
    sudo ./scripts/preinstall-ubuntu.sh <username>
    ```

### Windows

1.  Open PowerShell as an Administrator.
2.  Run the script with the desired username as an argument:
    ```powershell
    .\scripts\preinstall-windows.ps1 -Username <username>
    ```

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