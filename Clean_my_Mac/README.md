# Clean My Mac

A shell script (`mac_cleanup.sh`) that clears regenerable caches, logs, and
leftover app data on macOS to free up disk space. It's paired with a Claude
Code skill (`SKILL.md`) that scans and reports reclaimable space **before**
anything is deleted, so this script only touches paths that have already been
reviewed as safe.

## What it does

- Prints disk space (`df -h /`) before and after
- Empties each target cache/log directory (keeps the folder itself, only
  removes its contents) unless noted otherwise
- Removes leftover data for apps that are no longer installed
- Prunes old version folders for Chrome extensions and the Chrome ScreenAI
  model, keeping only the newest
- Runs `npm cache clean --force` if npm is installed

Everything is regenerable: apps rebuild these caches/logs automatically the
next time they run.

## Files and directories removed

| Category | Path | Notes |
|---|---|---|
| General | `~/Library/Caches` | All app/system caches |
| Apple | `~/Library/Caches/GeoServices` | |
| Apple | `~/Library/Caches/com.apple.helpd` | |
| Claude Code | `~/Library/Application Support/Claude/vm_bundles` | Runtime bundles, can grow to several GB |
| Claude (Electron app) | `~/Library/Application Support/Claude/Code Cache` | |
| Claude (Electron app) | `~/Library/Application Support/Claude/Cache` | |
| Claude (Electron app) | `~/Library/Application Support/Claude/Cache/Cache_Data` | |
| VS Code | `~/Library/Application Support/Code/Cache/Cache_Data` | |
| VS Code | `~/Library/Application Support/Code/WebStorage` | |
| VS Code | `~/Library/Application Support/Code/GPUCache` | |
| VS Code | `~/Library/Application Support/Code/Local Storage/leveldb` | |
| VS Code | `~/Library/Application Support/Code/Crashpad` | |
| VS Code | `~/Library/Application Support/Code/CachedData` | Compiled JS/bytecode cache |
| VS Code | `~/Library/Application Support/Code/logs` | |
| Antigravity IDE | `~/Library/Application Support/Antigravity IDE/CachedData` | |
| Antigravity IDE | `~/Library/Application Support/Antigravity IDE/GPUCache` | |
| Antigravity IDE | `~/Library/Application Support/Antigravity IDE/logs` | |
| macOS system agents | `~/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches` | |
| macOS system agents | `~/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches` | |
| macOS system agents | `~/Library/Containers/com.apple.geod/Data/Library/Caches` | |
| macOS system agents | `~/Library/Containers/com.apple.AvatarUI.AvatarPickerMemojiPicker/Data/Library/Caches` | |
| Microsoft Office | `~/Library/Containers/com.microsoft.Powerpoint/Data/Library/Logs` & `Caches` | |
| Microsoft Office | `~/Library/Containers/com.microsoft.Excel/Data/Library/Logs` & `Caches` | |
| Microsoft Office | `~/Library/Containers/com.microsoft.Word/Data/Library/Logs` & `Caches` | |
| WhatsApp | `~/Library/Containers/net.whatsapp.WhatsApp/Data/Library/Caches` | |
| Freeform | `~/Library/Containers/com.apple.freeform/Data/Library/Caches` | |
| Apple Music | `~/Library/Containers/com.apple.AMPArtworkAgent/Data/Documents/artwork` | Artwork cache, redownloads |
| Chrome | `~/Library/Application Support/Google/Chrome/OptGuideOnDeviceClassifierModel` | On-device Gemini Nano model, ~4 GB |
| Chrome | `~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel` | |
| Chrome | `~/Library/Application Support/Google/Chrome/optimization_guide_model_store` | |
| Chrome | `~/Library/Application Support/Google/Chrome/Default/optimization_guide_hint_cache_store` | |
| Chrome | `~/Library/Application Support/Google/Chrome/Profile*/optimization_guide_hint_cache_store` | Every profile |
| Google | `~/Library/Application Support/Google/GoogleUpdater` | Installer cache |
| Chrome | `~/Library/Application Support/Google/Chrome/extensions_crx_cache` | |
| Chrome | `~/Library/Application Support/Google/Chrome/component_crx_cache` | |
| Chrome | `~/Library/Application Support/Google/Chrome/Default/GPUCache` | |
| Chrome | `~/Library/Application Support/Google/Chrome/*/Service Worker/CacheStorage` | Every profile |
| Chrome | `~/Library/Application Support/Google/Chrome/*/Service Worker/ScriptCache` | Every profile |
| Chrome | `~/Library/Application Support/Google/Chrome/*/GPUCache` | Every profile |
| Chrome | Old extension version folders under `.../Default/Extensions` and `.../Profile 4/Extensions` | Keeps only the newest version per extension |
| Chrome | Old versions under `.../Chrome/screen_ai` | Keeps only the newest |
| OneDrive | `~/Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite/FileProviderLogs` | Debug logs only, not synced files |
| System | `~/Library/Logs` | User-level logs |
| Shell | `~/.zsh_sessions` | Terminal session-restore state |
| Media library | `~/Movies/TV` | |
| Media library | `~/Music/Music/Music Library.musiclibrary` | |
| opencode | `~/.local/share/opencode/log` | |
| Gemini CLI | `~/.gemini/tmp` | |
| npm | `~/.npm/_cacache` | |
| npm | `npm cache clean --force` | Run if `npm` is on PATH |
| WhatsApp | `~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Logs` (incl. `WhatsApp_2`) | |
| WhatsApp | `~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Library/Caches` | |
| WhatsApp | `~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Message/Media` | ⚠️ Local chat media — not guaranteed recoverable if deleted/expired on sender's end |
| WhatsApp | `~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/statusDB` | ⚠️ Local WhatsApp Status data — not guaranteed recoverable |
| macOS | `~/Library/Group Containers/com.apple.systempreferences.cache/com.apple.systemsettings.usercache` | File removed, not just emptied |
| Photos | `~/Library/Photos/**/Syndication.photoslibrary` (up to 4 levels deep) | Widget/syndication cache |
| Ghost apps | `~/Library/Application Support/{Firefox,Opera,Windsurf}` | Only if the corresponding `.app` is no longer in `/Applications` |
| Codex CLI | `~/.codex/cache` | |
| Generic | `~/.cache` | XDG-style cache used by various CLI tools |
| AnyDesk | `~/.anydesk/thumbnails` | |
| GitHub Copilot CLI | `~/.copilot/logs` | |
| Notion | `~/Library/Application Support/Notion/Partitions/notion/Cache/Cache_Data` | |
| Notion | `~/Library/Application Support/Notion/Partitions/notion/Service Worker/CacheStorage` | |
| Notion | `~/Library/Application Support/Notion/Partitions/notion/Service Worker/ScriptCache` | |
| Notion | `~/Library/Application Support/Notion/Partitions/notion/Code Cache` | |

