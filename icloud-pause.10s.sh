#!/bin/bash
# <xbar.title>iCloud Pause</xbar.title>
# <xbar.desc>Temporarily freeze iCloud sync daemons (bird, cloudd) with an auto-resume timer.</xbar.desc>
# <xbar.version>1.0</xbar.version>
#
# Works in xbar and SwiftBar. Refreshes every 10s (see filename).
# Pausing sends SIGSTOP to bird/cloudd; resuming sends SIGCONT.
# State file holds the resume deadline (epoch seconds) and the boot time,
# so a reboot clears a stale pause.

SELF="$0"
STATE="$HOME/.icloud-pause.state"
PROCS="bird cloudd"
BOOT="$(/usr/sbin/sysctl -n kern.boottime 2>/dev/null | /usr/bin/sed -E 's/.*sec = ([0-9]+).*/\1/')"

stop_procs()   { /usr/bin/killall -STOP $PROCS 2>/dev/null; }
resume_procs() { /usr/bin/killall -CONT $PROCS 2>/dev/null; }

procs_stopped() {
  local pid st
  for pid in $(/usr/bin/pgrep -x bird; /usr/bin/pgrep -x cloudd); do
    st="$(/bin/ps -o state= -p "$pid" 2>/dev/null | /usr/bin/tr -d ' ')"
    case "$st" in T*) return 0 ;; esac
  done
  return 1
}

# --- actions invoked from the menu ---
case "$1" in
  pause)
    hours="${2:-4}"
    until=$(( $(/bin/date +%s) + hours * 3600 ))
    printf '%s\n%s\n' "$until" "$BOOT" > "$STATE"
    stop_procs
    exit 0
    ;;
  resume)
    resume_procs
    /bin/rm -f "$STATE"
    exit 0
    ;;
esac

# --- refresh: decide what to show ---
now="$(/bin/date +%s)"
until=""
saved_boot=""
if [ -f "$STATE" ]; then
  until="$(/usr/bin/sed -n '1p' "$STATE")"
  saved_boot="$(/usr/bin/sed -n '2p' "$STATE")"
fi

# Stale pause from before a reboot: drop it.
if [ -n "$until" ] && [ -n "$BOOT" ] && [ "$saved_boot" != "$BOOT" ]; then
  /bin/rm -f "$STATE"
  until=""
fi

# Timer expired: resume.
if [ -n "$until" ] && [ "$now" -ge "$until" ]; then
  resume_procs
  /bin/rm -f "$STATE"
  until=""
fi

menu_options() {
  local label="$1"
  for h in 4 8 12 24; do
    echo "$label $h hours | bash=\"$SELF\" param1=pause param2=$h terminal=false refresh=true"
  done
}

if [ -n "$until" ]; then
  # Timer active. launchd may have respawned a daemon, so re-apply the stop.
  stop_procs
  rem=$(( until - now ))
  h=$(( rem / 3600 ))
  m=$(( (rem % 3600) / 60 ))
  resume_at="$(/bin/date -r "$until" '+%a %-I:%M %p')"
  echo "☁️⏸ ${h}h${m}m"
  echo "---"
  echo "iCloud sync paused"
  echo "Auto-resumes $resume_at"
  echo "Resume now | bash=\"$SELF\" param1=resume terminal=false refresh=true"
  echo "---"
  menu_options "Restart timer:"
elif procs_stopped; then
  # Stopped outside this plugin (no timer).
  echo "☁️⏸"
  echo "---"
  echo "iCloud sync paused (no timer)"
  echo "Resume now | bash=\"$SELF\" param1=resume terminal=false refresh=true"
  echo "---"
  menu_options "Pause for"
else
  echo "☁️"
  echo "---"
  echo "iCloud sync running"
  echo "---"
  menu_options "Pause for"
fi
