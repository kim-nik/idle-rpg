# AGENTS.md — AI Agent Instructions

## Project Overview

**Engine:** Godot 4.x
**Language:** GDScript
**Platform:** Android
**Renderer:** Mobile

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
- Declare signals with `signal`
- Use `@onready` for node references when needed
- Use `func _ready()` for initialization
- Use `func _process(delta)` for per-frame logic
- Use `func _physics_process(delta)` for physics
- Groups: `get_tree().call_group("enemies", "die")`
- Autoloads: access through `/root/<AutoloadName>` or the configured singleton name

## Useful Commands

### Godot
```bash
godot                     # Open editor
godot --headless          # Run headless (for CI/scripts)
godot --check-only        # Syntax check scripts
```

### Git
```bash
git status                # Show working tree status
git diff                  # Show unstaged changes
git log --oneline -10     # Show recent commits
```

## Code Review Guidelines

When generating code, ensure:
1. Signals use Godot's `signal` syntax
2. Node paths use `$` or `get_node()` correctly
3. Physics uses `_physics_process` not `_process` for consistency
4. Memory management follows Godot 4 patterns (no `free()`)
5. Exports have proper hints for editor UI
6. Comments in English
7. Error handling with `push_error()` or `push_warning()`

## Good Practices

- Prefer small, focused scripts with a clear responsibility.
- Keep scene structure predictable and avoid fragile node-path dependencies.
- Prefer implementing UI, gameplay components, and entity composition in Godot scenes and built-in engine primitives first.
- Do not build scene structure primarily in code when it can be declared cleanly in `.tscn` scenes.
- Favor configuration and reusable helpers over duplicated logic.
- Make gameplay-related values easy to tune and keep magic numbers to a minimum.
- Use descriptive names for scenes, nodes, functions, and variables.
- When changing gameplay flow, verify both runtime behavior and saved-state interactions.
- Keep temporary debug code isolated and easy to remove or disable.

## Testing Requirements

- Always run relevant tests after code changes.
- Always add automated tests for new gameplay, UI, save, or progression behavior when the functionality is testable.
- When adding a new automated test case, register it in `scripts/smoke_test.gd` so it participates in the full test run.
- For this project, run the headless smoke test when the change can affect gameplay, scenes, autoloads, saves, or progression:
  - `godot --headless --path E:\android_game --scene res://scenes/SmokeTest.tscn`
- Fix any test failures or runtime errors found during verification before considering the task complete.
- If a test cannot be run in the current environment, state this explicitly and explain why.

## Plan Maintenance

- When working from a plan document such as `docs/STAGE_1_PLAN.md`, always mark completed items in that plan as part of the same task.
- Keep plan documents current so they reflect actual implementation status.

## Adding New Scenes

1. Create scene in Godot editor
2. Save to `scenes/` directory
3. Add to version control
4. Update this file only if project conventions or structure changed
