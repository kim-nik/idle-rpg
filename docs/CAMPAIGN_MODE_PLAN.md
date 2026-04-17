# Campaign Mode Plan

## Goals

- Keep campaign progression chapter-based and deterministic.
- After every completed regular wave, launch a mandatory wave boss.
- Keep a separate Super Boss at the end of the chapter after Wave `10`.
- Preserve manual wave selection on the `Map` tab.
- Do not add a direct-launch button for wave bosses.

## Current Status

- [x] Chapter and wave persistence
- [x] Wave boss state and runtime flow
- [x] Super Boss unlock and fight state
- [x] Rollback after wave boss defeat
- [x] Rollback after Super Boss defeat
- [x] `Map` tab with manual wave selection
- [x] `Map` tab with manual Super Boss selection
- [x] `Settings` tab with `Auto Next Wave` and `Auto Start Super Boss`
- [x] Smoke tests for wave boss and Super Boss flow

## Campaign Structure

- `1` chapter = `10` regular waves + `9` mandatory wave bosses + `1` Super Boss
- Waves `1` to `9`:
  - clear regular enemies
  - enter a mandatory wave boss encounter
  - defeat the boss to unlock the next wave
- Wave `10`:
  - clear regular enemies
  - unlock or auto-start the Super Boss
  - defeat the Super Boss to complete the chapter

## Progression Rules

- The player can manually select any unlocked regular wave in the current chapter.
- The player cannot skip a queued wave boss.
- The player cannot manually jump to the next chapter.
- The `Map` tab keeps the Super Boss button only for the chapter-ending boss.
- Clearing a wave boss unlocks the next regular wave.
- Clearing the Super Boss advances to:
  - next chapter
  - wave `1`
  - no queued boss
  - no Super Boss unlock

## Boss Rules

### Wave Boss

- Triggered automatically after clearing waves `1` to `9`.
- Uses exactly `1` boss enemy.
- Uses a shorter timer than the chapter-ending Super Boss.
- Does not expose a direct start button in `Map`.
- On defeat:
  - stay in the same chapter
  - return to the same wave
  - require replaying that wave before moving on

### Super Boss

- Triggered after clearing Wave `10`.
- Uses exactly `1` boss enemy.
- Remains manually startable from `Map` when `Auto Start Super Boss = OFF`.
- On defeat:
  - stay in the same chapter
  - return to Wave `10`
  - clear the Super Boss unlock

## UI Rules

### Top Banner

- Regular wave: `Chapter N - Wave X/10`
- Wave boss: `Chapter N - Wave X Boss`
- Super Boss: `Chapter N - Super Boss`

### Status Text

- Wave boss queued: `Wave boss incoming. Clear it before selecting another wave.`
- Wave boss active: `Wave Boss timer: ...`
- Super Boss ready: `Super Boss unlocked. Start it from Map or keep farming Wave 10.`
- Super Boss active: `Super Boss timer: ...`

### Top Banner Boss Button

- When a wave boss is pending and `Auto Start Boss = OFF`, the current wave repeats.
- During that repeat, the top banner shows a `Boss` button.
- Pressing `Boss` starts the boss of the current wave immediately.
- The button hides as soon as the boss fight starts.
- The button appears again only after the player clears another regular wave and a new wave boss becomes available.

### Map Tab

- Shows the current chapter number.
- Shows `10` wave buttons.
- Shows one `Super Boss` button.
- Disables wave selection while a wave boss is queued or active.
- Keeps `Start Selected` for:
  - the chosen regular wave
  - the selected Super Boss

## Save Fields

- `campaign_chapter`
- `campaign_wave`
- `campaign_highest_unlocked_wave`
- `campaign_highest_cleared_chapter`
- `campaign_in_boss`
- `campaign_active_boss_kind`
- `campaign_pending_boss_kind`
- `campaign_boss_unlocked`
- `campaign_selected_wave`
- `campaign_selected_boss`
- `setting_auto_next_wave`
- `setting_auto_start_boss`

## Verification

- Run the full headless smoke test after gameplay or UI changes:
  - `godot --headless --path E:\android_game --scene res://scenes/SmokeTest.tscn`
