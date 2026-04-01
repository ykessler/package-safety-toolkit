# Package Safety Short Checklist

This checklist only covers the easy global settings for `bun`, `npm`, `pip`, and `uv`.

## One-time setup

1. `bun`: create `~/.bunfig.toml` with:

   ```toml
   [install]
   minimumReleaseAge = 604800
   ```

2. `npm`: add this to `~/.npmrc`:

   ```ini
   min-release-age=7
   ```

   If your npm version does not support `min-release-age`, use a fixed cutoff and refresh it weekly:

   ```sh
   npm config set before "$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)" --location=user
   ```

3. `pip`: set a fixed cutoff and refresh it weekly:

   ```sh
   python3 -m pip config --user set install.uploaded-prior-to "$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)"
   ```

4. `uv`: create `~/.config/uv/uv.toml` with:

   ```toml
   exclude-newer = "1 week"
   ```

5. Clear old caches once:

   ```sh
   bun pm cache rm
   npm cache clean --force
   python3 -m pip cache purge
   uv cache clean
   ```

## Weekly refresh

1. Refresh the npm fixed cutoff if you are using `before` instead of `min-release-age`.
2. Refresh the pip `uploaded-prior-to` cutoff.
3. Leave the Bun and uv configs alone unless you want to change the policy.
