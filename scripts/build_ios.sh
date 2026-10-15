#!/bin/bash
set -e

echo "📱 Kâmus iOS Derleniyor..."

# Xcode projesini yeniden üret (yeni dosya eklendiyse senkronize olsun)
python3 scripts/generate_xcodeproj.py

# Simülatör için derle
SIM_NAME="iPhone 17"
echo "🔨 Hedef simülatör: ${SIM_NAME}"

xcodebuild -project Kamus.xcodeproj \
  -scheme Kamus \
  -destination "platform=iOS Simulator,name=${SIM_NAME}" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build

echo ""
echo "✅ iOS Uygulaması, Action Extension ve Widget'lar başarıyla derlendi!"
echo "📂 Projeyi açmak için: open Kamus.xcodeproj"
