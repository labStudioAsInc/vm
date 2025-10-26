# Google Drive API Setup Guide

This guide will help you set up Google Drive API integration for persistent RDP sessions.

## Prerequisites

- A Google account with Google Drive access
- Access to Google Cloud Console
- 2TB Google Drive storage (as mentioned in your setup)

## Step 1: Create a Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" at the top of the page
3. Click "New Project"
4. Enter a project name (e.g., "RDP-Persistence")
5. Click "Create"

## Step 2: Enable Google Drive API

1. In your Google Cloud project, go to "APIs & Services" > "Library"
2. Search for "Google Drive API"
3. Click on "Google Drive API"
4. Click "Enable"

## Step 3: Create Service Account (Recommended)

**Note**: API keys have limited permissions and cannot upload/download files. Use a Service Account instead.

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "Service Account"
3. Enter a service account name (e.g., "rdp-backup-service")
4. Click "Create and Continue"
5. Skip the optional steps and click "Done"
6. Click on the created service account
7. Go to the "Keys" tab
8. Click "Add Key" > "Create new key"
9. Choose "JSON" format and click "Create"
10. Save the downloaded JSON file securely

## Step 4: Share Google Drive Folder with Service Account

1. Open Google Drive in your browser
2. Create a folder named "RDP-Sessions-Backup" (or use existing)
3. Right-click the folder and select "Share"
4. Add the service account email (from the JSON file, `client_email` field)
5. Give it "Editor" permissions
6. Click "Send"

## Step 5: Add Service Account to GitHub Secrets

1. Go to your forked repository on GitHub
2. Click "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Name: `GOOGLE_SERVICE_ACCOUNT_JSON`
5. Value: Paste the entire contents of the JSON file from Step 3 (the complete JSON, including all the curly braces)
6. Click "Add secret"

**Example of what the JSON should look like:**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "your-service@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

## Alternative: API Key Setup (Limited Functionality)

If you prefer to use an API key (with limitations):

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. Add it as `GOOGLE_DRIVE_API_KEY` secret in GitHub

**Note**: With API key, backups will be stored locally only, not in Google Drive.

## Step 6: Test the Setup

1. Run your Windows workflow from the **Actions** tab
2. Look for the **"Test Google Drive authentication"** step in the workflow logs
3. Check for successful authentication messages:
   - ✓ GOOGLE_SERVICE_ACCOUNT_JSON is set
   - ✓ JSON is valid
   - ✓ Private key is present
4. Monitor the **"Restore user data from Google Drive"** and **"Final backup before shutdown"** steps
5. In your RDP session, look for desktop shortcuts:
   - "Backup to Google Drive.bat"
   - "Restore from Google Drive.bat"
   - "Check Backup Status.bat"

## Important Notes

### Security Considerations

- **API Key Security**: Your API key is stored as a GitHub secret and is only accessible during workflow execution
- **Data Privacy**: Your data is stored in your own Google Drive account
- **Access Control**: The API key only has access to Google Drive API, not your entire Google account

### Storage Limits

- The system will use your Google Drive storage quota
- With 2TB available, you should have plenty of space for RDP session backups
- Each backup is compressed to minimize storage usage

### Backup Behavior

- **First Run**: No restore will occur (no backup exists yet)
- **Subsequent Runs**: Previous session data will be automatically restored
- **Periodic Backups**: Every 30 minutes during active sessions
- **Final Backup**: When the workflow ends (session timeout or manual termination)

## Troubleshooting

### Common Issues

1. **"GOOGLE_SERVICE_ACCOUNT_JSON environment variable is not set" error**:
   - Ensure `GOOGLE_SERVICE_ACCOUNT_JSON` is added to GitHub repository secrets
   - Check that the secret name is exactly `GOOGLE_SERVICE_ACCOUNT_JSON`
   - Verify you pasted the complete JSON content (including curly braces)

2. **"JSON is invalid" error**:
   - Check that you copied the entire JSON file content
   - Ensure no extra characters or truncation occurred
   - Verify the JSON format is valid

3. **"Failed to get access token" error**:
   - Verify Google Drive API is enabled in your Google Cloud project
   - Check that your Service Account has the correct permissions
   - Ensure the private key in the JSON is not corrupted

4. **"Failed to get/create backup folder" error**:
   - Verify the Service Account has access to Google Drive
   - Check your Google Drive storage quota
   - Ensure the Service Account email has been shared with the backup folder

5. **"No backup found" warning**:
   - This is normal for the first run
   - Subsequent runs should find and restore backups

6. **Upload/Download failures**:
   - Check your Google Drive storage quota
   - Verify your internet connection in the RDP session
   - Ensure the Service Account has proper permissions

### Getting Help

If you encounter issues:

1. Check the GitHub Actions logs for detailed error messages
2. Use the "Check Backup Status.bat" shortcut in your RDP session
3. Verify your Google Cloud Console settings
4. Ensure your API key hasn't been restricted too heavily

## API Quotas and Limits

Google Drive API has the following default quotas:
- 1,000 requests per 100 seconds per user
- 10,000 requests per 100 seconds

These limits are more than sufficient for the backup/restore operations in this system.