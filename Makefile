GODOT ?= godot
SRC   := src

# Run GUT unit tests headlessly.
# Requires Godot 4 in PATH and GUT installed at src/addons/gut/.
# On macOS (Steam): export GODOT="/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
test:
	@echo "→ Importing resources..."
	@cd $(SRC) && "$(GODOT)" --headless --import --quit --path . 2>/dev/null || true
	@echo "→ Running tests..."
	@cd $(SRC) && GODOT_DISABLE_LEAK_CHECKS=1 "$(GODOT)" --headless \
		--display-driver headless --audio-driver Dummy \
		--disable-render-loop --path . \
		-s res://addons/gut/gut_cmdln.gd \
		-gconfig=res://.gutconfig.json \
		-gexit

# Generate the Godot Theme resource from design tokens + Kenney assets.
# Run after changing ThemeBuilder.gd or design tokens.
theme:
	@echo "→ Importing resources..."
	@cd $(SRC) && "$(GODOT)" --headless --import --quit --path . 2>/dev/null || true
	@echo "→ Generating theme..."
	@cd $(SRC) && "$(GODOT)" --headless --script res://assets/ui/ThemeBuilder.gd --path . 2>/dev/null

.PHONY: test theme
