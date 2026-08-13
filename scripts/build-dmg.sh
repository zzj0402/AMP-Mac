#!/bin/bash
set -euo pipefail

# AMP DMG Build Script
# Builds the macOS app and creates a DMG installer

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AMP"
APP_BUNDLE="${APP_NAME}.app"
VERSION="${VERSION:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="${PROJECT_ROOT}/.build"
RELEASE_DIR="${BUILD_DIR}/release"
APP_DIR="${BUILD_DIR}/${APP_BUNDLE}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "=== Building AMP for macOS ==="

# Clean any previous build
rm -rf "${APP_DIR}"

# Build the executable using Swift Package Manager
echo "Building executable with SPM..."
swift build -c release --product AMPApp

# Locate the built executable
EXECUTABLE="$(swift build -c release --product AMPApp --show-bin-path)/AMPApp"

if [ ! -f "${EXECUTABLE}" ]; then
    echo "Error: Built executable not found at ${EXECUTABLE}"
    exit 1
fi

echo "Executable built at: ${EXECUTABLE}"

# Create the .app bundle directory structure
echo "Creating app bundle structure..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy the executable into the app bundle
cp "${EXECUTABLE}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy the Info.plist
cp "${PROJECT_ROOT}/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Create PkgInfo (optional but standard for app bundles)
echo -n 'APPLAPMP' > "${CONTENTS_DIR}/PkgInfo"

echo "App bundle created at: ${APP_DIR}"

# Build the DMG
DMG_OUTPUT="${RELEASE_DIR}/${DMG_NAME}"
rm -f "${DMG_OUTPUT}"
mkdir -p "${RELEASE_DIR}"

echo "Creating DMG..."

# Create a temporary folder for the DMG contents (with drag-and-drop symlink to Applications)
DMG_STAGING="$(mktemp -d)"
cp -R "${APP_DIR}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

# Create DMG using hdiutil
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_OUTPUT}"

# Clean up staging
rm -rf "${DMG_STAGING}"

# Verify the DMG
if hdiutil verify "${DMG_OUTPUT}" > /dev/null 2>&1; then
    echo "DMG verification: PASSED"
else
    echo "DMG verification: FAILED"
    exit 1
fi

DMG_SIZE=$(du -h "${DMG_OUTPUT}" | cut -f1)
echo ""
echo "=== Build complete ==="
echo "DMG: ${DMG_OUTPUT}"
echo "Size: ${DMG_SIZE}"
