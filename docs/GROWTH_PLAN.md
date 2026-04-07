# Idle RPG Prototype - Growth Plan

## Purpose
- This document expands the base prototype from [SPEC.md](/E:/android_game/docs/SPEC.md) into the next development stages.
- The goal is to define what should be added after the current MVP, why it is needed, and in what order it should be implemented.
- The plan is focused on gameplay depth, UI structure, content scalability, and production readiness for Android.

## Product Direction
- Keep the core loop simple: combat runs automatically, the player makes meaningful meta-decisions.
- Expand depth through stats, abilities, wave progression, and long-term retention systems.
- Preserve mobile-friendly interaction: large controls, low input complexity, readable combat feedback.
- Build systems in a way that supports future content additions without rewriting the foundations.

## High-Level Roadmap

- [ ] Stage 1. System Foundation
  - Extend hero and monster stats.
  - Prepare save format for future systems.
  - Add damage numbers and improved combat feedback.
  - Rework bottom menu into tabbed navigation.

- [ ] Stage 2. Mid-Core Progression
  - Add ability inventory and 8 active ability slots.
  - Add offline gold accumulation.
  - Expand wave progression into level structure with boss waves.

- [ ] Stage 3. Presentation Layer
  - Replace placeholder UI visuals with styled interface assets.
  - Replace primitive hero and monster visuals with proper art pipeline.
  - Add support for story cutscenes and scripted presentation moments.

## 1. Hero and Monster Stats

### Goal
- Make combat less flat than simple ATK/SPD/HP exchanges.
- Create more knobs for progression, enemy design, bosses, and abilities.

### Recommended Base Stat Set

#### Hero stats
- Health
- Armor
- Health regeneration
- Attack damage
- Attack speed
- Crit chance
- Crit damage
- Attack range
- Lifesteal
- Dodge chance
- Tenacity or status resistance

#### Monster stats
- Health
- Armor
- Health regeneration
- Attack damage
- Attack speed
- Movement speed
- Crit chance if needed for elite enemies
- Special resistance values if statuses are introduced later

### Combat Rules To Define
- Armor formula:
  damage reduction should be predictable and capped to avoid invulnerability.
- Regeneration:
  define whether it works every second, every attack cycle, or only out of combat.
- Lifesteal:
  should heal after final damage calculation.
- Dodge:
  should be rare and easy to read in combat feedback.
- Status resistance:
  only useful if stun, poison, burn, slow, or similar effects are planned.

### Implementation Notes
- Introduce a shared stat container/resource so hero and monsters use the same calculation pipeline.
- Separate:
  base stats, upgrade bonuses, temporary combat modifiers, and ability buffs.
- Keep derived values centralized to avoid duplicated formulas across scripts.

### Risks
- Too many stats too early can make balancing opaque.
- Flat bonuses from upgrades may stop scaling well once armor/regeneration are introduced.

### Recommendation
- First add armor and health regeneration.
- Add lifesteal and dodge only after combat feedback is clear enough to communicate them.

## 2. Hero Abilities

### Goal
- Add player choice beyond passive stat upgrades.
- Create build diversity and stronger mid-term progression.

### Core Concept
- The hero has 8 ability slots.
- The player unlocks abilities into a library/list.
- Any unlocked ability can be assigned to a slot, depending on slot rules.
- Abilities may activate:
  automatically, manually, conditionally, or on cooldown.

### Recommended Ability Model

#### Ability categories
- Active manual:
  player taps a button to trigger the skill.
- Active auto-cast:
  skill triggers automatically when ready.
- Passive:
  permanently modifies stats or rules.
- Triggered reactive:
  fires on hit, on kill, on low HP, on crit, or on wave start.

#### Example abilities
- Power Strike:
  next hit deals bonus damage.
- Whirlwind:
  area damage around the hero.
- Shield Wall:
  temporary armor boost.
- Blood Pact:
  convert part of damage dealt into healing.
- Fire Nova:
  periodic AoE pulse.
- Execute:
  bonus damage to low-HP enemies.
- Rage:
  attack speed increases below a health threshold.

### Slot Rules To Decide
- Are all 8 slots identical, or split into active/passive/utility types?
- Can the same ability be equipped more than once?
- Can abilities be leveled independently?
- Is there a resource cost, or only cooldown?

### UI Requirements
- Ability tab with:
  list of unlocked abilities, slot grid, ability details, equip/unequip actions.
- Optional combat HUD:
  if manual skills are supported, show large cooldown buttons during combat.

### Save Requirements
- Unlocked abilities
- Equipped abilities by slot
- Ability levels if progression is added
- Cooldowns should normally not persist between sessions unless there is a strong design reason

