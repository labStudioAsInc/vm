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
INSTALL_VIRTUAL_SOUND_CARD="${2:-false}"
INSTALL_VSCODE="${3:-false}"

echo "Starting Ubuntu pre-install steps for user '$USERNAME'..."
sudo apt-get update

# 1. Optional Installations
if [ "$INSTALL_VIRTUAL_SOUND_CARD" == "true" ]; then
    echo "Setting up virtual audio..."
    # Ensure the module is available, install if necessary
    if ! modinfo snd-aloop &> /dev/null; then
        echo "snd-aloop not found, installing necessary packages..."
        sudo apt-get install -y linux-modules-extra-$(uname -r)
    fi

    # Load the module
    sudo modprobe snd-aloop
    if lsmod | grep -q "snd_aloop"; then
        echo "snd-aloop module loaded successfully."
    else
        echo "Error: Failed to load snd-aloop module."
    fi
fi

if [ "$INSTALL_VSCODE" == "true" ]; then
    echo "Installing VS Code..."
    sudo apt-get install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo rm -f packages.microsoft.gpg
    sudo apt-get install -y apt-transport-https
    sudo apt-get update
    sudo apt-get install -y code
    echo "VS Code installed successfully."
fi

# 2. Create a new user and configure their session
echo "Step 2: Creating new user '$USERNAME' and configuring session..."
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists. Setting password and ensuring sudo rights."
    echo "$USERNAME:$USER_PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo "$USERNAME"
else
    sudo useradd -m -s /bin/bash "$USERNAME"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create user '$USERNAME'."
        exit 1
    fi
    echo "$USERNAME:$USER_PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo "$USERNAME"
    echo "Successfully created user '$USERNAME' and added to sudo group."
fi

# Create .xsession file immediately after user creation
echo "xfce4-session" | sudo tee /home/$USERNAME/.xsession
sudo chown $USERNAME:$USERNAME /home/$USERNAME/.xsession
echo ".xsession file created successfully."

# 3. Configure RDP
echo "Step 3: Configuring RDP..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-goodies xrdp
sudo systemctl enable --now xrdp
sudo ufw allow 3389
echo "RDP configured successfully."

echo "Ubuntu pre-install steps completed."