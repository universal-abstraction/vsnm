#!/bin/bash
#
# vsnm config migration script
# Migrates user config to match current version's options
#

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/vsnm"
CONFIG_FILE="$CONFIG_DIR/config"
TEMPLATES_DIR="$CONFIG_DIR/templates"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Current valid config options (add new options here)
VALID_OPTIONS=(
    "NOTES_DIR"
    "EDITOR"
    "TERMINAL"
    "DATE_FORMAT"
    "MENU_LAUNCHER"
    "DAILY_TEMPLATE"
    "RECENT_LIST_ENABLED"
    "RECENT_LIST_COUNT"
    "RECENT_LIST_INCLUDE_CUSTOM"
    "RECENT_LIST_INCLUDE_TODAY"
    "RECENT_LIST_SORT"
    "CUSTOM_NOTES_ENABLED"
    "CUSTOM_NOTES_DATE_PREFIX"
    "CUSTOM_NOTES_TEMPLATE"
)

# Renamed options: OLD_NAME -> NEW_NAME
declare -A RENAMED_OPTIONS=(
    ["NOTE_TEMPLATE"]="DAILY_TEMPLATE"
    ["RECENT_NOTES_COUNT"]="RECENT_LIST_COUNT"
)

# Generate fresh config template
generate_template() {
    cat << 'EOF'
# vsnm configuration

# === General ===
# Notes directory
NOTES_DIR="$HOME/notes"
# Editor to use for editing notes
EDITOR="nvim"
# Terminal emulator
TERMINAL="kitty"
# Date format for note filenames (see 'man date')
# Examples: %Y-%m-%d (2024-12-15), %d-%m-%Y (15-12-2024)
DATE_FORMAT="%d-%m-%Y"
# Menu launcher: wofi, rofi, dmenu, or fzf
MENU_LAUNCHER="wofi"

# === Daily Notes ===
# Template for daily notes (from ~/.config/vsnm/templates/)
DAILY_TEMPLATE="daily"

# === Recent Notes List ===
# Show recent notes list in menu
RECENT_LIST_ENABLED=true
# Number of notes to show
RECENT_LIST_COUNT=10
# Include custom (non-daily) notes in the list
RECENT_LIST_INCLUDE_CUSTOM=false
# Include today's and tomorrow's notes in the list
RECENT_LIST_INCLUDE_TODAY=false
# Sort order: date_modified_desc, date_modified_asc,
#             date_created_desc, date_created_asc,
#             name_asc, name_desc
RECENT_LIST_SORT="date_modified_desc"

# === Custom Notes ===
# Show "New Note" option in menu
CUSTOM_NOTES_ENABLED=true
# Add date prefix to custom note filename
# true:  "29-12-2024_meeting.md"
# false: "meeting.md"
CUSTOM_NOTES_DATE_PREFIX=true
# Template for custom notes (from ~/.config/vsnm/templates/)
CUSTOM_NOTES_TEMPLATE="custom"

# === Hooks ===
# Custom rewind hook (uncomment to enable)
# rewind_hook() {
#     # Custom logic for rewinding notes
#     # $1 = source file, $2 = destination file
#     cat "$1" | sed 's/\[ \]/[ ]/g' > "$2"
# }
EOF
}

# Check if option is valid
is_valid_option() {
    local opt="$1"
    for valid in "${VALID_OPTIONS[@]}"; do
        [[ "$opt" == "$valid" ]] && return 0
    done
    return 1
}

# Get new name if option was renamed
get_new_name() {
    local opt="$1"
    echo "${RENAMED_OPTIONS[$opt]:-}"
}

# Extract option value from config line
get_option_value() {
    local line="$1"
    # Handle both quoted and unquoted values
    echo "$line" | sed 's/^[^=]*=//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//'
}

# Main migration function
migrate_config() {
    # Check if config exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${GREEN}No existing config found. Fresh config will be created on first run.${NC}"
        return 0
    fi

    echo "Migrating config: $CONFIG_FILE"
    echo ""

    # Create backup
    local backup_file="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    echo -e "${GREEN}✓${NC} Backup created: $backup_file"

    # Parse existing config
    declare -A user_values
    local deprecated_options=()
    local renamed_options=()

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Skip function definitions (hooks)
        [[ "$line" =~ ^[[:space:]]*(rewind_hook|.*\(\)) ]] && continue
        [[ "$line" =~ ^\} ]] && continue
        [[ "$line" =~ ^[[:space:]]+ ]] && continue

        # Extract option name
        local opt_name
        opt_name=$(echo "$line" | cut -d'=' -f1 | tr -d ' ')

        [[ -z "$opt_name" ]] && continue

        local opt_value
        opt_value=$(get_option_value "$line")

        # Check if option was renamed
        local new_name
        new_name=$(get_new_name "$opt_name")
        if [[ -n "$new_name" ]]; then
            renamed_options+=("$opt_name -> $new_name")
            user_values["$new_name"]="$opt_value"
            continue
        fi

        # Check if option is still valid
        if is_valid_option "$opt_name"; then
            user_values["$opt_name"]="$opt_value"
        else
            deprecated_options+=("$opt_name")
        fi
    done < "$CONFIG_FILE"

    # Generate new config with user values
    local new_config
    new_config=$(generate_template)

    # Replace default values with user values
    for opt in "${!user_values[@]}"; do
        local value="${user_values[$opt]}"
        # Escape special characters for sed
        local escaped_value
        escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')

        # Handle different value formats (quoted strings vs bare values)
        if [[ "$value" =~ ^\$ ]] || [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" =~ ^[0-9]+$ ]]; then
            # Unquoted value (variables, booleans, numbers)
            new_config=$(echo "$new_config" | sed "s/^${opt}=.*/${opt}=${escaped_value}/")
        else
            # Quoted string value
            new_config=$(echo "$new_config" | sed "s/^${opt}=.*/${opt}=\"${escaped_value}\"/")
        fi
    done

    # Write new config
    echo "$new_config" > "$CONFIG_FILE"
    echo -e "${GREEN}✓${NC} Config migrated successfully"

    # Report renamed options
    if [[ ${#renamed_options[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Renamed options (automatically migrated):${NC}"
        for opt in "${renamed_options[@]}"; do
            echo "  • $opt"
        done
    fi

    # Report deprecated options
    if [[ ${#deprecated_options[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Deprecated options (removed from config):${NC}"
        for opt in "${deprecated_options[@]}"; do
            echo "  • $opt"
        done
        echo ""
        echo "These options are no longer supported and have been removed."
        echo "Check the backup file if you need to reference old values."
    fi

    # Report migrated values
    if [[ ${#user_values[@]} -gt 0 ]]; then
        echo ""
        echo -e "${GREEN}Preserved user settings:${NC}"
        for opt in "${!user_values[@]}"; do
            echo "  • $opt = ${user_values[$opt]}"
        done
    fi

    echo ""
    echo -e "${GREEN}Migration complete!${NC}"
}

# Run migration
migrate_config
