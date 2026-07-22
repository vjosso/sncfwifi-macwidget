#!/usr/bin/env bash
# make_icon.sh — Génère Resources/AppIcon.icns (squircle carmillon + tram blanc).
# À relancer uniquement si l'on veut régénérer l'icône.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "🎨 Rendu du PNG 1024×1024…"
swift "${ROOT}/scripts/make_icon.swift" "${TMP}/icon_1024.png"

echo "🧩 Assemblage de l'iconset…"
ICONSET="${TMP}/AppIcon.iconset"
mkdir -p "$ICONSET"
SRC="${TMP}/icon_1024.png"

sips -z 16 16     "$SRC" --out "${ICONSET}/icon_16x16.png"      >/dev/null
sips -z 32 32     "$SRC" --out "${ICONSET}/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$SRC" --out "${ICONSET}/icon_32x32.png"      >/dev/null
sips -z 64 64     "$SRC" --out "${ICONSET}/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$SRC" --out "${ICONSET}/icon_128x128.png"    >/dev/null
sips -z 256 256   "$SRC" --out "${ICONSET}/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$SRC" --out "${ICONSET}/icon_256x256.png"    >/dev/null
sips -z 512 512   "$SRC" --out "${ICONSET}/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$SRC" --out "${ICONSET}/icon_512x512.png"    >/dev/null
cp "$SRC" "${ICONSET}/icon_512x512@2x.png"

echo "📦 Création de Resources/AppIcon.icns…"
iconutil -c icns "$ICONSET" -o "${ROOT}/Resources/AppIcon.icns"

echo "✅ Icône générée : Resources/AppIcon.icns"
