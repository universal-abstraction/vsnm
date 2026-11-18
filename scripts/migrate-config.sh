#!/bin/bash
#
# vsnm config migration script
#
# Rebuilds the user config from the current default config, keeping the
# user's values, renaming options that changed name, and dropping options
# that no longer exist. Function definitions (hooks such as rewind_hook)
# are copied over unchanged.
#
# Usage: migrate-config.sh [DEFAULT_CONFIG]
#   DEFAULT_CONFIG defaults to the installed copy in $XDG_DATA_HOME/vsnm.
#

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/vsnm"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/vsnm"
CONFIG_FILE="$CONFIG_DIR/config"
DEFAULT_CONFIG="${1:-$DATA_DIR/defaults/config}"

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

is_valid_option() {
    local opt="$1" valid
    for valid in "${VALID_OPTIONS[@]}"; do
        [[ "$opt" == "$valid" ]] && return 0
    done
    return 1
}

migrate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${GREEN}No existing config found. A fresh config will be created on first run.${NC}"
        return 0
    fi

    if [[ ! -f "$DEFAULT_CONFIG" ]]; then
        echo "Error: default config not found at $DEFAULT_CONFIG" >&2
        echo "Run 'make install' to install vsnm properly" >&2
        exit 1
    fi

    # Parse the existing config. Values are kept exactly as written
    # (quotes, variables and all), so sourcing the new config gives the
    # same result as before.
    declare -A user_values=()
    local deprecated_options=()
    local renamed_options=()
    local hooks=""
    local in_function=false
    local line name value new_name

    while IFS= read -r line || [[ -n "$line" ]]; do
        if $in_function; then
            hooks+="$line"$'\n'
            [[ "$line" =~ ^\} ]] && in_function=false
            continue
        fi

        # Function definition, e.g. "rewind_hook() {"
        if [[ "$line" =~ ^[[:space:]]*(function[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\) ]]; then
            hooks+="$line"$'\n'
            # One-line definitions end on the same line
            [[ "$line" =~ \}[[:space:]]*$ ]] || in_function=true
            continue
        fi

        # Assignment, e.g. NOTES_DIR="$HOME/notes"
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            name="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            new_name="${RENAMED_OPTIONS[$name]:-}"
            if [[ -n "$new_name" ]]; then
                renamed_options+=("$name -> $new_name")
                name="$new_name"
            fi

            if is_valid_option "$name"; then
                user_values["$name"]="$value"
            else
                deprecated_options+=("$name")
            fi
        fi
    done < "$CONFIG_FILE"

    # Build the new config: default config with the user's values put back
    local new_config="" key
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            key="${BASH_REMATCH[1]}"
            if [[ -n "${user_values[$key]+set}" ]]; then
                line="$key=${user_values[$key]}"
            fi
        fi
        new_config+="$line"$'\n'
    done < "$DEFAULT_CONFIG"

    if [[ -n "$hooks" ]]; then
        new_config+=$'\n'"# --- Hooks from your previous config ---"$'\n'"$hooks"
    fi

    # Nothing to do if the result is identical
    if [[ "$new_config" == "$(cat "$CONFIG_FILE")"$'\n' ]]; then
        echo -e "${GREEN}✓${NC} Config is up to date: $CONFIG_FILE"
        return 0
    fi

    echo "Migrating config: $CONFIG_FILE"
    echo ""

    local backup_file
    backup_file="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    echo -e "${GREEN}✓${NC} Backup created: $backup_file"

    printf '%s' "$new_config" > "$CONFIG_FILE"
    echo -e "${GREEN}✓${NC} Config migrated"

    if [[ ${#renamed_options[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Renamed options (migrated automatically):${NC}"
        printf '  • %s\n' "${renamed_options[@]}"
    fi

    if [[ ${#deprecated_options[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Removed options (no longer supported):${NC}"
        printf '  • %s\n' "${deprecated_options[@]}"
        echo ""
        echo "Their old values are in the backup file."
    fi

    if [[ -n "$hooks" ]]; then
        echo ""
        echo -e "${GREEN}Hooks preserved${NC} at the end of the config."
    fi
}

migrate_config
