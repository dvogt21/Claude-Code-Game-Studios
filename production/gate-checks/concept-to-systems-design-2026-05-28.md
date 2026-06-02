# Gate Check: Concept → Systems Design

**Date**: 2026-05-28
**Checked by**: gate-check skill
**Review mode**: lean (all four phase-gate directors ran)
**Verdict**: CONCERNS (accepted — advanced to Systems Design)

---

## Required Artifacts: 3/3 present

- [x] `design/gdd/game-concept.md` — complete concept document
- [x] Game pillars defined — 4 pillars + 5 anti-pillars (in concept doc)
- [x] Visual Identity Anchor section — present (one-line rule + 3 supporting principles)

## Recommended: present

- [x] Concept prototype with PROCEED verdict — `prototypes/combat-feel-concept/REPORT.md`

## Quality Checks

- [x] Core loop described and understood
- [x] Target audience identified (18–35, mid-core to hardcore)
- [x] Visual Identity Anchor has one-line rule + ≥2 supporting principles (has 3)
- [?] Game concept formally `/design-review`'d — NOT run (advisory, not blocking for this gate)

---

## Director Panel Assessment

### Creative Director — CONCERNS
Pillars faithfully represented, core fantasy preserved, combat-first MVP is correct.
Concern: Pillar 3 ("No One Fights Alone") — the game's #2 aesthetic and primary
differentiator — is its riskiest, last-validated system (all companion content
deferred to Vertical Slice).
- Schedule the Companion AI spike in parallel with MVP combat so a PIVOT is
  discoverable before VS scope locks.
- Resolve the healing-system decision (Estus / consumables / companion healing /
  regen) during the Health & Death GDD — it is entangled with Pillar 3.
- Resolve companion-gacha monetization before designing Companion Recruitment
  (gacha conflicts with the "companions are emotional anchors, not stat bonuses" pillar).
- Verify "stamina governs defense, not offense" survives the Combat/Stamina/Movement GDDs.

### Technical Director — CONCERNS
Decomposition sound, dependencies acyclic, prototype values carried forward correctly.
- **[FIXED]** Stagger System was tagged Gameplay in the Categories table but placed in
  the Presentation layer of the dependency map. Reclassified to Feature layer (with
  Skills & Abilities and Companion Recruitment) — stagger is authoritative gameplay
  state (gates the burst window), not presentation.
- Combat & Enemy AI GDDs should express physics-timing values as ranges pending Jolt
  determinism validation; the prototype validated 0.35s parry feel with colored
  rectangles, not Jolt hitbox/hurtbox determinism.
- GDDs must not bake in unverified Godot 4.4–4.6 API behavior — defer API claims to ADRs.
- Companion AI spike must gate VS scope (its GDD can be written first to scope the spike).

### Producer — CONCERNS
MVP sizing correct and disciplined; dependency order works for solo sequential work.
- The 3–5yr solo timeline is the dominant unmitigated scope risk — enforce tier
  boundaries as hard go/no-go gates.
- Author **MVP-tier GDDs only** this phase; defer VS/Alpha/Full to avoid paper-locking
  unvalidated design.
- VS tier clusters two L-effort systems (Class & Leveling, Companion AI) — require the
  Companion AI spike before VS commitment; design Warrior as a class template first.

### Art Director — CONCERNS
Section 1 is correct depth for this gate; Foundation/Core GDDs can start with zero art risk.
- Color System (Sec 4) and HUD Visual Direction (Sec 7) are empty but are consumed by
  the MVP Combat Feedback GDD and the HUD GDD — draft semantic combat/UI colors
  (HP, stamina, stagger, parry-success, burst-window) + a HUD visual stub before
  authoring those two GDDs to avoid rework.
- Shape Language (Sec 3) is a minor risk for the Enemy AI telegraph GDD — instruct
  authors to cite Principle 3's silhouette test rather than invent a shape vocabulary.

---

## Escalation

All four directors returned CONCERNS; none NOT READY. Per escalation rules, overall
verdict = minimum CONCERNS. No blocking issues; all concerns resolvable within the
Systems Design phase.

## Chain-of-Verification

5 questions checked — verdict unchanged (CONCERNS).
- [TOOL ACTION] Grepped the systems index: confirmed the Stagger layer inconsistency
  was real (now fixed).
- [TOOL ACTION] Confirmed game-concept.md and art-bible.md have real content (no FAIL
  condition softened into a CONCERN).
- No concern elevates to a blocker; all are independent and sequenced.

---

## Actions Taken at Gate

- Reclassified Stagger System, Skills & Abilities, Companion Recruitment to Feature
  layer in `design/gdd/systems-index.md` (dependency map + design order).
- Recorded TD-PHASE-GATE verdict in the systems index status header.
- Advanced `production/stage.txt` → `Systems Design`.

## Tracked Concerns (carry into Systems Design)

1. Schedule Companion AI spike in parallel with MVP combat (CD, PR, TD).
2. Resolve healing-system decision during the Health & Death GDD (CD).
3. Resolve companion-gacha monetization before Companion Recruitment design (CD).
4. Draft art-bible Color System (Sec 4) + HUD stub (Sec 7) before Combat Feedback / HUD GDDs (AD).
5. Author MVP-tier GDDs only this phase; defer VS/Alpha/Full (PR).
6. Combat/Enemy AI GDDs: timing values as ranges pending Jolt validation; no unverified 4.4–4.6 API claims (TD).
