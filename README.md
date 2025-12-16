# vsnm - very simple note manager

A minimal, keyboard-driven note management system for dmenu-like launchers (wofi/rofi/dmenu/fzf).

## Features

- **Quick access** via wofi/rofi/dmenu/fzf
- **Today/Tomorrow** shortcuts for daily notes
- **Rewind** - copy yesterday's note as today's template
- **Recent notes** - last 10 notes sorted by date
- **Browse** - open notes directory in terminal
- **Customizable** - templates, date format, editor, terminal
- **Extensible** - custom hooks for advanced workflows

## Requirements

- Bash 4+
- One of: `wofi`, `rofi`, `dmenu`, or `fzf`
- A terminal emulator (kitty, foot, alacritty, etc.)
- Optional: `notify-send` for notifications

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/vsnm.git
cd vsnm
make install
```

This installs `vsnm` to `~/.local/bin/` (ensure it's in your `$PATH`).

## Quick Start

Bind `vsnm` to a hotkey in your window manager:

**Hyprland:**
```
bind = SUPER, N, exec, vsnm
```

**Sway:**
```
bindsym $mod+n exec vsnm
```

**i3:**
```
bindsym $mod+n exec --no-startup-id vsnm
```

Press the hotkey and select:
- **Today** - Open/create today's note
- **Tomorrow** - Open/create tomorrow's note
- **Rewind** - Copy yesterday's note as template for today
- **Recent notes** - Your 10 most recent notes
- **Browse Notes** - Open notes directory in terminal

## Configuration

Configuration file is automatically created on first run at:
```
~/.config/vsnm/config
```

Edit this file to customize:

```bash
# Notes directory
NOTES_DIR="$HOME/notes"

# Editor
EDITOR="nvim"

# Terminal emulator
TERMINAL="kitty"

# Date format for filenames (see 'man date')
DATE_FORMAT="%d-%m-%Y"

# Menu launcher (wofi, rofi, dmenu, fzf)
MENU_LAUNCHER="wofi"

# Number of recent notes to show
RECENT_NOTES_COUNT="10"

# Default template name
NOTE_TEMPLATE="default"
```

## Templates

Templates are stored in `~/.config/vsnm/templates/`.

A default template is created automatically. You can create custom templates:

**Example:** `~/.config/vsnm/templates/daily.md`
```markdown
# Notes for {{DATE}}

## Morning routine
- [ ] Review yesterday
- [ ] Plan today

## Tasks


## Evening reflection

```

To use: set `NOTE_TEMPLATE="daily"` in your config.

### Template Variables

- `{{DATE}}` - Replaced with the note's date

## Advanced Configuration

### Custom Rewind Hook

You can define custom logic for the "Rewind" feature in your config:

```bash
rewind_hook() {
    local source="$1"
    local dest="$2"

    # Example: Copy only uncompleted tasks from yesterday
    grep '\[ \]' "$source" > /tmp/tasks
    sed "s/{{DATE}}/$(date +$DATE_FORMAT)/" "$TEMPLATES_DIR/daily.md" > "$dest"
    sed -i '/## Tasks/r /tmp/tasks' "$dest"
}
```

## Future Features

- CLI commands for creating/listing/searching notes
- More template variables
- Smart rewind modes
- Note search and filtering

## Uninstall

```bash
make uninstall
```

To also remove configuration:
```bash
rm -rf ~/.config/vsnm
```

## Architecture

`vsnm` is a single self-contained bash script (~350 lines) with:

- XDG-compliant paths (`~/.config/vsnm/`)
- Automatic config initialization
- Template system
- Extensible via hooks
- Clean section-based structure for easy maintenance

This makes it a perfect proof-of-concept for future migration to a compiled language.

## License

MIT

## Contributing

Pull requests welcome! Please open an issue first to discuss changes.
