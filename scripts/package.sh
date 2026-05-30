#!/usr/bin/env bash
# Build p2p.zip (manifest.json at ROOT — required by install_plugin_from_zip)
# and update.json from the repo root. Run from the repo root: scripts/package.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(node -e 'console.log(require("./manifest.json").version)')
MIN_APP=$(node -e 'console.log(require("./manifest.json").minAppVersion || "")')
FILE_URL="https://github.com/outcast1000/viboplr-p2p/releases/latest/download/p2p.zip"

# Changelog: lines under the top-most "## " heading in CHANGELOG.md, if present.
CHANGELOG=""
if [ -f CHANGELOG.md ]; then
  CHANGELOG=$(awk '/^## /{if(seen)exit; seen=1; next} seen{print}' CHANGELOG.md | sed '/^$/d' | head -50)
fi

rm -f p2p.zip
zip -q p2p.zip manifest.json index.js picker.js picker.d.ts
echo "--- zip contents (manifest.json must have no dir prefix) ---"
unzip -l p2p.zip

VERSION="$VERSION" MIN_APP="$MIN_APP" FILE_URL="$FILE_URL" CHANGELOG="$CHANGELOG" node -e '
const fs=require("fs");
const info={version:process.env.VERSION, file:process.env.FILE_URL};
if(process.env.MIN_APP) info.minAppVersion=process.env.MIN_APP;
if(process.env.CHANGELOG) info.changelog=process.env.CHANGELOG;
fs.writeFileSync("update.json", JSON.stringify(info,null,2)+"\n");
console.log("wrote update.json:", JSON.stringify(info));
'

echo
echo "NOTE: minAppVersion in manifest.json gates this release. P2P behavior lives in"
echo "the host app's Rust (libp2p) + the viboplr-relay repo. If a change needs newer"
echo "host P2P commands, bump minAppVersion in lockstep so older apps don't pull it."
echo
echo "To publish:"
echo "  gh release create v${VERSION} p2p.zip update.json --repo outcast1000/viboplr-p2p --title \"v${VERSION}\" --notes-file CHANGELOG.md"
