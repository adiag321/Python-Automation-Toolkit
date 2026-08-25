#!/bin/bash
# mac_cleanup.sh - clear caches and logs from SAFE items per SKILL.md
#
# Only regenerable cache/log data is touched. Apps silently recreate what
# they need on next launch. Re-run whenever you want to reclaim space.

echo "================================================"
echo "  Mac Cleanup Script  (SAFE items, SKILL.md)"
echo "================================================"

echo ""
echo "--- Disk space BEFORE ---"
df -h /

echo ""
echo "--- Cleaning caches and logs ---"

# Helper: empty a directory in place (keeps the directory itself).
# Uses find so dotfiles are also removed and behavior is unaffected by
# the surrounding shell's nullglob/dotglob settings.
safe_clean_dir() {
    local p="$1"
    if [ -d "$p" ]; then
        find "$p" -mindepth 1 -exec rm -rf -- {} + 2>/dev/null
        echo "  cleaned: $p"
    fi
}

# Helper: remove a file or directory, including the path itself.
safe_remove_path() {
    local p="$1"
    if [ -e "$p" ] || [ -L "$p" ]; then
        rm -rf -- "$p" 2>/dev/null && echo "  removed: $p"
    fi
}

# --- All cache/log/data directories to empty ----------------------------------
for p in \
    "$HOME/Library/Caches" \
    "$HOME/Library/Caches/GeoServices" \
    "$HOME/Library/Caches/com.apple.helpd" \
    "$HOME/Library/Caches/CloudKit" \
    "$HOME/Library/Caches/com.apple.finder" \
    "$HOME/Library/Caches/org.swift.swiftpm" \
    "$HOME/Library/Caches/CocoaPods" \
    "$HOME/Library/Caches/com.apple.dt.Xcode" \
    "$HOME/Library/Caches/Adobe" \
    "$HOME/Library/Caches/Google/Chrome" \
    "$HOME/Library/Application Support/Claude/vm_bundles" \
    "$HOME/Library/Application Support/Claude/Code Cache" \
    "$HOME/Library/Application Support/Claude/Cache" \
    "$HOME/Library/Application Support/Claude/Cache/Cache_Data" \
    "$HOME/Library/Application Support/Code/Cache/Cache_Data" \
    "$HOME/Library/Application Support/Code/WebStorage" \
    "$HOME/Library/Application Support/Code/GPUCache" \
    "$HOME/Library/Application Support/Code/Local Storage/leveldb" \
    "$HOME/Library/Application Support/Code/Crashpad" \
    "$HOME/Library/Application Support/Code/CachedData" \
    "$HOME/Library/Application Support/Code/logs" \
    "$HOME/Library/Application Support/Antigravity IDE/CachedData" \
    "$HOME/Library/Application Support/Antigravity IDE/GPUCache" \
    "$HOME/Library/Application Support/Antigravity IDE/logs" \
    "$HOME/.antigravity-ide/extensions/ms-toolsai.jupyter-2025.9.1-universal/temp" \
    "$HOME/Library/Application Support/Docker" \
    "$HOME/Library/Application Support/Notion/Partitions/notion/Cache/Cache_Data" \
    "$HOME/Library/Application Support/Notion/Partitions/notion/Service Worker/CacheStorage" \
    "$HOME/Library/Application Support/Notion/Partitions/notion/Service Worker/ScriptCache" \
    "$HOME/Library/Application Support/Notion/Partitions/notion/Code Cache" \
    "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceClassifierModel" \
    "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel" \
    "$HOME/Library/Application Support/Google/Chrome/optimization_guide_model_store" \
    "$HOME/Library/Application Support/Google/Chrome/Default/optimization_guide_hint_cache_store" \
    "$HOME/Library/Application Support/Google/GoogleUpdater" \
    "$HOME/Library/Application Support/Google/Chrome/extensions_crx_cache" \
    "$HOME/Library/Application Support/Google/Chrome/component_crx_cache" \
    "$HOME/Library/Application Support/Google/Chrome/Default/GPUCache" \
    "$HOME/Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage" \
    "$HOME/Library/Application Support/Google/Chrome/Default/Service Worker/ScriptCache" \
    "$HOME/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches" \
    "$HOME/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches" \
    "$HOME/Library/Containers/com.microsoft.Powerpoint/Data/Library/Logs" \
    "$HOME/Library/Containers/com.microsoft.Powerpoint/Data/Library/Caches" \
    "$HOME/Library/Containers/com.microsoft.Excel/Data/Library/Logs" \
    "$HOME/Library/Containers/com.microsoft.Excel/Data/Library/Caches" \
    "$HOME/Library/Containers/net.whatsapp.WhatsApp/Data/Library/Caches" \
    "$HOME/Library/Containers/com.apple.geod/Data/Library/Caches" \
    "$HOME/Library/Containers/com.microsoft.Word/Data/Library/Logs" \
    "$HOME/Library/Containers/com.microsoft.Word/Data/Library/Caches" \
    "$HOME/Library/Containers/com.apple.AvatarUI.AvatarPickerMemojiPicker/Data/Library/Caches" \
    "$HOME/Library/Containers/com.apple.freeform/Data/Library/Caches" \
    "$HOME/Library/Containers/com.apple.AMPArtworkAgent/Data/Documents/artwork" \
    "$HOME/Library/Containers/com.apple.Safari/Data/Library/Caches" \
    "$HOME/Library/Containers/com.spotify.client/Data/Library/Caches" \
    "$HOME/Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite/FileProviderLogs" \
    "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Logs" \
    "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Logs/WhatsApp_2" \
    "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Library/Caches" \
    "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Message/Media" \
    "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/statusDB" \
    "$HOME/Library/Developer/CoreSimulator" \
    "$HOME/Library/Developer/Xcode/DerivedData" \
    "$HOME/Library/Logs" \
    "$HOME/Library/Logs/DiagnosticReports" \
    "$HOME/.zsh_sessions" \
    "$HOME/Movies/TV" \
    "$HOME/Music/Music/Music Library.musiclibrary" \
    "$HOME/.local/share/opencode/log" \
    "$HOME/.gemini/tmp" \
    "$HOME/.npm/_cacache" \
    "$HOME/.codex/cache" \
    "$HOME/.cache" \
    "$HOME/.cache/pip" \
    "$HOME/.cache/huggingface" \
    "$HOME/.cache/yarn" \
    "$HOME/.cache/pnpm" \
    "$HOME/.gradle/caches" \
    "$HOME/.m2/repository" \
    "$HOME/go/pkg/mod/cache" \
    "$HOME/.anydesk/thumbnails" \
    "$HOME/.copilot/logs" \
    "$HOME/Library/Application Support/Code/CachedExtensionVSIXs" \
    "$HOME/Library/Application Support/Code/User/Crashpad" \
    "$HOME/Library/Application Support/Code/User/Service Worker/CacheStorage" \
    "$HOME/Library/Application Support/Code/User/Service Worker/ScriptCache" \
    ; do
    safe_clean_dir "$p"
