# Look & feel — design

Date: 2026-11-23. Approved in chat ("yes"). Project 1 of 2 (project 2: Sunny Dunes + new cards).

## Goal

Make every moment of a match feel physical and alive: hits that land, spells that look like
themselves, cards that move like cards, creatures with personality. All with code, shaders,
particles and the models' own animations; no new illustrated art. Budget: ≤ ~2 fps on the HD 620
at Low; effects scale down on Low.

## 1. Combat

- Wind-up: attacker crouches with a glint; the target braces and turns toward it.
- Impact by timing-bar result (Action.Hit): CRIT = long hit-stop, white flash on the target,
  star-spark ring, strong shake, "CRIT!" stamp, short slow-mo; NORMAL = medium; GLANCING = small
  puff, no shake.
- Knockback: the hit creature squashes and slides back, then springs home. Hit-back too.
- Damage numbers: bigger, punchier pop; crits big and gold.
- Death by cause: big hit (damage ≥ 4 or crit) → knocked flying, spinning into stars; frozen →
  shatter into ice shards; fire spell → burn to ash; venom → green melt (exists); else the
  current dissolve.
- Hero hit (human): portrait shake + red screen-edge flash.

## 2. Spells

- Cast sequence: the card flies to the screen centre, flips face up, glows in its land colour,
  then bursts into particles that become the spell (~0.5 s).
- Spell FX kit (`view/fx/spell_kit.gd`): comet projectile with trail, beam, rain, magic circle on
  the ground, buff aura, shield, swirl, vines/ground spikes, slash. Each spell maps to a recipe +
  land colours (`VisualDB.SPELL_FX`), so every spell looks like itself. New cards reuse the kit.

## 3. Cards & hand

- Draw: the card flies from the deck box into the hand with a flip.
- Playable cards: soft land-coloured glow edge.
- Creature play: the card hovers over the lane, bursts into a land-coloured puff and the creature
  drops out of it.
- Burned card (full hand): it burns away (fire dissolve).
- Turn start: magic gems fill with a sparkle. END TURN squishes when pressed.

## 4. Creatures alive

- Happy hop + hearts when played.
- Squash-and-stretch spring on landing, hitting, being hit.
- Look-at: creatures turn toward the card being dragged and toward an attacker.
- Allies cheer (Yes/Dance) after a kill or big hit; small creatures cower when a big enemy attacks
  nearby.
- Low health (≤ 30%): sweat drops and a wobble.

## Testing

Unit/playback tests per piece; screenshot checks per stage (desktop + Compatibility); fps on Low
against the base commit; full suite at the end.
