#!/bin/bash

# ── SETUP ────────────────────────────────
REPO_OWNER="${REPO_OWNER_ENV}"
REPO_NAME="${REPO_NAME_ENV}"
BRANCH="${BRANCH_ENV}"
URLS_RAW="${YT_URLS}"
read -ra URL_LIST <<< "$URLS_RAW"
TOTAL_URLS=${#URL_LIST[@]}
QUALITY="${YT_QUALITY}"
ZIP_PASSWORD="${YT_PASSWORD}"
SPLIT_MB=45
SPLIT_BYTES=$(( SPLIT_MB * 1024 * 1024 ))
BACKUP_DIR="/tmp/video_backup_$$"
mkdir -p "$BACKUP_DIR"
mkdir -p videos
> /tmp/video_info.txt

echo "=========================================="
echo "🎬 YouTube Video Downloader"
echo "=========================================="
echo "Total URLs to download: $TOTAL_URLS"
echo "Quality: $QUALITY"
echo "Site: YouTube"

if [ -f "cookies.txt" ]; then
    COOKIE_FLAG="--cookies cookies.txt"
    echo "✅ Using cookies for YouTube authentication"
else
    COOKIE_FLAG=""
    echo "⚠️ No cookies found for YouTube"
fi

# ── FUNCTIONS ────────────────────────────────
sanitize_name() {
    echo "$1" | sed 's/ /-/g' | sed 's/　/-/g' | tr -s '-'
}

urlencode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

case "$QUALITY" in
    "audio") FORMAT="bestaudio/bestaudio*/best";;
    "best") FORMAT="bestvideo+bestaudio/bestvideo*+bestaudio*/best";;
    "2160"|"4k") FORMAT="bestvideo[height<=2160]+bestaudio/bestvideo[height<=2160]*+bestaudio*/bestvideo+bestaudio/best";;
    "1440"|"2k") FORMAT="bestvideo[height<=1440]+bestaudio/bestvideo[height<=1440]*+bestaudio*/bestvideo+bestaudio/best";;
    "1080") FORMAT="bestvideo[height<=1080]+bestaudio/bestvideo[height<=1080]*+bestaudio*/bestvideo+bestaudio/best";;
    "720") FORMAT="bestvideo[height<=720]+bestaudio/bestvideo[height<=720]*+bestaudio*/bestvideo+bestaudio/best";;
    "480") FORMAT="bestvideo[height<=480]+bestaudio/bestvideo[height<=480]*+bestaudio*/bestvideo+bestaudio/best";;
    *) FORMAT="bestvideo+bestaudio/bestvideo*+bestaudio*/best";;
esac

download_video() {
    local METHOD=$1; local URL=$2; local TMP_DIR=$3;
    echo "Trying download method $METHOD for YouTube..."
    
    COMMON_FLAGS="--merge-output-format mp4 --write-thumbnail --convert-thumbnails jpg --no-cache-dir --output ${TMP_DIR}/%(title)s.%(ext)s --no-part --no-playlist --retries 10 --fragment-retries 10 --no-check-certificates --concurrent-fragments 4 --buffer-size 16K --http-chunk-size 5M --limit-rate 3M --sleep-requests 3 --sleep-interval 5 --max-sleep-interval 15 --throttled-rate 100K --progress --newline"
    
    if [ "$QUALITY" = "audio" ]; then
        COMMON_FLAGS="--extract-audio --audio-format mp3 --audio-quality 0 --write-thumbnail --convert-thumbnails jpg --no-cache-dir --output ${TMP_DIR}/%(title)s.%(ext)s --no-part --no-playlist --retries 10 --fragment-retries 10 --no-check-certificates --concurrent-fragments 4 --buffer-size 16K --http-chunk-size 5M --limit-rate 3M --sleep-requests 3 --sleep-interval 5 --max-sleep-interval 15 --progress --newline"
    fi
    
    case $METHOD in
        1) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=android,web" \
            --extractor-args "youtube:skip=webpage" \
            --js-runtimes deno \
            --remote-components ejs:github \
            --user-agent "Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" \
            --add-header "Accept-Language:en-US,en;q=0.9" \
            "$URL";;
            
        2) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=ios" \
            --js-runtimes deno \
            --remote-components ejs:github \
            --user-agent "com.google.ios.youtube/19.09.3 (iPhone14,3; U; CPU iOS 15_5 like Mac OS X)" \
            --add-header "Accept-Language:en-US,en;q=0.9" \
            "$URL";;
            
        3) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=tv_embedded" \
            --js-runtimes deno \
            --remote-components ejs:github \
            --user-agent "Mozilla/5.0 (ChromiumStylePlatform) AppleWebKit/605.1.15 (KHTML, like Gecko) GoogleChrome/125.0.0.0 Safari/605.1.15" \
            "$URL";;
            
        4) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=mweb" \
            --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "$URL";;
            
        5) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=android_vr" \
            --user-agent "Mozilla/5.0 (Linux; Android 12; SM-S906N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" \
            "$URL";;
            
        6) yt-dlp $COOKIE_FLAG --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=web" \
            --js-runtimes deno \
            --remote-components ejs:github \
            --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "$URL";;
            
        7) yt-dlp $COOKIE_FLAG --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=mweb" \
            --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "$URL";;
            
        8) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=android" \
            --user-agent "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" \
            "$URL";;
            
        9) yt-dlp $COOKIE_FLAG --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=web" \
            --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "$URL";;
            
        10) yt-dlp $COOKIE_FLAG --proxy "socks5://127.0.0.1:1080" \
            --format "$FORMAT" $COMMON_FLAGS \
            --extractor-args "youtube:player_client=web" \
            --geo-bypass \
            --geo-bypass-country US \
            --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "$URL";;
    esac
}

