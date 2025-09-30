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
apt-get update

# 1. Optional Installations
if [ "$INSTALL_VIRTUAL_SOUND_CARD" == "true" ]; then
    echo "Setting up virtual audio..."
    # Ensure the module is available, install if necessary
    if ! modinfo snd-aloop &> /dev/null; then
        echo "snd-aloop not found, installing necessary packages..."
        apt-get install -y linux-modules-extra-$(uname -r)
    fi

    # Load the module
    modprobe snd-aloop
    if lsmod | grep -q "snd_aloop"; then
        echo "snd-aloop module loaded successfully."
    else
        echo "Error: Failed to load snd-aloop module."
    fi
fi

if [ "$INSTALL_VSCODE" == "true" ]; then
    echo "Installing VS Code..."
    apt-get install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    apt-get install -y apt-transport-https
    apt-get update
    apt-get install -y code
    echo "VS Code installed successfully."
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