done

# --- Clean HTTPStorages network cache ----------------------------------------
safe_clean_dir "$HOME/Library/HTTPStorages"

# --- Chrome per-profile Service Worker / GPU / Script / hint caches ----------
shopt -s nullglob
for p in "$HOME/Library/Application Support/Google/Chrome"/Profile*/optimization_guide_hint_cache_store; do
    safe_clean_dir "$p"
done
for p in "$HOME/Library/Application Support/Google/Chrome"/*/"Service Worker"/CacheStorage; do
    safe_clean_dir "$p"
done
for p in "$HOME/Library/Application Support/Google/Chrome"/*/"Service Worker"/ScriptCache; do
    safe_clean_dir "$p"
done
for p in "$HOME/Library/Application Support/Google/Chrome"/*/GPUCache; do
    safe_clean_dir "$p"
done
shopt -u nullglob

# --- Clean leftover Chrome update clones in macOS temp folders ---
shopt -s nullglob
for p in /private/var/folders/*/*/*/com.google.Chrome.code_sign_clone; do
    safe_remove_path "$p"
done
shopt -u nullglob


# --- Single-file/path removals (removes the path itself, not just contents) --
safe_remove_path "$HOME/Library/Group Containers/com.apple.systempreferences.cache/com.apple.systemsettings.usercache"

# --- Photos Syndication widget cache (regenerates) ---------------------------
while IFS= read -r -d '' p; do
    [ -e "$p" ] && rm -rf "$p" 2>/dev/null && echo "  cleaned: $p"
done < <(find "$HOME/Library/Photos" -maxdepth 4 -iname "Syndication.photoslibrary" -print0 2>/dev/null)

# --- Ghost app leftovers for apps that are no longer installed ---------------
for app in Firefox Opera Windsurf; do
    if [ ! -d "/Applications/${app}.app" ] && [ -d "$HOME/Library/Application Support/${app}" ]; then
        rm -rf "$HOME/Library/Application Support/${app}" 2>/dev/null \
            && echo "  cleaned (ghost app): $HOME/Library/Application Support/${app}"
    fi
done

# --- Keep only the newest-created immediate subdirectory of $1; delete the rest.
keep_latest_subdir() {
    local parent="$1"
    [ -d "$parent" ] || return
    local latest="" latest_time=0 d t
    for d in "$parent"/*/; do
        [ -d "$d" ] || continue
        t=$(stat -f "%B" "$d" 2>/dev/null)
        [ -z "$t" ] && t=$(stat -f "%m" "$d" 2>/dev/null)
        if [ -n "$t" ] && [ "$t" -gt "$latest_time" ]; then
            latest_time="$t"
            latest="$d"
        fi
    done
    for d in "$parent"/*/; do
        [ -d "$d" ] || continue
        if [ "$d" != "$latest" ]; then
            rm -rf -- "$d"
            echo "  removed old version: $d"
        fi
    done
}

# --- Prune old-version folders inside a Chrome Extensions directory ----------
clean_extension_versions() {
    local ext_dir="$1"
    [ -d "$ext_dir" ] || return
    local ext_id_dir base
    for ext_id_dir in "$ext_dir"/*/; do
        [ -d "$ext_id_dir" ] || continue
        base=$(basename "$ext_id_dir")
        [ "$base" = "Temp" ] && continue
        keep_latest_subdir "$ext_id_dir"
    done
}

