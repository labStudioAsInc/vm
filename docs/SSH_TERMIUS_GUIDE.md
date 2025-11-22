# SSH Access via Termius

This guide explains how to connect to your VM using SSH through Termius.

## Prerequisites

1. **Termius App**: Download from [termius.com](https://www.termius.com)
2. **USER_PASSWORD Secret**: Set in your GitHub repository secrets
3. **NGROK_AUTH_TOKEN Secret**: Set in your GitHub repository secrets (for tunneling)

## Setup Steps

### 1. Configure GitHub Secrets

Go to your repository:
- Settings → Secrets and variables → Actions
- Add `USER_PASSWORD`: Your desired SSH password
- Add `NGROK_AUTH_TOKEN`: Your ngrok authentication token (get from [ngrok.com](https://ngrok.com))

### 2. Run the SSH Debug Workflow

1. Go to **Actions** tab
2. Select **SSH Debug Access** workflow
3. Click **Run workflow**
4. Choose your OS (macOS, Ubuntu, or Windows)
5. Select ngrok region (default: auto)
6. Click **Run workflow**

### 3. Get Connection Details

Once the workflow starts:
1. Open the workflow run
2. Expand the **Connection Info** step
3. Copy the connection details:
   - **Host**: The ngrok address
   - **Port**: The ngrok port
   - **User**: `runner` (Linux/macOS) or `runneradmin` (Windows)
   - **Password**: Your `USER_PASSWORD` secret

### 4. Connect via Termius

#### On Desktop/Web:

1. Open Termius
2. Click **New Host**
3. Fill in:
   - **Label**: VM Name (e.g., "macOS VM")
   - **Address**: Host from Connection Info
   - **Port**: Port from Connection Info
   - **Username**: `runner` or `runneradmin`
   - **Password**: Your USER_PASSWORD
4. Click **Save**
5. Click the host to connect

#### On Mobile:

1. Open Termius
2. Tap **+** to add new host
3. Enter the same details as above
4. Tap **Save**
5. Tap to connect

## Connection Details Example

```
=== TERMIUS CONNECTION ===
Host: 0.tcp.ngrok.io
Port: 12345
User: runner
Pass: (YOUR_USER_PASSWORD)
```

## Troubleshooting

**Connection refused**: Workflow may still be initializing. Wait 30 seconds and retry.

**Authentication failed**: Verify your `USER_PASSWORD` secret is set correctly.

**Timeout**: Check that your `NGROK_AUTH_TOKEN` is valid.

**Connection lost**: The workflow runs for 6 hours. Restart it to get a new connection.

## Notes

- The VM is temporary and will be destroyed after the workflow completes
- Default timeout: 6 hours
- Each workflow run gets a new ngrok tunnel URL
- SSH is tunneled through ngrok for secure remote access
