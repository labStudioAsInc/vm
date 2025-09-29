#!/bin/bash
#
# This script contains pre-installation steps for Ubuntu.
#

echo "Starting Ubuntu pre-install steps..."

# Load snd-aloop module for virtual audio
echo "Loading snd-aloop module for virtual audio..."
modprobe snd-aloop

# Create a new user with a static password
echo "Creating new user..."
# This command needs to be run with sudo, which should be handled by the execution environment
useradd -m -s /bin/bash testuser
echo "testuser:Gck83gYShmW6IqfpNwRT" | chpasswd
# Add user to the sudo group
usermod -aG sudo testuser

echo "Ubuntu pre-install steps completed."