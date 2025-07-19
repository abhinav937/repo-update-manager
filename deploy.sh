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