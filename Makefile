PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share/vsnm
SCRIPTSDIR = scripts

.PHONY: all install uninstall migrate-config lint help

all: help

help:
	@echo "vsnm - a minimal note manager"
	@echo ""
	@echo "Usage:"
	@echo "  make install        - Install vsnm and migrate an existing config"
	@echo "  make uninstall      - Remove installed files (keeps your config and notes)"
	@echo "  make migrate-config - Migrate an existing config to the current version"
	@echo "  make lint           - Run shellcheck"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX              - Installation prefix (default: ~/.local)"

install:
	@echo "Installing vsnm..."
	@mkdir -p $(BINDIR)
	@mkdir -p $(DATADIR)/defaults
	@mkdir -p $(DATADIR)/templates
	@cp vsnm $(BINDIR)/vsnm
	@chmod +x $(BINDIR)/vsnm
	@cp -r defaults $(DATADIR)/
	@cp defaults/templates/*.md $(DATADIR)/templates/
	@echo ""
	@echo "✓ Installed to $(BINDIR)/vsnm"
	@echo "✓ Data installed to $(DATADIR)"
	@echo ""
	@# Run config migration if config exists
	@if [ -f "$${XDG_CONFIG_HOME:-$$HOME/.config}/vsnm/config" ]; then \
		$(SCRIPTSDIR)/migrate-config.sh defaults/config; \
		echo ""; \
	else \
		echo "Configuration will be created on first run at:"; \
		echo "  ~/.config/vsnm/config"; \
		echo ""; \
	fi
	@echo "Add to your window manager config:"
	@echo "  Hyprland:  bind = SUPER, N, exec, vsnm"
	@echo "  Sway:      bindsym \$$mod+n exec vsnm"
	@echo "  i3:        bindsym \$$mod+n exec --no-startup-id vsnm"
	@echo ""
	@echo "Run 'vsnm --help' for more information"

uninstall:
	@echo "Uninstalling vsnm..."
	@rm -f $(BINDIR)/vsnm
	@rm -rf $(DATADIR)
	@echo "Removed $(BINDIR)/vsnm"
	@echo "Removed $(DATADIR)"
	@echo ""
	@echo "Note: Configuration at ~/.config/vsnm/ was preserved"
	@echo "To remove config: rm -rf ~/.config/vsnm"

migrate-config:
	@$(SCRIPTSDIR)/migrate-config.sh defaults/config

lint:
	shellcheck vsnm $(SCRIPTSDIR)/migrate-config.sh
