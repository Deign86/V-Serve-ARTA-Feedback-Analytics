#!/bin/bash
set -e

echo "=== Current directory ==="
pwd
ls -la

echo "=== Installing Flutter SDK ==="
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

echo "=== Flutter Version ==="
/tmp/flutter/bin/flutter --version

echo "=== Checking project directory ==="
ls -la frontend/arta_css

echo "=== Building Flutter Web App ==="
cd frontend/arta_css
pwd
ls -la
/tmp/flutter/bin/flutter pub get
/tmp/flutter/bin/flutter build web --release

echo "=== Build Complete ==="
