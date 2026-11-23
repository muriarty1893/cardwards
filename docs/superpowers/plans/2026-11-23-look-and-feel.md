# Look & feel — plan

Spec: `docs/superpowers/specs/2026-11-23-look-and-feel-design.md`. Branch `feat/look-and-feel` (from master 95be9c4).
Native execution, self-approved (user's standing instruction). Ledger `.superpowers/sdd/2026-11-23-look-and-feel/progress.md`.
Suite: `timeout 1800 godot --headless --path . --script res://tests/run_tests.gd`. Screens: `--demo-keywords --demo-act=…`, `--zoom=1.0`, `--shot-frames=N`.

## Stage A: combat
1. Impact tiers by hit (hit-stop, flash, spark ring, shake, CRIT stamp, slow-mo) in FxDirector attack_hit / EventPlayer.
2. Wind-up glint + target brace/turn; knockback squash-slide-spring on hit and hit-back.
3. Damage numbers: bigger pop, crit gold.
4. Death variants (knock-flying, shatter, ash) chosen from the batch (crit/big hit, frozen, fire spell).
5. Human hero hit: portrait shake + red edge flash (ScreenFlash).

## Stage B: spells
6. Cast sequence (card to centre, flip, land glow, burst).
7. `view/fx/spell_kit.gd` recipes (comet, beam, rain, circle, aura, shield, swirl, vines, slash) + `VisualDB.SPELL_FX` per spell; FxDirector uses them for spell sources.

## Stage C: cards & hand
8. Draw flight deck box → hand with flip; playable glow; burned card fire-dissolve.
9. Creature play puff over the lane; gem fill sparkle; END TURN squish.

## Stage D: creatures alive
10. Spring squash/stretch helper on CreatureView; happy hop + hearts on play.
11. Look-at drag card / attacker; cheer and cower reactions; low-health sweat + wobble.

## Stage E: finish
12. Full suite, Compatibility screenshots, fps vs base on Low, self-review, ledger.
