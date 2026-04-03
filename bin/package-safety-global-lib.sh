#!/bin/sh

set -u

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

bun_global_config_path() {
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    printf '%s\n' "$XDG_CONFIG_HOME/.bunfig.toml"
  else
    printf '%s\n' "$HOME/.bunfig.toml"
  fi
}

uv_global_config_path() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml"
}

cutoff_utc() {
  if date -u -v-7d +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v-7d +%Y-%m-%dT%H:%M:%SZ
    return 0
  fi

  if date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ
    return 0
  fi

  warn "unable to compute a UTC timestamp for 7 days ago"
  return 1
}

version_ge() {
  awk -v left="$1" -v right="$2" '
    BEGIN {
      split(left, a, ".")
      split(right, b, ".")

      for (i = 1; i <= 3; i++) {
        av = (i in a) ? a[i] + 0 : 0
        bv = (i in b) ? b[i] + 0 : 0

        if (av > bv) exit 0
        if (av < bv) exit 1
      }

      exit 0
    }
  '
}

npm_version_value() {
  npm --version 2>/dev/null | sed 's/^v//' | awk -F- '{print $1}'
}

npm_policy_value() {
  npm_version=$(npm_version_value)

  if [ -n "$npm_version" ] && version_ge "$npm_version" "11.10.0"; then
    printf '%s\n' 'min-release-age=7'
    return 0
  fi

  cutoff=$(cutoff_utc) || return 1
  printf 'before=%s\n' "$cutoff"
}

print_toolchain_report() {
  log "== Toolchain report =="

  bun_config=$(bun_global_config_path)
  if have_cmd bun; then
    log "bun: $(bun --version 2>/dev/null) | config: $bun_config | policy: minimumReleaseAge=604800"
  else
    warn "bun not found; expected config path is $bun_config"
  fi

  if have_cmd npm; then
    npm_version=$(npm_version_value)
    npm_config=$(npm config get userconfig 2>/dev/null)
    npm_policy=$(npm_policy_value 2>/dev/null)
    log "npm: $npm_version | config: $npm_config | policy: $npm_policy"
  else
    warn "npm not found; skipped npm report"
  fi

  if have_cmd python3; then
    log "python3: $(python3 --version 2>&1)"
    if python3 -m pip --version >/dev/null 2>&1; then
      cutoff=$(cutoff_utc 2>/dev/null || true)
      log "pip: $(python3 -m pip --version 2>/dev/null) | policy: install.uploaded-prior-to=${cutoff:-unknown}"
    else
      warn "pip not available via python3 -m pip; skipped pip report"
    fi
  else
    warn "python3 not found; skipped python and pip report"
  fi

  uv_config=$(uv_global_config_path)
  if have_cmd uv; then
    log "uv: $(uv --version 2>/dev/null) | config: $uv_config | policy: exclude-newer=\"1 week\""
  else
    warn "uv not found; expected config path is $uv_config"
  fi

  pip_wrapper_dir="${PACKAGE_SAFETY_BIN_DIR:-$HOME/.local/bin}"
  if [ -f "$pip_wrapper_dir/pip" ] && grep -q 'package-safety-toolkit' "$pip_wrapper_dir/pip" 2>/dev/null; then
    if have_cmd uv; then
      log "pip wrapper: $pip_wrapper_dir/pip → uv pip (active)"
      log "pip3 wrapper: $pip_wrapper_dir/pip3 → uv pip (active)"
    else
      log "pip wrapper: $pip_wrapper_dir/pip → uv pip (installed, uv not yet available)"
      log "pip3 wrapper: $pip_wrapper_dir/pip3 → uv pip (installed, uv not yet available)"
    fi
  else
    warn "pip uv wrappers not installed in $pip_wrapper_dir"
  fi
}

configure_npm_global() {
  if ! have_cmd npm; then
    warn "npm not found; skipped npm global settings"
    return 0
  fi

  npm_version=$(npm_version_value)
  if [ -n "$npm_version" ] && version_ge "$npm_version" "11.10.0"; then
    log "Configuring npm: min-release-age=7"
    npm config set min-release-age 7 --location=user
    return $?
  fi

  cutoff=$(cutoff_utc) || return 1
  log "Configuring npm: before=$cutoff"
  npm config set before "$cutoff" --location=user
}

