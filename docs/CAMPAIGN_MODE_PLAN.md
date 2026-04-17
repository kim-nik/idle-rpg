# Campaign Mode Plan

## Goal
- Replace the current endless-wave feel of the core loop with a chapter-based campaign structure.
- Keep the system simple: regular waves, one boss gate, deterministic rollback, and two automation toggles.
- Do not add extra gameplay systems beyond the campaign rules described here.

## Implementation Status
- [x] Chapter and wave campaign state
- [x] Boss unlock and boss fight state
- [x] Rollback on regular-wave defeat
- [x] Rollback from boss defeat to wave `10`
- [x] `20` enemies per regular wave
- [x] `10` maximum active enemies on screen
- [x] `Map` tab with manual wave and boss selection
- [x] `Settings` tab with `Auto Next Wave` and `Auto Start Boss`
- [x] Boss timeout defeat after `30` seconds
- [x] Campaign and automation save/load fields
- [x] Headless smoke coverage for campaign flow

## Scope
- Add chapter-based progression.
- Add boss access after regular wave completion.
- Add rollback rules on player defeat.
- Add a bottom `Settings` tab with two campaign automation toggles.
- Update `Map` to act as the manual campaign navigation surface when automation is disabled.

## Fixed Numbers
- `1` chapter = `10` regular waves + `1` boss encounter
- `1` regular wave = `20` enemies total
- Maximum enemies visible on screen at the same time = `10`
- Regular wave numbers inside a chapter = `1` to `10`
- Boss encounter count = `1` boss enemy
- Boss fight timer = `30` seconds
- `Auto Next Wave` default = `ON`
- `Auto Start Boss` default = `OFF`

## Terminology
- `Chapter`: one full campaign block of `10` regular waves and `1` boss fight
- `Regular Wave`: a normal combat wave with `20` enemies
- `Boss`: the chapter-ending fight that opens the next chapter

## Difficulty Rules

### Regular Wave Scaling
- Wave `1` multiplier = `1.00x`
- Each next regular wave in the same chapter adds `+10%`
- Formula:
- `regular_wave_multiplier = 1.00 + (wave_index - 1) * 0.10`
- Result:
- Wave `1` = `1.00x`
- Wave `2` = `1.10x`
- Wave `3` = `1.20x`
- Wave `4` = `1.30x`
- Wave `5` = `1.40x`
- Wave `6` = `1.50x`
- Wave `7` = `1.60x`
- Wave `8` = `1.70x`
- Wave `9` = `1.80x`
- Wave `10` = `1.90x`

### Chapter Scaling
- Chapter `1` base multiplier = `1.00x`
- Each next chapter adds `+25%`
- Formula:
- `chapter_multiplier = 1.00 + (chapter_index - 1) * 0.25`
- Result:
- Chapter `1` = `1.00x`
- Chapter `2` = `1.25x`
- Chapter `3` = `1.50x`
- Chapter `4` = `1.75x`

### Final Regular Enemy Multiplier
- Formula:
- `final_regular_multiplier = chapter_multiplier * regular_wave_multiplier`

### Boss Scaling
- Boss uses the current chapter baseline and replaces the regular wave multiplier with a fixed boss multiplier
- Boss HP multiplier = `3.00x`
- Boss damage multiplier = `1.75x`
- Boss armor multiplier = `1.50x`
- Boss regeneration multiplier = `1.50x`
- Boss count on screen = `1`
- Boss does not spawn together with regular enemies

## Wave Flow

### Chapter Start
- A new chapter always starts at regular wave `1`
- The first playable state of the game is:
- `Chapter 1, Wave 1`

### Regular Wave Clear
- Clearing a regular wave unlocks the next regular wave in the same chapter
- Wave `1` clear unlocks wave `2`
- Wave `2` clear unlocks wave `3`
- ...
- Wave `9` clear unlocks wave `10`
- Wave `10` clear unlocks the boss encounter for the current chapter

### Boss Clear
- Clearing the boss completes the current chapter
- After boss victory, the player advances immediately to:
- `Next Chapter, Wave 1`
- Example:
- `Chapter 1 Boss` clear -> `Chapter 2, Wave 1`

## Runtime States
- The campaign flow should use exactly `4` runtime states:
- `Regular Wave`
- `Boss Ready`
- `Boss Fight`
- `Defeat Recovery`

