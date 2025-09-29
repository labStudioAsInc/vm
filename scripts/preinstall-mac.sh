#!/bin/bash
#
# This script contains pre-installation steps for macOS.
#

echo "Starting macOS pre-install steps..."

# Install BlackHole for virtual audio
echo "Installing BlackHole virtual audio device..."
brew install blackhole-2ch

# Enable Remote Management and Screen Sharing to fix black screen issue
echo "Enabling Remote Management and Screen Sharing..."
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users admin -privs -all -restart -agent -menu

# Create a new user with a static password
echo "Creating new user..."
# This command needs to be run with sudo, which should be handled by the execution environment
dscl . -create /Users/testuser
dscl . -create /Users/testuser UserShell /bin/bash
dscl . -create /Users/testuser RealName "Test User"
dscl . -create /Users/testuser UniqueID "502"
dscl . -create /Users/testuser PrimaryGroupID 20
dscl . -create /Users/testuser NFSHomeDirectory /Users/testuser
dscl . -passwd /Users/testuser Gck83gYShmW6IqfpNwRT
# Add user to the admin group
dscl . -append /Groups/admin GroupMembership testuser


echo "macOS pre-install steps completed."