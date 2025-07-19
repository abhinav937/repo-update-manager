# Repo Update Manager

A powerful automation tool for deploying and managing Git repositories on Raspberry Pi devices with package management and scheduled updates.

## Features

- **Automated Repository Deployment**: Clone and manage multiple Git repositories
- **Package Management**: Install and update apt packages automatically
- **Scheduled Updates**: Daily cron jobs for automatic repository updates
- **Custom Installation Scripts**: Support for repository-specific `install.sh` scripts
- **Comprehensive Logging**: Detailed logs of all operations
- **Remote Deployment**: Deploy to multiple Pis via SSH
- **Easy Management**: Simple commands to check and apply updates

## Quick Installation

### One-Command Installation

The fastest way to get started - just run this command on your Raspberry Pi:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/repo-update-manager/main/install.sh | bash
```

This will:
- Install to `/env/` directory by default
- Set up all necessary scripts and cron jobs
- Configure logging and package management
- Make `update-my-repos` and `upgrade-my-repos` commands available globally

### Single-Line Install (Advanced)

```bash
# Install to default /env/ directory
curl -fsSL https://raw.githubusercontent.com/yourusername/repo-update-manager/main/install.sh | bash

# Or install to custom directory
curl -fsSL https://raw.githubusercontent.com/yourusername/repo-update-manager/main/install.sh | bash -s /home/pi/repos
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/repo-update-manager.git
cd repo-update-manager
```

2. Configure the deployment settings in `deploy.sh`

3. Run the deployment:
```bash
./deploy.sh
```

## Configuration

Edit the configuration section in `deploy.sh`:

```bash
# Git repositories to deploy
REPOS=(
    "https://github.com/yourusername/repo1.git"
    "https://github.com/yourusername/repo2.git"
    "https://github.com/yourusername/repo3.git"
)

# Additional apt packages to install
APT_PACKAGES=(
    "vim"
    "python3"
    "nginx"
)

# Base directory for repositories (default: /env/)
BASE_DIR="/env"

# Enable automatic daily updates
ENABLE_CRON=true

# Target Raspberry Pi IPs (empty for local deployment)
PIS=("")  # Example: ("192.168.1.10" "192.168.1.11")
```

## Usage

After deployment, you'll have access to these commands:

### Check for Updates
```bash
update-my-repos
```
Checks for available updates in all configured repositories without applying them.

### Apply Updates
```bash
upgrade-my-repos
```
Pulls latest changes, clones missing repositories, and runs optional `install.sh` scripts.

### View Logs
```bash
tail -f /env/update.log
```
Monitor deployment and update activities.

## Repository Structure

Each repository can include an optional `install.sh` script that will be executed after cloning or updating:

```
your-repo/
├── install.sh          # Optional: Custom installation script
├── README.md
└── ... (other files)
```

Example `install.sh`:
```bash
#!/bin/bash
# Custom installation steps
pip3 install -r requirements.txt
sudo systemctl enable my-service
```

## Remote Deployment

To deploy to multiple Raspberry Pis:

1. Ensure SSH access is configured (passwordless preferred)
2. Update the `PIS` array with target IP addresses
3. Run the deployment script

```bash
# Example: Deploy to multiple Pis
PIS=("192.168.1.10" "192.168.1.11" "192.168.1.12")
./deploy.sh
```

## Cron Jobs

When `ENABLE_CRON=true`, the script creates a daily cron job that runs at 2 AM:

```bash
0 2 * * * update-my-repos && upgrade-my-repos
```

## Logging

All operations are logged to `/env/update.log` with timestamps:

```
2024-01-15 10:30:00: Updated apt package lists on local Pi
2024-01-15 10:30:05: Installed packages (git vim python3 nginx) on local Pi
2024-01-15 10:30:10: Cloned repo1 to /env/repo1
2024-01-15 10:30:15: Changes detected in repo1
```

## Requirements

- Raspberry Pi (or compatible Linux system)
- Git
- SSH access (for remote deployment)
- Internet connection

## Troubleshooting

### Permission Issues
```bash
sudo chmod +x deploy.sh
```

### SSH Connection Problems
```bash
# Test SSH connection
ssh pi@192.168.1.10 "echo 'SSH working'"
```

### Manual Repository Update
```bash
cd /env/your-repo
git pull
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the logs at `/env/update.log`
- Review the configuration in `deploy.sh`
