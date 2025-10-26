#!/bin/bash
#
# This script contains pre-installation steps for macOS.
# It should be run with sudo privileges.
#

if [ -z "$1" ]; then
    echo "Error: Username must be provided as the first argument."
    exit 1
fi

if [ -z "$USER_PASSWORD" ]; then
    echo "Error: USER_PASSWORD environment variable is not set."
    exit 1
fi

USERNAME="$1"
INSTALL_VIRTUAL_SOUND_CARD="${2:-false}"

echo "Starting macOS pre-install steps for user '$USERNAME'..."

# 1. Optional Installations
if [ "$INSTALL_VIRTUAL_SOUND_CARD" == "true" ]; then
    echo "Installing BlackHole virtual audio device..."
    if command -v brew &> /dev/null; then
        brew install blackhole-2ch
    else
        echo "Warning: Homebrew not found. Skipping BlackHole installation."
    fi
fi

# 2. Create a new user with a static password and admin rights
echo "Step 2: Creating new user '$USERNAME'..."
# Use sysadminctl to create user and grant admin privileges
sysadminctl -addUser "$USERNAME" -password "$USER_PASSWORD" -admin
if [ $? -eq 0 ]; then
    echo "Successfully created admin user '$USERNAME'."
else
    echo "Error: Failed to create user '$USERNAME'. It may already exist."
fi


# 3. Enable Remote Management and Screen Sharing to fix black screen issue
echo "Step 3: Enabling Remote Management and Screen Sharing for '$USERNAME'..."
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users "$USERNAME" -privs -all -restart -agent -menu

echo "macOS pre-install steps completed."
