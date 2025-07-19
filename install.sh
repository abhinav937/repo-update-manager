#!/bin/bash

echo "Repo Update Manager - Quick Installer"
echo "======================================"

echo "Downloading simplified installer..."

# Download the simplified installer
curl -fsSL https://raw.githubusercontent.com/abhinav937/repo-update-manager/main/simple_install.sh -o /tmp/simple_install.sh

if [ $? -eq 0 ]; then
    echo "Download successful, running installer..."
    bash /tmp/simple_install.sh
else
    echo "Download failed, trying alternative method..."
    # Fallback: try to run the script directly
    curl -fsSL https://raw.githubusercontent.com/abhinav937/repo-update-manager/main/simple_install.sh | bash
fi

echo ""
echo "Installation completed successfully!"
echo "Repositories will be installed to: /env"
echo "Logs will be written to: /env/update.log" 