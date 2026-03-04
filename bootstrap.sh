#!/bin/bash
set -e

# Install Tuist if not present
if ! command -v tuist &> /dev/null; then
    echo "Tuist not found. Installing via Homebrew..."
    brew install tuist
else
    echo "Tuist found: $(tuist version)"
fi

# Install dependencies
echo "Installing dependencies..."
tuist install

# Generate Xcode project
echo "Generating project..."
tuist generate
