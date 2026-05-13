#!/bin/bash

BRANCH="${GITHUB_REF_NAME}"
source /tmp/env_vars.txt
REPO_OWNER=${REPO_OWNER_ENV}
REPO_NAME=${REPO_NAME_ENV}
BACKUP_DIR=$(cat /tmp/backup_dir_path.txt)

BACKUP_FILE_COUNT=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)

if [ "$BACKUP_FILE_COUNT" -eq 0 ]; then
    echo "WARNING: No files in backup directory — all downloads may have failed."
    echo "Ensuring videos/ folder exists in repository with a master README..."

    git fetch origin "$BRANCH"
    git reset --hard origin/"$BRANCH"

    mkdir -p videos

    if [ ! -f "videos/README.md" ]; then
        {
            echo "# DOWNLOADED VIDEOS LIST :"
            echo ""
            echo "----"
            echo ""
            echo "> No videos downloaded yet."
        } > videos/README.md
        git add -f videos/README.md
        if ! git diff --cached --quiet; then
            git commit -m "[AVASAM] Initialize videos folder [skip ci]"
            PUSH_RETRY=0
            while [ $PUSH_RETRY -lt 5 ]; do
                PUSH_RETRY=$((PUSH_RETRY + 1))
                if timeout 60 git push origin HEAD:"$BRANCH"; then
                    echo "videos/ folder initialized and pushed."
                    break
                else
                    echo "Push failed, retry $PUSH_RETRY/5..."
                    sleep 3
                fi
            done
        else
            echo "videos/README.md already exists, nothing to push."
        fi
    else
        echo "videos/ folder already exists in repository."
    fi

    echo "No video files to push. Exiting."
    exit 0
fi

urlencode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

regenerate_master_readme() {
    MASTER_README="videos/README.md"
    {
        echo "# DOWNLOADED VIDEOS LIST :"
        echo ""
        echo "----"
        echo ""
    } > "$MASTER_README"
    
    NUM=0
    for folder in videos/*/; do
        [ -d "$folder" ] || continue
        FOLDER_NAME=$(basename "$folder")
        [ -f "$folder/README.md" ] || continue
        NUM=$((NUM + 1))
        FOLDER_ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$FOLDER_NAME")
        FOLDER_LINK="https://github.com/${REPO_OWNER}/${REPO_NAME}/tree/${BRANCH}/videos/${FOLDER_ENCODED}"
        printf -- "- %s - 🎬 [%s](%s)\n" "$NUM" "$FOLDER_NAME" "$FOLDER_LINK" >> "$MASTER_README"
    done
}

git fetch origin "$BRANCH"
git reset --hard origin/"$BRANCH"
mkdir -p videos
cp -r "$BACKUP_DIR"/* videos/

git add -f videos/
regenerate_master_readme
git add -f videos/README.md

if ! git diff --cached --quiet; then
    git commit -m "[AVASAM] YouTube download [skip ci]"
    PUSH_RETRY=0
    while [ $PUSH_RETRY -lt 10 ]; do
        PUSH_RETRY=$((PUSH_RETRY + 1))
        if timeout 300 git push origin HEAD:"$BRANCH"; then
            echo "Push successful!"
            break
        else
            echo "Push failed, retry $PUSH_RETRY/10..."
            sleep 5
            git fetch origin "$BRANCH"
            git reset --hard origin/"$BRANCH"
            cp -r "$BACKUP_DIR"/* videos/
            git add -f videos/
            regenerate_master_readme
            git add -f videos/README.md
            git diff --cached --quiet || git commit -m "[AVASAM] YouTube download [skip ci]"
        fi
    done
fi

echo "=========================================="
echo "All files pushed successfully!"
echo "made in AVASAM (https://avasam.ir)"
echo "=========================================="
