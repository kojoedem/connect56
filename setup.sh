#!/bin/bash

echo "Installing required dependencies..."

# Update package list
sudo apt update

# Install required tools
sudo apt install -y curl jq whois

echo "Setup complete. You can now run ./connect56.sh"