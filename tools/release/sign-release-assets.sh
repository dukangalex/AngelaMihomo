#!/usr/bin/env bash
# AngelaMihomo release checksum signing (T273).
#
# Usage:
#   sign-release-assets.sh <assets-dir> [private-key]
#   ANGELA_UPDATE_SIGNING_KEY=<path> sign-release-assets.sh <assets-dir>
#
# Writes <assets-dir>/sha256sums.txt covering every regular file in
# <assets-dir> except the manifest and its signature, then signs the
# manifest with the project's update signing key (Ed25519, raw
# detached signature) into <assets-dir>/sha256sums.txt.sig and
# verifies the signature against the key's public half.
#
# Upload BOTH files to the GitHub release next to the assets. The
# in-app updater only installs from a release whose signed manifest
# verifies and lists the package being installed (releases without
# one keep the browser download path). The private key must never be
# committed or uploaded.
set -euo pipefail

dir="${1:?usage: sign-release-assets.sh <assets-dir> [private-key]}"
key="${2:-${ANGELA_UPDATE_SIGNING_KEY:-}}"
if [ -z "$key" ] || [ ! -f "$key" ]; then
  echo "error: update signing key not found (pass it as argument 2 or set ANGELA_UPDATE_SIGNING_KEY)" >&2
  exit 1
fi
if [ ! -d "$dir" ]; then
  echo "error: not a directory: $dir" >&2
  exit 1
fi

manifest="$dir/sha256sums.txt"
signature="$dir/sha256sums.txt.sig"
rm -f "$manifest" "$signature"

(
  cd "$dir"
  find . -maxdepth 1 -type f ! -name 'sha256sums.txt' ! -name 'sha256sums.txt.sig' -printf '%P\n' \
    | LC_ALL=C sort \
    | while IFS= read -r name; do sha256sum -- "$name"; done
) > "$manifest"

if [ ! -s "$manifest" ]; then
  echo "error: no assets found in $dir" >&2
  exit 1
fi

openssl pkeyutl -sign -rawin -inkey "$key" -in "$manifest" -out "$signature"

pub="$(mktemp)"
trap 'rm -f "$pub"' EXIT
openssl pkey -in "$key" -pubout -out "$pub" 2>/dev/null
openssl pkeyutl -verify -rawin -pubin -inkey "$pub" -sigfile "$signature" -in "$manifest" >/dev/null

echo "signed manifest: $manifest"
echo "signature:       $signature"
echo "upload both files to the release as assets named sha256sums.txt and sha256sums.txt.sig"
