#!/bin/bash
#
# This script contains pre-installation steps for macOS.
#

# Check for and install Homebrew if not found
if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install VB-Cable virtual audio device
echo "Installing VB-Cable..."
brew install --cask vb-cable

echo "macOS pre-install steps completed."
