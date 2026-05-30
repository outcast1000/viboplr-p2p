# CLAUDE.md — viboplr-p2p

This file orients Claude Code working in this repository.

## What this repo is

This is a **plugin for the Viboplr desktop app** — NOT a standalone application,
and NOT a self-contained one. Viboplr is a Tauri 2 desktop music app whose source
lives in the separate host repo **`outcast1000/viboplr`** (likely not checked out
here). This repo contains the P2P Sharing plugin's **JavaScript UI shell** and
ships it as a versioned release the host app auto-updates.

- **Plugin id:** `p2p-sharing` (set in `manifest.json`). An installed copy with
  this id overrides the app's bundled built-in copy.

## ⚠️ CRITICAL: this is a thin shell over host-app Rust — read before editing

Unlike the spotify/tidal plugins (which are self-contained and hold all their
logic in JS), **the P2P engine is NOT in this repo.** It lives in:
- the **host app's Rust** (`outcast1000/viboplr`, `src-tauri/src/p2p/`, ~1400+
  lines of libp2p) exposed via the host bridge `api.p2p.*`
  (`start`, `stop`, `getStatus`, `searchPeer`, `streamFromPeer`,
  `downloadFromPeer`, `getSharedCollections`, `setSharedCollections`,
  `reserveRelay`, `getMultiaddrs`, `getDiagnostics`), each a thin `invoke()` over
  a host Tauri command; and
- the **`outcast1000/viboplr-relay` repo** — its libp2p version must match the
  host app's (mismatch silently breaks hole-punching).

Consequences for anyone working here:
- A change in this repo can only affect the **JS UI / orchestration**, never the
  P2P protocol or networking. Those are host-app + relay changes that ship with an
  app release.
- **`minAppVersion` (currently `0.9.78`) is the guardrail.** If a JS change starts
  depending on a newer/changed `api.p2p.*` command, **bump `minAppVersion` to the
  host version that introduced it** so older apps get `requires_app_update`
  instead of a runtime failure. `scripts/bump.sh` does NOT touch `minAppVersion` —
  set it by hand.
- Do NOT try to "implement P2P" here. If a feature needs new networking behavior,
  it belongs in the host repo's Rust (and possibly the relay), with a matching
  `api.p2p.*` method — then the JS here can call it.

## The plugin runtime (host-imposed)

The host runs `index.js` as the body of `new Function("api", "window", "globalThis",
"self", "document", code)` in the app's WebView.
- Must end with `return { activate, deactivate };`. Host calls `activate(api)`.
- `api` is the only host bridge. This plugin uses `api.p2p.*` (above) plus standard
  `api.network.fetch` (Supabase peer discovery/heartbeat), `api.storage`, `api.ui`,
  `api.playback`, `api.downloads`, `api.collections`, `api.log`. No global `fetch`,
  no `require`/`import`, no real DOM/filesystem. Frozen-sandbox globals only.
- `picker.js` uses ESM `export` and is reference/testable only — the sandbox can't
  `import` it; the relay-pick logic is used inline in `index.js`.

## Gotchas

- **Manifest id vs folder name:** the host's dev-folder loader keys on the manifest
  `"id"` (`p2p-sharing`), not the directory name. Keep the id unchanged.
- **Zip root:** `p2p.zip` MUST have `manifest.json` at its root. `scripts/package.sh`
  guarantees this (it zips manifest.json, index.js, picker.js, picker.d.ts).

## How to release

See `README.md` → *Develop & Release*: bump version (and `minAppVersion` by hand
if needed), update `CHANGELOG.md`, push a tag `vX.Y.Z` (or run the *Release*
Action). CI builds `p2p.zip` + `update.json` and publishes. The host bundles a
baseline copy at `src-tauri/plugins/p2p-sharing/` — sync the files back after a
release.
