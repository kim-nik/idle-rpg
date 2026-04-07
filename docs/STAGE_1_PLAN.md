# Stage 1 - System Foundation

## Goal
- Build the technical foundation for deeper combat, scalable UI, and future progression systems.
- Keep implementation incremental so the current prototype remains playable at every step.

## Stage 1 Checklist
- [x] Introduce a shared stat model for hero and monsters
- [x] Add armor to combat calculations
- [x] Add health regeneration
- [ ] Prepare save-data migration for new systems
- [x] Add reusable floating damage numbers
- [x] Expand combat feedback rules for crit, heal, and future dodge/block events
- [ ] Rework the lower panel into a tab-based UI shell
- [ ] Move the current upgrade screen into the new `Upgrades` tab
- [ ] Add placeholder `Abilities` and `Map` tabs
- [x] Add smoke-test coverage for the new combat/UI foundation

## Implementation Plan

### 1. Shared Stat Model
- [x] Define a common stat structure used by hero and monsters
- [x] Separate raw stats from derived combat values
- [x] Centralize formulas for damage, crit, armor, and regeneration
- [x] Ensure current upgrades continue to modify derived hero stats correctly

### 2. Armor
- [x] Add armor field to hero state
- [x] Add armor field to monster state
- [x] Define a predictable armor formula with safe cap behavior
- [x] Surface armor in debug output or UI where needed for balancing
- [x] Add tests for armor reducing incoming damage

### 3. Health Regeneration
- [x] Add regeneration stat for hero
- [x] Add regeneration stat for monsters if enabled by type/design
- [x] Decide tick cadence:
  per second is recommended for readability
- [x] Prevent regeneration from exceeding max HP
- [x] Add tests for regen behavior in and out of combat as designed

### 4. Save Preparation
- [ ] Add version field to save data if missing
- [ ] Add migration path for future fields
- [ ] Store defaults safely when loading older saves
- [ ] Verify old saves still load without crashes

### 5. Floating Damage Numbers
- [x] Create a reusable floating text scene
- [x] Show damage values when the hero hits a monster
- [x] Show damage values when a monster hits the hero
- [x] Use distinct styling for critical hits
- [x] Keep implementation lightweight enough for Android

### 6. Combat Feedback Rules
- [x] Standardize colors/styles for normal hit, crit, and healing
- [ ] Reserve styles for future `Dodge`, `Block`, and `Resist` events
- [ ] Avoid spawning excessive temporary nodes in dense combat

### 7. Tabbed Bottom Menu
- [ ] Create a persistent bottom tab bar
- [ ] Split content area from tab navigation
- [ ] Add `Upgrades` tab content scene
- [ ] Add placeholder `Abilities` tab content scene
- [ ] Add placeholder `Map` tab content scene
- [ ] Keep combat area visible while switching tabs

### 8. UI Refactor Safety
- [ ] Minimize direct node-path coupling between systems and UI tabs
- [ ] Route shared state through gameplay systems/autoloads
- [ ] Keep tab scenes modular so future tabs can be added without rewriting the shell

### 9. Testing
- [ ] Update smoke tests for the tab shell
- [x] Add tests for damage-number scene creation where practical
- [x] Re-run the headless smoke test after each combat/UI milestone

## Recommended Delivery Order
1. Floating damage numbers
2. Shared stat model
3. Armor
4. Regeneration
5. Save migration support
6. Tabbed bottom menu shell
7. Upgrade tab migration
8. Placeholder `Abilities` and `Map` tabs
9. Test stabilization and cleanup

## Notes For Implementation
- Floating damage numbers should land first because they improve balancing visibility with low risk.
- Shared stat logic should be added before more advanced progression systems to avoid duplicated combat formulas.
- The tab shell should be introduced before abilities and map content to prevent repeated UI rewrites.
- Save migration should be added early, even if only a small number of new fields are introduced at first.
