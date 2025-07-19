#!/bin/bash

# ------------------------------------------------------------------------------
# Script: deploy-repos-to-pi.sh
# Purpose: Automates the deployment and management of Git repositories and
#          specified apt packages on one or more Raspberry Pi devices, either
#          locally or remotely via SSH. It sets up repositories, installs required
#          packages, creates scripts to check for and apply updates, and optionally
#          schedules automatic updates via a cron job.
# Usage:   - Configure REPOS, APT_PACKAGES, BASE_DIR, LOG_FILE, ENABLE_CRON, and PIS below.
#          - Run the script locally: `./deploy-repos-to-pi.sh`
#          - Ensure SSH access is configured for remote Pis (passwordless preferred).
# Notes:   - Requires Git and specified apt packages to be available in the apt repositories.
#          - Repositories may include an optional `install.sh` script for custom setup.
#          - Logs all operations to the specified LOG_FILE.
# Author:  Abhinav Chinnusamy
# Date:    July 18, 2025
# ------------------------------------------------------------------------------

# --------------------- Command Line Arguments ---------------------------------
# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --install)
      if [[ -n "$2" && "$2" != -* ]]; then
        BASE_DIR="$2"
        LOG_FILE="$2/update.log"
        shift 2
      else
        echo "Error: --install requires a directory path"
        exit 1
      fi
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --install DIR    Install to specified directory (default: /env/)"
      echo "  --help, -h       Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                    # Install to default /env/ directory"
      echo "  $0 --install /home/$USER/repos  # Install to custom directory"
      echo "  curl -fsSL https://raw.githubusercontent.com/abhinav937/repo-update-manager/main/deploy.sh | bash -s -- --install /env/"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# --------------------- Configuration Section -----------------------------------
# Array of Git repository URLs to deploy and manage
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)

# Array of additional apt packages to install
APT_PACKAGES=(
    "vim"
    "python3"
    # Add more packages as needed
)

# Base directory for cloning repositories (default: /env/)
BASE_DIR="/env"

# Log file to record deployment and update operations
LOG_FILE="/env/update.log"

# Enable/disable daily cron job for automatic updates (true/false)
ENABLE_CRON=true

# List of Raspberry Pi IP addresses for remote deployment
# Leave empty ("") to run locally on the current Pi
PIS=("")  # Example: ("192.168.1.10" "192.168.1.11" "192.168.1.12")

