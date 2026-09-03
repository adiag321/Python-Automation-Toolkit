#!/bin/bash
# mac_cleanup.sh - all-in-one Mac cleanup & maintenance toolkit
#
# Usage:
#   ./mac_cleanup.sh                        clean caches/logs (SAFE items) - default, no prompts
#   ./mac_cleanup.sh --all                  clean + dev artifact purge + stale installers + optimize
#   ./mac_cleanup.sh --clean                cache/log cleanup only (same as no args)
#   ./mac_cleanup.sh --purge                dev artifact purge only (node_modules/target/.build/dist)
#   ./mac_cleanup.sh --installers           stale installer cleanup only (.dmg/.pkg/.mpkg/.iso/.xip)
#   ./mac_cleanup.sh --optimize             light maintenance only (DNS/QuickLook/icon cache/Spotlight)
#   ./mac_cleanup.sh --uninstall "AppName"  remove an app + its leftover data
#   ./mac_cleanup.sh --help                 show this help
#
# Flags that modify behavior:
#   --yes                    skip confirmation prompts for --purge/--installers/--uninstall
#   --purge-min-age N        dev artifacts untouched > N days are purge candidates (default 14)
#   --purge-paths "p1 p2"    custom project roots to scan for --purge (space-separated)
#   --installer-min-age N    installers older than N days are cleanup candidates (default 3)
#   --reindex-spotlight      with --optimize, also force a full Spotlight reindex of / (slow)
#   --list-only              with --uninstall, only report findings, never delete
#
# Only the cache/log cleanup (default, or part of --all) runs without asking -
# every path there is pure regenerable cache/log data that apps recreate on
# next launch. Purge, installer cleanup, and uninstall touch things you might
# still want (an unrebuilt project, an installer you haven't run yet, an
# entire app), so they always list what they found and require a y/N
# confirmation unless --yes is passed.
#
# Every path this script cleans/removes is printed with the space it freed,
# e.g. "  cleaned: ~/Library/Caches/Foo (freed 42M)", and the cache-clean
# action prints a running grand total. Every run's full output is also
# saved to ~/Library/Application Support/mac_cleanup/logs/run-<timestamp>.log
# (deliberately not under ~/Library/Logs, since that directory itself gets
# emptied by the cache-clean step).

set -uo pipefail

# ==============================================================================
# Helper Functions
# ==============================================================================

# Helper: empty a directory in place (keeps the directory itself).
# Uses find so dotfiles are also removed and behavior is unaffected by
# the surrounding shell's nullglob/dotglob settings.
# Adds its size to TOTAL_FREED_KB when a caller has declared that variable
# (bash's dynamic scoping makes a caller's `local` visible to callees).
safe_clean_dir() {
    local p="$1"
    if [ -d "$p" ]; then
        local size_kb size_h
        size_kb=$(du -sk "$p" 2>/dev/null | cut -f1)
        size_kb=${size_kb:-0}
        size_h=$(du -sh "$p" 2>/dev/null | cut -f1)
        find "$p" -mindepth 1 -exec rm -rf -- {} + 2>/dev/null
        [ -n "${TOTAL_FREED_KB+x}" ] && TOTAL_FREED_KB=$((TOTAL_FREED_KB + size_kb))
        echo "  cleaned: $p (freed ${size_h:-0B})"
    fi
}

# Helper: remove a file or directory, including the path itself.
safe_remove_path() {
    local p="$1"
    if [ -e "$p" ] || [ -L "$p" ]; then
        local size_kb size_h
        size_kb=$(du -sk "$p" 2>/dev/null | cut -f1)
        size_kb=${size_kb:-0}
        size_h=$(du -sh "$p" 2>/dev/null | cut -f1)
        if rm -rf -- "$p" 2>/dev/null; then
            [ -n "${TOTAL_FREED_KB+x}" ] && TOTAL_FREED_KB=$((TOTAL_FREED_KB + size_kb))
            echo "  removed: $p (freed ${size_h:-0B})"
        fi
    fi
}

# Helper: empty a directory if its size is greater than the specified limit in MB.
safe_clean_dir_if_large() {
    local p="$1"
    local limit_mb="$2"
    if [ -d "$p" ]; then
        local size_kb size_h
        size_kb=$(du -sk "$p" | cut -f1)
        if [ "$size_kb" -gt $((limit_mb * 1024)) ]; then
            size_h=$(du -sh "$p" 2>/dev/null | cut -f1)
            find "$p" -mindepth 1 -exec rm -rf -- {} + 2>/dev/null
            [ -n "${TOTAL_FREED_KB+x}" ] && TOTAL_FREED_KB=$((TOTAL_FREED_KB + size_kb))
            echo "  cleaned (>${limit_mb}MB): $p (freed ${size_h:-0B})"
        else
            echo "  skipped (<= ${limit_mb}MB): $p"
        fi
    fi
}

