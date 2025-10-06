#!/bin/bash
#
# SCRIPT: preinstall-mac.sh
# AUTHOR: TheRealAshik
# DATE: 2025-10-06
#
# DESCRIPTION:
#   This script performs pre-installation and configuration tasks for a macOS VM.
#   It automates the initial setup by creating a new user, installing optional
#   software, and enabling remote access for VNC connections.
#
# USAGE:
#   sudo ./preinstall-mac.sh <username> [install_virtual_sound_card] [install_github_desktop] [install_vscode]
#
# ARGUMENTS:
#   $1: username (required) - The username for the new local user account.
#   $2: install_virtual_sound_card (optional) - 'true' to install BlackHole audio driver. Default is 'false'.
#   $3: install_github_desktop (optional) - 'true' to install GitHub Desktop. Default is 'false'.
#   $4: install_vscode (optional) - 'true' to install Visual Studio Code. Default is 'false'.
#
# ENVIRONMENT VARIABLES:
#   USER_PASSWORD (required): The password for the new user account.
#
# NOTES:
#   This script must be run with sudo privileges to perform administrative tasks
#   like creating users and enabling remote management.
#

# --- Argument and Environment Variable Validation ---
if [ -z "$1" ]; then
    echo "Error: Username must be provided as the first argument."
    exit 1
fi

if [ -z "$USER_PASSWORD" ]; then
    echo "Error: USER_PASSWORD environment variable is not set."
    exit 1
fi

# --- Script Parameters ---
USERNAME="$1"
INSTALL_VIRTUAL_SOUND_CARD="${2:-false}"
INSTALL_GITHUB_DESKTOP="${3:-false}"
INSTALL_VSCODE="${4:-false}"

echo "Starting macOS pre-install steps for user '$USERNAME'..."

# --- Section 1: Optional Software Installations ---
# This section installs software if the corresponding argument is set to 'true'.
# It uses Homebrew for package management and checks if it's installed first.
if [ "$INSTALL_VIRTUAL_SOUND_CARD" == "true" ]; then
    echo "Installing BlackHole virtual audio device..."
    if command -v brew &> /dev/null; then
        brew install blackhole-2ch
    else
        echo "Warning: Homebrew not found. Skipping BlackHole installation."
    fi
fi

if [ "$INSTALL_GITHUB_DESKTOP" == "true" ]; then
    echo "Installing GitHub Desktop..."
    if command -v brew &> /dev/null; then
        brew install --cask github
    else
        echo "Warning: Homebrew not found. Skipping GitHub Desktop installation."
    fi
fi

if [ "$INSTALL_VSCODE" == "true" ]; then
    echo "Installing VS Code..."
    if command -v brew &> /dev/null; then
        brew install --cask visual-studio-code
    else
        echo "Warning: Homebrew not found. Skipping VS Code installation."
    fi
fi


# --- Section 2: Create New User ---
# Creates a new local user with administrative (admin) privileges.
# The password is set from the USER_PASSWORD environment variable.
echo "Step 2: Creating new user '$USERNAME'..."
sysadminctl -addUser "$USERNAME" -password "$USER_PASSWORD" -admin
if [ $? -eq 0 ]; then
    echo "Successfully created admin user '$USERNAME'."
else
    echo "Error: Failed to create user '$USERNAME'. It may already exist."
fi


# --- Section 3: Enable Remote Access ---
# Activates and configures Apple Remote Desktop (ARD) and Screen Sharing.
# This is crucial for enabling VNC connections and preventing black screen issues.
# It grants the newly created user all necessary privileges for remote access.
echo "Step 3: Enabling Remote Management and Screen Sharing for '$USERNAME'..."
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users "$USERNAME" -privs -all -restart -agent -menu

echo "macOS pre-install steps completed."