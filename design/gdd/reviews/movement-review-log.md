# Review Log: Movement

## Review — 2026-06-01 — Verdict: MAJOR REVISION NEEDED → Revised in session

Scope signal: L
Specialists: game-designer, systems-designer, gameplay-programmer, qa-lead, creative-director
Blocking items: 14 | Recommended: 8
Summary: The GDD had a sound mechanical skeleton and well-specified I-frame formula, but contained a critical state table contradiction (JUMPING/FALLING listed as "no inputs" while horizontal movement was never suppressed in the rules), a conflation of PARRY_DURATION with PARRY_WINDOW (removing all parry punishment), a shared COYOTE_FRAMES constant coupling jump leniency to ladder re-grab suppression, no terminal velocity cap (Jolt tunneling risk), and eight acceptance criteria with structural defects. All 14 blocking items were resolved in the same session. Sprint was determined to be a universal Movement mechanic; design session pending before implementation.
Prior verdict resolved: N/A — first review

## Review — 2026-06-02 — Verdict: APPROVED (post-revision, same session)

Scope signal: L
Specialists: game-designer, systems-designer, gameplay-programmer, qa-lead, creative-director
Blocking items: 6 | Recommended: 8
Summary: Re-review triggered by Health & Death GDD approval (2026-06-02) which formally required Movement to add a HEALING state that did not exist. Other blockers included: Formula 3/2 safe ranges allowing barrier skip within documented bounds (DODGE_SPEED_MULTIPLIER ceiling tightened 3.0→2.5), PARRY_LOCKED floor-loss behavior undefined (resolved as transition-to-FALLING), JUMPING/FALLING no-combat-actions was an undocumented silent decision (labeled as deliberate MVP scope), and SPRINTING missing from state enum. All 6 blockers resolved in session including H&D AC-COMP-01 threshold correction (0.40→0.18). Prior revision work from 2026-06-01 held.
Prior verdict resolved: Yes — NEEDS REVISION → APPROVED (single-session revision pass)
