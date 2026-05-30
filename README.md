# Viboplr P2P Sharing Plugin

Search, stream, and download tracks from other Viboplr users over peer-to-peer.

Plugin id: `p2p-sharing` (installed from the Viboplr plugin gallery; it is not
bundled in the app).

> ## ⚠️ This plugin is a UI shell — the P2P engine lives in the host app
>
> Unlike most plugins, **this repo does NOT contain the peer-to-peer logic.** The
> actual P2P stack — libp2p networking, peer discovery, NAT traversal, the
> streaming/download protocol — lives in the **host app's Rust backend**
> (`outcast1000/viboplr`, `src-tauri/src/p2p/`) and is reached through the host's
> `api.p2p.*` bridge (`p2p_start`, `p2p_search_peer`, `p2p_stream_from_peer`,
> `p2p_download_from_peer`, `p2p_set_shared_collections`, …). It is also
> **version-coupled to the `outcast1000/viboplr-relay` repo** (the relay's libp2p
> version must match the app's).
>
> **What that means for releases here:**
> - A release from this repo can only change the **JS UI / orchestration** —
>   never the P2P behavior itself.
> - Any real protocol/networking change is a **host-app + relay** change and ships
>   with an app release, not a plugin auto-update.
> - **`minAppVersion` is the guardrail.** It is currently `0.9.78`. If a JS change
>   here relies on newer host `api.p2p.*` commands, **bump `minAppVersion` in
>   lockstep** so older apps get `requires_app_update` instead of a broken plugin.
>   `scripts/bump.sh` deliberately does NOT touch `minAppVersion` — set it by hand.

## Install

In Viboplr: **Extensions → Install from URL** and paste this repo's URL, or it
auto-updates if already installed (the app checks `updateUrl` every 24h, subject
to `minAppVersion`).

## Files

- `index.js` — the plugin (UI, peer list, wiring to `api.p2p.*`)
- `picker.js` / `picker.d.ts` — small relay-selection helper (reference/testable;
  the sandbox can't `import` ESM, so the logic is inlined where used)
- `manifest.json` — metadata + contributions (sidebar, stream/download providers,
  context menu, settings panel)

## Develop & Release

For every release: edit `index.js` / `manifest.json`, **bump `version`**
(`scripts/bump.sh <patch|minor|major>`), set `minAppVersion` by hand if you now
depend on newer host P2P commands, add a `## vX.Y.Z` section to `CHANGELOG.md`,
then publish.

### Release via CI (preferred)

A GitHub Actions workflow (`.github/workflows/release.yml`) verifies the manifest
version matches the release and that the zip has `manifest.json` at its root, then
attaches `p2p.zip` + `update.json`. Trigger by pushing a tag `vX.Y.Z`, or via
Actions → *Release* → *Run workflow* (enter the version).

### Release manually (fallback)

1. `scripts/package.sh` → produces `p2p.zip` + `update.json` (zip has
   `manifest.json` at root — verify via the printed `unzip -l`).
2. `gh release create vX.Y.Z p2p.zip update.json --repo outcast1000/viboplr-p2p --title "vX.Y.Z" --notes-file CHANGELOG.md`

The update endpoint is the permanent
`https://github.com/outcast1000/viboplr-p2p/releases/latest/download/update.json`.

## Dev loop

Symlink/copy this folder into the host app's user plugin dir
(`{app_data}/profiles/{profile}/plugins/p2p-sharing/`), or use the host's
Developer mode (Settings → Debug → Developer) to point at this repo and Reload.
Open DevTools (F12) for `console`/`api.log` output. The host must be a build that
ships the `api.p2p.*` commands (>= `minAppVersion`).

