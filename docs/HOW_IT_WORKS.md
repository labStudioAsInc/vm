## How it works

This project leverages GitHub Actions to provide you with a temporary, free virtual machine. Here's the basic workflow:

1.  **Triggering the Action**: When you run a workflow in the "Actions" tab, GitHub provisions a fresh virtual machine (VM) with the operating system you choose (Windows, Ubuntu, or macOS).
2.  **Running the Script**: The action then executes one of the pre-installation scripts from this repository on the new VM.
3.  **Setting up Remote Access**: The script installs the necessary software for remote access (RDP for Windows/Ubuntu, VNC for macOS) and creates a new user account with the password you provide in the `USER_PASSWORD` secret.
4.  **Creating a Secure Tunnel**: The script then installs `ngrok` and uses your `NGROK_AUTH_TOKEN` to create a secure tunnel from the public internet to the remote desktop port on the VM.
5.  **Accessing the VM**: The unique ngrok URL for your session is printed in the GitHub Actions logs. You can use this URL with any standard RDP or VNC client to connect to your temporary VM.

Since the VM is part of a GitHub Actions job, it is temporary and will be destroyed once the job finishes (after a maximum of 6 hours).