# Kiro Remote Terminal Setup Guide

This workflow allows you to access a Kiro CLI terminal running on GitHub Actions from your Android device.

## 🚀 Quick Start

### 1. Setup Secrets (Optional)

**For Cloudflare**: No setup needed! Uses temporary Quick Tunnel (no token required)

**For ngrok** (if you want to use it):
- Go to: https://dashboard.ngrok.com/get-started/your-authtoken
- Copy your authtoken
- In GitHub: Settings → Secrets and variables → Actions → New repository secret
- Name: `NGROK_AUTH_TOKEN`
- Value: Your ngrok authtoken

### 2. Run the Workflow

1. Go to **Actions** tab in your GitHub repository
2. Click **Kiro Remote Terminal Access**
3. Click **Run workflow**
4. Choose options:
   - **Tunnel provider**: `cloudflare` (free, no setup) or `ngrok` (requires token)
   - **Duration**: How many hours to keep it running (max 6)
5. Click **Run workflow**

### 3. Get Your Access URL

1. Click on the running workflow
2. Click on the **kiro-terminal** job
3. Expand the tunnel step (either "Start Cloudflare Tunnel" or "Start ngrok Tunnel")
4. Look for the URL like:
   - Cloudflare: `https://xxxxx.trycloudflare.com`
   - ngrok: `https://xxxxx.ngrok-free.app`

### 4. Access from Android

1. Open the URL in your Android browser (Chrome, Firefox, etc.)
2. You'll see a terminal interface
3. Start using Kiro CLI!

## 📋 Comparison: Cloudflare vs ngrok

| Feature | Cloudflare Quick Tunnel | ngrok |
|---------|------------------------|-------|
| **Setup** | Zero config needed ✅ | Requires authtoken for best experience |
| **Token required** | No | Yes (already configured) |
| **Speed** | Fast | Fast |
| **Reliability** | Very stable | Very stable |
| **Free tier** | Unlimited temporary tunnels | 1 online tunnel, 40 connections/min |
| **URL format** | `*.trycloudflare.com` | `*.ngrok-free.app` |
| **Best for** | Quick access, no setup | More features, custom domains (paid) |

## ⚠️ Important Notes

1. **Temporary Environment**: Everything is deleted when the workflow ends
2. **Time Limits**: Maximum 6 hours per run
3. **No Persistence**: Each run starts fresh
4. **Public Access**: Anyone with the URL can access your terminal (URLs are random)
5. **Security**: Don't expose sensitive data or credentials

## 🛠️ Customization

### Install Kiro CLI

Edit the workflow file at `.github/workflows/kiro-remote-terminal.yml`:

```yaml
- name: Install Kiro CLI
  run: |
    # Replace with actual Kiro installation
    npm install -g @amazon/kiro-cli
    # or
    curl -o kiro https://example.com/kiro && chmod +x kiro
```

### Change Terminal Settings

Modify the ttyd command:
```yaml
ttyd -p 7681 -W bash  # Current
ttyd -p 7681 -W -c user:pass bash  # Add password protection
ttyd -p 7681 -W -t fontSize=16 bash  # Larger font
```

## 🔧 Troubleshooting

### Tunnel URL not showing
- Check the tunnel step logs
- Make sure the workflow has internet access
- Try the other tunnel provider

### Terminal not loading
- Check if ttyd started successfully
- Verify port 7681 is not blocked
- Try refreshing the browser

### Kiro CLI not found
- Update the "Install Kiro CLI" step with correct installation commands
- Check if Kiro is in PATH

## 💡 Tips

- **Bookmark the URL** during your session for quick access
- **Use tmux/screen** to keep sessions alive if connection drops
- **Clone your repo** in the terminal to work on your code
- **Install additional tools** as needed (they'll be available for that session)

## 🔐 Security Best Practices

1. Don't store sensitive credentials in the workflow
2. Use GitHub Secrets for tokens and passwords
3. Be aware that the tunnel URL is publicly accessible
4. Consider adding password protection to ttyd
5. Cancel the workflow when done to close the tunnel

## 📱 Android Browser Recommendations

- **Chrome**: Best compatibility
- **Firefox**: Good alternative
- **Brave**: Privacy-focused option
- **Samsung Internet**: Works well on Samsung devices

## 🎯 Use Cases

- Quick testing on Linux environment
- Running Kiro CLI without local installation
- Accessing development tools from mobile
- Temporary cloud workspace
- Learning and experimentation

---

**Need help?** Check the workflow logs for detailed error messages.
