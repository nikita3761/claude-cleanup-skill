#!/bin/bash
# Write RESTORE-MANIFEST.txt into an archive made by offload.sh.
# Usage: bash manifest.sh ARCHIVE_DIR [BASE (default $HOME)]
A="${1:?archive dir}"; BASE="${2:-$HOME}"; OUT="$A/RESTORE-MANIFEST.txt"
cd "$A" || exit 1
F=(-type f ! -name .DS_Store ! -name '._*' ! -name RESTORE-MANIFEST.txt)
total=$(find . "${F[@]}" | wc -l | tr -d ' ')
{
cat <<EOF
RESTORE MANIFEST
================
Created:  $(date '+%Y-%m-%d %H:%M')
Source:   $BASE
Archive:  $A
Method:   rsync copy → checksum verify (rsync -c) → original moved to Trash

PATH MAPPING
  The archive mirrors the source one-to-one:
    <archive>/<path>  →  $BASE/<path>

HOW TO RESTORE (Terminal)
  A="$A"
  One folder:   rsync -rt --progress --exclude '._*' "\$A/Pictures/2023" "$BASE/Pictures/"
  One file:     rsync -t "\$A/<path>/<file>" "$BASE/<path>/"
  Everything:   rsync -rt --progress --exclude '._*' --exclude RESTORE-MANIFEST.txt "\$A/" "$BASE/"
  Rule:         rsync -rt --exclude '._*' "\$A/<path>" "$BASE/<parent of path>/"
  Finder:       drag the item back into the original folder listed below.

NOTES
  * "._name" files are macOS metadata created on exFAT/FAT drives — not user files, not listed below.
  * .DS_Store files were not copied.

SUMMARY (top-level items: size, files, original location)
EOF
find . "${F[@]}" | sed 's#^\./##' | awk -F/ '{
    # group by first 2 components (e.g. Pictures/USA); single files at depth ≤2 stay as is
    key = (NF<=2) ? $0 : $1"/"$2; print key }' | sort | uniq -c |
  while read -r n key; do
    sz=$(find "./$key" "${F[@]}" -print0 2>/dev/null | xargs -0 stat -f %z 2>/dev/null | awk '{s+=$1} END{printf "%.0fM", s/1048576}')
    printf '  %-7s %6s files  %s/%s%s\n' "$sz" "$n" "$BASE" "$key" "$([ -d "$key" ] && echo /)"
  done
echo
echo "FULL FILE LIST (original absolute paths; archive path = same path without '$BASE/')"
cur=""
find . "${F[@]}" | sed 's#^\./##' | LC_ALL=C sort | while IFS= read -r f; do
  d=$(dirname "$f"); [ "$d" != "$cur" ] && { echo; echo "[$BASE/$d/]"; cur="$d"; }
  echo "$BASE/$f"
done
echo
echo "Total files: $total"
} > "$OUT"
echo "Wrote $OUT ($total files)"
