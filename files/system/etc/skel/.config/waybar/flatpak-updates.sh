#!/bin/bash

# Waybar Module for Flatpak updates

# Check if flatpak is installed
if ! command -v flatpak &>/dev/null; then
  echo "Error: flatpak is not installed."
  exit 1
fi

# Get list of packages to update
package_list=$(flatpak update --list)

# Count number of packages to update
package_count=$(flatpak update --list | wc -l)

# Set Waybar icon and tooltip
if [ "$package_count" -gt 0 ]; then
  icon=" $package_count"
  tooltip=$(echo "$package_list" | head -n 20 | sed -z 's/\n/\\n/g')
fi

# Output JSON for Waybar
echo "{ \"text\": \"$icon\", \"tooltip\": \"$tooltip\" }"
