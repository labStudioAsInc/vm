#!/bin/bash
#
# This script contains pre-installation steps for macOS.
# It should be run with sudo privileges.
#

echo "Starting macOS pre-install steps..."

# 1. Install BlackHole for virtual audio
echo "Step 1: Installing BlackHole virtual audio device..."
# Assuming Homebrew is installed and in the PATH
if command -v brew &> /dev/null; then
    brew install blackhole-2ch
else
    echo "Warning: Homebrew not found. Skipping BlackHole installation."
fi

# 2. Create a new user with a static password and admin rights
echo "Step 2: Creating new user 'testuser'..."
# Use sysadminctl to create user and grant admin privileges
sysadminctl -addUser "testuser" -password "Gck83gYShmW6IqfpNwRT" -admin
if [ $? -eq 0 ]; then
    echo "Successfully created admin user 'testuser'."
else
    echo "Error: Failed to create user 'testuser'. It may already exist."
fi


# 3. Enable Remote Management and Screen Sharing to fix black screen issue
echo "Step 3: Enabling Remote Management and Screen Sharing for 'testuser'..."
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users "testuser" -privs -all -restart -agent -menu

echo "macOS pre-install steps completed."