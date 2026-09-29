#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ Xcode 빌드…"
xcodebuild \
  -project YTConverter.xcodeproj \
  -scheme YTConverter \
  -configuration Debug \
  -derivedDataPath "$ROOT/.derivedData" \
  build

APP_SRC="$ROOT/.derivedData/Build/Products/Debug/YTConverter.app"
APP_DST="/Applications/YTConverter.app"

echo "▶ /Applications 에 설치…"
ditto "$APP_SRC" "$APP_DST"

# Spotlight·Finder 중복 방지: DerivedData 쪽 .app 제거 (실행은 /Applications 만 사용)
rm -rf "$APP_SRC"

echo "✅ 완료: $APP_DST"
open -R "$APP_DST"
