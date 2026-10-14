# cleanup — deep disk cleanup skill for Claude Code (macOS)

A [Claude Code](https://claude.com/claude-code) skill. Type `/cleanup` (or just say "my disk is full") and Claude:

1. **Scans read-only** — what actually eats the disk: build outputs, caches, simulators, emulators, data of uninstalled apps, media, external drives.
2. **Deletes only what regenerates itself** and isn't in use — Xcode `DerivedData`, caches of closed apps, npm/Homebrew caches.
3. **Asks you once, in batches** — not file by file — about everything else.
4. **Moves photos, videos and archives to an external drive** safely: copy → checksum verify → original to the Trash.
5. **Writes `RESTORE-MANIFEST.txt`** on the drive — every file's original path plus ready-to-paste restore commands.

## Safety rules it follows

- Anything used in the last **14 days** stays. In folders still in use, only older files move.
- Things that come back on the next build or device connection (Xcode DeviceSupport, Gradle caches, Playwright) are kept.
- No `rm` on your data — everything goes to `~/.Trash/cleanup-<date>/`; **you** empty the Trash after checking.
- Never fights macOS protection (SIP/TCC) with `sudo`.
- Looks inside data of uninstalled apps for your own videos/projects before removing it.
- Knows that `~/Movies/CapCut`, photo/Lightroom libraries and editor catalogs are app data, not media.
- Checks the drive filesystem first (NTFS is read-only on macOS; exFAT works).

## Install

```bash
git clone https://github.com/nikita3761/claude-cleanup-skill ~/.claude/skills/cleanup
```

Then in Claude Code: `/cleanup`.

## Scripts (usable on their own)

| Script | What it does |
|---|---|
| `scripts/scan.sh [N]` | Read-only report: disk, external drives, top folders, dev tooling, build outputs, media folders with last-modified dates, running apps |
| `scripts/offload.sh --dest DIR --list FILE [--min-age-days 14] [--dry-run]` | Copy listed `$HOME`-relative paths to `DIR`, verify with `rsync -c`, move originals to the Trash. `copy:` prefix keeps the original |
| `scripts/manifest.sh DIR` | Writes `RESTORE-MANIFEST.txt` with path mapping, restore commands, summary and full file list |

Requirements: macOS, `rsync` (built in), `zsh`/`bash`. Tested on macOS 15.

## License

MIT
