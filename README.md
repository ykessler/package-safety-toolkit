# Package Safety Toolkit

Portable scripts and launchd wiring for a conservative macOS package safety baseline.

## What This Repo Is For

This repo gives you a reusable, per-user macOS setup for:

- applying a conservative global safety baseline for `bun`, `npm`, `pip`, and `uv`
- refreshing the rolling date-based settings automatically every week
- installing the runnable scripts into `~/.local/bin/`
- installing a LaunchAgent plist into `~/Library/LaunchAgents/`

Keep the repo itself anywhere permanent, for example `~/src/package-safety-toolkit` or another personal tools directory. The installer copies the runnable files out of the repo into the standard per-user locations.

## Requirements

- macOS
- a POSIX shell (`/bin/sh`)
- standard macOS tools such as `install`, `sed`, `awk`, `launchctl`, and `date`
- optional package managers: `bun`, `npm`, `python3`/`pip`, and `uv`

If a package manager is missing, the scripts print a warning and skip that part.

## From Scratch

1. Get the repo onto the Mac.

Clone it anywhere you keep personal tooling:

```sh
git clone <repo-url> ~/src/package-safety-toolkit
cd ~/src/package-safety-toolkit
```

If you are not using Git, download the repo as a ZIP, extract it somewhere permanent, and `cd` into the extracted folder.

2. Choose the installer mode you want.

`./bin/install-package-safety`

- Copies the scripts into `~/.local/bin/`
- Writes the LaunchAgent plist into `~/Library/LaunchAgents/`
- Does not run the bootstrap script
- Does not load the LaunchAgent

Use this when you want to inspect the installed files first and trigger everything manually.

`./bin/install-package-safety --run-bootstrap`

- Installs the files
- Runs `package-safety-bootstrap`
- Applies the settings immediately
- Clears Bun, npm, pip, and uv caches once
- Does not load the LaunchAgent

Use this when you want the safety settings now but do not want automatic scheduling yet.

`./bin/install-package-safety --load-agent`

- Installs the files
- Loads or reloads the LaunchAgent
- Because the plist has `RunAtLoad`, this immediately runs `package-safety-refresh-weekly` once
- Does not run the bootstrap script
- Does not clear caches

Use this when you want the ongoing schedule and you do not care about clearing caches right now.

`./bin/install-package-safety --run-bootstrap --load-agent`

- Installs the files
- Applies the settings immediately with bootstrap
- Clears caches once
- Loads the LaunchAgent for future automatic runs

Use this as the normal first-time setup if you want both immediate protection and weekly refresh.

3. Confirm where the installer wrote everything.

By default the installer writes:

- scripts to `~/.local/bin/`
- plist to `~/Library/LaunchAgents/`
- logs to `~/Library/Logs/package-safety-refresh.log`

4. If you did not use `--load-agent`, load the LaunchAgent later when you are ready.

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.package-safety.refresh.plist
```

That command also runs the weekly refresh once immediately because the plist has `RunAtLoad`.

## Recommended Commands

Most people should use this on first setup:

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

If you want a dry install first and no setting changes yet:

```sh
./bin/install-package-safety
```

## What It Installs

- `bin/package-safety-bootstrap`
- `bin/package-safety-refresh-weekly`
- `bin/package-safety-global-lib.sh`
- `bin/install-package-safety`
- `launchd/local.package-safety.refresh.plist.template`
- `docs/package-safety-short-checklist.md`

## Policy Scope

This toolkit only covers the easy global settings:

- `bun`: global `minimumReleaseAge = 604800`
- `npm`: `min-release-age=7` when supported, otherwise a rolling `before=...` cutoff
- `pip`: rolling `install.uploaded-prior-to=...` cutoff
- `uv`: global `exclude-newer = "1 week"`

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

1. Update the repo where you cloned it:

```sh
git pull
```

2. Re-run the installer:

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
