#!/bin/bash
set -e

BIN="./ToggleNaturalScrolling"
BUNDLE="./ToggleNaturalScrolling.app"

clang -Wall -O2 \
    -framework Foundation \
    -framework AppKit \
    -framework ApplicationServices \
    -o "$BIN" \
    Retry.m \
    ProcUtil.m \
    UiUtil.m \
    Main.m

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
cp Info.plist "$BUNDLE/Contents/"
cp "$BIN" "$BUNDLE/Contents/MacOS/"
