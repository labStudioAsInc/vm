#!/bin/bash
#
# SCRIPT: preinstall-ubuntu.sh
# AUTHOR: TheRealAshik
# DATE: 2025-10-06
#
# DESCRIPTION:
#   This script performs pre-installation and configuration tasks for an Ubuntu VM.
#   It automates the initial setup by creating a new user, installing optional
#   software, and configuring the XFCE desktop environment with XRDP for remote access.
#
# USAGE:
#   sudo ./preinstall-ubuntu.sh <username> [install_virtual_sound_card] [install_vscode]
#
# ARGUMENTS:
#   $1: username (required) - The username for the new local user account.
#   $2: install_virtual_sound_card (optional) - 'true' to install and load the snd-aloop kernel module. Default is 'false'.
#   $3: install_vscode (optional) - 'true' to install Visual Studio Code. Default is 'false'.
#
# ENVIRONMENT VARIABLES:
#   USER_PASSWORD (required): The password for the new user account.
#
# NOTES:
#   This script must be run with sudo privileges to perform administrative tasks
#   like installing packages, creating users, and managing services.
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
INSTALL_VSCODE="${3:-false}"

echo "Starting Ubuntu pre-install steps for user '$USERNAME'..."
sudo apt-get update

# --- Section 1: Optional Installations ---
# This section installs software based on the script arguments.
if [ "$INSTALL_VIRTUAL_SOUND_CARD" == "true" ]; then
    echo "Setting up virtual audio..."
    # Ensure the snd-aloop module is available, install kernel extras if necessary.
    if ! modinfo snd-aloop &> /dev/null; then
        echo "snd-aloop not found, installing necessary packages..."
        sudo apt-get install -y linux-modules-extra-$(uname -r)
    fi

    # Load the snd-aloop kernel module to create virtual loopback sound cards.
    sudo modprobe snd-aloop
    if lsmod | grep -q "snd_aloop"; then
        echo "snd-aloop module loaded successfully."
    else
        echo "Error: Failed to load snd-aloop module."
    fi
fi

if [ "$INSTALL_VSCODE" == "true" ]; then
    echo "Installing VS Code..."
    # Add the Microsoft GPG key and repository, then install VS Code.
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

# --- Section 2: Create New User ---
# Creates a new user or updates an existing one.
# The user is given a password from the USER_PASSWORD environment variable and granted sudo privileges.
echo "Step 2: Creating new user '$USERNAME'..."
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

# --- Section 3: Install and Configure RDP ---
# Installs XFCE desktop environment and XRDP server.
# It configures XRDP to use XFCE as the default session for remote users.
echo "Step 3: Installing and configuring RDP..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-goodies xrdp
# Modify the xrdp startup script to launch XFCE.
sudo sed -i.bak '/fi/a #xrdp multiple users configuration \n startxfce4 \n' /etc/xrdp/startwm.sh
sudo systemctl enable --now xrdp
# Allow RDP traffic through the firewall.
sudo ufw allow 3389
echo "RDP packages installed and configured."

# --- Section 4: Configure User Session ---
# Ensures the user's home directory exists and sets up the .xsession file.
# The .xsession file tells the login manager which desktop environment to start.
echo "Step 4: Configuring user session for '$USERNAME'..."
# Failsafe: ensure home directory exists and has correct ownership.
sudo mkdir -p /home/$USERNAME
sudo chown $USERNAME:$USERNAME /home/$USERNAME
# Create .xsession file to launch XFCE.
sudo -u $USERNAME sh -c "echo '#!/bin/sh' > /home/$USERNAME/.xsession"
sudo -u $USERNAME sh -c "echo 'startxfce4' >> /home/$USERNAME/.xsession"
sudo -u $USERNAME chmod +x /home/$USERNAME/.xsession

# Restart xrdp to apply all configuration changes.
sudo systemctl restart xrdp
echo "User session configured successfully."

echo "Ubuntu pre-install steps completed."