### Regular Wave
- Active while fighting wave `1` to `10`
- Uses the regular spawn pool of `20` enemies

### Boss Ready
- Reached only after clearing wave `10`
- If `Auto Start Boss = OFF`, the game remains in `Boss Ready`
- In this state, the boss stays unlocked for manual launch from `Map`
- In this state, combat should not silently start the boss

### Boss Fight
- Active while fighting the chapter boss
- Uses exactly `1` boss enemy
- Starts immediately when the boss encounter begins
- Starts a `30` second countdown
- If the timer reaches `0`, the boss fight counts as a defeat

### Defeat Recovery
- Temporary state after player death
- Ends when the target rollback wave or boss restart target is selected and loaded

## Defeat and Rollback Rules

### Regular Wave Defeat
- On defeat in wave `1`, restart at:
- `same chapter, wave 1`
- On defeat in wave `2`, restart at:
- `same chapter, wave 1`
- On defeat in wave `3`, restart at:
- `same chapter, wave 2`
- General rule:
- `defeat on wave N restarts the player at wave N-1`

### Boss Defeat
- On defeat during the boss fight, restart at:
- `same chapter, wave 10`

### Reset Precision
- Rollback always sends the player to the start of the target wave
- The restarted wave begins at:
- `0 / 20` defeated enemies
- Boss restart begins at:
- boss full HP

## Repetition and Automation Rules

### Auto Next Wave
- Toggle name:
- `Auto Next Wave`
- Default:
- `ON`
- Scope:
- Applies only to transitions between regular waves `1` to `10`

### Auto Start Boss
- Toggle name:
- `Auto Start Boss`
- Default:
- `OFF`
- Scope:
- Applies only to the transition from `Wave 10` to `Boss`

### Regular Wave Completion Behavior
- If `Auto Next Wave = ON`:
- after a successful clear of waves `1` to `9`, start the next unlocked wave automatically
- If `Auto Next Wave = OFF`:
- after a successful clear of waves `1` to `9`, repeat the same wave automatically

### Wave 10 Completion Behavior
- If `Auto Start Boss = ON`:
- after a successful clear of wave `10`, start the boss automatically
- If `Auto Start Boss = OFF`:
- after a successful clear of wave `10`, unlock the boss and keep farming by repeating wave `10` automatically until the player manually starts the boss from `Map`

### Manual Progression Rule
- Manual progression must always be possible through the `Map` tab
- If the game is repeating the same regular wave because automation is disabled, the player can manually select:
- the next unlocked regular wave
- the boss, if it is unlocked

## Spawn Rules
- Each regular wave contains exactly `20` enemies total
- At any moment, no more than `10` enemies may be alive on screen
- When the number of living enemies falls below `10`, the wave may spawn more enemies until the total wave budget of `20` is exhausted
- After `20` total enemies have spawned, the wave only waits for the remaining alive enemies to be defeated
- Boss encounters ignore the regular spawn pool and use exactly `1` boss

## UI Changes

### Bottom Tabs
- Current bottom tab set becomes:
- `Upgrades`
- `Abilities`
- `Map`
- `Settings`

### Bottom Tab Buttons
- The bottom navigation bar contains exactly `4` buttons:
- `Upgrades`
- `Abilities`
- `Map`
- `Settings`
- Each button switches immediately to its tab
- The active tab button must have a distinct selected state
- There is no hidden overflow menu for these `4` tabs

### Combat Header
- The combat area should show these campaign labels at all times:
- `Chapter N`
- `Wave X / 10` during regular waves
- `Boss` during boss-ready and boss-fight states
- `Defeated Y / 20` during regular waves
- Boss encounters should replace the regular enemy progress label with:
- `Boss Fight`

### Post-Combat Status Messaging
- After clearing wave `10` with `Auto Start Boss = OFF`, the UI should show:
- `Boss unlocked`
- After clearing a regular wave with `Auto Next Wave = OFF`, the UI should show:
- `Repeating wave`
- After player defeat, the UI should show:
- `Retrying Wave N`
- or
- `Retrying Chapter N Boss access from Wave 10`

### Settings Tab
- The new `Settings` tab contains exactly `2` campaign toggles:
- `Auto Next Wave`
- `Auto Start Boss`
- No additional gameplay controls are part of this task

