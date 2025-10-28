<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%">

# VM with GitHub Actions

**Get a free, temporary Virtual Machine in the cloud, powered by GitHub Actions.**

This project provides a simple way to get a remote desktop environment for Windows, macOS, or Ubuntu running directly from your GitHub repository. It's perfect for testing, development, or any task that requires a clean, temporary OS instance.

</div>

---

## 🚀 Getting Started

Getting your own temporary VM is easy. Here's how:

1.  **Fork this Repository**: Click the **Fork** button at the top-right of this page to create your own copy.

2.  **Configure Secrets**:
    - Go to your forked repository's `Settings` > `Secrets and variables` > `Actions`.
    - Add a `USER_PASSWORD` secret. This will be the password for the user account on the VM.
    - If you want to use `ngrok` for the tunnel, add your `NGROK_AUTH_TOKEN`.
    - For more details on configuration, see the [Configurations Guide](docs/CONFIGURATIONS.md).

3.  **Run the Workflow**:
    - Go to the **Actions** tab of your repository.
    - Select the **Main Entrypoint** workflow.
    - Click **Run workflow**, choose your desired OS and other options, and you're off!

4.  **Connect to Your VM**:
    - Once the workflow is running, go to the workflow logs.
    - Find the **Display Connection Details** step to get the address and port.
    - Use your favorite RDP or VNC client to connect. Check out our [Installation and Use Guide](docs/INSTALLATION_AND_USE.md) for recommended clients.

## ✨ Features

- **Multi-OS Support**: Choose from Windows, macOS, and Ubuntu.
- **Customizable Setup**: Install common development tools like VS Code, GitHub Desktop, and even Android Studio using workflow inputs.
- **Flexible Tunneling**: Use either `ngrok` or `cloudflare` to create a secure tunnel to your VM.
- **Easy to Use**: Get up and running in minutes with minimal configuration.
- **Free**: Leverages the free tier of GitHub Actions.

## 🖥️ VM Specifications

The hardware specifications for the VMs (CPU, RAM, Storage) vary depending on the operating system you choose. For a detailed breakdown, please see our [**VM Specifications Document**](docs/VM_INFO.md).

## 📚 Documentation

For more detailed information, please refer to the documents in the `/docs` directory:

- [**How It Works**](docs/HOW_IT_WORKS.md): A technical overview of the project.
- [**Installation and Use**](docs/INSTALLATION_AND_USE.md): Step-by-step guide to using the workflows.
- [**Configurations**](docs/CONFIGURATIONS.md): Detailed information on all workflow inputs and secrets.
- [**Pre-installed Software**](docs/PRE_INSTALLED_SOFTWARE.md): A list of all available optional software.
- [**Disclaimer**](docs/DISCLAIMER.md): Important limitations and usage guidelines.

> [!WARNING]
> The macOS and Ubuntu workflows are not actively maintained and may be unstable. For the best experience, we recommend using the Windows runners.
