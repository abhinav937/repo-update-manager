#!/bin/bash

# Quick installer bootstrap
echo "Repo Update Manager - Quick Installer"
echo "======================================"

# Configuration
BASE_DIR="/env"
LOG_FILE="$BASE_DIR/update.log"
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)
APT_PACKAGES=(
    "vim"
    "python3"
)
ENABLE_CRON=true  # Set to false to disable daily updates

# Create base directory and log with sudo
sudo mkdir -p "$BASE_DIR"
sudo chown "$USER:$USER" "$BASE_DIR"
touch "$LOG_FILE"
echo "$(date): Starting bootstrap installation" >> "$LOG_FILE"

# Install APT packages if apt available
if [ -f /usr/bin/apt ]; then
    sudo apt update -y >> "$LOG_FILE" 2>&1 && echo "$(date): APT updated" >> "$LOG_FILE"
    sudo apt install -y git "${APT_PACKAGES[@]}" >> "$LOG_FILE" 2>&1 && echo "$(date): Installed Git and packages (${APT_PACKAGES[*]})" >> "$LOG_FILE"
else
    echo "$(date): APT not available, skipping" >> "$LOG_FILE"
fi

# Clone and install repos
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_path="$BASE_DIR/$repo_name"
    if [ ! -d "$repo_path" ]; then
        git clone "$repo" "$repo_path" >> "$LOG_FILE" 2>&1 && echo "$(date): Cloned $repo_name" >> "$LOG_FILE"
        if [ -f "$repo_path/install.sh" ]; then
            cd "$repo_path"
            chmod +x install.sh
            # Run install.sh as user; repo scripts handle their own sudo if needed
            ./install.sh >> "$LOG_FILE" 2>&1 && echo "$(date): Ran install.sh for $repo_name" >> "$LOG_FILE"
            cd - >/dev/null
        fi
    else
        echo "$(date): $repo_name already exists, skipping clone" >> "$LOG_FILE"
    fi
done

# Create update script with sudo tee to avoid permission issues
cat << 'EOF' | sudo tee /usr/local/bin/update-my-repos.sh > /dev/null
#!/bin/bash

BASE_DIR="/env"
LOG_FILE="$BASE_DIR/update.log"
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)

echo "$(date): Starting repository update" >> "$LOG_FILE"

for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_path="$BASE_DIR/$repo_name"
    if [ -d "$repo_path" ]; then
        cd "$repo_path"
        git pull >> "$LOG_FILE" 2>&1 && echo "$(date): Pulled updates for $repo_name" >> "$LOG_FILE"
        if [ -f install.sh ]; then
            chmod +x install.sh
            ./install.sh >> "$LOG_FILE" 2>&1 && echo "$(date): Ran install.sh for $repo_name after update" >> "$LOG_FILE"
        fi
        cd - >/dev/null
    else
        echo "$(date): $repo_name not found, cloning now" >> "$LOG_FILE"
        git clone "$repo" "$repo_path" >> "$LOG_FILE" 2>&1 && echo "$(date): Cloned $repo_name" >> "$LOG_FILE"
        if [ -f "$repo_path/install.sh" ]; then
            cd "$repo_path"
            chmod +x install.sh
            ./install.sh >> "$LOG_FILE" 2>&1 && echo "$(date): Ran install.sh for $repo_name" >> "$LOG_FILE"
            cd - >/dev/null
        fi
    fi
done

echo "$(date): Update complete" >> "$LOG_FILE"
EOF

sudo chmod +x /usr/local/bin/update-my-repos.sh
echo "$(date): Created update-my-repos.sh" >> "$LOG_FILE"

# Set up cron for daily updates (user crontab, no sudo needed)
if [ "$ENABLE_CRON" = true ]; then
    (crontab -l 2>/dev/null | grep -v '/usr/local/bin/update-my-repos.sh'; echo "0 2 * * * /usr/local/bin/update-my-repos.sh") | crontab -
    echo "$(date): Enabled daily cron at 2 AM" >> "$LOG_FILE"
fi

echo "$(date): Bootstrap complete" >> "$LOG_FILE"
echo "Installation complete! Repos in $BASE_DIR. Run 'update-my-repos.sh' to update manually. Logs: tail -f $LOG_FILE"