# Helper: Keep only the newest-created immediate subdirectory of $1; delete the rest.
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
            local size_kb size_h
            size_kb=$(du -sk "$d" 2>/dev/null | cut -f1)
            size_kb=${size_kb:-0}
            size_h=$(du -sh "$d" 2>/dev/null | cut -f1)
            rm -rf -- "$d"
            [ -n "${TOTAL_FREED_KB+x}" ] && TOTAL_FREED_KB=$((TOTAL_FREED_KB + size_kb))
            echo "  removed old version: $d (freed ${size_h:-0B})"
        fi
    done
}

# Helper: Prune old-version folders inside a Chrome Extensions directory
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

# ==============================================================================
# Action: Cache/Log Cleanup (SAFE items - runs immediately, no confirmation)
# ==============================================================================
run_cache_clean() {
    local TOTAL_FREED_KB=0

    echo "================================================"
    echo "  Mac Cleanup Script  (SAFE items, SKILL.md)"
    echo "================================================"

    echo ""
    echo "--- Disk space BEFORE ---"
    df -h /

    echo ""
    echo "--- Cleaning caches and logs ---"

    # --- System & General Caches ---
    for p in \
        "$HOME/Library/Caches" \
        "$HOME/Library/Caches/GeoServices" \
        "$HOME/Library/Caches/com.apple.helpd" \
        "$HOME/Library/Caches/CloudKit" \
        "$HOME/Library/Caches/com.apple.finder" \
        "$HOME/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.geod/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.AvatarUI.AvatarPickerMemojiPicker/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.freeform/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.AppStore/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.AMPArtworkAgent/Data/Documents/artwork" \
        "$HOME/Library/Containers/com.apple.AMPArtworkAgent/Data/Library/Caches" \
        "$HOME/Library/Containers/com.apple.AppleMediaServicesUI.UtilityExtension/Data/tmp" \
        "$HOME/Library/Containers/com.apple.wallpaper.extension.aerials/Data/tmp" \
        "$HOME/Library/Containers/com.betafish.adblock-mac/Data/Library/Caches" \
        "$HOME/Library/Containers/com.betafish.adblock-mac.SafariContentBlocker/Data/Library/Caches" \
        "$HOME/Library/Group Containers/group.com.betafish.adblock-mac/Library/Caches/logs" \
        "$HOME/Library/Application Support/CrashReporter" \
        "$HOME/Movies/TV" \
        "$HOME/Music/Music/Music Library.musiclibrary" \
        "$HOME/.cache" \
        ; do
        safe_clean_dir "$p"
    done

    # --- Developer Tools (Xcode, Swift, CocoaPods, Docker) ---
    for p in \
        "$HOME/Library/Caches/org.swift.swiftpm" \
        "$HOME/Library/Caches/CocoaPods" \
        "$HOME/Library/Caches/com.apple.dt.Xcode" \
        "$HOME/Library/Application Support/Docker" \
        "$HOME/Library/Developer/CoreSimulator" \
        "$HOME/Library/Developer/Xcode/DerivedData" \
        ; do
        safe_clean_dir "$p"
    done

    # --- AI & IDEs (VS Code, Claude, Antigravity, GitHub Desktop, opencode, etc.) ---
    for p in \
        "$HOME/Library/Application Support/Claude/vm_bundles" \
        "$HOME/Library/Application Support/Claude/Code Cache" \
        "$HOME/Library/Application Support/Claude/Cache" \
        "$HOME/Library/Application Support/Claude/Cache/Cache_Data" \
        "$HOME/Library/Application Support/Claude/GPUCache" \
        "$HOME/Library/Application Support/Claude/DawnGraphiteCache" \
        "$HOME/Library/Application Support/Claude/DawnWebGPUCache" \
        "$HOME/Library/Application Support/Code/Cache/Cache_Data" \
        "$HOME/Library/Application Support/Code/Code Cache" \
        "$HOME/Library/Application Support/Code/DawnGraphiteCache" \
        "$HOME/Library/Application Support/Code/DawnWebGPUCache" \
        "$HOME/Library/Application Support/Code/WebStorage" \
        "$HOME/Library/Application Support/Code/GPUCache" \
        "$HOME/Library/Application Support/Code/Crashpad" \
        "$HOME/Library/Application Support/Code/CachedData" \
        "$HOME/Library/Application Support/Code/logs" \
        "$HOME/Library/Application Support/Code/CachedExtensionVSIXs" \
        "$HOME/Library/Application Support/Code/User/Crashpad" \
        "$HOME/Library/Application Support/Code/User/Service Worker/CacheStorage" \
        "$HOME/Library/Application Support/Code/User/Service Worker/ScriptCache" \
        "$HOME/Library/Application Support/Antigravity IDE/CachedData" \
        "$HOME/Library/Application Support/Antigravity IDE/GPUCache" \
        "$HOME/Library/Application Support/Antigravity IDE/logs" \
        "$HOME/Library/Application Support/Antigravity IDE/Code Cache" \
        "$HOME/Library/Application Support/Antigravity IDE/DawnGraphiteCache" \
        "$HOME/Library/Application Support/Antigravity IDE/DawnWebGPUCache" \
        "$HOME/Library/Application Support/Antigravity IDE/Cache/Cache_Data" \
        "$HOME/.antigravity-ide/extensions/ms-toolsai.jupyter-2025.9.1-universal/temp" \
        "$HOME/Library/Application Support/GitHub Desktop/Code Cache" \
        "$HOME/Library/Application Support/GitHub Desktop/GPUCache" \
        "$HOME/Library/Application Support/GitHub Desktop/DawnGraphiteCache" \
        "$HOME/Library/Application Support/GitHub Desktop/DawnWebGPUCache" \
        "$HOME/Library/Application Support/GitHub Desktop/Cache/Cache_Data" \
        "$HOME/Library/Application Support/Freebuff/Code Cache" \
        "$HOME/Library/Application Support/Freebuff/GPUCache" \
        "$HOME/Library/Application Support/Freebuff/DawnGraphiteCache" \
        "$HOME/Library/Application Support/Freebuff/DawnWebGPUCache" \
        "$HOME/Library/Application Support/Freebuff/Cache" \
        "$HOME/Library/Application Support/ai.opencode.desktop/Code Cache" \
        "$HOME/Library/Application Support/ai.opencode.desktop/GPUCache" \
        "$HOME/Library/Application Support/ai.opencode.desktop/DawnGraphiteCache" \
        "$HOME/Library/Application Support/ai.opencode.desktop/DawnWebGPUCache" \
        "$HOME/Library/Application Support/ai.opencode.desktop/Cache/Cache_Data" \
        "$HOME/.local/share/opencode/log" \
        "$HOME/.gemini/tmp" \
        "$HOME/.codex/cache" \
        "$HOME/.copilot/logs" \
        ; do
        safe_clean_dir "$p"
    done

    # Clean VS Code Local Storage only if > 50MB
    safe_clean_dir_if_large "$HOME/Library/Application Support/Code/Local Storage/leveldb" 50

    # --- Productivity Apps (Notion, Microsoft Office, WhatsApp, Spotify, Adobe) ---
    for p in \
        "$HOME/Library/Caches/Adobe" \
        "$HOME/Library/Application Support/Notion/Partitions/notion/Cache/Cache_Data" \
        "$HOME/Library/Application Support/Notion/Partitions/notion/Service Worker/CacheStorage" \
        "$HOME/Library/Application Support/Notion/Partitions/notion/Service Worker/ScriptCache" \
        "$HOME/Library/Application Support/Notion/Partitions/notion/Code Cache" \
        "$HOME/Library/Application Support/Notion/Code Cache" \
        "$HOME/Library/Application Support/Notion/GPUCache" \
        "$HOME/Library/Application Support/Notion/DawnGraphiteCache" \
        "$HOME/Library/Application Support/Notion/DawnWebGPUCache" \
        "$HOME/Library/Application Support/Notion/Cache/Cache_Data" \
        "$HOME/Library/Containers/com.microsoft.Powerpoint/Data/Library/Logs" \
        "$HOME/Library/Containers/com.microsoft.Powerpoint/Data/Library/Caches" \
        "$HOME/Library/Containers/com.microsoft.Excel/Data/Library/Logs" \
        "$HOME/Library/Containers/com.microsoft.Excel/Data/Library/Caches" \
        "$HOME/Library/Containers/com.microsoft.Excel/Data/tmp" \
        "$HOME/Library/Containers/com.microsoft.Word/Data/Library/Logs" \
        "$HOME/Library/Containers/com.microsoft.Word/Data/Library/Caches" \
        "$HOME/Library/Containers/com.microsoft.Word/Data/tmp" \
        "$HOME/Library/Containers/net.whatsapp.WhatsApp/Data/Library/Caches" \
        "$HOME/Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite/FileProviderLogs" \
        "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Logs" \
        "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Logs/WhatsApp_2" \
        "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Library/Caches" \
        "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/statusDB" \
        "$HOME/Library/Containers/com.spotify.client/Data/Library/Caches" \
        "$HOME/.anydesk/thumbnails" \
        ; do
        safe_clean_dir "$p"
    done

    # WhatsApp Message/Media may hold non-recoverable photos/videos/voice notes;
    # only clear it once it has grown past 500MB.
    safe_clean_dir_if_large "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Message/Media" 500

    # --- Web Browsers & Network Caches (Chrome, Safari, etc.) ---
    for p in \
        "$HOME/Library/Caches/Google/Chrome" \
        "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceClassifierModel" \
        "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel" \
        "$HOME/Library/Application Support/Google/Chrome/optimization_guide_model_store" \
        "$HOME/Library/Application Support/Google/Chrome/Default/optimization_guide_hint_cache_store" \
        "$HOME/Library/Application Support/Google/GoogleUpdater" \
        "$HOME/Library/Application Support/Google/Chrome/extensions_crx_cache" \
        "$HOME/Library/Application Support/Google/Chrome/component_crx_cache" \
        "$HOME/Library/Application Support/Google/Chrome/Default/GPUCache" \
        "$HOME/Library/Application Support/Google/Chrome/Default/Cache/Cache_Data" \
        "$HOME/Library/Application Support/Google/Chrome/Default/Service Worker/ScriptCache" \
        "$HOME/Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage" \
        "$HOME/Library/Containers/com.apple.Safari/Data/Library/Caches" \
        ; do
        safe_clean_dir "$p"
    done

    safe_clean_dir "$HOME/Library/HTTPStorages"

    # Chrome per-profile Service Worker / GPU / Script / hint caches
    shopt -s nullglob
    for p in "$HOME/Library/Application Support/Google/Chrome"/Profile*/optimization_guide_hint_cache_store; do
        safe_clean_dir "$p"
    done
    for p in "$HOME/Library/Application Support/Google/Chrome"/*/Cache/Cache_Data; do
        safe_clean_dir "$p"
    done
    for p in "$HOME/Library/Application Support/Google/Chrome"/*/"Service Worker"/ScriptCache; do
        safe_clean_dir "$p"
    done
    for p in "$HOME/Library/Application Support/Google/Chrome"/*/"Service Worker"/CacheStorage; do
        safe_clean_dir "$p"
    done
    for p in "$HOME/Library/Application Support/Google/Chrome"/*/GPUCache; do
        safe_clean_dir "$p"
    done
    shopt -u nullglob

    for ext_dir in "$HOME/Library/Application Support/Google/Chrome"/*/Extensions; do
        clean_extension_versions "$ext_dir"
    done
    keep_latest_subdir "$HOME/Library/Application Support/Google/Chrome/screen_ai"

    # --- Programming Language Package Caches ---
    for p in \
        "$HOME/.cache/pip" \
        "$HOME/.cache/huggingface" \
        "$HOME/.cache/yarn" \
        "$HOME/.cache/pnpm" \
        "$HOME/.gradle/caches" \
        "$HOME/.m2/repository" \
        "$HOME/go/pkg/mod/cache" \
        "$HOME/.npm/_npx" \
        "$HOME/.npm/_logs" \
        ; do
        safe_clean_dir "$p"
    done

    # npm cache (regenerates)
    if command -v npm >/dev/null 2>&1; then
        echo "  running: npm cache clean --force"
        npm cache clean --force 2>/dev/null
    fi

    # Homebrew cache (regenerates on next install)
    if command -v brew >/dev/null 2>&1; then
        echo "  running: brew cleanup --prune=all"
        brew cleanup --prune=all 2>/dev/null
    fi

    # --- Ghost App Leftovers ---
    for app in Firefox Opera Windsurf Freebuff; do
        ghost_path="$HOME/Library/Application Support/${app}"
        if [ ! -d "/Applications/${app}.app" ] && [ -d "$ghost_path" ]; then
            ghost_size_kb=$(du -sk "$ghost_path" 2>/dev/null | cut -f1)
            ghost_size_kb=${ghost_size_kb:-0}
            ghost_size_h=$(du -sh "$ghost_path" 2>/dev/null | cut -f1)
            rm -rf "$ghost_path" 2>/dev/null \
                && { TOTAL_FREED_KB=$((TOTAL_FREED_KB + ghost_size_kb)); \
                     echo "  cleaned (ghost app): $ghost_path (freed ${ghost_size_h:-0B})"; }
        fi
    done

    # --- System Logs & Single Items ---
    safe_remove_path "$HOME/Library/Group Containers/com.apple.systempreferences.cache/com.apple.systemsettings.usercache"
    safe_remove_path "$HOME/Library/Containers/com.apple.geod/Data/tmp"
    safe_remove_path "$HOME/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/com.apple.mediaanalysisd"

    for p in \
        "$HOME/Library/Logs" \
        "$HOME/Library/Logs/DiagnosticReports" \
        "$HOME/.zsh_sessions" \
        ; do
        safe_clean_dir "$p"
    done

    # System logs in /private/var/log (requires sudo)
    safe_clean_dir "/private/var/log/powermanagement"
    safe_clean_dir "/private/var/log/DiagnosticMessages"
    safe_clean_dir "/private/var/log/asl"

    shopt -s nullglob
    for p in /private/var/log/*.bz2 /private/var/log/*.gz; do
        safe_remove_path "$p"
    done
    # Clean leftover Chrome update clones in macOS temp folders
    for p in /private/var/folders/*/*/*/com.google.Chrome.code_sign_clone; do
        safe_remove_path "$p"
    done
    shopt -u nullglob

    # Photos Syndication widget cache (regenerates)
    while IFS= read -r -d '' p; do
        if [ -e "$p" ]; then
            photo_size_kb=$(du -sk "$p" 2>/dev/null | cut -f1)
            photo_size_kb=${photo_size_kb:-0}
            photo_size_h=$(du -sh "$p" 2>/dev/null | cut -f1)
            rm -rf "$p" 2>/dev/null \
                && { TOTAL_FREED_KB=$((TOTAL_FREED_KB + photo_size_kb)); \
                     echo "  cleaned: $p (freed ${photo_size_h:-0B})"; }
        fi
    done < <(find "$HOME/Library/Photos" -maxdepth 4 -iname "Syndication.photoslibrary" -print0 2>/dev/null)

    echo ""
    echo "--- Total freed (sum of items above): ~$((TOTAL_FREED_KB / 1024))MB ---"

    echo ""
    echo "--- Disk space AFTER ---"
    df -h /

    echo ""
    echo "==========================================================="
    echo "  Done. Apps may need a relaunch to regenerate caches."
    echo "==========================================================="
}

# ==============================================================================
# Action: Dev Artifact Purge (node_modules/target/.build/dist - lists, then confirms)
# ==============================================================================
run_dev_purge() {
    local artifact_names=(node_modules target .build dist)
    local default_roots=(
        "$HOME/Documents"
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Developer"
        "$HOME/dev"
        "$HOME/Projects"
        "$HOME/Code"
    )
    local roots=()
    [ ${#PURGE_ROOTS[@]} -gt 0 ] && roots=("${PURGE_ROOTS[@]}") || roots=("${default_roots[@]}")

    echo ""
    echo "=== Dev Artifact Purge ==="
    echo "Looking for: ${artifact_names[*]}"
    echo "Skipping anything modified within the last $PURGE_MIN_AGE_DAYS days."
    echo ""

    local tmp_list
    tmp_list=$(mktemp)

    local now cutoff
    now=$(date +%s)
    cutoff=$((now - PURGE_MIN_AGE_DAYS * 86400))

    local find_expr=(-name "${artifact_names[0]}")
    local n
    for n in "${artifact_names[@]:1}"; do
        find_expr+=(-o -name "$n")
    done

    local root dir mtime
    for root in "${roots[@]}"; do
        [ -d "$root" ] || continue
        while IFS= read -r -d '' dir; do
            mtime=$(stat -f "%m" "$dir" 2>/dev/null || echo 0)
            if [ "$mtime" -lt "$cutoff" ]; then
                echo "$dir" >> "$tmp_list"
            fi
        done < <(find "$root" -type d \( "${find_expr[@]}" \) -prune -print0 2>/dev/null)
    done

    if [ ! -s "$tmp_list" ]; then
        echo "No stale dev artifacts found."
        rm -f "$tmp_list"
        return 0
    fi

    sort -u -o "$tmp_list" "$tmp_list"

    local total_kb=0 count=0 size_kb size_h
    echo "Candidates (untouched > $PURGE_MIN_AGE_DAYS days):"
    while IFS= read -r dir; do
        size_kb=$(du -sk "$dir" 2>/dev/null | cut -f1)
        size_kb=${size_kb:-0}
        total_kb=$((total_kb + size_kb))
        size_h=$(du -sh "$dir" 2>/dev/null | cut -f1)
        printf "  %8s  %s\n" "${size_h:-?}" "$dir"
        count=$((count + 1))
    done < "$tmp_list"

    echo ""
    echo "Total reclaimable: ~$((total_kb / 1024))MB across $count artifact dirs"

    if [ "$AUTO_YES" -eq 0 ]; then
        local reply
        read -r -p "Delete all listed artifact dirs? [y/N] " reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            echo "Aborted, nothing deleted."
            rm -f "$tmp_list"
            return 0
        fi
    fi

    echo ""
    while IFS= read -r dir; do
        rm -rf -- "$dir" && echo "  removed: $dir"
    done < "$tmp_list"
    rm -f "$tmp_list"

    echo ""
    echo "Done. Re-run npm install / cargo build / swift build / your build tool"
    echo "in affected projects before working on them again."
}

# ==============================================================================
# Action: Stale Installer Cleanup (.dmg/.pkg/.mpkg/.iso/.xip - lists, then confirms)
# ==============================================================================
run_installer_cleanup() {
    local locations=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
        "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
    )

    if command -v brew >/dev/null 2>&1; then
        local brew_cache
        brew_cache=$(brew --cache 2>/dev/null)
        [ -n "$brew_cache" ] && locations+=("$brew_cache")
    fi

    echo ""
    echo "=== Stale Installer Cleanup ==="
    echo "Extensions: .dmg .pkg .mpkg .iso .xip   |   Older than: $INSTALLER_MIN_AGE_DAYS days"
    echo ""

    local tmp_list
    tmp_list=$(mktemp)

    local loc f
    for loc in "${locations[@]}"; do
        [ -d "$loc" ] || continue
        while IFS= read -r -d '' f; do
            echo "$f" >> "$tmp_list"
        done < <(find "$loc" -maxdepth 3 -type f \
            \( -iname "*.dmg" -o -iname "*.pkg" -o -iname "*.mpkg" -o -iname "*.iso" -o -iname "*.xip" \) \
            -mtime +"$INSTALLER_MIN_AGE_DAYS" -print0 2>/dev/null)
    done

    if [ ! -s "$tmp_list" ]; then
        echo "No stale installers found."
        rm -f "$tmp_list"
        return 0
    fi

    sort -u -o "$tmp_list" "$tmp_list"

    local total_kb=0 count=0 size_kb size_h
    echo "Candidates:"
    while IFS= read -r f; do
        size_kb=$(du -sk "$f" 2>/dev/null | cut -f1)
        size_kb=${size_kb:-0}
        total_kb=$((total_kb + size_kb))
        size_h=$(du -sh "$f" 2>/dev/null | cut -f1)
        printf "  %8s  %s\n" "${size_h:-?}" "$f"
        count=$((count + 1))
    done < "$tmp_list"

    echo ""
    echo "Total reclaimable: ~$((total_kb / 1024))MB across $count files"

    if [ "$AUTO_YES" -eq 0 ]; then
        local reply
        read -r -p "Delete all listed installer files? [y/N] " reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            echo "Aborted, nothing deleted."
            rm -f "$tmp_list"
            return 0
        fi
    fi

    echo ""
    while IFS= read -r f; do
        rm -rf -- "$f" && echo "  removed: $f"
    done < "$tmp_list"
    rm -f "$tmp_list"

    echo ""
    echo "Done."
}

# ==============================================================================
# Action: Light Maintenance (DNS/QuickLook/icon cache/Spotlight - runs immediately)
# ==============================================================================
run_optimize() {
    echo ""
    echo "=== Mac Optimize (light maintenance) ==="

    echo ""
    echo "--- Flushing DNS cache ---"
    sudo dscacheutil -flushcache 2>/dev/null
    sudo killall -HUP mDNSResponder 2>/dev/null
    echo "  done"

    echo ""
    echo "--- Resetting QuickLook thumbnail cache ---"
    qlmanage -r cache 2>/dev/null
    qlmanage -r 2>/dev/null
    echo "  done"

    echo ""
    echo "--- Rebuilding Dock/Finder icon cache ---"
    find /private/var/folders -maxdepth 4 -iname "com.apple.dock.iconcache" -exec rm -f -- {} + 2>/dev/null
    find /private/var/folders -maxdepth 4 -iname "com.apple.iconservices*" -exec rm -rf -- {} + 2>/dev/null
    killall Dock 2>/dev/null
    killall Finder 2>/dev/null
    echo "  done (Dock and Finder restarted - a brief flicker is normal)"

    echo ""
    echo "--- Spotlight index status ---"
    mdutil -s / 2>/dev/null

    if [ "$REINDEX_SPOTLIGHT" -eq 1 ]; then
        echo ""
        echo "--- Forcing full Spotlight reindex of / ---"
        sudo mdutil -E / 2>/dev/null
        echo "  reindex triggered - Spotlight search may be incomplete until it finishes"
    fi

    echo ""
    echo "=== Optimize done ==="
}

# ==============================================================================
# Action: App Uninstaller (finds app + leftovers - lists, then confirms)
# ==============================================================================
run_uninstall_app() {
    local app_name="$1"
    local app_path=""
    local candidate

    for candidate in "/Applications/${app_name}.app" "$HOME/Applications/${app_name}.app"; do
        if [ -d "$candidate" ]; then
            app_path="$candidate"
            break
        fi
    done

    if [ -z "$app_path" ]; then
        echo "Could not find /Applications/${app_name}.app or ~/Applications/${app_name}.app"
        echo "Pass the exact name as it appears without \".app\", e.g. \"Google Chrome\""
        return 1
    fi

    local bundle_id
    bundle_id=$(defaults read "$app_path/Contents/Info" CFBundleIdentifier 2>/dev/null)

    echo ""
    echo "=== App Uninstaller ==="
    echo "App:       $app_path"
    echo "Bundle ID: ${bundle_id:-<unknown>}"
    echo ""

    local tmp_list
    tmp_list=$(mktemp)

    local add_if_exists
    add_if_exists() {
        [ -e "$1" ] && echo "$1" >> "$tmp_list"
    }

    add_if_exists "$HOME/Library/Application Support/${app_name}"
    add_if_exists "$HOME/Library/Caches/${app_name}"
    add_if_exists "$HOME/Library/Logs/${app_name}"
    add_if_exists "$HOME/Library/WebKit/${app_name}"

    if [ -n "$bundle_id" ]; then
        add_if_exists "$HOME/Library/Containers/${bundle_id}"

        shopt -s nullglob
        local f
        for f in "$HOME/Library/Caches/${bundle_id}"*; do add_if_exists "$f"; done
        for f in "$HOME/Library/Preferences/${bundle_id}"*.plist; do add_if_exists "$f"; done
        for f in "$HOME/Library/Saved Application State/${bundle_id}"*.savedState; do add_if_exists "$f"; done
        for f in "$HOME/Library/HTTPStorages/${bundle_id}"*; do add_if_exists "$f"; done
        for f in "$HOME/Library/LaunchAgents/${bundle_id}"*.plist; do add_if_exists "$f"; done
        shopt -u nullglob

        # Group Containers: best-effort match on the bundle id's domain tail,
        # since group container ids vary by vendor (group.com.foo, teamid.foo, etc).
        local domain_tail="${bundle_id#*.}"
        if [ -n "$domain_tail" ] && [ -d "$HOME/Library/Group Containers" ]; then
            local d
            while IFS= read -r -d '' d; do
                echo "$d" >> "$tmp_list"
            done < <(find "$HOME/Library/Group Containers" -maxdepth 1 -iname "*${domain_tail}*" -print0 2>/dev/null)
        fi
    fi

    echo "Found leftovers:"
    if [ -s "$tmp_list" ]; then
        sort -u -o "$tmp_list" "$tmp_list"
        local p size_h
        while IFS= read -r p; do
            size_h=$(du -sh "$p" 2>/dev/null | cut -f1)
            printf "  %8s  %s\n" "${size_h:-?}" "$p"
        done < "$tmp_list"
    else
        echo "  (none found besides the app bundle itself)"
    fi

    echo ""
    if [ -n "$bundle_id" ]; then
        echo "Note: system-wide launch agents/daemons aren't checked automatically."
        echo "If needed, look manually:"
        echo "  grep -rl \"$bundle_id\" /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null"
    fi
    echo "Note: if another copy of this app (e.g. a beta build) shares this bundle"
    echo "ID or Group Container, removing items above can wipe its shared data too."

    if [ "$LIST_ONLY" -eq 1 ]; then
        rm -f "$tmp_list"
        return 0
    fi

    if [ "$AUTO_YES" -eq 0 ]; then
        echo ""
        local reply
        read -r -p "Remove the app and everything listed above? [y/N] " reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            echo "Aborted, nothing removed."
            rm -f "$tmp_list"
            return 0
        fi
    fi

    echo ""
    rm -rf -- "$app_path" && echo "  removed: $app_path"
    local p
    while IFS= read -r p; do
        rm -rf -- "$p" && echo "  removed: $p"
    done < "$tmp_list"
    rm -f "$tmp_list"

    echo ""
    echo "Done. If ${app_name} left a menu bar helper or background agent running,"
    echo "you may need to log out/in for it to fully disappear."
}

# ==============================================================================
# Argument Parsing & Dispatch
# ==============================================================================
show_help() {
    sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
}

DO_CLEAN=0
DO_PURGE=0
DO_INSTALLERS=0
DO_OPTIMIZE=0
DO_UNINSTALL=0
UNINSTALL_APP_NAME=""
ACTION_GIVEN=0

AUTO_YES=0
LIST_ONLY=0
REINDEX_SPOTLIGHT=0
PURGE_MIN_AGE_DAYS=14
INSTALLER_MIN_AGE_DAYS=3
PURGE_ROOTS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --all)
            DO_CLEAN=1; DO_PURGE=1; DO_INSTALLERS=1; DO_OPTIMIZE=1
            ACTION_GIVEN=1
            ;;
        --clean)
            DO_CLEAN=1
            ACTION_GIVEN=1
            ;;
        --purge)
            DO_PURGE=1
            ACTION_GIVEN=1
            ;;
        --installers)
            DO_INSTALLERS=1
            ACTION_GIVEN=1
            ;;
        --optimize)
            DO_OPTIMIZE=1
            ACTION_GIVEN=1
            ;;
        --uninstall)
            DO_UNINSTALL=1
            ACTION_GIVEN=1
            shift
            UNINSTALL_APP_NAME="${1:-}"
            ;;
        --yes)
            AUTO_YES=1
            ;;
        --list-only)
            LIST_ONLY=1
            ;;
        --reindex-spotlight)
            REINDEX_SPOTLIGHT=1
            ;;
        --purge-min-age)
            shift
            PURGE_MIN_AGE_DAYS="${1:-14}"
            ;;
        --purge-paths)
            shift
            read -r -a PURGE_ROOTS <<< "${1:-}"
            ;;
        --installer-min-age)
            shift
            INSTALLER_MIN_AGE_DAYS="${1:-3}"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run with --help for usage."
            exit 1
            ;;
    esac
    shift
done

# No action flag at all -> preserve original default behavior: just clean.
if [ "$ACTION_GIVEN" -eq 0 ]; then
    DO_CLEAN=1
fi

if [ "$DO_UNINSTALL" -eq 1 ] && [ -z "$UNINSTALL_APP_NAME" ]; then
    echo "--uninstall requires an app name, e.g. --uninstall \"Google Chrome\""
    exit 1
fi

# Persist a full record of every path this run touches (and what it freed)
# to a timestamped log, in addition to printing to the terminal.
# NOTE: deliberately NOT under ~/Library/Logs - the cache-clean step empties
# that directory, which would delete this run's own log file mid-run.
LOG_DIR="$HOME/Library/Application Support/mac_cleanup/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging full output to: $LOG_FILE"
echo ""

EXIT_CODE=0
if [ "$DO_CLEAN" -eq 1 ]; then run_cache_clean || EXIT_CODE=$?; fi
if [ "$DO_PURGE" -eq 1 ]; then run_dev_purge || EXIT_CODE=$?; fi
if [ "$DO_INSTALLERS" -eq 1 ]; then run_installer_cleanup || EXIT_CODE=$?; fi
if [ "$DO_OPTIMIZE" -eq 1 ]; then run_optimize || EXIT_CODE=$?; fi
if [ "$DO_UNINSTALL" -eq 1 ]; then run_uninstall_app "$UNINSTALL_APP_NAME" || EXIT_CODE=$?; fi

exit "$EXIT_CODE"
