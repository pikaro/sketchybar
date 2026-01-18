#!/bin/bash

# Copy link to icon_map.json from Github latest release:
# https://github.com/kvndrsslr/sketchybar-app-font/releases

FONT_VERSION="$(brew info font-sketchybar-app-font --json=v2 --cask | jq -r '.casks[0].version')"

if ! echo "${FONT_VERSION}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: Unable to determine font version from Homebrew." >&2
    exit 1
fi

exec >app_icons.lua

echo 'return {'

curl -L "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v${FONT_VERSION}/icon_map.json" | jq -r '.[] | .iconName as $icon | .appNames[] | { key: ., value: $icon } | "    [\"" + .key + "\"] = \"" + .value + "\","' | sort

echo '}'
