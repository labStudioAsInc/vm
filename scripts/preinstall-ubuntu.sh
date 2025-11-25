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

# 2. Create a new user
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

# 3. Install and Configure RDP
echo "Step 3: Installing and configuring RDP..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-goodies xrdp
# Configure xrdp to use the XFCE session
sudo sed -i.bak '/fi/a #xrdp multiple users configuration \n startxfce4 \n' /etc/xrdp/startwm.sh
sudo systemctl enable --now xrdp
sudo ufw allow 3389
echo "RDP packages installed and configured."

# 4. Configure user session
echo "Step 4: Configuring user session for '$USERNAME'..."
# Failsafe: ensure home directory exists and has correct ownership
sudo mkdir -p /home/$USERNAME
sudo chown $USERNAME:$USERNAME /home/$USERNAME
# Create .xsession file to launch XFCE
sudo -u $USERNAME sh -c "echo '#!/bin/sh' > /home/$USERNAME/.xsession"
sudo -u $USERNAME sh -c "echo 'startxfce4' >> /home/$USERNAME/.xsession"
sudo -u $USERNAME chmod +x /home/$USERNAME/.xsession

# Restart xrdp to apply all changes
sudo systemctl restart xrdp
echo "User session configured successfully."

# 5. Install Kiro CLI
echo "Step 5: Installing Kiro CLI..."
sudo -u $USERNAME bash -c 'curl -fsSL https://install.kiro.aws | bash'
if [ $? -eq 0 ]; then
    echo "Kiro CLI installed successfully."
else
    echo "Warning: Kiro CLI installation failed."
fi

# Add Kiro CLI to PATH
sudo -u $USERNAME bash -c 'echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc'
echo "PATH configured for Kiro CLI."

# Configure Git
sudo -u $USERNAME git config --global user.email "mashikahamed0@gmail.com"
sudo -u $USERNAME git config --global user.name "@TheRealAshik"
echo "Git configured."

echo "Ubuntu pre-install steps completed."