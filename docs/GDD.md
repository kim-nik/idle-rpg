# Game Design Document

## Purpose
- High-level GDD and feature checklist for the current idle RPG direction.
- Based on recurring idle RPG patterns from genre articles and game overviews.
- Status legend:
- `[x]` already implemented in the current project
- `[ ]` not implemented yet / planned later

## Product Direction
- Android-first idle RPG with auto-combat and short player sessions.
- Player agency should come mostly from long-term progression, build choices, and loadout management.
- The game should stay readable, lightweight, and comfortable for frequent mobile check-ins.

## High-Level Feature Checklist

### Core Loop
- [x] Auto-battle against waves of enemies
- [x] Permanent growth through gold and stat upgrades
- [x] Save/load persistence for core progression
- [x] Combat feedback for damage, crits, and ability impact
- [ ] Campaign mode with chapter progression, boss gate, rollback-on-defeat, and automation settings ([detailed plan](./CAMPAIGN_MODE_PLAN.md))
- [ ] AFK / offline reward collection on return
- [ ] Farm acceleration systems such as speed-up or auto-clear

### Hero Progression
- [x] Core combat stat progression
- [x] Ability library and 8-slot ability loadout
- [ ] Equipment / gear / runes
- [ ] Talent tree / ascension / awakening layer
- [ ] Prestige / rebirth / meta-reset loop
- [ ] Pets / summons / companions

### Build Depth
- [x] One main hero build shaped by upgrades and abilities
- [ ] Team-based hero roster
- [ ] Classes / roles / factions
- [ ] Formation or synergy-based team building

### Progression Structure
- [x] Endless wave-based progression
- [x] Tabbed lower UI shell for `Upgrades`, `Abilities`, and `Map`
- [ ] Real stage / chapter / map progression
- [ ] Boss waves and milestone gates
- [ ] Dungeons / towers / raids
- [ ] Daily challenges
- [ ] Story campaign or world exploration

### Economy and Retention
- [x] Single soft currency: gold
- [ ] Multi-currency economy
- [ ] Loot and material drops
- [ ] Quests / achievements / milestone rewards
- [ ] Daily login rewards
- [ ] Limited-time events
- [ ] Summon / gacha layer

### Social and Competitive
- [ ] PvP arena
- [ ] Guilds / guild bosses
- [ ] Leaderboards
- [ ] Async or co-op social features

### Presentation
- [x] Functional mobile UI with dedicated ability management
- [ ] Production-ready art for hero, enemies, and UI
- [ ] Stronger VFX / audio polish
- [ ] Story cutscenes or narrative delivery

## Current Project Snapshot
- The project already covers the MVP combat loop, upgrade economy, save migration, combat feedback, and ability loadout management.
- The next missing genre-defining layers are offline rewards, structured map progression, bosses, equipment, and repeatable side modes.
- For now, the game is closer to a single-hero idle battler than to a full roster-based idle RPG.

## Research Basis
- Common genre patterns were cross-checked against these articles:
- [Udonis: Types of Game Mechanics and How They Work](https://www.blog.udonis.co/mobile-marketing/mobile-games/game-mechanics)
- [Pocket Gamer: Clicker Knight is an essential idle RPG, out now on Android](https://www.pocketgamer.com/clicker-knight-incremental-idle-rpg/clicker-knight-is-an-essential-idle-rpg-out-now-on-android/)
- [Pocket Gamer: Summoners Era is a visually impressive idle RPG that's available now for iOS and Android](https://www.pocketgamer.com/summoners-era/summoners-era-is-a-visually-impressive-idle-rpg-thats-available-now-for-ios-and/)
- [Pocket Gamer: Mythic Heroes: Idle RPG hands on](https://www.pocketgamer.com/mythic-heroes/mythic-heroes-idle-rpg-hands-on-an-idle-game-thatl/)
- [Pocket Gamer: AFK Journey Review](https://www.pocketgamer.com/afk-journey/review/)

## Note
- This document is intentionally high-level.
- Detailed sub-systems, formulas, screens, and content plans should be added later only after the feature set is approved.
