# AGENTS.md — AI Agent Instructions

## Project Overview

**Project Name:** godot_android_game
**Engine:** Godot 4.6.1 (stable)
**Language:** GDScript
**Platform:** Android (API 26+)
**Renderer:** Mobile (GLES3)

## Project Structure

```
android_game/
├── .godot/              # Generated, DO NOT commit
├── assets/              # Raw assets (sprites, audio) - create as needed
├── scenes/              # Game scenes (.tscn) - create as needed
├── scripts/             # GDScript files (.gd) - create as needed
├── resources/           # Resource files (.tres) - create as needed
├── project.godot        # Godot project config
├── export_presets.cfg   # Export settings (auto-generated)
├── icon.svg             # Project icon
└── AGENTS.md            # This file
```

## GDScript Conventions

### Naming
- **Classes:** PascalCase (`PlayerController`)
- **Functions:** snake_case (`get_player_input`)
- **Variables:** snake_case (`health_points`)
- **Constants:** SCREAMING_SNAKE_CASE (`MAX_SPEED`)
- **Signals:** past tense snake_case (`player_died`)

### Style
- Indent: 4 spaces (no tabs)
- Max line length: 120 characters
- Use `func` keyword for functions
- Use `var` for variables, `const` for constants
- Use `@export` for exported properties
- Use `pass` for empty function bodies

### Godot 4 Specific
- Always use `[signal]` to declare signals
- Use `@onready` for node references when needed
- Use `func _ready()` for initialization
- Use `func _process(delta)` for per-frame logic
- Use `func _physics_process(delta)` for physics
- Groups: `get_tree().call_group("enemies", "die")`
- Autoloads: access via `Singletons.name`

## Android Build Instructions

### Prerequisites
- Godot 4.6+ with Android export templates installed
- Android SDK with API 26+ (set via `ANDROID_HOME` or in Godot preferences)

### Build Commands
```bash
# Export debug APK via Godot editor
# Editor > Project > Export > Android > Export Project

# Or via command line (requires export templates)
godot --headless --export-release "Android" export/android_game.apk
```

### APK Output
- Debug APK location: configured in export_presets.cfg
- Signed release APKs for Play Store require signing config

## Useful Commands

### Godot
```bash
godot                     # Open editor
godot --headless          # Run headless (for CI/scripts)
godot --check_only        # Syntax check scripts
```

### Git
```bash
git status                # Show working tree status
git diff                  # Show unstaged changes
git log --oneline -10     # Show recent commits
```

## Code Review Guidelines

When generating code, ensure:
1. All signals are declared with `[signal]` decorator
2. Node paths use `$` or `get_node()` correctly
3. Physics uses `_physics_process` not `_process` for consistency
4. Memory management follows Godot 4 patterns (no `free()`)
5. Exports have proper hints for editor UI
6. Comments in English
7. Error handling with `push_error()` or `push_warning()`

## Adding New Scenes

1. Create scene in Godot editor
2. Save to `scenes/` directory
3. Add to version control
4. Update this file if adding new directory structure