# --------------------- Function Definitions ------------------------------------
# Function: deploy_to_pi
# Purpose:  Deploys repositories, installs apt packages, and sets up update scripts
#           on a single Pi
# Arguments:
#   $1: Target (IP address for remote Pi or "local" for local execution)
#   $2: Boolean indicating if the operation is local ("true") or remote ("false")
deploy_to_pi() {
  local target=$1
  local is_local=$2

  # Set SSH prefix for remote execution; empty for local
  local ssh_prefix=""
  if [ "$is_local" != "true" ]; then
    ssh_prefix="ssh pi@$target"
  fi

  echo "Deploying to ${target:-local Pi}..."

  # Update apt package lists
  $ssh_prefix "sudo apt update" && echo "$(date): Updated apt package lists on ${target:-local Pi}" >> $LOG_FILE

  # Install Git and additional apt packages
  local packages_to_install="git ${APT_PACKAGES[*]}"
  $ssh_prefix "sudo apt install -y $packages_to_install" && \
    echo "$(date): Installed packages ($packages_to_install) on ${target:-local Pi}" >> $LOG_FILE

  # Create base directory and log file if they don't exist
  $ssh_prefix "sudo mkdir -p $BASE_DIR && sudo chown $USER:$USER $BASE_DIR && touch $LOG_FILE"

  # Clone each repository if not already present
  for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    remote_path="$BASE_DIR/$repo_name"
    $ssh_prefix "if [ ! -d \"$remote_path\" ]; then git clone \"$repo\" \"$remote_path\" && echo \"$(date): Cloned $repo_name to $remote_path\" >> $LOG_FILE; fi"
  done

  # Create update-my-repos.sh to check for repository updates
  $ssh_prefix "cat > /home/$USER/update-my-repos.sh << 'EOF'
#!/bin/bash
# Script: update-my-repos.sh
# Purpose: Checks for updates in configured Git repositories without applying them
# Output: Logs changes to $LOG_FILE and prompts to run upgrade-my-repos
BASE_DIR=\"$BASE_DIR\"
REPOS=(${REPOS[*]})
LOG_FILE=\"$LOG_FILE\"
echo \"\$(date): Running update-my-repos\" >> \$LOG_FILE
for repo in \"\${REPOS[@]}\"; do
  repo_name=\$(basename \"\$repo\" .git)
  remote_path=\"\$BASE_DIR/\$repo_name\"
  if [ -d \"\$remote_path\" ]; then
    cd \"\$remote_path\"
    git fetch
    if [ \$(git rev-parse HEAD) != \$(git rev-parse @{u}) ]; then
      echo \"\$(date): Changes detected in \$repo_name\" >> \$LOG_FILE
      git log --oneline HEAD..@{u} >> \$LOG_FILE
    else
      echo \"\$(date): No changes in \$repo_name\" >> \$LOG_FILE
    fi
  else
    echo \"\$(date): \$repo_name not found, will clone on upgrade\" >> \$LOG_FILE
  fi
done
echo \"Run 'upgrade-my-repos' to apply changes.\" | tee -a \$LOG_FILE
EOF"

  # Create upgrade-my-repos.sh to apply updates and run install scripts
  $ssh_prefix "cat > /home/$USER/upgrade-my-repos.sh << 'EOF'
#!/bin/bash
# Script: upgrade-my-repos.sh
# Purpose: Pulls latest changes for repositories, clones missing ones, and runs
#          optional install.sh scripts
# Output: Logs all operations to $LOG_FILE
BASE_DIR=\"$BASE_DIR\"
REPOS=(${REPOS[*]})
LOG_FILE=\"$LOG_FILE\"
echo \"\$(date): Running upgrade-my-repos\" >> \$LOG_FILE
for repo in \"\${REPOS[@]}\"; do
  repo_name=\$(basename \"\$repo\" .git)
  remote_path=\"\$BASE_DIR/\$repo_name\"
  if [ -d \"\$remote_path\" ]; then
    cd \"\$remote_path\" && git pull && [ -f install.sh ] && bash install.sh >> \$LOG_FILE 2>&1
    echo \"\$(date): Updated $repo_name\" >> \$LOG_FILE
  else
    git clone \"\$repo\" \"$remote_path\" && cd \"\$remote_path\" && [ -f install.sh ] && bash install.sh >> \$LOG_FILE 2>&1
    echo \"\$(date): Cloned and installed $repo_name\" >> \$LOG_FILE
  fi
done
EOF"

  # Make scripts executable and move to /usr/local/bin for global access
  $ssh_prefix "chmod +x /home/$USER/update-my-repos.sh /home/$USER/upgrade-my-repos.sh && \
               sudo mv /home/$USER/update-my-repos.sh /usr/local/bin/update-my-repos && \
               sudo mv /home/$USER/upgrade-my-repos.sh /usr/local/bin/upgrade-my-repos"

  # Set up daily cron job at 2 AM if enabled
  if [ "$ENABLE_CRON" = "true" ]; then
    $ssh_prefix "(crontab -l 2>/dev/null | grep -v update-my-repos; echo '0 2 * * * update-my-repos && upgrade-my-repos') | crontab -"
    echo "$(date): Cron job enabled for daily updates on ${target:-local Pi}" >> $LOG_FILE
  fi
}

# --------------------- Main Execution Logic ------------------------------------
echo "Repo Update Manager - Installation Starting..."
echo "Installing to: $BASE_DIR"
echo "Log file: $LOG_FILE"
echo ""

# Check if PIS is empty or unset to determine local or remote execution
if [ ${#PIS[@]} -eq 0 ] || [ -z "${PIS[0]}" ]; then
  # Deploy locally on the current Pi
  deploy_to_pi "local" "true"
  echo ""
  echo "Installation complete!"
  echo "Available commands:"
  echo "   update-my-repos    - Check for repository updates"
  echo "   upgrade-my-repos   - Apply repository updates"
  echo "   tail -f $LOG_FILE  - View logs"
  echo ""
  echo "Daily updates will run at 2 AM (if cron enabled)"
else
  # Deploy to each remote Pi specified in PIS
  for ip in "${PIS[@]}"; do
    deploy_to_pi "$ip" "false"
  done
  echo ""
  echo "Remote deployment complete!"
fi 