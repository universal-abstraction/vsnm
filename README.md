# vsnm — very simple note manager

[![shellcheck](https://github.com/universal-abstraction/vsnm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/universal-abstraction/vsnm/actions/workflows/shellcheck.yml)

A Bash script for daily and ad-hoc Markdown notes, driven from a dmenu-style
launcher (wofi, rofi, dmenu or fzf). Pick an entry and the note opens in your
editor in a new terminal window.

## Features

- **Today / Tomorrow**: open the daily note for that date, creating it from a
  template if needed.
- **Rewind**: start today's note from the most recent previous daily note.
- **New Note**: create a named note, optionally prefixed with today's date.
- **Recent notes**: the latest notes, with configurable count, filter and
  sort order.
- **Browse Notes**: list the notes directory in a terminal.
- Templates, date format, editor, terminal and launcher are configurable.
- A `rewind_hook` function in the config replaces the default Rewind logic.

## Requirements

- Linux with GNU coreutils and findutils (`date -d`, `stat -c`, `find -printf`)
- Bash 4+
- One of: `wofi`, `rofi`, `dmenu`, or `fzf`
- A terminal emulator (kitty, foot, alacritty, ...)
- Optional: `notify-send` for notifications

## Installation

```bash
git clone https://github.com/universal-abstraction/vsnm.git
cd vsnm
make install
```

This installs `vsnm` to `~/.local/bin/` (make sure it is in your `$PATH`) and
the default config and templates to `~/.local/share/vsnm/`. To install
elsewhere, set `PREFIX`, e.g. `make install PREFIX=/usr/local`.

If you already have a config, `make install` migrates it to the current
version: renamed options are carried over, removed ones are dropped, your
values and hook functions are kept, and a backup is written next to it. If
nothing needs to change, the config is left untouched.

## Usage

Bind `vsnm` to a key in your window manager:

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

The menu shows:
- **Today** — open or create today's note.
- **Tomorrow** — open or create tomorrow's note.
- **Rewind** — create today's note as a copy of the latest daily note from
  the past year, with the date in its first line updated. If today's note
  already exists, Rewind just opens it.
- **New Note** — ask for a name and create a note from the custom template.
- **Recent notes** — open one of the listed notes.
- **Browse Notes** — open the notes directory in a terminal.

With `MENU_LAUNCHER="fzf"`, run `vsnm` from a terminal: fzf needs one to draw
the menu.

## Configuration

On first run vsnm copies the default config to `~/.config/vsnm/config`
(`$XDG_CONFIG_HOME/vsnm/config`). The main options:

```bash
# Notes directory
NOTES_DIR="$HOME/notes"

# Editor and terminal emulator. Both may include flags,
# e.g. TERMINAL="alacritty -e".
EDITOR="nvim"
TERMINAL="kitty"

# Date format for daily note filenames (see 'man date')
DATE_FORMAT="%d-%m-%Y"

# Menu launcher: wofi, rofi, dmenu, or fzf
MENU_LAUNCHER="wofi"

# Templates for daily and custom notes
DAILY_TEMPLATE="daily"
CUSTOM_NOTES_TEMPLATE="custom"

# Recent notes list
RECENT_LIST_ENABLED=true
RECENT_LIST_COUNT=10
RECENT_LIST_INCLUDE_CUSTOM=false   # also list notes created with "New Note"
RECENT_LIST_INCLUDE_TODAY=false    # also list today's and tomorrow's notes
RECENT_LIST_SORT="date_modified_desc"

# Custom notes
CUSTOM_NOTES_ENABLED=true
CUSTOM_NOTES_DATE_PREFIX=true      # "18-11-2026_meeting.md" vs "meeting.md"
```

`RECENT_LIST_SORT` accepts `date_modified_desc`, `date_modified_asc`,
`date_created_desc`, `date_created_asc`, `name_asc` and `name_desc`. The
`date_created_*` modes use the file's birth time when the filesystem records
it and fall back to its change time otherwise.

Avoid `/` and `_` in `DATE_FORMAT`: `/` would create subdirectories, and `_`
separates the date from the name in custom notes.

## Templates

vsnm looks for a template in `~/.config/vsnm/templates/` first and then in the
installed templates, so you can override `daily.md` or add your own without
touching the installed files.

**Example:** `~/.config/vsnm/templates/journal.md`
```markdown
# Notes for {{DATE}}

## Morning routine
- [ ] Review yesterday
- [ ] Plan today

## Tasks


## Evening reflection

```

To use it, set `DAILY_TEMPLATE="journal"` in your config.

### Template variables

- `{{DATE}}` — the note's date, formatted with `DATE_FORMAT`
- `{{TITLE}}` — the name typed for a custom note, as entered

## Rewind hook

Define `rewind_hook` in your config to replace the default Rewind behaviour.
It receives the previous daily note and the path of today's note to create:

```bash
rewind_hook() {
    local source="$1"
    local dest="$2"

    # Start today's note with the unfinished tasks only
    {
        echo "# $(date +"$DATE_FORMAT")"
        echo
        echo "## Tasks"
        grep -- '- \[ \]' "$source" || true
    } > "$dest"
}
```

vsnm runs with `set -e`, so a command in the hook that fails stops vsnm; that
is why `grep` is followed by `|| true`.

## Roadmap

- CLI commands for creating, listing and searching notes
- More template variables

## Uninstall

```bash
make uninstall
```

Your config and notes are not removed. To also remove the configuration:

```bash
rm -rf ~/.config/vsnm
```

## License

MIT, see [LICENSE](LICENSE).

## Contributing

Pull requests are welcome. For larger changes, please open an issue first.