clean_extension_versions "$HOME/Library/Application Support/Google/Chrome/Default/Extensions"
clean_extension_versions "$HOME/Library/Application Support/Google/Chrome/Profile 4/Extensions"

# --- Prune old ScreenAI model versions (keep newest) --------------------------
keep_latest_subdir "$HOME/Library/Application Support/Google/Chrome/screen_ai"

# --- npm cache (regenerates) --------------------------------------------------
if command -v npm >/dev/null 2>&1; then
    echo "  running: npm cache clean --force"
    npm cache clean --force 2>/dev/null
fi

# --- System logs in /private/var/log (requires sudo) -------------------------
safe_clean_dir "/private/var/log/powermanagement"
safe_clean_dir "/private/var/log/DiagnosticMessages"
safe_clean_dir "/private/var/log/asl"

shopt -s nullglob
for p in /private/var/log/*.bz2 /private/var/log/*.gz; do
    safe_remove_path "$p"
done
shopt -u nullglob

# --- Homebrew cache (regenerates on next install) -----------------------------
if command -v brew >/dev/null 2>&1; then
    echo "  running: brew cleanup --prune=all"
    brew cleanup --prune=all 2>/dev/null
fi

echo ""
echo "--- Disk space AFTER ---"
df -h /

echo ""
echo "==========================================================="
echo "  Done. Apps may need a relaunch to regenerate caches."
echo "==========================================================="

