#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Building Flutter Web App ==="
cd frontend/arta_css
flutter pub get
flutter build web --release

echo "=== Build Complete ==="
