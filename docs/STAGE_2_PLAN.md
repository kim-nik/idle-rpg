# Stage 2 - Mid-Core Progression

## Goal
- Expand the prototype from a solid combat/UI foundation into a retention loop with stronger progression choices.
- Add systems that increase player return value without destabilizing the existing Stage 1 gameplay flow.
- Keep implementation staged so each new system can be tested independently before the next one lands.

## Stage 2 Checklist
- [x] Add an ability library with data-driven ability definitions
- [x] Add an 8-slot ability loadout system
- [x] Ship the first passive and auto-cast abilities
- [x] Add ability management UI to the `Abilities` tab
- [ ] Add offline gold accumulation with claim flow
- [ ] Extend progression from raw waves into level and boss structure
- [ ] Add map progression UI for current level, cleared levels, and boss milestones
- [ ] Extend save data and migration paths for abilities, offline rewards, and level progression
- [ ] Add smoke and system tests for all Stage 2 progression features

## Implementation Plan

### 1. Ability Data Model
- [x] Define a shared ability definition format:
  id, name, description, icon, trigger type, cooldown, target rule, and scaling data
- [x] Store ability definitions in data-driven resources or dictionaries rather than hardcoding behavior in `hero.gd`
- [x] Separate unlocked state, equipped state, cooldown state, and effect logic
- [x] Reserve room for future manual abilities without requiring a rewrite of passive and auto abilities
- [x] Decide and document the initial trigger set:
  passive, periodic auto-cast, on-hit, on-kill, on-low-hp

### 2. Ability Runtime System
- [x] Add a dedicated ability system that owns ability evaluation and execution
- [x] Ensure combat scripts ask the ability system for modifiers instead of embedding one-off checks
- [x] Support passive stat modifiers that apply cleanly through the shared combat/stat pipeline
- [x] Support non-manual triggered abilities on a predictable update cadence
- [x] Add clear hooks for future combat events:
  hit dealt, hit taken, crit dealt, kill, wave start, and boss start

### 3. Ability Unlocks and Loadout
- [x] Add save-backed unlocked ability collection
- [x] Add 8 persistent ability slots
- [x] Define slot behavior for Stage 2:
  all 8 slots are shared loadout slots unless design changes later
- [x] Prevent invalid equip states and duplicate assignment rules according to the chosen design
- [x] Add equip, unequip, and swap operations that are safe to call from UI and tests

### 4. First Ability Content Pass
- [x] Implement a small starter set of abilities that prove the framework
- [x] Include at least one passive stat booster
- [x] Include at least one periodic auto-cast effect
- [x] Include at least one reactive trigger ability
- [x] Keep the first batch simple enough to balance with the current combat presentation
- [x] Validate that abilities interact correctly with armor, regen, crit, and future boss waves

### 5. Abilities Tab UI
- [x] Replace the placeholder `Abilities` tab with a real management screen
- [x] Show unlocked abilities in a scrollable library/list
- [x] Show 8 equipped slots in a mobile-friendly layout
- [x] Add a details panel or summary area with description, trigger type, and key stats
- [x] Support equip and unequip without deep modal chains
- [x] Keep combat visible and avoid shrinking the active gameplay area too aggressively

### 6. Offline Gold Model
- [ ] Add last-active timestamp and offline reward bookkeeping to save data
- [ ] Define a capped offline duration:
  use a simple first-pass cap such as 4 to 8 hours
- [ ] Base offline reward on stable progression data rather than replaying exact combat
- [ ] Choose a predictable reward input:
  highest cleared level or current level income tier
- [ ] Clamp invalid or abusive values defensively so clock changes do not produce extreme rewards

### 7. Offline Reward Flow
- [ ] Calculate offline reward on startup after save load and migration
- [ ] Add a claim popup or panel that shows elapsed time and gold earned
- [ ] Ensure rewards are granted once and cannot be re-claimed by reopening the same session state
- [ ] Keep the first version focused on gold only
- [ ] Make the claim flow safe if the player exits before interacting with the popup

### 8. Level Structure
- [ ] Replace raw endless-wave progression with explicit level progression data
- [ ] Define a level model with:
  level id, display name, wave count, enemy pool, boss id, reward modifiers, and unlock status
- [ ] Define a wave model with:
  monster count, spawn interval, stat scaling, elite chance, and special flags if needed
- [ ] Implement the baseline structure:
  10 normal waves followed by 1 boss wave per level
- [ ] Preserve current combat pacing as much as possible while migrating progression data

### 9. Boss Waves
- [ ] Add a boss wave state distinct from normal waves
- [ ] Add at least one boss gameplay hook that feels different from normal enemies
- [ ] Add boss start messaging or UI emphasis so the transition is readable
- [ ] Grant level-clear progress only after boss defeat
- [ ] Ensure boss progression integrates safely with save/load and offline reward logic

### 10. Map Tab Progression UI
- [ ] Replace the placeholder `Map` tab with a progression overview
- [ ] Show current level, current wave, boss wave state, and cleared milestones
- [ ] Show next unlock or next reward where possible
- [ ] Keep the layout readable on small mobile screens
- [ ] Make map state driven from progression data rather than duplicated UI state

### 11. Save Data and Migration
- [ ] Add save fields for unlocked abilities, equipped slots, progression state, last active time, and offline reward claim state
- [ ] Increment save version and add migration steps for all Stage 2 fields
- [ ] Ensure old Stage 1 saves load with safe defaults and no missing-key failures
- [ ] Validate that reset-progress behavior clears Stage 2 systems correctly
- [ ] Document any intentionally non-persistent runtime values such as temporary cooldowns

### 12. Testing
- [x] Add unit/system coverage for ability unlock, equip, and trigger behavior
- [x] Add tests for passive modifiers affecting hero stats through the shared combat pipeline
- [ ] Add tests for offline reward calculation, cap behavior, and one-time claim flow
- [ ] Add tests for level progression and boss-gated unlock flow
- [ ] Add UI smoke coverage for the populated `Abilities` and `Map` tabs
- [x] Register new automated tests in `scripts/smoke_test.gd`
- [x] Re-run the headless smoke test after each milestone that touches gameplay, scenes, saves, or autoloads

## Recommended Delivery Order
1. Save-data extension and migration scaffolding
2. Level and wave data model
3. Boss-wave progression and clear-state rules
4. Offline gold calculation and claim flow
5. Ability definition format and runtime system
6. Ability unlock/loadout persistence
7. Initial ability content pass
8. `Abilities` tab implementation
9. `Map` tab implementation
10. Test stabilization, balancing pass, and cleanup

## Notes For Implementation
- Save and migration scaffolding should land first because every other Stage 2 system depends on new persistent fields.
- Level structure should stabilize before offline gold, otherwise reward formulas will be tied to temporary wave logic and need rework.
- The first ability batch should stay passive and auto-driven; manual abilities can wait until the mobile HUD model is stronger.
- Offline rewards should use an intentionally conservative formula in the first pass to reduce exploit risk and balancing churn.
- `Abilities` and `Map` UI should consume shared progression data instead of owning game state directly.
- Boss implementation should prove progression gates and presentation, not maximize encounter complexity in the first version.
