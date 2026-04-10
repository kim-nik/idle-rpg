# Architecture Notes

## Goal
- Keep gameplay behavior unchanged while making combat, runtime wiring, and UI easier to extend.
- Prefer explicit runtime dependencies over fragile relative node-path lookups.
- Keep feature additions local so new systems do not bloat `main.gd` and `ui_controller.gd`.

## Runtime Composition

### `Main`
- Acts as the composition root for the active scene.
- Wires together `Hero`, `WaveManager`, `UIArea`, monster container, and `AbilitySystem`.
- Owns only high-level orchestration such as attack polling and scene reload on death.

### `CombatFeedbackController`
- Owns floating combat text pooling.
- Owns ability impact icon pooling and reuse.
- Keeps visual combat feedback out of `main.gd`.

### `WaveManager`
- Owns wave state, spawn cadence, and persistence of wave progress.
- Accepts explicit runtime references to hero and monster container.
- Can still resolve scene references as a fallback for tests and editor-driven instantiation.

### `Monster`
- Owns movement, queue positioning, attack cadence, and death handling.
- Uses an injected hero reference when available.
- Falls back to scene resolution only when spawned outside the normal wave flow.

### `UIController`
- Owns tab state and view refresh.
- Uses data-driven button configuration for upgrades instead of hardcoded repetitive wiring.
- Delegates touch-versus-scroll interaction rules to `ScrollableButtonHandler`.
- Keeps its public API compatible with the smoke tests.

## Shared Services

### `GameServices`
- Central place for resolving autoloads:
  `SaveManager`, `UpgradeSystem`, `AbilitySystem`.
- Reduces repeated string paths across gameplay scripts.

### `SaveManager`
- Remains the persistence source of truth.
- Now exposes small mutation helpers for common save-data updates.

### `UpgradeSystem`
- Still stores upgrade formulas in one place.
- Now exposes display metadata alongside level/cost state for UI use.

### `AbilitySystem`
- Continues to own unlocked state, equipped state, cooldown state, and execution.
- Binds to the runtime scene through explicit references from `Main`.

## Extension Points
- Add a new upgrade by extending `UPGRADE_CONFIGS` and the matching UI row.
- Add a new passive or triggered ability through a new `AbilityDefinition` resource.
- Add new combat feedback types inside `CombatFeedbackController` instead of `Main`.
- Add new runtime actors by following the same explicit binding pattern used by `WaveManager` and `Monster`.

## Verification
- Headless smoke suite:
  `godot --headless --path E:\android_game --scene res://scenes/SmokeTest.tscn`