### Technical Notes
- Each ability should be data-driven:
  id, name, description, icon, cooldown, trigger type, targeting rule, scaling values.
- Execution should go through a common ability system instead of custom per-skill wiring inside `hero.gd`.

### Recommendation
- Start with auto and passive abilities first.
- Add manual abilities only after the bottom menu and combat HUD are stable on mobile.

## 3. Bottom Menu Tabs

### Goal
- Turn the lower half of the screen into a scalable navigation area.
- Avoid overloading one screen as more systems are added.

### Required Tabs
- Upgrades:
  current progression screen.
- Abilities:
  slot management and skill list.
- Map:
  wave/level progression overview.

### Future Tabs
- Inventory
- Quests
- Crafting
- Story or Codex
- Settings if needed inside game flow

### UX Principles
- Persistent tab bar at the bottom.
- One active content panel above it.
- Keep combat visible while the player navigates tabs.
- Avoid deep modal chains for core systems.

### Technical Structure
- Replace the current single panel layout with:
  `TabBar` + `ContentStack`.
- Each tab should be its own scene/controller.
- Shared state should come from game systems, not from tab-to-tab direct references.

### Recommendation
- Implement tab infrastructure before adding abilities and map features.
- This reduces future UI rewrites.

## 4. Offline Gold Accumulation

### Goal
- Reward returning players and support idle progression.

### Core Rules To Define
- Gold accumulates while the game is closed.
- Calculation should be limited by a maximum offline duration.
- Reward can be based on:
  current wave income, recent average kill rate, or a simplified formula.

### Recommended Version 1
- Store timestamp on exit/save.
- On next launch, calculate elapsed time.
- Clamp offline time to a safe cap, for example 4 to 8 hours.
- Grant gold based on the highest cleared level or current farming strength.

### UI Requirements
- Return popup on login:
  offline duration, gold earned, claim button.
- Optional multiplier later:
  watch ad, premium bonus, or special talent.

### Save/Data Requirements
- Last active timestamp
- Highest cleared level or reference income tier
- Optional anti-cheese validation fields if clock manipulation becomes a concern

### Risks
- Device time manipulation can be abused.
- Current wave state may be too volatile for exact simulation.

### Recommendation
- Use an intentionally simple formula first.
- Tie offline reward to stable progression milestones rather than exact combat replay.

## 5. Wave and Level Structure

### Goal
- Convert endless waves into clearer progression blocks with milestones.

### Proposed Structure
- 1 level = 10 normal waves + 1 boss wave.
- After boss defeat, the player unlocks the next level.
- Each level can have:
  a visual theme, enemy pool, boss mechanics, and reward table.

### Benefits
- Easier pacing and tuning
- Better sense of progress
- Clearer unlock conditions for content, abilities, and story beats

### Content Structure

#### Level data should define
- Level id
- Display name
- Theme/background
- Normal enemy pool
- Boss id
- Wave count
- Reward modifiers
- Unlock requirements

#### Wave data should define
- Monster count
- Spawn interval
- Elite chance
- Stat multiplier
- Special conditions if needed

### Boss Design Requirements
- Boss must feel distinct from normal monsters.
- Boss should have at least one gameplay hook:
  burst attack, shield phase, summon phase, enrage, heal, or stun.
- Boss wave should be clearly announced in UI and combat presentation.

### Map Integration
- Map tab should show:
  current level, cleared levels, boss status, and next rewards.

### Recommendation
- Move current endless progression into explicit `LevelData` and `WaveData` definitions before adding many enemy types.

## 6. Damage Numbers

### Goal
- Make combat readable and satisfying.
- Surface the impact of upgrades, crits, armor, and future abilities.

### Required Behaviors
- Show floating numbers on hit.
- Crit hits should look distinct.
- Healing should use a different color/style.
- Miss, dodge, block, or resisted hits should have their own small text styles if those systems are added.

### Presentation Recommendations
- Normal damage:
  compact white or yellow text.
- Crit damage:
  larger size, brighter color, slightly stronger motion.
- Healing:
  green text rising upward.
- Avoid too many simultaneous labels on low-end devices.

### Technical Notes
- Use a reusable damage-number scene instead of creating raw labels directly in the main script.
- Pool instances if combat density increases.
- Animate with tween or `AnimationPlayer`.

### Recommendation
- This should be implemented early because it improves debugging and balancing in addition to player feedback.

## 7. UI Graphics

### Goal
- Replace raw default controls with a coherent visual identity.

