#!/bin/bash
#
# This script contains pre-installation steps for Ubuntu.
# It should be run with sudo privileges.
#

echo "Starting Ubuntu pre-install steps..."

# 1. Install and load snd-aloop module for virtual audio
echo "Step 1: Setting up virtual audio..."
# Ensure the module is available, install if necessary
if ! modinfo snd-aloop &> /dev/null; then
    echo "snd-aloop not found, installing necessary packages..."
    apt-get update
    apt-get install -y linux-modules-extra-$(uname -r)
fi

# Load the module
modprobe snd-aloop
if lsmod | grep -q "snd_aloop"; then
    echo "snd-aloop module loaded successfully."
else
    echo "Error: Failed to load snd-aloop module."
fi

# 2. Create a new user with a static password and sudo rights
echo "Step 2: Creating new user 'testuser'..."
if id "testuser" &>/dev/null; then
    echo "User 'testuser' already exists. Setting password and ensuring sudo rights."
    echo "testuser:Gck83gYShmW6IqfpNwRT" | chpasswd
    usermod -aG sudo testuser
else
    useradd -m -s /bin/bash testuser
    if [ $? -eq 0 ]; then
        echo "testuser:Gck83gYShmW6IqfpNwRT" | chpasswd
        usermod -aG sudo testuser
        echo "Successfully created user 'testuser' and added to sudo group."
    else
        echo "Error: Failed to create user 'testuser'."
    fi
fi

echo "Ubuntu pre-install steps completed."