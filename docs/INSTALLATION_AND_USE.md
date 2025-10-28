# Installation and Use Guide

This guide will walk you through the process of setting up and connecting to your temporary VM.

## 🚀 Installation

Getting started is simple. Just follow these three steps:

1.  **Fork this Repository**: Click the **Fork** button at the top-right of this page to create your own copy. This will give you your own version of the project that you can run workflows from.

2.  **Configure Secrets**: Before you can run the workflow, you need to add at least one secret to your repository:
    - Go to your forked repository's `Settings` > `Secrets and variables` > `Actions`.
    - Add a `USER_PASSWORD` secret. This will be the password for the user account on the VM.
    - Depending on which tunnel provider you want to use, you may also need to add an `NGROK_AUTH_TOKEN` or `CF_TUNNEL_TOKEN`.
    - For a full explanation of all the required secrets, please see the [Configurations Guide](CONFIGURATIONS.md).

3.  **Run the Workflow**:
    - Go to the **Actions** tab of your forked repository.
    - In the left sidebar, click on the **Main Entrypoint** workflow.
    - Click the **Run workflow** button.
    - Select your desired OS and any other options, then click **Run workflow** again.

## 🖥️ How to Use

Once the workflow is running, you can connect to your VM using a remote desktop client.

### Step 1: Get Connection Details

1.  Go to the **Actions** tab in your repository and click on the running **Main Entrypoint** workflow.
2.  In the job summary, look for the **Display Connection Details** step.
3.  The logs will contain the **Address** and **Port** you need to connect.

### Step 2: Connect to the VM

The connection method depends on the OS you chose.

#### RDP (for Windows and Ubuntu)

To connect to a Windows or Ubuntu VM, you'll need an RDP client.

- **Windows**: The built-in **Remote Desktop Connection** app is the best choice.
- **macOS**: We recommend the [Microsoft Remote Desktop](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12) app from the App Store.
- **Linux**: [Remmina](https://remmina.org/) is a popular and effective option.

When you connect, use the **Address** and **Port** from the workflow logs, the `username` you specified, and the `USER_PASSWORD` you set in your secrets.

#### VNC (for macOS)

To connect to a macOS VM, you'll need a VNC client.

- **Windows**: [TightVNC](https://www.tightvnc.com/) and [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) are both excellent choices.
- **macOS**: The built-in **Screen Sharing** app works perfectly.
- **Linux**: [Remmina](https://remmina.org/) also supports VNC connections.

Use the **Address** and **Port** from the logs, along with your `username` and `USER_PASSWORD`.