configure_pip_global() {
  if ! have_cmd python3; then
    warn "python3 not found; skipped pip global settings"
    return 0
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    warn "pip not available via python3 -m pip; skipped pip global settings"
    return 0
  fi

  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/pip"

  cutoff=$(cutoff_utc) || return 1
  log "Configuring pip: install.uploaded-prior-to=$cutoff"
  python3 -m pip config --user set install.uploaded-prior-to "$cutoff"
}

ensure_bun_global_config() {
  bun_file=$(bun_global_config_path)

  desired='minimumReleaseAge = 604800'
  bun_dir=$(dirname "$bun_file")

  mkdir -p "$bun_dir" || return 1

  if [ ! -f "$bun_file" ]; then
    log "Creating Bun config: $bun_file"
    {
      printf '%s\n' '[install]'
      printf '%s\n' "$desired"
    } > "$bun_file"
    return $?
  fi

  temp_file=$(mktemp "${TMPDIR:-/tmp}/bunfig.toml.XXXXXX") || return 1

  awk -v desired="$desired" '
    BEGIN {
      in_install = 0
      saw_install = 0
      replaced = 0
    }
    /^\[install\][[:space:]]*$/ {
      saw_install = 1
      in_install = 1
      print
      next
    }
    /^\[/ {
      if (in_install && !replaced) {
        print desired
        replaced = 1
      }
      in_install = 0
      print
      next
    }
    in_install && /^[[:space:]]*minimumReleaseAge[[:space:]]*=/ {
      if (!replaced) {
        print desired
        replaced = 1
      }
      next
    }
    {
      print
    }
    END {
      if (saw_install) {
        if (!replaced) print desired
      } else {
        if (NR > 0) print ""
        print "[install]"
        print desired
      }
    }
  ' "$bun_file" > "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }

  mv "$temp_file" "$bun_file"
}

ensure_uv_global_config() {
  uv_file=$(uv_global_config_path)
  uv_dir=$(dirname "$uv_file")
  desired='exclude-newer = "1 week"'

  mkdir -p "$uv_dir" || return 1

  if [ ! -f "$uv_file" ]; then
    log "Creating uv config: $uv_file"
    printf '%s\n' "$desired" > "$uv_file"
    return $?
  fi

  temp_file=$(mktemp "${TMPDIR:-/tmp}/uv.toml.XXXXXX") || return 1

  if grep -Eq '^[[:space:]]*exclude-newer[[:space:]]*=' "$uv_file"; then
    awk -v desired="$desired" '
      BEGIN { replaced = 0 }
      /^[[:space:]]*exclude-newer[[:space:]]*=/ && !replaced {
        print desired
        replaced = 1
        next
      }
      { print }
      END {
        if (!replaced) print desired
      }
    ' "$uv_file" > "$temp_file" || {
      rm -f "$temp_file"
      return 1
    }
  else
    awk -v desired="$desired" '
      BEGIN { inserted = 0 }
      /^\[/ && !inserted {
        print desired
        print ""
        inserted = 1
      }
      { print }
      END {
        if (!inserted) print desired
      }
    ' "$uv_file" > "$temp_file" || {
      rm -f "$temp_file"
      return 1
    }
  fi

  mv "$temp_file" "$uv_file"
}

clear_package_caches() {
  status=0

  if have_cmd bun; then
    log "Clearing Bun cache"
    temp_bun_dir=$(mktemp -d "${TMPDIR:-/tmp}/bun-cache-clear.XXXXXX") || { status=1; }
    if [ -n "${temp_bun_dir:-}" ]; then
      printf '{}' > "$temp_bun_dir/package.json"
      (cd "$temp_bun_dir" && bun pm cache rm) || status=1
      rm -rf "$temp_bun_dir"
    fi
  else
    warn "bun not found; skipped Bun cache clear"
  fi

  if have_cmd npm; then
    log "Clearing npm cache"
    npm cache clean --force || status=1
  else
    warn "npm not found; skipped npm cache clear"
  fi

  if have_cmd python3 && python3 -m pip --version >/dev/null 2>&1; then
    log "Clearing pip cache"
    python3 -m pip cache purge || status=1
  else
    warn "pip not available; skipped pip cache clear"
  fi

  if have_cmd uv; then
    log "Clearing uv cache"
    uv cache clean || status=1
  else
    warn "uv not found; skipped uv cache clear"
  fi

  return "$status"
}
