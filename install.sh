#!/bin/bash

# Repo Update Manager - Quick Installer
# This script downloads and runs the main deployment script

set -e

echo "Repo Update Manager - Quick Installer"
echo "======================================"

# Default installation directory
INSTALL_DIR="${1:-/env}"

# Download and run the deployment script
echo "Downloading deployment script..."
curl -fsSL https://raw.githubusercontent.com/yourusername/repo-update-manager/main/deploy.sh | bash -s -- --install "$INSTALL_DIR"

echo ""
echo "Installation completed successfully!"
echo "Repositories will be installed to: $INSTALL_DIR"
echo "Logs will be written to: $INSTALL_DIR/update.log" 