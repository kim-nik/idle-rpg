# UI Style Guide

## Purpose

This document defines the practical UI design rules for `android_game`.
It is based on the current implementation, the bundled Kenney UI pack, and the existing button theme already used in the project.

The goal is consistency first:

- readable on a phone in portrait
- fast to scan during combat
- easy to extend without inventing a new visual language for each screen

## Current Visual Direction

The project already uses three clear visual building blocks:

1. `Kenney` UI assets in [UI_kenney](E:/android_game/UI_kenney)
2. a custom textured button theme in [upgrade_button_theme.tres](E:/android_game/resources/upgrade_button_theme.tres)
3. simple flat color panels and separators in [Main.tscn](E:/android_game/scenes/Main.tscn) and [UI.tscn](E:/android_game/scenes/UI.tscn)

This gives the project a readable mobile arcade style:

- dark neutral background
- warm gold accent
- bright blue primary action buttons
- simple rectangular blocks with generous spacing

New UI should extend this style instead of replacing it.

## Core Principles

### 1. Readability Over Decoration

UI must remain legible during combat. Prefer:

- high contrast text
- large touch targets
- short labels
- one strong accent color at a time

Avoid:

- dense dashboards
- long multi-line button labels unless necessary
- low-contrast grey-on-grey text

### 2. One Screen, One Job

Each tab should have a narrow responsibility:

- `Upgrades`: buy and compare upgrades
- `Abilities`: loadout and ability inspection
- `Map`: campaign navigation
- `Settings`: runtime rules and toggles

If a screen starts mixing multiple jobs, split it instead.

### 3. States Must Be Obvious

Every interactive element must clearly show:

- available
- selected
- disabled
- current
- pending

If the player can misread a button state, the design is wrong even if the logic is correct.

## Color System

These colors are already established in scenes and should be treated as the base palette.

### Base Colors

- Arena background: `Color(0.16, 0.18, 0.22, 1)`
- Popup panel background: `Color(0.12, 0.14, 0.18, 1)`
- Accent gold: `Color(0.95, 0.75, 0.32, 1)`
- Divider gold alpha variant: `Color(0.95, 0.75, 0.32, 0.75)`

### Semantic Usage

- Blue: primary button actions and upgrade purchases
- Grey: disabled or unavailable states
- Gold: section dividers, current progress emphasis, important status accents
- Red: enemy danger, defeat, high-threat feedback
- Green: positive combat or success feedback

### Rules

- Do not introduce new primary UI colors unless there is a clear system-level reason.
- Gold should remain the global accent, not a general-purpose fill color.
- Disabled states should feel clearly unavailable, not merely “less important.”

## Typography

### Current Pattern

The project currently relies on large Godot label and button text with explicit font sizes.

Established sizes:

- `32`: popup title
- `30`: top combat banner
- `28`: main upgrade row action
- `26`: tab titles
- `24`: secondary large button text and section labels
- `22`: primary stats lines
- `20`: descriptive labels and popup metadata
- `18`: helper text and descriptions

### Typography Rules

- Keep combat-critical text at `22+`
- Keep tap targets readable without zoom
- Use title case or short sentence case consistently
- Avoid full uppercase for long labels

### Font Recommendation

If the project adopts a dedicated UI font later, use the bundled Kenney font family from:

- [Kenney Future.ttf](E:/android_game/UI_kenney/Font/Kenney%20Future.ttf)
- [Kenney Future Narrow.ttf](E:/android_game/UI_kenney/Font/Kenney%20Future%20Narrow.ttf)

Use one family project-wide. Do not mix multiple display fonts.

## Spacing and Layout

### Established Spacing

Current screens repeatedly use:

- `16` for section separation
- `10` for grid spacing
- `8` for grouped button spacing

This should remain the default layout rhythm.

### Touch Target Rules

Minimum practical heights already in use:

- `88` for main action buttons
- `72` for settings toggles
- `64` for tab bar buttons
- `144` for ability tiles

Do not introduce buttons smaller than these without a very good reason.

### Layout Rules

- Prefer vertical stacking for mobile
- Keep horizontal groups to small clusters only
- Preserve large bottom spacing in scroll views so the UI never feels clipped
- Use grids only when comparing equivalent items such as waves or ability slots

## Buttons

