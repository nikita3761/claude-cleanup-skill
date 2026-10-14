#!/bin/bash
# Read-only disk scan for macOS. Changes nothing.
# Usage: bash scan.sh [top-N]   (default 25)
N="${1:-25}"
H="$HOME"

hdr() { printf '\n===== %s =====\n' "$1"; }
sizes() { du -sh "$@" 2>/dev/null | sort -rh | head -"$N"; }
lastmod() { # newest file mtime under a path, YYYY-MM-DD
  local t; t=$(find "$1" -type f -print0 2>/dev/null | xargs -0 stat -f '%m' 2>/dev/null | sort -n | tail -1)
  [ -n "$t" ] && date -r "$t" +%Y-%m-%d || echo "?"
}

hdr "Disk"
df -h / /System/Volumes/Data 2>/dev/null
tmutil listlocalsnapshots / 2>/dev/null

hdr "External volumes (filesystem, free space)"
for v in /Volumes/*; do
  [ "$v" = "/Volumes/Macintosh HD" ] && continue
  fs=$(mount | grep -F " on $v (" | sed -E 's/.*\(([a-z0-9]+),.*/\1/')
  [ -n "$fs" ] || continue
  ro=$(mount | grep -F " on $v (" | grep -q 'read-only' && echo " READ-ONLY")
  printf '%s  fs=%s%s  free=%s\n' "$v" "$fs" "$ro" "$(df -h "$v" | awk 'NR==2{print $4}')"
  [ "$fs" = "ntfs" ] && echo "  !! NTFS is read-only on macOS without a third-party driver"
done

hdr "Home top level"
sizes "$H"/* "$H"/.[!.]*

hdr "~/Library top level"
sizes "$H/Library"/*

hdr "Biggest app data (Application Support / Containers / Group Containers / Caches)"
sizes "$H/Library/Application Support"/* "$H/Library/Containers"/* "$H/Library/Group Containers"/* "$H/Library/Caches"/* "$H/Library/Caches/Google"/*

hdr "System level"
sizes /Applications /Library /private/var /usr/local /opt/homebrew /Users/Shared
sizes /Library/Developer/* /Library/Application\ Support/*

hdr "Applications"
sizes /Applications/*

hdr "Developer tooling"
xcrun simctl runtime list 2>/dev/null | grep -E 'iOS|watchOS|tvOS|visionOS'
sizes /Library/Developer/CoreSimulator/* "$H/Library/Developer/Xcode"/* "$H/Library/Developer/Xcode/iOS DeviceSupport"/* \
      "$H/Library/Developer/CoreSimulator/Devices" "$H/.android/avd" "$H/Library/Android/sdk"/* \
      "$H/.gradle"/* "$H/.npm" "$H/.nvm/versions/node"/* "$H/.pyenv/versions"/* "$H/Library/Caches/ms-playwright" \
      "$H/Library/Containers/com.docker.docker" "$(brew --cache 2>/dev/null)"

hdr "Build outputs and dependency folders under ~ (depth ≤ 6)"
find "$H" -maxdepth 6 -type d \( -name DerivedData -o -name node_modules -o -name .next -o -name Pods \
  -o -name .gradle -o -name .venv -o -name venv -o -name target -o -name build -o -name dist -o -name '.dd-*' \) \
  -not -path "$H/Library/*" -not -path '*/node_modules/*' -prune 2>/dev/null \
  | while IFS= read -r d; do du -sh "$d" 2>/dev/null; done | sort -rh | head -"$N"

hdr "Personal media/document folders (size, newest file)"
for d in "$H/Pictures"/* "$H/Movies"/* "$H/Music"/* "$H/Documents"/* "$H/Downloads"/* "$H/Desktop"/*; do
  [ -e "$d" ] || continue
  s=$(du -sh "$d" 2>/dev/null | cut -f1); [ -n "$s" ] || s="(no access)"
  printf '%s\t%s\t%s\n' "$(lastmod "$d")" "$s" "${d#$H/}"
done | sort

hdr "Trash"
du -sh "$H/.Trash" 2>/dev/null || echo "(no access to ~/.Trash — check in Finder)"

hdr "Running apps that own big caches (do not delete their caches while running)"
pgrep -lf 'Google Chrome.app/Contents/MacOS|Android Studio.app/Contents/MacOS|Xcode.app/Contents/MacOS|xcodebuild|GradleDaemon|Simulator.app|Telegram|Discord|Slack' 2>/dev/null | cut -c1-110

hdr "Not measurable without Full Disk Access"
echo "Photos Library, Mail, Messages, some Containers → System Settings → General → Storage"
