# Server Pre-installation Scripts

This repository contains scripts for the initial setup and configuration of servers for various operating systems. These scripts are designed to automate the pre-installation process, ensuring a consistent and reliable environment for our applications.

## Available OS Images

- Windows Server 2025
- Ubuntu 24
- macOS 26

## System Configuration

| OS | CPU | RAM | Storage |
| :--- | :--- | :--- | :--- |
| Windows Server 2025 | 4 Cores | 16 GB | 256 GB SSD |
| Ubuntu 24 | 4 Cores | 16 GB | 256 GB SSD |
| macOS 26 | 4 Cores | 16 GB | 256 GB SSD |

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

**Do not use these VMs for mining cryptocurrency, gaming, or any other unethical tasks. Your GitHub account may be flagged or permanently suspended.**

---

*This repository is maintained by StudioAs Inc.*
*aiaccess.pro*