#!/bin/bash
# Auto-push script for HRMs-ERP repository
# Runs daily at 5:00 PM (17:00 IST)

REPO_DIR="/Users/acamedia/VINODH/KEKA CLONE"
LOG_FILE="$REPO_DIR/auto_push.log"

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"

echo "=== Auto-push started at $(date) ===" >> "$LOG_FILE"
cd "$REPO_DIR" || exit 1

# Check if there are any changes (modified, untracked, deleted)
if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected. Staging files..." >> "$LOG_FILE"
    git add . >> "$LOG_FILE" 2>&1
    
    COMMIT_MSG="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Committing with message: $COMMIT_MSG" >> "$LOG_FILE"
    git commit -m "$COMMIT_MSG" >> "$LOG_FILE" 2>&1
    
    echo "Pushing to origin main..." >> "$LOG_FILE"
    git push origin main >> "$LOG_FILE" 2>&1
    echo "Push completed successfully." >> "$LOG_FILE"
else
    echo "No changes detected. Nothing to push." >> "$LOG_FILE"
fi

echo "=== Auto-push finished at $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
