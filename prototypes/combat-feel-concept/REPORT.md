# Concept Prototype Report: Combat Feel — Parry / Dodge Timing

> **Date**: 2026-05-28
> **Prototype Path**: Engine (Godot 4.6 GDScript)
> **Concept File**: design/gdd/game-concept.md

---

## Hypothesis

If the player faces a color-coded enemy with distinct light and heavy attack wind-ups,
they will learn to distinguish attacks and time parry/dodge responses within ~3 attempts —
confirmed if they correctly execute a parry or dodge within 3 deaths without external instruction.

---

## Riskiest Assumption Tested

The biggest risk was that a short, fixed parry timing window would feel either too
arbitrary (invisible, unlearnable) or too punishing to be worth attempting when a
safe dodge option exists. The prototype tested whether the window was legible enough
to learn without being so easy that it removed skill expression.

---

## Approach

Built a minimal 1v1 arena in Godot 4.6: colored-rectangle player with dodge roll
(I-frame window) and parry (fixed 0.35s tap window), vs. an Armored Knight enemy
that alternates light and heavy attacks with color-coded wind-up phases. No art, no
audio, no menus. A debug overlay displayed player and enemy state in real time.
Visual sword geometry (Line2D) was added mid-session after initial color-only testing
confirmed the timing window worked — the sword reinforced spatial read.

**Path chosen:** Engine
**Reason for path:** Feel IS the hypothesis. Browser latency would produce false
results for a timing-sensitive parry window.

**Shortcuts taken (intentional):**
- Colored rectangles for all characters (no sprites)
- Color-coded enemy body to telegraph attack phase (yellow = light wind-up, orange = heavy, red = live)
- Hardcoded spawn positions, no level design
- No stamina, stagger meter, audio, menus, or save state
- Single enemy type, fixed attack pattern
- Initial parry used hold-to-extend behavior (0.55s), corrected mid-session to fixed tap (0.35s)

---

## Result

Hypothesis **CONFIRMED**. Three deaths was sufficient for a new player to learn the
parry timing. Veteran action game players would likely learn within the first death.

The most rewarding moment was successfully parrying a light → heavy → light combo
in succession — chaining parries felt satisfying even with placeholder art, which is
a strong signal that the underlying mechanic has the reward loop the concept needs.

Two findings worth recording:
1. **Attack pattern predictability**: The strict light/heavy alternation was learned
   too quickly. Players stopped reading the enemy and started pattern-matching.
   Production enemy design will need varied or player-read attack sequencing.
2. **No stagger feedback**: Without a visible stagger meter or clear reward signal,
   the parry payoff felt incomplete. This was out of scope for this prototype but
   is a required element for production feel.

The color-coding worked as training wheels to prove the timing window is valid. It
would not ship — production will rely on sword animation read (wind-up angle, speed,
body weight shift) rather than body color to communicate attack type.

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | Engine (Godot 4.6) |
| Iterations to playable | ~3 (type error fixes, then hold-to-extend parry fix) |
| Prototype duration | 1 session |
| Playtesters | 1 internal |
| Feel assessment | Parry at 0.35s window: tight but learnable; 0.55s hold-to-extend was trivially easy and was cut |
| Hypothesis verdict | CONFIRMED |

---

## Recommendation: PROCEED

The parry timing window is learnable within the target attempt count, and chaining
parries felt rewarding enough to justify the mechanic's place as the high-skill,
high-reward defensive option. The dodge roll read as the safer, lower-reward alternative
without any explicit tutorialing — the risk/reward split is working at the mechanical
level.

---

## If Proceeding

- **Core tuning values discovered:**
  - Parry window: `0.35s` fixed tap (not hold-to-extend) — this is the baseline for production
  - Light wind-up: `0.55s` — readable without being slow
  - Heavy wind-up: `0.95s` — enough time to recognize and commit to a parry
  - I-frame window: starts `80ms` into dodge, lasts `220ms` — felt fair; dodge was never the "correct" answer, just the safer one
  - Hit stun: `0.35s` — punishing enough to matter, not so long it felt unfair

- **Assumptions confirmed:**
  - A short fixed parry window is learnable within 3 attempts against a basic enemy
  - Color alone communicates attack phase sufficiently at prototype level
  - The dodge/parry risk-reward split is legible without explicit instruction

- **Assumptions disproved:**
  - Hold-to-extend parry was the obvious first implementation but made the mechanic
    trivial — a fixed tap window is required for skill expression

- **Emergent mechanics:**
  - Parry chaining across a combo sequence felt distinctly more rewarding than single
    parries — consider whether production design formalizes combo parry windows or
    bonus rewards for consecutive parries

**Notes for GDD writing:**
- The stagger meter is a required production element; the payoff loop is incomplete without it
- Enemy attack patterns must be varied or player-readable — a fixed cycle is learned
  too quickly and eliminates the read-and-react skill the mechanic is built around
- Production parry feedback will depend entirely on animation quality; the color
  training-wheel approach proved the timing is valid, but animation must carry the
  full communication load in production

**Next steps:**
1. `/design-review design/gdd/game-concept.md`
2. `/gate-check`
3. `/map-systems`
4. `/design-system combat` — use parry window values (0.35s), I-frame values (80ms start / 220ms duration), and wind-up timings as baseline Tuning Knobs

---

## Lessons Learned

- **What assumptions were broken by actually building this?**
  Hold-to-extend parry felt natural to implement but completely undermined the mechanic.
  The timing constraint is the mechanic — without it, parry is just a stance with no skill.

- **What surprised us that didn't show up in the brainstorm?**
  Parry chaining across a combo emerged as the most satisfying moment, more so than
  any individual parry. This suggests the production design should explicitly reward
  consecutive parries rather than treating each as an isolated action.

- **What would we test differently next time?**
  Add a minimal stagger/reward signal (even a flash or a number) earlier in the session.
  The timing mechanics were proven, but the reward loop felt unfinished — testing both
  together in the same session would give a more complete read on the full feel.

---

> *Prototype code location: `prototypes/combat-feel-concept/`*
> *This code is throwaway. Never refactor into production.*
