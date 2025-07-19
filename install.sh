#!/bin/bash

# Configuration
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)
APT_PACKAGES=(
    "vim"
    "python3"
)
BASE_DIR="/env"
LOG_FILE="$BASE_DIR/update.log"
ENABLE_CRON=true  # Set to false to disable automatic daily updates

# Create base directory and log file
sudo mkdir -p "$BASE_DIR"
sudo chown "$USER:$USER" "$BASE_DIR"
touch "$LOG_FILE"
echo "$(date): Starting initial setup" >> "$LOG_FILE"

# Install APT packages if apt is available
if [ -f /usr/bin/apt ]; then
    sudo apt update && echo "$(date): APT package lists updated" >> "$LOG_FILE"
    sudo apt install -y git "${APT_PACKAGES[@]}" && echo "$(date): Installed Git and APT packages (${APT_PACKAGES[*]})" >> "$LOG_FILE"
else
    echo "$(date): APT not available, skipping package installation" >> "$LOG_FILE"
fi

# Clone repositories and run optional install.sh
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_path="$BASE_DIR/$repo_name"
    if [ ! -d "$repo_path" ]; then
        git clone "$repo" "$repo_path" && echo "$(date): Cloned $repo_name to $repo_path" >> "$LOG_FILE"
        if [ -f "$repo_path/install.sh" ]; then
            cd "$repo_path" && bash install.sh >> "$LOG_FILE" 2>&1 && cd - >/dev/null
            echo "$(date): Ran install.sh for $repo_name" >> "$LOG_FILE"
        fi
    else
        echo "$(date): $repo_name already exists, skipping clone" >> "$LOG_FILE"
    fi
done

# Create the update script in /usr/local/bin
cat > /usr/local/bin/update-my-repos.sh << 'EOF'
#!/bin/bash

# Configuration (same as setup.sh)
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
        git pull && echo "$(date): Pulled updates for $repo_name" >> "$LOG_FILE"
        if [ -f install.sh ]; then
            bash install.sh >> "$LOG_FILE" 2>&1
            echo "$(date): Ran install.sh for $repo_name after update" >> "$LOG_FILE"
        fi
        cd - >/dev/null
    else
        echo "$(date): $repo_name not found, cloning now" >> "$LOG_FILE"
        git clone "$repo" "$repo_path" && echo "$(date): Cloned $repo_name during update" >> "$LOG_FILE"
        if [ -f "$repo_path/install.sh" ]; then
            cd "$repo_path" && bash install.sh >> "$LOG_FILE" 2>&1 && cd - >/dev/null
            echo "$(date): Ran install.sh for newly cloned $repo_name" >> "$LOG_FILE"
        fi
    fi
done

echo "$(date): Repository update complete" >> "$LOG_FILE"
EOF

chmod +x /usr/local/bin/update-my-repos.sh
echo "$(date): Created update-my-repos.sh script" >> "$LOG_FILE"

# Set up daily cron job at 2 AM if enabled
if [ "$ENABLE_CRON" = true ]; then
    (crontab -l 2>/dev/null | grep -v update-my-repos; echo "0 2 * * * /usr/local/bin/update-my-repos.sh") | crontab -
    echo "$(date): Enabled daily cron job for updates" >> "$LOG_FILE"
fi

echo "$(date): Initial setup complete" >> "$LOG_FILE"
echo "Setup complete! Run 'update-my-repos.sh' manually to update, or check logs with 'tail -f $LOG_FILE'."