### Scope
- Panel backgrounds
- Buttons and states
- Tab bar icons
- Currency display
- Progress bars
- Boss warnings
- Ability icons and frames
- Popup windows

### Art Direction Questions
- Clean fantasy
- Dark fantasy
- Cartoon mobile
- Retro RPG

### Recommended UI Asset Strategy
- Build a small reusable UI kit first:
  panel, primary button, secondary button, icon frame, tab item, progress bar, modal frame.
- Use 9-slice compatible assets where possible.
- Keep text readable on small mobile screens.

### Technical Notes
- Move away from raw default theme values toward a project theme resource.
- Define color, spacing, fonts, and states centrally.
- Avoid baking layout logic into textures.

### Recommendation
- UI art should start after the tab structure is stable.
- Otherwise asset work will be redone during layout changes.

## 8. Hero and Monster Graphics

### Goal
- Replace placeholder primitives with proper visual content while keeping production scope realistic.

### Scope
- Hero idle/attack/hit/death visuals
- Monster variations by archetype
- Boss visuals
- Attack effects
- Hit effects
- Environment/background elements

### Content Strategy Options

#### Option A. Stylized 2D sprites
- Lowest integration complexity
- Good fit for mobile idle RPG

#### Option B. Cutout characters with limited animation
- Faster production than full frame-by-frame
- Easier to scale content quantity

#### Option C. Simple skeletal setup
- Better reuse but higher setup overhead

### Recommendation
- For this project, stylized 2D sprites or cutout animation is the most practical path.

### Technical Notes
- Separate gameplay logic from visuals now so art swap is low risk later.
- Scene structure should support replacing `Polygon2D` placeholders with `Sprite2D` or animated nodes without rewriting combat code.
- Keep monster archetypes data-driven so visuals and stats are not tightly coupled.

## 9. Story Cutscenes

### Goal
- Add narrative delivery without turning the project into a dialogue-heavy RPG.

### Use Cases
- Intro scene before first battle
- Boss introductions
- Level completion story beats
- Unlocking a new region
- Major system unlocks such as abilities

### Supported Formats
- Static illustrated panels with text
- Character portraits with dialogue
- Camera pans over combat scene
- Short scripted in-engine sequences

### Recommended Version 1
- Lightweight cutscene system with:
  background image, speaker name, text, portrait, next button, skip button.
- Triggered from progression milestones.

### Technical Notes
- Keep cutscene content data-driven:
  sequence id, ordered steps, assets, text, transitions, trigger condition.
- The game must be able to pause combat safely when a blocking cutscene opens.
- Save system should record viewed cutscenes to avoid forced repetition.

### Recommendation
- Implement story support after level progression exists, so cutscenes attach to concrete milestones.

## Cross-System Dependencies

### Recommended build order
1. Bottom menu tabs
2. Shared stat system
3. Damage number system
4. Level and boss structure
5. Offline gold
6. Ability system and slots
7. UI graphics
8. Character and monster graphics
9. Story cutscene framework

### Why this order
- Tabs are foundational for the UI architecture.
- Stats must be unified before abilities and bosses add more modifiers.
- Damage numbers help tune new combat rules.
- Level structure gives a framework for map, bosses, rewards, and story.
- Offline gold depends on stable progression rules.
- Art and cutscenes should follow stable gameplay/UI structure.

## Suggested Milestones

### Milestone A. Combat Depth
- Add armor and regeneration.
- Add reusable damage numbers.
- Refactor combat calculations into shared stat logic.

### Milestone B. UI Expansion
- Add bottom tab bar.
- Move current upgrade panel into a dedicated tab.
- Add placeholder tabs for abilities and map.

### Milestone C. Structured Progression
- Add levels with boss waves.
- Add map screen for progression overview.
- Add reward hooks for level completion.

### Milestone D. Retention Features
- Add offline gold rewards.
- Add entry popup and claim flow.

### Milestone E. Build Diversity
- Add ability library.
- Add 8-slot loadout screen.
- Add first batch of passive and auto abilities.

### Milestone F. Presentation Upgrade
- Apply UI theme and graphic assets.
- Replace primitive character visuals.
- Add first cutscene sequences.

## Open Design Questions
- Should abilities be unlocked by level progress, currency, drops, or quests?
- Should bosses be replayable for farming?
- Should offline rewards simulate only gold, or also wave progress/materials later?
- Are manual abilities required for the core target experience, or are they optional depth?
- Does armor reduce flat damage or percentage damage?
- Should story scenes be skippable and replayable from a gallery?

## Practical Next Step
- The next implementation document should break Stage 1 into concrete engineering tasks:
  data structures, scene changes, save migration, UI architecture, and test coverage.
