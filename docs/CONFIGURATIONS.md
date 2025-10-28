## Workflow Inputs

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

## Secrets Configuration

The following secrets must be added to your repository for the scripts to function correctly. We are using "USER_PASSWORD" as a GitHub environment secret.

| Secret | Description | Example |
| :--- | :--- | :--- |
| `NGROK_AUTH_TOKEN` | Your authentication token from the [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken). Required if `tunnel_provider` is `ngrok`. | `2aBcDeFgHiJkLmNoPqRsTuVwXyZ_123456789` |
| `CF_TUNNEL_TOKEN` | Your Cloudflare Tunnel token. Required if `tunnel_provider` is `cloudflare`. | `your-long-cloudflare-token` |
| `USER_PASSWORD` | **Required**. The password for the new user account that will be created on the VM. | `your-strong-password` |