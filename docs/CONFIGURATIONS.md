# Configurations Guide

This guide provides detailed information on all the available workflow inputs and secrets.

## Workflow Inputs

You can customize the VM setup by providing the following inputs when you run the **Main Entrypoint** workflow.

| Input | Description | Type | Default |
| :--- | :--- | :--- | :--- |
| `os` | The operating system for the VM. | `choice` | `windows-latest` |
| `username` | The username for the new user account on the VM. | `string` | **Required** |
| `tunnel_provider` | The tunneling service to use for remote access. Can be `ngrok` or `cloudflare`. | `choice` | `ngrok` |
| `region` | The [ngrok tunnel region](https://ngrok.com/docs/ngrok-agent/config#region) to use. This only applies if `tunnel_provider` is `ngrok`. | `choice` | `us` |
| `timeout` | The session timeout in minutes. The maximum is 360 (6 hours). | `string` | `360` |
| `install_virtual_sound_card` | Install a virtual sound card. | `boolean` | `false` |
| `install_github_desktop` | Install GitHub Desktop (Windows/macOS only). | `boolean` | `false` |
| `install_browseros` | Install BrowserOS (Windows only, placeholder). | `boolean` | `false` |
| `install_void_editor` | Install Void Editor (Windows only, placeholder). | `boolean` | `false` |
| `install_android_studio` | Install Android Studio (Windows only). | `boolean` | `false` |
| `install_vscode` | Install Visual Studio Code. | `boolean` | `false` |
| `set_default_browser` | Set the default web browser on Windows. Can be `chrome` or `browseros`. | `string` | `chrome` |

## Secrets Configuration

To use this project, you need to add the following secrets to your repository. You can do this in `Settings` > `Secrets and variables` > `Actions`.

| Secret | Description | Required? |
| :--- | :--- | :--- |
| `USER_PASSWORD` | The password for the user account that will be created on the VM. | **Yes** |
| `NGROK_AUTH_TOKEN` | Your authentication token from the [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken). | **Yes**, if `tunnel_provider` is `ngrok`. |
| `CF_TUNNEL_TOKEN` | Your Cloudflare Tunnel token from the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/). | **Yes**, if `tunnel_provider` is `cloudflare`. |

> [!IMPORTANT]
> Keep your secrets secure. Do not share your `NGROK_AUTH_TOKEN`, `CF_TUNNEL_TOKEN`, or `USER_PASSWORD` with anyone.
