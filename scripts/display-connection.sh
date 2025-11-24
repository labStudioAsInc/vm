#!/bin/bash
# Display connection details
# Usage: ./display-connection.sh <provider> <os> <address> <port> <username> <password>

PROVIDER=$1
OS=$2
ADDRESS=$3
PORT=$4
USERNAME=$5
PASSWORD=$6

if [ "$PROVIDER" == "ngrok" ]; then
    if [[ "$OS" == "macos"* ]]; then
        PROTOCOL="VNC (Use a VNC Viewer like RealVNC or TightVNC)"
    else
        PROTOCOL="RDP (Use Remote Desktop Connection)"
    fi

    echo "🎯 CONNECTION DETAILS 🎯"
    echo "=========================================="
    echo "OS: $OS"
    echo "Protocol: $PROTOCOL"
    echo "Address: $ADDRESS"
    echo "Port: $PORT"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "=========================================="
    echo "Connection string: $ADDRESS:$PORT"

elif [ "$PROVIDER" == "cloudflare" ]; then
    echo "🎯 CLOUDFLARE CONNECTION DETAILS 🎯"
    echo "=========================================="
    echo "OS: $OS"
    
    if [[ "$OS" == *"windows"* ]]; then
        echo "Protocol: RDP (Use Remote Desktop Connection)"
        echo "Address: $ADDRESS"
    else
        echo "1. Install cloudflared on your local machine."
        echo "2. Run the following command:"
        echo "   cloudflared access rdp --hostname $ADDRESS"
        echo ""
    fi
    
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "=========================================="
fi
