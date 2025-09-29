#!/bin/bash
#
# This script contains pre-installation steps for Ubuntu.
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

echo "Starting Ubuntu pre-install steps for user '$USERNAME'..."

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
echo "Step 2: Creating new user '$USERNAME'..."
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists. Setting password and ensuring sudo rights."
    echo "$USERNAME:$USER_PASSWORD" | chpasswd
    usermod -aG sudo "$USERNAME"
else
    useradd -m -s /bin/bash "$USERNAME"
    if [ $? -eq 0 ]; then
        echo "$USERNAME:$USER_PASSWORD" | chpasswd
        usermod -aG sudo "$USERNAME"
        echo "Successfully created user '$USERNAME' and added to sudo group."
    else
        echo "Error: Failed to create user '$USERNAME'."
    fi
fi

echo "Ubuntu pre-install steps completed."