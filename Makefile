.PHONY: install uninstall list

install:
	@bash install.sh

uninstall:
	@bash uninstall.sh

list:
	@echo "Available skills:"
	@for d in */; do [ -f "$$d/SKILL.md" ] && echo "  /$$( basename $$d )"; done
