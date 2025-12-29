PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
SCRIPTSDIR = scripts

.PHONY: all install uninstall migrate-config help

all: help

help:
	@echo "vsnm - A minimal note management system"
	@echo ""
	@echo "Usage:"
	@echo "  make install        - Install vsnm and migrate config"
	@echo "  make uninstall      - Remove installed files"
	@echo "  make migrate-config - Migrate existing config to current version"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX              - Installation prefix (default: ~/.local)"

install:
	@echo "Installing vsnm..."
	@mkdir -p $(BINDIR)
	@cp vsnm $(BINDIR)/vsnm
	@chmod +x $(BINDIR)/vsnm
	@echo ""
	@echo "✓ Installed to $(BINDIR)/vsnm"
	@echo ""
	@# Run config migration if config exists
	@if [ -f "$(HOME)/.config/vsnm/config" ]; then \
		echo "Checking config..."; \
		echo ""; \
		$(SCRIPTSDIR)/migrate-config.sh; \
		echo ""; \
	else \
		echo "Configuration will be created automatically on first run at:"; \
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
	@echo "Removed $(BINDIR)/vsnm"
	@echo ""
	@echo "Note: Configuration at ~/.config/vsnm/ was preserved"
	@echo "To remove config: rm -rf ~/.config/vsnm"

migrate-config:
	@$(SCRIPTSDIR)/migrate-config.sh
