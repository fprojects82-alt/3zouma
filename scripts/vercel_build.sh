#!/usr/bin/env bash
# Builds the web version on Vercel (Flutter is not preinstalled there).
set -euo pipefail
if [ ! -d .flutter-sdk ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git .flutter-sdk
fi
export PATH="$PWD/.flutter-sdk/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version
bash scripts/setup_platforms.sh
flutter pub get
flutter build web --release
