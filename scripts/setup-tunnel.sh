#!/bin/bash
# Universal tunnel setup script for all operating systems
# Usage: ./setup-tunnel.sh <provider> <os> <port> <region> <auth_token>

PROVIDER=$1
OS=$2
PORT=$3
REGION=$4
AUTH_TOKEN=$5

if [ "$PROVIDER" == "ngrok" ]; then
    echo "Setting up Ngrok tunnel..."
    NGROK_LOG="ngrok.log"
    CONFIG_FILE="ngrok.yml"

    echo "version: \"2\"" > $CONFIG_FILE
    echo "authtoken: $AUTH_TOKEN" >> $CONFIG_FILE
    [ -n "$REGION" ] && echo "region: $REGION" >> $CONFIG_FILE

    # Install ngrok based on OS
    if [[ "$OS" == *"windows"* ]]; then
        if [ "$RUNNER_ARCH" == "ARM64" ]; then
            curl -sL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-arm64.zip -o ngrok.zip
        else
            curl -sL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -o ngrok.zip
        fi
        unzip -o ngrok.zip
        pwsh -Command "Start-Process -NoNewWindow -FilePath 'ngrok.exe' -ArgumentList 'tcp $PORT --config $CONFIG_FILE --log $NGROK_LOG --region=$REGION'"
    elif [[ "$OS" == "macos"* ]]; then
        brew install ngrok
        nohup ngrok tcp $PORT --config "$CONFIG_FILE" --log "$NGROK_LOG" > /dev/null 2>&1 &
    else
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
        sudo apt update
        sudo apt install -y ngrok
        nohup ngrok tcp $PORT --config "$CONFIG_FILE" --log "$NGROK_LOG" > /dev/null 2>&1 &
    fi

    sleep 15

    # Get tunnel URL
    for i in {1..5}; do
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url // empty')
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
        echo "Attempt $i: Tunnel not ready yet, waiting..."
        sleep 5
    done

    if [ -z "$TUNNEL_URL" ]; then
        echo "::error::Failed to get ngrok tunnel info"
        cat "$NGROK_LOG" 2>/dev/null || echo "No ngrok log found"
        exit 1
    fi

    RDP_ADDRESS=$(echo "$TUNNEL_URL" | sed 's|tcp://||' | cut -d: -f1)
    RDP_PORT=$(echo "$TUNNEL_URL" | sed 's|tcp://||' | cut -d: -f2)
    echo "RDP_ADDRESS=$RDP_ADDRESS" >> $GITHUB_ENV
    echo "RDP_PORT=$RDP_PORT" >> $GITHUB_ENV
    echo "Tunnel established: $TUNNEL_URL"

elif [ "$PROVIDER" == "cloudflare" ]; then
    echo "Setting up Cloudflare tunnel..."
    CF_LOG="cloudflared.log"

    # Install cloudflared based on OS
    if [[ "$OS" == *"windows"* ]]; then
        if [ "$RUNNER_ARCH" == "ARM64" ]; then
            curl -L --output cloudflared.exe https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-arm64.exe
        else
            curl -L --output cloudflared.exe https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe
        fi
        ./cloudflared.exe tunnel --url rdp://localhost:$PORT > $CF_LOG 2>&1 &
    elif [[ "$OS" == "macos"* ]]; then
        brew install cloudflare/cloudflare/cloudflared
        nohup cloudflared tunnel --url tcp://localhost:$PORT > $CF_LOG 2>&1 &
    else
        curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared.deb
        nohup cloudflared tunnel --url tcp://localhost:$PORT > $CF_LOG 2>&1 &
    fi

    sleep 15

    # Get tunnel URL
    for i in {1..10}; do
        TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' $CF_LOG | head -n 1)
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
        echo "Attempt $i: Tunnel not ready yet, waiting..."
        sleep 3
    done

    if [ -z "$TUNNEL_URL" ]; then
        echo "::error::Failed to get Cloudflare tunnel info"
        cat "$CF_LOG" 2>/dev/null || echo "No cloudflared log found"
        exit 1
    fi

    RDP_ADDRESS=$(echo "$TUNNEL_URL" | sed 's|https://||')
    echo "RDP_ADDRESS=$RDP_ADDRESS" >> $GITHUB_ENV
    echo "RDP_PORT=" >> $GITHUB_ENV
    echo "Tunnel established: $RDP_ADDRESS"
fi
