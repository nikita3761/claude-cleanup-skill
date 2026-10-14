#!/bin/zsh
# Copy → verify (checksums) → move original to Trash. Mirrors $BASE-relative paths under --dest.
#
# Usage: zsh offload.sh --dest DIR --list FILE [--min-age-days 14] [--base $HOME] [--trash DIR] [--dry-run]
#   FILE: one path per line, relative to --base (default $HOME). Blank lines and # comments are ignored.
#         Prefix "copy:" → copy and verify only, keep the original (e.g. the latest backup).
#   Files modified within --min-age-days stay in place; for such folders only older files move.
setopt no_nomatch pipe_fail
DEST="" LIST="" MINAGE=14 BASE="$HOME" TRASH="" DRY=0
while (( $# )); do case "$1" in
  --dest) DEST="$2"; shift 2;; --list) LIST="$2"; shift 2;; --min-age-days) MINAGE="$2"; shift 2;;
  --base) BASE="$2"; shift 2;; --trash) TRASH="$2"; shift 2;; --dry-run) DRY=1; shift;;
  *) echo "unknown arg $1"; exit 2;; esac; done
[[ -n "$DEST" && -f "$LIST" ]] || { echo "usage: --dest DIR --list FILE"; exit 2; }
[[ -n "$TRASH" ]] || TRASH="$HOME/.Trash/cleanup-$(date +%Y-%m-%d)/moved-to-$(basename "$DEST")"
LIST="${LIST:A}"

vol="${DEST#/Volumes/}"; vol="/Volumes/${vol%%/*}"
if [[ "$DEST" == /Volumes/* ]]; then
  mount | grep -F " on $vol (" | grep -q 'read-only' && { echo "!! $vol is read-only (NTFS?) — stop"; exit 1; }
fi
mkdir -p "$DEST" "$TRASH" || exit 1
cd "$BASE" || exit 1
EX=(--exclude .DS_Store --exclude '._*')
ok=0 fail=0 copied=0 recent=0 QUIET=0

# Copy one relative path, verify, then trash the original unless keep=1
xfer() {
  local p="$1" keep="$2"
  [[ -e "$p" ]] || { echo "MISSING  $p"; ((fail++)); return; }
  (( DRY )) && { echo "DRY      $p"; return; }
  rsync -rtR "${EX[@]}" "./$p" "$DEST/" || { echo "COPY-FAIL $p"; ((fail++)); return; }
  local diff; diff=$(rsync -rcnR "${EX[@]}" --itemize-changes "./$p" "$DEST/")
  if [[ -n "$diff" ]]; then echo "VERIFY-FAIL $p"; print -r -- "$diff" | head -5; ((fail++)); return; fi
  if (( keep )); then echo "COPIED   $p (original kept)"; ((copied++)); return; fi
  if mkdir -p "$TRASH/${p:h}" && mv "$p" "$TRASH/$p"; then (( QUIET )) || echo "MOVED    $p"; ((ok++))
  else echo "TRASH-FAIL $p (copied and verified, original left in place)"; ((fail++)); fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "${line// }" || "$line" == \#* ]] && continue
  keep=0; [[ "$line" == copy:* ]] && { keep=1; line="${line#copy:}"; }
  p="${line#./}"
  if (( keep )) || [[ ! -d "$p" ]]; then
    if [[ -f "$p" && $keep -eq 0 && -n $(find "$p" -mtime -"$MINAGE" 2>/dev/null) ]]; then
      echo "RECENT   $p (modified < $MINAGE days, kept)"; ((recent++)); continue
    fi
    xfer "$p" "$keep"; continue
  fi
  nrecent=$(find "$p" -type f ! -name .DS_Store -mtime -"$MINAGE" 2>/dev/null | wc -l | tr -d ' ')
  if (( nrecent == 0 )); then xfer "$p" 0; continue; fi
  # Folder in use: move only files older than MINAGE, one by one
  echo "PARTIAL  $p ($nrecent recent files stay)"; ((recent+=nrecent))
  find "$p" -type f ! -name .DS_Store ! -name '._*' -mtime +"$MINAGE" -print0 |
    while IFS= read -r -d '' f; do QUIET=1 xfer "$f" 0; done   # zsh runs the loop in this shell: counters survive, failures still print
  echo "         older files of $p processed"
done < "$LIST"

echo "DONE moved=$ok copied=$copied recent_kept=$recent failed=$fail"
echo "Originals are in: $TRASH"
(( fail == 0 ))
