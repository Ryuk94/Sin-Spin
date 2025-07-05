#!/bin/bash

echo "📦 Running gdformat..."
gdformat .

echo "🔍 Running gdlint..."
gdlint .

echo "🧪 Running Godot tests..."
"/c/Users/james/Desktop/Game_Design/Godot_v4.4.1-stable_mono_win64_console.exe" --headless --run-tests --path .

echo "✅ All checks passed!"