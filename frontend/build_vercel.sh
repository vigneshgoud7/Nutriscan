#!/bin/bash
echo "Installing Flutter SDK on Vercel..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Getting packages..."
flutter pub get

echo "Building web app..."
flutter build web
