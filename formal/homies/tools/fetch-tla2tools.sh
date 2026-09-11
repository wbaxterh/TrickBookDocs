#!/bin/bash
# Fetch the pinned TLA+ tools release used by the Homies verification.
# The jar is deliberately NOT committed; this script verifies its sha256.
set -euo pipefail

# v1.8.0 is a rolling nightly pre-release whose asset mutates; v1.7.4 is the
# latest immutable stable release (TLC2 Version 2.19 of 08 August 2024).
VERSION="v1.7.4"
SHA256="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"
URL="https://github.com/tlaplus/tlaplus/releases/download/${VERSION}/tla2tools.jar"
DIR="$(cd "$(dirname "$0")" && pwd)"
JAR="${DIR}/tla2tools.jar"

if [ -f "$JAR" ] && echo "${SHA256}  ${JAR}" | shasum -a 256 -c - >/dev/null 2>&1; then
  echo "tla2tools.jar ${VERSION} already present and verified"
  exit 0
fi

echo "Downloading tla2tools.jar ${VERSION}..."
curl -fsSL -o "$JAR" "$URL"
echo "${SHA256}  ${JAR}" | shasum -a 256 -c -
echo "OK: $JAR"
