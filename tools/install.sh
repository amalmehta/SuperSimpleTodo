#!/bin/zsh
# Builds a Release copy of Super Simple Todo and installs it in /Applications.
# Your tasks live in ~/Library/Application Support/Super Simple Todo and aren't touched.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="Super Simple Todo.app"
xcodebuild -project SuperSimpleTodo.xcodeproj -scheme "Super Simple Todo" -configuration Release \
  -derivedDataPath build/release build -quiet

osascript -e 'quit app id "com.amalmehta.SuperSimpleTodo"' 2>/dev/null || true
sleep 1
rm -rf "/Applications/$APP"
cp -R "build/release/Build/Products/Release/$APP" "/Applications/$APP"
echo "Installed /Applications/$APP"
open "/Applications/$APP"
