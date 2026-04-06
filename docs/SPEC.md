# Idle RPG Prototype - Specification

## Overview
- **Genre:** Idle RPG / Auto-battler
- **Platform:** Android (Godot 4.6.1, Mobile renderer)
- **Language:** GDScript
- **Core Loop:** Hero auto-attacks monsters → Earn gold → Buy upgrades → Repeat

## Screen Layout

```
┌─────────────────────────────────────┐
│           COMBAT ARENA              │  50% height
│  [Hero]  ───attack───>  [Monster]   │
│   HP Bar                    HP Bar  │
│                                     │
│         Wave: 1  Monster: 1/10      │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│            UPGRADE MENU             │  50% height
│                                     │
│   💰 Gold: 0                        │
│                                     │
│  [Damage    ]  Lv.1  Cost: 10      │
│  [AttackSpd ]  Lv.1  Cost: 15      │
│  [HP        ]  Lv.1  Cost: 12      │
│  [CritChance]  Lv.1  Cost: 20      │
│  [CritDmg   ]  Lv.1  Cost: 25      │
│                                     │
│  === Hero Stats ===                 │
│  ATK: 10  SPD: 1.0  HP: 100        │
└─────────────────────────────────────┘
```

## Core Features

### 1. Hero System
- Auto-attacks nearest monster at regular intervals
- Running animation (sprite animation loop)
- Attack animation (slash effect on attack)
- Health bar above hero
- Base stats: ATK=10, SPD=1.0, HP=100, CRIT_CHANCE=5%, CRIT_DMG=150%

### 2. Monster System
- Monsters spawn from right side
- Move toward hero
- Different types per wave:
  - **Slime** (Waves 1-3): HP=50, ATK=5, Gold=5
  - **Goblin** (Waves 4-6): HP=100, ATK=10, Gold=10
  - **Orc** (Waves 7-9): HP=200, ATK=20, Gold=20
  - **Demon** (Wave 10+): HP=500, ATK=50, Gold=50
- Health bar above monster
- Death animation (fade out)

### 3. Combat System
- Damage formula: `base_damage * (1 + upgrade_bonus)`
- Critical hit: `damage * crit_multiplier`
- Attack cooldown based on attack speed
- Monsters attack hero when in range

### 4. Wave System
- Each wave = 10 monsters
- 1 second delay between monsters
- 3 second delay between waves
- Wave number increases monster stats by 10%

### 5. Progression System (Upgrades)
| Upgrade | Base Cost | Cost Multiplier | Effect per Level |
|---------|-----------|-----------------|------------------|
| Damage | 10 | 1.5x | +10% base damage |
| Attack Speed | 15 | 1.6x | +10% attack speed |
| Max HP | 12 | 1.4x | +20 max HP |
| Crit Chance | 20 | 1.7x | +5% crit chance |
| Crit Damage | 25 | 1.6x | +25% crit multiplier |

### 6. Currency System
- Gold earned on monster kill
- Gold counter in UI
- Gold persists between sessions (save/load)

### 7. Save System
- Auto-save every 30 seconds
- Save on upgrade purchase
- Save: gold, upgrade levels, wave number

## Technical Implementation

### Scene Structure
```
Main (Node)
├── CombatArea (Node2D)
│   ├── Hero (Node2D)
│   │   ├── Sprite2D
│   │   ├── AnimationPlayer
│   │   └── HealthBar (ProgressBar)
│   ├── MonsterSpawner (Node)
│   └── Monsters (Node container)
└── UIArea (CanvasLayer)
    ├── GoldDisplay (Label)
    ├── UpgradeButtons (HBoxContainer/VBoxContainer)
    └── StatsDisplay (Panel)
```

### Scripts
| Script | Purpose |
|--------|---------|
| `main.gd` | Root controller, game state |
| `hero.gd` | Hero movement, attack logic |
| `monster.gd` | Monster AI, health, damage |
| `wave_manager.gd` | Spawn timing, wave progression |
| `upgrade_system.gd` | Upgrade logic, costs |
| `save_manager.gd` | Persistence |
| `ui_controller.gd` | UI updates |

### Godot Project Settings
- **Display/Width:** 1080
- **Display/Height:** 1920
- **Display/Stretch Mode:** viewport
- **Rendering:** Mobile (GLES3)

## Development Phases

### Phase 1: Core Loop
- [ ] Main scene with split layout
- [ ] Hero with auto-attack
- [ ] Basic monster spawning
- [ ] Damage and death handling
- [ ] Gold earning

### Phase 2: Progression
- [ ] Upgrade buttons
- [ ] Cost calculation
- [ ] Stats modification on upgrade
- [ ] UI feedback on purchase

### Phase 3: Polish
- [ ] Health bars
- [ ] Attack animations
- [ ] Death animations
- [ ] Wave progression text
- [ ] Save/Load system

### Phase 4: Mobile Export
- [ ] Export presets for Android
- [ ] Touch controls
- [ ] APK build test

## Placeholder Assets (Phase 1)
- Hero: Simple colored rectangle (pink)
- Monster: Simple colored rectangles (green=slime, brown=goblin, red=orc, purple=demon)
- Attack effect: White line/flash
- Health bars: Red/green progress bars

## Performance Targets
- 60 FPS on mid-range Android devices
- Minimal draw calls (batch similar sprites)
- Efficient collision detection (only check relevant range)