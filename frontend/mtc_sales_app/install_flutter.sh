#!/bin/bash

echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Enabling Web support..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building Web..."
flutter build web --release
