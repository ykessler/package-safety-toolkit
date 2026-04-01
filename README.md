# Package Safety Toolkit

Portable scripts and launchd wiring for a conservative macOS package safety baseline.

## What It Installs

- `bin/package-safety-bootstrap`
- `bin/package-safety-refresh-weekly`
- `bin/package-safety-global-lib.sh`
- `launchd/local.package-safety.refresh.plist.template`
- `docs/package-safety-short-checklist.md`

## Policy Scope

This toolkit only covers the easy global settings:

- `bun`: global `minimumReleaseAge = 604800`
- `npm`: `min-release-age=7` when supported, otherwise a rolling `before=...` cutoff
- `pip`: rolling `install.uploaded-prior-to=...` cutoff
- `uv`: global `exclude-newer = "1 week"`

It does not install a proxy, enforce network egress policy, or manage per-project settings for `pnpm`, Yarn, or Poetry.

## Install

Install the scripts into `~/.local/bin/` and write a LaunchAgent plist into `~/Library/LaunchAgents/`:

```sh
./bin/install-package-safety
```

Install, apply the settings immediately, and load the LaunchAgent:

```sh
./bin/install-package-safety --run-bootstrap --load-agent
```

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

## Scripts

- `package-safety-bootstrap` applies the settings and clears the Bun, npm, pip, and uv caches once.
- `package-safety-refresh-weekly` reapplies the settings without clearing caches.

Both scripts print a toolchain report first so each Mac tells you which tools were found, the versions, and the config paths in use.
