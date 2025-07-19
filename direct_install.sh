#!/bin/bash

# Direct Repo Update Manager Installer
# Run this directly on your Raspberry Pi

set -e  # Exit on any error

echo "Direct Repo Update Manager Installer"
echo "===================================="

# Configuration
BASE_DIR="/env"
LOG_FILE="$BASE_DIR/update.log"
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)

echo "Installing to: $BASE_DIR"
echo "Log file: $LOG_FILE"
echo ""

# Step 1: Create base directory
echo "Step 1: Creating base directory..."
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR"
    echo "Created directory: $BASE_DIR"
else
    echo "Directory already exists: $BASE_DIR"
fi

# Step 2: Create log file
echo "Step 2: Creating log file..."
touch "$LOG_FILE"
echo "$(date): Installation started" >> "$LOG_FILE"
echo "Created log file: $LOG_FILE"

# Step 3: Try to install packages (optional)
echo "Step 3: Installing packages..."
if command -v apt >/dev/null 2>&1; then
    echo "apt found, attempting to install packages..."
    sudo apt update || echo "apt update failed, continuing..."
    sudo apt install -y git vim python3 || echo "Package installation failed, continuing..."
    echo "$(date): Package installation attempted" >> "$LOG_FILE"
else
    echo "apt not found, skipping package installation"
    echo "$(date): apt not available, skipped package installation" >> "$LOG_FILE"
fi

# Step 4: Clone repositories
echo "Step 4: Cloning repositories..."
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_path="$BASE_DIR/$repo_name"
    
    if [ ! -d "$repo_path" ]; then
        echo "Cloning $repo_name..."
        if git clone "$repo" "$repo_path"; then
            echo "Successfully cloned $repo_name"
            echo "$(date): Cloned $repo_name to $repo_path" >> "$LOG_FILE"
        else
            echo "Failed to clone $repo_name"
            echo "$(date): Failed to clone $repo_name" >> "$LOG_FILE"
        fi
    else
        echo "$repo_name already exists, skipping..."
        echo "$(date): $repo_name already exists" >> "$LOG_FILE"
    fi
done

# Step 5: Create update script
echo "Step 5: Creating update script..."
cat > "$BASE_DIR/update-my-repos.sh" << 'EOF'
#!/bin/bash
# Simple update script
BASE_DIR="/env"
LOG_FILE="/env/update.log"
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)

echo "$(date): Running update-my-repos" >> "$LOG_FILE"
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_path="$BASE_DIR/$repo_name"
    if [ -d "$repo_path" ]; then
        cd "$repo_path"
        git fetch
        if [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]; then
            echo "$(date): Changes detected in $repo_name" >> "$LOG_FILE"
            git log --oneline HEAD..@{u} >> "$LOG_FILE"
        else
            echo "$(date): No changes in $repo_name" >> "$LOG_FILE"
        fi
    else
        echo "$(date): $repo_name not found" >> "$LOG_FILE"
    fi
done
echo "Run 'upgrade-my-repos' to apply changes."
EOF

# Step 6: Create upgrade script
echo "Step 6: Creating upgrade script..."
cat > "$BASE_DIR/upgrade-my-repos.sh" << 'EOF'
#!/bin/bash
# Simple upgrade script
BASE_DIR="/env"
LOG_FILE="/env/update.log"
REPOS=(
    "https://github.com/abhinav937/Lattice_NanoIce.git"
    "https://github.com/abhinav937/ssh-push.git"
)

echo "$(date): Running upgrade-my-repos" >> "$LOG_FILE"
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_path="$BASE_DIR/$repo_name"
    if [ -d "$repo_path" ]; then
        cd "$repo_path"
        git pull
        if [ -f install.sh ]; then
            bash install.sh >> "$LOG_FILE" 2>&1
        fi
        echo "$(date): Updated $repo_name" >> "$LOG_FILE"
    else
        git clone "$repo" "$repo_path"
        cd "$repo_path"
        if [ -f install.sh ]; then
            bash install.sh >> "$LOG_FILE" 2>&1
        fi
        echo "$(date): Cloned and installed $repo_name" >> "$LOG_FILE"
    fi
done
EOF

# Step 7: Make scripts executable
echo "Step 7: Making scripts executable..."
chmod +x "$BASE_DIR/update-my-repos.sh"
chmod +x "$BASE_DIR/upgrade-my-repos.sh"

# Step 8: Create global commands
echo "Step 8: Creating global commands..."
if [ -w /usr/local/bin ]; then
    sudo cp "$BASE_DIR/update-my-repos.sh" /usr/local/bin/update-my-repos
    sudo cp "$BASE_DIR/upgrade-my-repos.sh" /usr/local/bin/upgrade-my-repos
    echo "Global commands created successfully"
else
    echo "Cannot write to /usr/local/bin, creating aliases instead..."
    echo "alias update-my-repos='$BASE_DIR/update-my-repos.sh'" >> ~/.bashrc
    echo "alias upgrade-my-repos='$BASE_DIR/upgrade-my-repos.sh'" >> ~/.bashrc
    echo "Aliases added to ~/.bashrc"
fi

# Step 9: Set up cron job
echo "Step 9: Setting up cron job..."
(crontab -l 2>/dev/null | grep -v update-my-repos; echo "0 2 * * * $BASE_DIR/update-my-repos.sh && $BASE_DIR/upgrade-my-repos.sh") | crontab -
echo "Cron job set up for daily updates at 2 AM"

# Final status
echo ""
echo "Installation completed successfully!"
echo "===================================="
echo "Repositories installed to: $BASE_DIR"
echo "Log file: $LOG_FILE"
echo ""
echo "Available commands:"
if [ -w /usr/local/bin ]; then
    echo "  update-my-repos    - Check for repository updates"
    echo "  upgrade-my-repos   - Apply repository updates"
else
    echo "  update-my-repos    - Check for repository updates (after restarting shell)"
    echo "  upgrade-my-repos   - Apply repository updates (after restarting shell)"
fi
echo "  tail -f $LOG_FILE  - View logs"
echo ""
echo "Daily updates will run at 2 AM"
echo "$(date): Installation completed successfully" >> "$LOG_FILE" 