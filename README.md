# icloud-pause

An [xbar](https://xbarapp.com) / [SwiftBar](https://swiftbar.app) plugin that temporarily pauses iCloud sync on macOS and resumes it automatically after 4, 8, 12 or 24 hours.

It freezes the iCloud sync daemons (`bird` and `cloudd`) with `SIGSTOP` and resumes them with `SIGCONT`. Nothing is disabled or modified, so it's safe to undo at any time.

## Install

1. Install SwiftBar (`brew install --cask swiftbar`) or xbar.
2. Copy `icloud-pause.10s.sh` into your plugin folder. Keep the filename: `10s` is the refresh interval.
3. Make it executable: `chmod +x icloud-pause.10s.sh`, then refresh plugins.

## Usage

- **☁️** iCloud sync is running. Pick "Pause for 4 / 8 / 12 / 24 hours".
- **☁️⏸ 3h59m** Paused. The menu shows the resume time, "Resume now", and options to restart the timer.

## How it works

- State is stored in `~/.icloud-pause.state` (resume deadline and boot time).
- Every refresh, the plugin resumes the daemons once the deadline passes, and re-freezes them if launchd respawned one during a pause.
- A pause from before a reboot is discarded.

## Limitations

- The timer only runs while SwiftBar/xbar is running. If you quit it mid-pause, run `killall -CONT bird cloudd` or reboot.
- Finder may show iCloud as stuck while paused, and apps that depend on iCloud files can stall.
- This freezes the daemons rather than using any Apple-supported pause mechanism.
- Only tested on macOS with SwiftBar/xbar; use at your own risk.
