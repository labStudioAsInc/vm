## Installation

1.  **Fork this repository**: Click the "Fork" button at the top-right of this page to create your own copy.
2.  **Add secrets**: Go to your forked repository's `Settings` > `Secrets and variables` > `Actions` and add the necessary secrets as described in the "Secrets Configuration" section below.
3.  **Run workflow**: Go to the "Actions" tab of your repository, select the desired workflow, and run it.

## How to use

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