#!/bin/bash

# Build script for designAR
echo "Building designAR..."

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode command line tools not found"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Build the project
cd "$(dirname "$0")"

echo "Cleaning build folder..."
rm -rf build/

echo "Building project..."
xcodebuild -project designAR.xcodeproj \
    -scheme designAR \
    -configuration Debug \
    -derivedDataPath build/ \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "App location: build/Build/Products/Debug/designAR.app"
else
    echo "❌ Build failed. Check errors above."
    exit 1
fi