> ⚠️ The two WhatsApp media/status rows are the only paths in this script that
> can hold data that isn't a pure cache (message media, Status posts). Review
> the script before running it if you rely on local WhatsApp media/Status history.

## How to run

```bash
cd "/Users/adityaagarwal/Library/CloudStorage/OneDrive-NortheasternUniversity/Jupyter Notebook/Python scripts/Clean_my_Mac"
chmod +x mac_cleanup.sh   # first time only
./mac_cleanup.sh
```

The script prints `df -h /` before and after, and logs each path it cleans
with the space it freed (e.g. `cleaned: ~/Library/Caches/Foo (freed 42M)`),
plus a running grand total. No confirmation prompt is built into the default
cache/log cleanup — review the table above (or the script itself) before
running, since everything it touches is deleted immediately.

Every run's full output is also saved to a timestamped log file at
`~/Library/Application Support/mac_cleanup/logs/run-<timestamp>.log`, so you
can look back at exactly what a past run deleted. (It's intentionally not
under `~/Library/Logs` — that directory itself is one of the things the
cache-clean step empties.)

Re-run any time to reclaim space; all cleaned data regenerates automatically
the next time the relevant app launches.

## Using the Claude Code skill instead

`SKILL.md` defines a `mac-cleanup` skill for Claude Code that:

1. **Scans** the same categories (plus a few more, e.g. Google Drive cache
   cap, Claude Code session transcripts) and reports sizes and risk tier
   (`SAFE` / `CAUTION` / `HIGH RISK`) — without deleting anything.
2. Only deletes what you explicitly approve — `CAUTION` and `HIGH RISK`
   items must be approved by name.

Invoke it in Claude Code by asking to "clean up my Mac" or "find caches I can
clear" — it will not run `mac_cleanup.sh` directly, but performs the
equivalent scan-and-report workflow interactively.

## Additional actions (same file, opt-in flags)

`mac_cleanup.sh` also bundles four extra actions beyond cache/log cleanup.
They live in the same file but are **not** part of the default (no-argument)
run — they touch things riskier than pure cache (build artifacts you'd need
to rebuild, installer files, an entire app + its data), so each one **lists
what it found and asks for confirmation before deleting anything**, unlike
the default cache/log cleanup which runs immediately.

| Flag | What it does | Default behavior |
|---|---|---|
| `--purge` | Finds `node_modules`, `target`, `.build`, `dist` folders under common project roots, skipping any touched in the last 14 days | Lists candidates + total size, prompts y/N before deleting |
| `--installers` | Finds `.dmg`/`.pkg`/`.mpkg`/`.iso`/`.xip` installers in Downloads, Desktop, iCloud Downloads, Mail Downloads, and the Homebrew cache, older than 3 days | Lists candidates + total size, prompts y/N before deleting |
| `--optimize` | Flushes DNS cache, resets QuickLook thumbnail cache, rebuilds the Dock/Finder icon cache, reports Spotlight index status | Runs immediately (all steps are self-healing); `--reindex-spotlight` forces a full reindex (slow, opt-in) |
| `--uninstall "AppName"` | Finds an app's Application Support, caches, preferences, logs, containers, saved state, and best-effort Group Containers | Lists everything found, prompts y/N before removing the app + leftovers |

`--all` runs cache/log cleanup + `--purge` + `--installers` + `--optimize`
in one go (still prompting for the riskier ones). `--yes` skips confirmation
prompts (for scripting). `--purge`/`--installers` accept `--purge-min-age N`
/ `--installer-min-age N` to adjust the staleness cutoff, and `--purge-paths
"p1 p2"` to scan custom project roots. `--uninstall` accepts `--list-only`
to just report without ever deleting. Run `./mac_cleanup.sh --help` for
the full list.

```bash
chmod +x mac_cleanup.sh   # first time only
./mac_cleanup.sh                          # default: cache/log cleanup only
./mac_cleanup.sh --purge
./mac_cleanup.sh --installers
./mac_cleanup.sh --optimize
./mac_cleanup.sh --uninstall "Some App" --list-only
./mac_cleanup.sh --all
```

## Requirements

- macOS (uses `stat -f`, `find`, BSD `df`/`du` syntax)
- `bash`
- `npm` optional — the script only runs `npm cache clean` if `npm` is found on `PATH`
