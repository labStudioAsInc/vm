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