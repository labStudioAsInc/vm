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

if [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo "Error: NGROK_AUTH_TOKEN environment variable is not set."
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

# 3. Install Desktop Environment, VNC Server, and ngrok
echo "Step 3: Installing Desktop Environment, VNC Server, and ngrok..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-goodies tightvncserver wget unzip

# Install ngrok
wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O ngrok.zip
unzip ngrok.zip
mv ngrok /usr/local/bin/
ngrok authtoken $NGROK_AUTH_TOKEN

# 4. Configure VNC server
echo "Step 4: Configuring VNC server for user '$USERNAME'..."
su - $USERNAME -c 'mkdir -p ~/.vnc'
su - $USERNAME -c "echo '$USER_PASSWORD' | vncpasswd -f > ~/.vnc/passwd"
chmod 600 /home/$USERNAME/.vnc/passwd

# Create xstartup file
cat <<EOT > /home/$USERNAME/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOT

chmod +x /home/$USERNAME/.vnc/xstartup
chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

# 5. Start VNC and ngrok tunnel
echo "Step 5: Starting VNC server and ngrok tunnel..."
su - $USERNAME -c 'vncserver :1 -geometry 1280x800 -depth 24'

echo "Starting ngrok tunnel..."
ngrok tcp 5901 --log=stdout > ngrok.log &

echo "Setup is complete. Find your ngrok URL in the 'ngrok.log' artifact or the action logs."
echo "Ubuntu pre-install steps completed."