RANDOM_WORDS=("alpha" "beta" "gamma" "delta" "epsilon" "zeta" "theta" "kappa" "lambda" "sigma" "omega" "nova" "star" "moon" "sun" "sky" "cloud" "river" "ocean" "mountain")
get_random_word() { echo "${RANDOM_WORDS[$RANDOM % ${#RANDOM_WORDS[@]}]}_$RANDOM"; }

get_unique_folder() {
    local BASE_PATH="$1"; local NAME="$2";
    if [ ! -d "$BASE_PATH/$NAME" ] && [ ! -d "$BACKUP_DIR/$NAME" ]; then echo "$NAME"; return; fi
    local RANDOM_SUFFIX=$(get_random_word)
    while [ -d "$BASE_PATH/${NAME}_${RANDOM_SUFFIX}" ] || [ -d "$BACKUP_DIR/${NAME}_${RANDOM_SUFFIX}" ]; do RANDOM_SUFFIX=$(get_random_word); done
    echo "${NAME}_${RANDOM_SUFFIX}"
}

normalize_youtube_url() {
    local INPUT_URL="$1"
    if [[ "$INPUT_URL" =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
        VIDEO_ID="${BASH_REMATCH[1]}"; VIDEO_ID="${VIDEO_ID%%\?*}";
        echo "https://www.youtube.com/watch?v=${VIDEO_ID}"
    else
        echo "$INPUT_URL"
    fi
}

# ── SMART RETRY FUNCTION ────────────────────
smart_retry_download() {
    local url=$1
    local tmp_dir=$2
    local max_retries=5
    
    for retry in $(seq 1 $max_retries); do
        for method in 1 2 3 4 5 6 7 8 9 10; do
            if download_video $method "$url" "$tmp_dir"; then
                echo "✅ Download successful with method $method on try $retry!"
                
                if [ "$QUALITY" != "best" ] && [ "$QUALITY" != "audio" ]; then
                    for downloaded_file in "$tmp_dir"/*.mp4 "$tmp_dir"/*.webm "$tmp_dir"/*.mkv; do
                        [ -f "$downloaded_file" ] || continue
                        actual_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$downloaded_file" 2>/dev/null || echo "unknown")
                        target_quality=$QUALITY
                        if [ "$target_quality" = "1080" ]; then target_quality=1080; fi
                        if [ "$target_quality" = "720" ]; then target_quality=720; fi
                        if [ "$target_quality" = "480" ]; then target_quality=480; fi
                        
                        if [ "$actual_height" != "unknown" ] && [ "$actual_height" -lt "$target_quality" ] 2>/dev/null; then
                            echo "⚠️ Method $method delivered ${actual_height}p instead of ${target_quality}p — retrying..."
                            rm -f "$downloaded_file"
                            return 1
                        fi
                    done
                fi
                return 0
            fi
            echo "Method $method failed, waiting 5 seconds..."
            sleep 5
        done
        
        if [ $retry -lt $max_retries ]; then
            wait_time=$((30 * retry))
            echo "All methods failed on try $retry. Waiting $wait_time seconds before retry..."
            sleep $wait_time
        fi
    done
    return 1
}

# ── MAIN LOOP ────────────────────────────────
URL_INDEX=0
for URL in "${URL_LIST[@]}"; do
    URL_INDEX=$((URL_INDEX + 1))
    URL=$(normalize_youtube_url "$URL")
    echo "============================================================"
    echo "Processing URL $URL_INDEX / $TOTAL_URLS : $URL"
    echo "============================================================"
    TMP_DIR="tmp_downloads_${URL_INDEX}"
    mkdir -p "$TMP_DIR"
    
    if smart_retry_download "$URL" "$TMP_DIR"; then
        echo "✅ Download completed successfully!"
    else
        echo "❌ All download methods failed for URL: $URL — skipping."
        rm -rf "$TMP_DIR"
        continue
    fi
    
    find "$TMP_DIR" -name "*.part" -delete
    for FILE in "$TMP_DIR"/*; do
        [ -f "$FILE" ] || continue
        if [[ "$FILE" == *.jpg ]] || [[ "$FILE" == *.webp ]]; then continue; fi
        SIZE=$(stat -c%s "$FILE")
        BASENAME=$(basename "$FILE")
        FILENAME_NO_EXT="${BASENAME%.*}"
        EXT="${BASENAME##*.}"
        FILENAME_NO_EXT=$(sanitize_name "$FILENAME_NO_EXT")
        FINAL_FOLDER_NAME=$(get_unique_folder "videos" "$FILENAME_NO_EXT")
        mkdir -p "$BACKUP_DIR/${FINAL_FOLDER_NAME}"
        
        THUMB_FILE=$(ls "$TMP_DIR"/*.jpg 2>/dev/null | head -1)
        if [ -n "$THUMB_FILE" ] && [ -f "$THUMB_FILE" ]; then
            cp "$THUMB_FILE" "$BACKUP_DIR/${FINAL_FOLDER_NAME}/thumbnail.jpg"
        fi
        
        echo "${FILENAME_NO_EXT}|${FINAL_FOLDER_NAME}" >> /tmp/video_info.txt
        FOLDER_ENCODED=$(urlencode "${FINAL_FOLDER_NAME}")
        
        if [ "$SIZE" -gt "$SPLIT_BYTES" ]; then
            ARCHIVE_BASE="$BACKUP_DIR/${FINAL_FOLDER_NAME}/${FINAL_FOLDER_NAME}"
            if [ -n "$ZIP_PASSWORD" ]; then
                7z a -tzip -v${SPLIT_MB}m -p"${ZIP_PASSWORD}" -mx=0 "${ARCHIVE_BASE}.zip" "$FILE"
            else
                zip -0 -s ${SPLIT_MB}m "${ARCHIVE_BASE}.zip" "$FILE"
            fi
            PART_COUNT=$(ls "$BACKUP_DIR/${FINAL_FOLDER_NAME}/"*.zip "$BACKUP_DIR/${FINAL_FOLDER_NAME}/"*.z[0-9]* 2>/dev/null | wc -l)
            
            TOTAL_SIZE=0
            for part_file in "$BACKUP_DIR/${FINAL_FOLDER_NAME}"/*; do
                if [ -f "$part_file" ]; then
                    PART_SIZE=$(stat -c%s "$part_file")
                    TOTAL_SIZE=$((TOTAL_SIZE + PART_SIZE))
                fi
            done
            TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
            
            DOWNLOAD_LINKS_MD=""
            LINK_NUM=0
            for part_file in $(ls "$BACKUP_DIR/${FINAL_FOLDER_NAME}/"*.zip "$BACKUP_DIR/${FINAL_FOLDER_NAME}/"*.z[0-9]* 2>/dev/null | sort -V); do
                if [ -f "$part_file" ]; then
                    PART_BASENAME=$(basename "$part_file")
                    PART_ENCODED=$(urlencode "${PART_BASENAME}")
                    RAW_LINK="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/videos/${FOLDER_ENCODED}/${PART_ENCODED}"
                    LINK_NUM=$((LINK_NUM + 1))
                    DOWNLOAD_LINKS_MD="${DOWNLOAD_LINKS_MD}| ${LINK_NUM} | \`${PART_BASENAME}\` | [Download](${RAW_LINK}) |"$'\n'
                fi
            done
            
            MAIN_ZIP="${FINAL_FOLDER_NAME}.zip"
            README_FILE="$BACKUP_DIR/${FINAL_FOLDER_NAME}/README.md"
            {
                printf '%s\n' "# ${FILENAME_NO_EXT}"
                printf '%s\n' ""
                if [ -f "$BACKUP_DIR/${FINAL_FOLDER_NAME}/thumbnail.jpg" ]; then
                    printf '%s\n' "<div align=\"center\"><picture><img src=\"thumbnail.jpg\" width=\"250\" /></picture></div>"
                    printf '%s\n' ""
                    printf '%s\n' "<br>"
                    printf '%s\n' ""
                fi
                printf '%s\n' "---"
                printf '%s\n' ""
                printf '%s\n' "## Video Information"
                printf '%s\n' ""
                printf '%s\n' "| Property | Value |"
                printf '%s\n' "|----------|-------|"
                printf '%s\n' "| **Video Name** | \`${FILENAME_NO_EXT}\` |"
                printf '%s\n' "| **Original Link** | [YouTube Video](${URL}) |"
                printf '%s\n' "| **Total Size** | **${PART_COUNT} parts** - **${TOTAL_SIZE_MB} MB** |"
                printf '%s\n' "| **Quality** | **${QUALITY}** |"
                printf '%s\n' "| **Status** | **Complete (100%)** |"
                if [ -n "$ZIP_PASSWORD" ]; then
                    printf '%s\n' "| **Password Protected** | **YES** |"
                else
                    printf '%s\n' "| **Password Protected** | **NO** |"
                fi
                printf '%s\n' ""
                printf '%s\n' "---"
                printf '%s\n' ""
                printf '%s\n' "## Download Links"
                printf '%s\n' ""
                printf '%s\n' "> ⬇️ Download **all parts**, then open \`${MAIN_ZIP}\`"
                printf '%s\n' ""
                printf '%s\n' "| # | File | Link |"
                printf '%s\n' "|---|------|------|"
                printf '%s' "${DOWNLOAD_LINKS_MD}"
                printf '%s\n' ""
                printf '%s\n' "---"
                printf '%s\n' ""
                printf '%s\n' "*Created by [avasam.ir](https://avasam.ir)*"
            } > "$README_FILE"
        else
            if [ -n "$ZIP_PASSWORD" ]; then
                zip -0 -P "${ZIP_PASSWORD}" "$BACKUP_DIR/${FINAL_FOLDER_NAME}/${FINAL_FOLDER_NAME}.zip" "$FILE"
                SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
                FILE_ENCODED=$(urlencode "${FINAL_FOLDER_NAME}.zip")
                RAW_LINK="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/videos/${FOLDER_ENCODED}/${FILE_ENCODED}"
                README_FILE="$BACKUP_DIR/${FINAL_FOLDER_NAME}/README.md"
                {
                    printf '%s\n' "# ${FILENAME_NO_EXT}"
                    printf '%s\n' ""
                    if [ -f "$BACKUP_DIR/${FINAL_FOLDER_NAME}/thumbnail.jpg" ]; then
                        THUMB_ENCODED=$(urlencode "thumbnail.jpg")
                        THUMB_RAW_LINK="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/videos/${FOLDER_ENCODED}/${THUMB_ENCODED}"
                        printf '%s\n' "<div align=\"center\"><picture><img src=\"${THUMB_RAW_LINK}\" width=\"250\" /></picture></div>"
                        printf '%s\n' ""
                        printf '%s\n' "<br>"
                        printf '%s\n' ""
                    fi
                    printf '%s\n' "---"
                    printf '%s\n' ""
                    printf '%s\n' "## Video Information"
                    printf '%s\n' ""
                    printf '%s\n' "| Property | Value |"
                    printf '%s\n' "|----------|-------|"
                    printf '%s\n' "| **Video Name** | \`${FILENAME_NO_EXT}\` |"
                    printf '%s\n' "| **Original Link** | [YouTube Video](${URL}) |"
                    printf '%s\n' "| **Total Size** | **1 archive** - **${SIZE_MB} MB** |"
                    printf '%s\n' "| **Quality** | **${QUALITY}** |"
                    printf '%s\n' "| **Status** | **Complete (100%)** |"
                    printf '%s\n' "| **Password Protected** | **YES** |"
                    printf '%s\n' ""
                    printf '%s\n' "---"
                    printf '%s\n' ""
                    printf '%s\n' "## Download Link"
                    printf '%s\n' ""
                    printf '%s\n' "| # | File | Link |"
                    printf '%s\n' "|---|------|------|"
                    printf '%s\n' "| 1 | \`${FINAL_FOLDER_NAME}.zip\` | [Download](${RAW_LINK}) |"
                    printf '%s\n' ""
                    printf '%s\n' "---"
                    printf '%s\n' ""
                    printf '%s\n' "*Created by [avasam.ir](https://avasam.ir)*"
                } > "$README_FILE"
            else
                cp "$FILE" "$BACKUP_DIR/${FINAL_FOLDER_NAME}/${FINAL_FOLDER_NAME}.${EXT}"
                SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
                FILE_ENCODED=$(urlencode "${FINAL_FOLDER_NAME}.${EXT}")
                RAW_LINK="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/videos/${FOLDER_ENCODED}/${FILE_ENCODED}"
                README_FILE="$BACKUP_DIR/${FINAL_FOLDER_NAME}/README.md"
                {
                    printf '%s\n' "# ${FILENAME_NO_EXT}"
                    printf '%s\n' ""
                    if [ -f "$BACKUP_DIR/${FINAL_FOLDER_NAME}/thumbnail.jpg" ]; then
                        THUMB_ENCODED=$(urlencode "thumbnail.jpg")
                        THUMB_RAW_LINK="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/videos/${FOLDER_ENCODED}/${THUMB_ENCODED}"
                        printf '%s\n' "<div align=\"center\"><picture><img src=\"${THUMB_RAW_LINK}\" width=\"250\" /></picture></div>"
                        printf '%s\n' ""
                        printf '%s\n' "<br>"
                        printf '%s\n' ""
                    fi
                    printf '%s\n' "---"
                    printf '%s\n' ""
                    printf '%s\n' "## Video Information"
                    printf '%s\n' ""
                    printf '%s\n' "| Property | Value |"
                    printf '%s\n' "|----------|-------|"
                    printf '%s\n' "| **Video Name** | \`${FILENAME_NO_EXT}\` |"
                    printf '%s\n' "| **Original Link** | [YouTube Video](${URL}) |"
                    printf '%s\n' "| **Total Size** | **1 file** - **${SIZE_MB} MB** |"
                    printf '%s\n' "| **Quality** | **${QUALITY}** |"
                    printf '%s\n' "| **Status** | **Complete (100%)** |"
                    printf '%s\n' "| **Password Protected** | **NO** |"
                    printf '%s\n' ""
                    printf '%s\n' "---"
                    printf '%s\n' ""
                    printf '%s\n' "## Download Link"
                    printf '%s\n' ""
                    printf '%s\n' "| # | File | Link |"
                    printf '%s\n' "|---|------|------|"
                    printf '%s\n' "| 1 | \`${FINAL_FOLDER_NAME}.${EXT}\` | [Download](${RAW_LINK}) |"
                    printf '%s\n' ""
                    printf '%s\n' "---"
                    printf '%s\n' ""
                    printf '%s\n' "*Created by [avasam.ir](https://avasam.ir)*"
                } > "$README_FILE"
            fi
        fi
    done
    rm -rf "$TMP_DIR"
done

echo "$BACKUP_DIR" > /tmp/backup_dir_path.txt
echo "REPO_OWNER_ENV=${REPO_OWNER_ENV}" > /tmp/env_vars.txt
echo "REPO_NAME_ENV=${REPO_NAME_ENV}" >> /tmp/env_vars.txt
echo "BRANCH_ENV=${BRANCH_ENV}" >> /tmp/env_vars.txt
printf "%s\n" "${URL_LIST[@]}" > /tmp/yt_urls.txt

echo "=========================================="
echo "✅ YouTube download process completed!"
echo "=========================================="