## Primary Button Style

The upgrade screen already defines the strongest reusable button pattern through [upgrade_button_theme.tres](E:/android_game/resources/upgrade_button_theme.tres).

It uses:

- textured blue normal, hover, pressed, and focus states
- grey disabled state
- dark readable text
- thick inner padding through `StyleBoxTexture`

This should be the default visual reference for future primary buttons.

### Button Categories

- Primary action:
  use blue textured or similarly strong high-contrast styling
- Secondary action:
  use plain Godot button styling only if it remains visually subordinate
- Disabled:
  use grey and remove ambiguity
- Dangerous:
  reserve red-toned treatment for destructive or high-risk actions only

### Button Copy

- Start with the action verb or the noun the player expects
- Keep labels short
- Put extra explanation in nearby helper text, not inside the button

Good:

- `Start Selected`
- `Boss`
- `Reset Progress`

Bad:

- `Tap Here To Start Fighting The Current Boss`

## Panels and Containers

### Preferred Look

- dark flat or near-flat panels
- subtle borders or separators
- gold accent for important edges and dividers

The popup panel in [UI.tscn](E:/android_game/scenes/UI.tscn) is the best current reference:

- dark background
- warm accent border
- rounded corners

Use that style as the base for future overlays and modal surfaces.

## Tabs

The current bottom tab bar is functional and should stay simple.

Rules:

- exactly one active tab at a time
- active state must be obvious
- avoid adding icon-only tabs
- labels should stay one line

If icons are added later, they should support the text, not replace it.

## Combat UI

Combat UI must remain the highest-priority readability zone.

### Top Banner

The top banner should only show:

- current chapter/wave or boss state
- short-time critical action, such as the temporary `Boss` button

Do not overload this area with secondary stats.

### Mid/Bottom Stats

Persistent combat stats belong in the lower panel:

- gold
- wave progress
- campaign status
- hero stats

This separation is good and should be preserved.

## Ability UI

The ability screen already implies a useful pattern:

- square-ish or tall cards
- consistent tile sizing
- grid comparison layout
- clear empty-slot placeholder

Future ability cards should include only:

- icon
- short name
- one cooldown/status line

Do not overload tiles with long descriptions.
Descriptions belong in the popup.

## Map UI

The map screen is a selection surface, not a decorative map.

That means:

- clear chapter status
- clear current vs selected distinction
- obvious locked/unlocked states
- no ornamental clutter

Wave buttons should remain uniform in size and grouped in a grid.
Boss actions should remain visually separate from wave actions.

## Motion and Feedback

Current UI is mostly static, which is acceptable for this project.

Recommended motion rules:

- use small, fast transitions only for feedback
- do not animate large layout shifts during combat
- prefer state clarity over polish

Good future additions:

- slight pressed feedback on important buttons
- fade/slide for popups
- short highlight when a state changes

Avoid:

- slow transitions
- decorative looping animation on HUD
- multiple animated surfaces competing for attention

## Asset Usage Rules

### Kenney Pack

Use Kenney UI assets as the default source for:

- buttons
- toggles
- icons
- decorative arrows or simple UI markers

When choosing variants:

- prefer one family of button shapes per feature area
- avoid mixing gloss, flat, line, and border treatments randomly
- prefer rectangle buttons for main menu and economy actions
- reserve round or square treatments for icon-like actions only

### Custom Asset Rule

If a new custom UI asset is introduced:

- it must match the current color system
- it must fit the same padding and border weight as existing buttons
- it should not look more detailed than the rest of the interface

## Implementation Rules for Future UI Work

- Reuse [upgrade_button_theme.tres](E:/android_game/resources/upgrade_button_theme.tres) or create sibling themes derived from the same logic.
- Keep layout constants aligned to `8 / 10 / 16`.
- Keep mobile-first portrait layout assumptions.
- Prefer scene-declared UI over large runtime-generated trees.
- Add tests for any new interaction-critical control.

## Default Checklist

Before shipping a new UI surface, verify:

- text is readable on a phone-sized portrait screen
- buttons are large enough to tap reliably
- disabled and selected states are visually distinct
- color usage matches the existing palette
- the screen has one clear primary action
- long descriptions are moved out of buttons and into labels/popups
- the new UI does not visually conflict with the existing upgrade button style
