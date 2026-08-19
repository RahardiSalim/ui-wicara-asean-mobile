#!/usr/bin/env bash
# Vercel build for the Flutter web target. Vercel images have no Flutter SDK, so
# fetch a pinned one -- tracking `stable` would let an upstream release break a
# deploy that changed nothing on our side.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.9}"
API_BASE_URL="${WICARA_API_BASE_URL:-https://ui-wicara-asean-be.vercel.app}"
SDK_DIR="$HOME/flutter"

if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  echo "Fetching Flutter $FLUTTER_VERSION"
  curl -fsSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  mkdir -p "$SDK_DIR"
  tar -xf /tmp/flutter.tar.xz -C "$(dirname "$SDK_DIR")"
fi

export PATH="$SDK_DIR/bin:$PATH"
git config --global --add safe.directory "$SDK_DIR" || true

flutter --version
flutter pub get
flutter build web --release \
  --dart-define=WICARA_API_BASE_URL="$API_BASE_URL" \
  ${WICARA_GOOGLE_WEB_CLIENT_ID:+--dart-define=WICARA_GOOGLE_WEB_CLIENT_ID="$WICARA_GOOGLE_WEB_CLIENT_ID"}

echo "Built build/web"
