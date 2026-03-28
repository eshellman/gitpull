# Parent directory of where to look for files to push out:
PUSHDIR="/home/push"
# Where to move files after uploading them:
#DONE="/home/DONE"
DONE=DONE
# Output:
OUTFILE=../tmp/$$
#LASTRUNFILE=/home/gbnewby/logs/dopull-lastrun
LASTRUNFILE=dopull-lastrun
# Lock file to prevent multiple dopulls running at the same time:
#PULLRUNNING=/home/gbnewby/.dopull-running
PULLRUNNING=.dopull-running
# Trigger directory for JSON processing on ibiblio:
IBIBLIO_JSON_DIR="/public/vhost/g/gutenberg/private/logs/json"
BOSS="pterodactyl@fastmail.com"

# Lock file to prevent multiple dopulls running at the same time
acquire_lock() {
  if [[ -f "$PULLRUNNING" ]]; then
    notify_postponed_and_exit
  fi

  /bin/date > "$PULLRUNNING"
  trap cleanup EXIT INT TERM
}

# Remove the lock
cleanup() {
  rm -f -- "$PULLRUNNING"
  echo "cleanup called, lock removed"
}

# Notify the boss that a dopull is already running and exit
notify_postponed_and_exit() {
  echo "dopull postponed at $(date)"
  exit 0
  local tmp
  local ps_tmp
  tmp="$(mktemp /tmp/dopull-postponed.XXXXXX)"
  ps_tmp="$(mktemp /tmp/dopull-postponed-ps.XXXXXX)"

  /bin/ps -ef > "$ps_tmp"
  {
    echo "dopull postponed at $(date)"
    /bin/grep -i dopull "$ps_tmp" 2>/dev/null || true
    /bin/grep -i "$SCP" "$ps_tmp" 2>/dev/null || true
  } > "$tmp"

  /usr/bin/mail -s "dopull postponed" "$BOSS" < "$tmp"
  rm -f -- "$ps_tmp"
  rm -f -- "$tmp"
  exit 0
}

main() {
  /bin/date > "$LASTRUNFILE"
  acquire_lock

  shopt -s nullglob

  local trig_files=("$PUSHDIR"/*.txt "$PUSHDIR"/*.json)
  if (( ${#trig_files[@]} == 0 )); then
    echo "No trigger files found, exiting."  >> "$OUTFILE"
  else
    local i
    for i in "${trig_files[@]}"; do
      local filename bn
      filename="$(basename -- "$i")"
      echo "Processing trigger file: $filename" >> "$OUTFILE"
      [ -e "$i" ] || continue
      # get the book number
      bn=${filename%.*}
      # update the hosts
      echo python3 updatehosts.py "$bn" >> "$OUTFILE" 2>&1
      # python3 updatehosts.py $bn  >> $OUTFILE 2>&1
      if [ $? -ne 0 ] ; then
        echo "Got $? exit status, this file did not go!" >> "$OUTFILE"; BOMBED='ERROR'
      else
        echo "Success!" >> "$OUTFILE"; echo "" >> "$OUTFILE"
        # move file to DONE
        /bin/mv -f -- "$i" "${DONE}/"
      fi      # $? != 0
    done
  fi

  cleanup
}

main "$@"
