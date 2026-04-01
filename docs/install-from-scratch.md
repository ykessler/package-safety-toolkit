# Install From Scratch

This walkthrough assumes you are setting up `package-safety-toolkit` on a Mac for the first time.

## Download The Repo

### Clone it with Git

```sh
git clone https://github.com/ykessler/package-safety-toolkit.git ~/src/package-safety-toolkit
cd ~/src/package-safety-toolkit
```

### Or download a ZIP

1. Download the repo ZIP from GitHub.
2. Extract it somewhere permanent, for example `~/src/package-safety-toolkit`.
3. Open Terminal and `cd` into that folder.

The repo can live anywhere. The recommended pattern is to keep it in a stable personal tools directory and let the installer copy the runnable files into the standard locations.

## Recommended First-Time Setup

If you just want the normal setup, run this:

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

This:

- installs the files
- applies the package-manager settings immediately
- clears caches once
- enables the LaunchAgent for future automatic refreshes

## Other Install Modes

### Install files only

```sh
./bin/install-package-safety
```

What it does:

- installs the scripts into `~/.local/bin/`
- writes the LaunchAgent plist into `~/Library/LaunchAgents/`

What it does not do:

- does not apply the package-manager settings yet
- does not clear caches
- does not load the LaunchAgent

Use this if you want to inspect the files first.

### Apply settings now, but do not enable the scheduler yet

```sh
./bin/install-package-safety --run-bootstrap
```

What it does:

- installs the files
- runs `package-safety-bootstrap`
- applies the package-manager settings immediately
- clears Bun, npm, pip, and uv caches once

What it does not do:

- does not load the LaunchAgent
- does not schedule future weekly refreshes yet

Use this if you want immediate changes but not automation yet.

### Enable the scheduler, but skip the one-time cache clear

```sh
./bin/install-package-safety --load-agent
```

What it does:

- installs the files
- loads or reloads the LaunchAgent
- immediately runs `package-safety-refresh-weekly` once because the plist uses `RunAtLoad`
- enables future runs at login and on the weekly schedule

What it does not do:

- does not run `package-safety-bootstrap`
- does not clear caches

Use this if you want the ongoing scheduler and do not care about the one-time cache reset.

## Know Where The Files Go

By default:

- scripts are installed to `~/.local/bin/`
- the LaunchAgent plist is installed to `~/Library/LaunchAgents/`
- logs go to `~/Library/Logs/package-safety-refresh.log`

The installer script itself stays in the repo. It is not copied into `~/.local/bin/`.

## Manual Commands After Install

### Run the one-time bootstrap manually

```sh
~/.local/bin/package-safety-bootstrap
```

### Run the weekly refresh manually

```sh
~/.local/bin/package-safety-refresh-weekly
```

### Load the LaunchAgent manually

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.package-safety.refresh.plist
```

### Unload it later

```sh
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/local.package-safety.refresh.plist
```

## Updating Later

### Pull the latest repo changes

```sh
git pull
```

### Reinstall the updated scripts and plist

```sh
./bin/install-package-safety --load-agent
```

Use this instead if you also want to re-run the one-time bootstrap and clear caches again:

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

## If A Tool Is Missing

The scripts work even if some package managers are not installed. They print a warning and skip the missing tool.

Examples:

- no `bun`: Bun config is skipped
- no `uv`: uv config is skipped
- no `python3` or `pip`: pip config is skipped
- no `npm`: npm config is skipped
