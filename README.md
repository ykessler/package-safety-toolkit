# Package Safety Toolkit

Imposes a 7-day quarantine on new package releases across bun, npm, pip, and uv — the highest-ROI defense against supply-chain attacks on a Mac developer machine.

## Requirements

- macOS
- a POSIX shell (`/bin/sh`)
- standard macOS tools such as `install`, `sed`, `awk`, `launchctl`, and `date`
- optional package managers: `bun`, `npm`, `python3`/`pip`, and `uv`

If a package manager is missing, the scripts print a warning and skip that part.

### Recommended: install bun and uv first

For the strongest coverage, install bun and uv before running the toolkit:

```sh
brew install oven-sh/bun/bun
brew install uv
```

Both are modern, fast replacements for their respective ecosystems (npm and pip). The toolkit installs pip/pip3 wrapper scripts that transparently redirect pip calls through uv, which is especially useful for AI coding agents that invoke pip directly — the uv safety policy applies automatically without the agent needing to know about it.

## Quick Start

Most people should use this exact flow on a new Mac:

### Download the repo

If you have GitHub access:

```sh
git clone https://github.com/ykessler/package-safety-toolkit.git ~/src/package-safety-toolkit
cd ~/src/package-safety-toolkit
```

If you are not using Git:

- open the GitHub repo in a browser
- choose `Code` then `Download ZIP`
- extract it somewhere permanent, for example `~/src/package-safety-toolkit`
- open Terminal and run:

```sh
cd ~/src/package-safety-toolkit
```

### Run the recommended install command

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

This does four things:

- installs the runnable scripts into `~/.local/bin/`
- installs the LaunchAgent plist into `~/Library/LaunchAgents/`
- applies the package-manager safety settings immediately
- clears caches once, then enables an automatic weekly refresh

### What happens after install

By default:

- the one-time bootstrap runs immediately
- the LaunchAgent also runs the weekly refresh once immediately because it uses `RunAtLoad`
- after that, the refresh runs again on login and every Monday at 9:00 AM local time unless you change the schedule

Installed file locations:

- scripts: `~/.local/bin/`
- plist: `~/Library/LaunchAgents/local.package-safety.refresh.plist`
- log file: `~/Library/Logs/package-safety-refresh.log`

## What This Repo Is For

This repo gives you a reusable, per-user macOS setup for:

- applying a conservative global safety baseline for `bun`, `npm`, `pip`, and `uv`
- refreshing the rolling date-based settings automatically every week
- installing the runnable scripts into `~/.local/bin/`
- installing a LaunchAgent plist into `~/Library/LaunchAgents/`

Keep the repo itself anywhere permanent, for example `~/src/package-safety-toolkit` or another personal tools directory. The installer copies the runnable files out of the repo into the standard per-user locations.

## Install Modes

### Recommended: full setup now plus weekly refresh

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

Use this on a new Mac if you want the full setup in one pass.

What it does:

- installs the files
- applies the settings immediately with bootstrap
- clears caches once
- loads the LaunchAgent for future automatic refreshes

### Install files only

```sh
./bin/install-package-safety
```

Use this if you want to inspect the installed files before making changes.

What it does:

- installs the scripts into `~/.local/bin/`
- writes the LaunchAgent plist into `~/Library/LaunchAgents/`

What it does not do:

- does not apply the package-manager settings yet
- does not clear caches
- does not load the LaunchAgent

### Apply settings now, but do not enable the scheduler yet

```sh
./bin/install-package-safety --run-bootstrap
```

Use this if you want immediate changes but not automation yet.

What it does:

- installs the files
- runs `package-safety-bootstrap`
- applies the settings immediately
- clears Bun, npm, pip, and uv caches once

What it does not do:

- does not load the LaunchAgent
- does not schedule future weekly refreshes yet

### Enable the scheduler, but skip the one-time cache clear

```sh
./bin/install-package-safety --load-agent
```

Use this if you want the ongoing scheduler and you do not care about the bootstrap cache reset right now.

What it does:

- installs the files
- loads or reloads the LaunchAgent
- immediately runs `package-safety-refresh-weekly` once because the plist uses `RunAtLoad`
- enables future runs at login and on the weekly schedule

What it does not do:

- does not run `package-safety-bootstrap`
- does not clear caches

## Manual Commands

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

That command also runs the weekly refresh once immediately because the plist has `RunAtLoad`.

### Unload the LaunchAgent manually

```sh
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/local.package-safety.refresh.plist
```

## What It Installs

- `bin/package-safety-bootstrap`
- `bin/package-safety-refresh-weekly`
- `bin/package-safety-global-lib.sh`
- `bin/pip-uv-wrapper` (installed as `~/.local/bin/pip` and `pip3`)
- `bin/npm-wrapper` (installed as `~/.local/bin/npm`)
- `bin/install-package-safety`
- `launchd/local.package-safety.refresh.plist.template`
- `docs/package-safety-short-checklist.md`

## Policy Scope

This toolkit only covers the easy global settings:

- `bun`: global `minimumReleaseAge = 604800`
- `npm`: `min-release-age=7` when supported, otherwise a rolling `before=...` cutoff
- `pip`: rolling `install.uploaded-prior-to=...` cutoff
- `uv`: global `exclude-newer = "1 week"`
- `pip`/`pip3` wrapper scripts that redirect through `uv pip` when uv is available, ensuring the uv safety policy applies to all direct pip calls (including from AI agents)
- `npm` wrapper script that prints a visible quarantine banner on install/update commands and warns when specific packages are held back by the quarantine policy, including the bypass command

It does not install a proxy, enforce network egress policy, or manage per-project settings for `pnpm`, Yarn, or Poetry.

## Output Paths

By default the installer writes:

- scripts to `~/.local/bin/`
- plist to `~/Library/LaunchAgents/`
- logs to `~/Library/Logs/package-safety-refresh.log`

These can be overridden with environment variables:

- `PACKAGE_SAFETY_BIN_DIR`
- `PACKAGE_SAFETY_PLIST_DIR`
- `PACKAGE_SAFETY_LOG_DIR`
- `PACKAGE_SAFETY_LABEL`
- `PACKAGE_SAFETY_WEEKDAY`
- `PACKAGE_SAFETY_HOUR`
- `PACKAGE_SAFETY_MINUTE`

## Updating An Existing Install

### Pull the latest repo changes

```sh
git pull
```

### Re-run the installer

```sh
./bin/install-package-safety --load-agent
```

That refreshes the installed scripts and rewrites the LaunchAgent plist. If you also want to clear caches again, use:

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

## Scripts

- `package-safety-bootstrap` applies the settings and clears the Bun, npm, pip, and uv caches once.
- `package-safety-refresh-weekly` reapplies the settings without clearing caches.

Both scripts print a toolchain report first so each Mac tells you which tools were found, the versions, and the config paths in use.

## More Detail

See [docs/install-from-scratch.md](docs/install-from-scratch.md) for the same process written as a step-by-step walkthrough.
