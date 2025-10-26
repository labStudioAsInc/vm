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

## Step 3: Create API Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key
4. (Optional but recommended) Click "Restrict Key" to limit its usage:
   - Under "API restrictions", select "Restrict key"
   - Choose "Google Drive API" from the list
   - Click "Save"

## Step 4: Configure API Key Permissions

For the API key to work with your Google Drive, you need to ensure it has the right permissions:

1. Go to "APIs & Services" > "Credentials"
2. Click on your API key to edit it
3. Under "Application restrictions", you can leave it as "None" for testing
4. Under "API restrictions", make sure "Google Drive API" is selected
5. Click "Save"

## Step 5: Add API Key to GitHub Secrets

1. Go to your forked repository on GitHub
2. Click "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Name: `GOOGLE_DRIVE_API_KEY`
5. Value: Paste your API key from Step 3
6. Click "Add secret"

## Step 6: Test the Setup

1. Run your Windows workflow
2. Check the logs for successful backup/restore operations
3. Look for desktop shortcuts in your RDP session:
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

1. **"API Key not found" error**:
   - Ensure `GOOGLE_DRIVE_API_KEY` is added to GitHub repository secrets
   - Check that the secret name is exactly `GOOGLE_DRIVE_API_KEY`

2. **"Failed to get/create backup folder" error**:
   - Verify Google Drive API is enabled in your Google Cloud project
   - Check that your API key has Google Drive API permissions

3. **"No backup found" warning**:
   - This is normal for the first run
   - Subsequent runs should find and restore backups

4. **Upload/Download failures**:
   - Check your Google Drive storage quota
   - Verify your internet connection in the RDP session

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