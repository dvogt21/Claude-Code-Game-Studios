# Session State — Combat Feel Prototype

**Current task**: Prototype concluded — ready for design phase
**Phase**: COMPLETE
**Started**: 2026-05-28
**Concluded**: 2026-05-28

## Hypothesis
If the player fights an Armored Knight with two clearly telegraphed attacks
(short wind-up vs. long wind-up), and can roll-dodge or parry to avoid them,
then the timing window will feel learnable — we'll know this is true if the
player successfully avoids an attack by choice (not luck) within 3 attempts,
without being told what to press.

## Riskiest Assumption
The parry/dodge window isn't instinctive — if the player can't learn it in
a few tries with a simple enemy, the game doesn't work.

## Path
Engine — Godot 4.6 GDScript

## Scope
- Player: left/right movement, roll dodge (I-frames), shield parry (timing window)
- Enemy: Armored Knight, two attacks (Light Slash / Heavy Strike), color-coded wind-ups
- Visual feedback: color changes for all states, debug overlay ("PARRY WINDOW ACTIVE")
- 3-hit death → instant respawn, attempt counter
- NO: jump, stamina, stagger bar, multiple rooms, audio, menus, save/load

## Files
- prototypes/combat-feel-concept/project.godot
- prototypes/combat-feel-concept/main.tscn
- prototypes/combat-feel-concept/main.gd
- prototypes/combat-feel-concept/player.gd
- prototypes/combat-feel-concept/armored_knight.gd

## Status
[x] Write prototype files
[x] User runs and reports
[x] Iterate on feel (parry: removed hold-to-extend, tightened to 0.35s; added sword/shield visuals)
[x] Playtest debrief
[x] Generate REPORT.md

## Verdict
PROCEED — hypothesis confirmed, parry timing learnable within 3 deaths.
Key tuning values locked: parry 0.35s, I-frames 80ms/220ms, light wind-up 0.55s, heavy 0.95s.

## Next Step
/art-bible → /map-systems → /design-system combat