### Settings Tab Controls
- `Settings` contains exactly `2` interactive controls:
- toggle: `Auto Next Wave`
- toggle: `Auto Start Boss`
- Each toggle also has a short one-line description:
- `Auto Next Wave`: `After a win, go to the next unlocked regular wave`
- `Auto Start Boss`: `After Wave 10, start the boss automatically`
- Toggle values are applied immediately when changed
- Toggle values persist in save data

### Map Tab Responsibility
- `Map` becomes the manual campaign navigation surface
- It should display:
- current chapter number
- current regular wave number or `Boss`
- unlocked regular waves `1` to `10`
- boss availability for the current chapter
- completed chapter marker

### Map Tab Layout
- `Map` contains these visible blocks:
- chapter title label: `Chapter N`
- current state label: `Current: Wave X` or `Current: Boss`
- regular wave grid: `10` wave buttons
- boss area: `1` boss button
- action area: `1` primary start button
- automation status summary:
- `Auto Next Wave: ON/OFF`
- `Auto Start Boss: ON/OFF`

### Regular Wave Buttons
- The regular wave grid contains exactly `10` buttons:
- `Wave 1`
- `Wave 2`
- `Wave 3`
- `Wave 4`
- `Wave 5`
- `Wave 6`
- `Wave 7`
- `Wave 8`
- `Wave 9`
- `Wave 10`

### Boss Button
- The boss area contains exactly `1` button:
- `Boss`
- Boss button states:
- `Locked`
- `Unlocked`
- `Current`
- `Cleared`

### Primary Start Button
- The action area contains exactly `1` primary button:
- `Start Selected`
- `Start Selected` is enabled only when the current selected node is playable
- Playable means:
- an unlocked regular wave
- or an unlocked boss

### Selection Rules
- Tapping a wave button selects that wave but does not start it immediately
- Tapping the boss button selects the boss but does not start it immediately
- Starting the selected node requires pressing `Start Selected`
- The selected button must have a highlighted visual state
- The current live progress node must have a separate `Current` visual state

### Manual Selection in Map
- If automation is disabled and the game keeps repeating the current wave, the player can move forward manually through the `Map` tab
- Manual selection rules:
- unlocked regular waves are selectable
- locked regular waves are not selectable
- boss is selectable only after wave `10` has been cleared in the current chapter
- the player may replay any unlocked regular wave in the current chapter
- the player may not manually jump to the next chapter without clearing the current boss

### Map Node States
- Regular wave button states:
- `Locked`
- `Unlocked`
- `Selected`
- `Current`
- `Cleared`
- Boss button states:
- `Locked`
- `Unlocked`
- `Selected`
- `Current`
- `Cleared`

### Navigation to All Modes
- The player must be able to reach every campaign-related mode through explicit buttons:
- `Upgrades` button -> upgrade mode
- `Abilities` button -> ability loadout mode
- `Map` button -> chapter/wave/boss selection mode
- `Settings` button -> automation settings mode
- `Wave 1` to `Wave 10` buttons -> wave selection mode inside the current chapter
- `Boss` button -> boss selection mode inside the current chapter
- `Start Selected` button -> enter the selected combat target

## Save Data
- Add campaign state fields with explicit defaults:
- `campaign_chapter = 1`
- `campaign_wave = 1`
- `campaign_in_boss = false`
- `campaign_highest_unlocked_wave = 1`
- `campaign_boss_unlocked = false`
- `campaign_selected_wave = 1`
- `campaign_selected_boss = false`
- `setting_auto_next_wave = true`
- `setting_auto_start_boss = false`

## Minimum Implementation Order
1. Replace raw endless wave state with chapter + wave + boss state
2. Enforce `20` total enemies per regular wave
3. Enforce `10` maximum alive enemies on screen
4. Add rollback-on-defeat rules
5. Add chapter completion and next chapter start
6. Update `Map` to show chapter/wave/boss selection
7. Add the bottom `Settings` tab
8. Add the `Auto Next Wave` and `Auto Start Boss` toggles
9. Add save/load support for campaign and settings state

## Explicit Non-Goals
- No new currencies
- No equipment system
- No quests
- No offline rewards
- No new side modes
- No guild, PvP, or social features
- No new combat mechanics outside wave/chapter/boss flow
