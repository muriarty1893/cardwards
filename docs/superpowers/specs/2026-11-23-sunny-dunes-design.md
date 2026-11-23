# Sunny Dunes and new cards — design

Date: 2026-11-23. Approved in chat ("yes"). Project 2 of 2 (after Look & feel).

## Goal

A fifth land with its own look, creatures, quirk, reactions, field and pre-built deck, plus
about 30 new cards (14 Dunes, 4 per other land) with two new keywords and more Dream Up
(Discover) cards. Every deck should win 40–60% in AI-vs-AI simulations.

## 1. The land

- `CardData.Land.DUNES = 5`, appended after NEUTRAL (4) so existing data and the board shader's
  Meadow value are unchanged. `CardData.REAL_LANDS = [0, 1, 2, 3, 5]` replaces "the first four".
  Name "Sunny Dunes"; card colour warm gold-orange.
- Home quirk **Sun-baked**: at the start of your turn, your hero gains 1 armour per creature of
  yours at home on a Dunes lane.
- Reactions: an Ember spell on a Dunes lane → **Scorch** (+1 damage); a Dunes spell on a Frost lane
  → **Thaw** (unfreeze, heal 2).
- Field **Heatwave**: at the end of each turn, every creature not at home takes 1 damage.
- Board: sand lanes with wind ripples and darker sand drifts, three looks (dune ripples,
  sandstone ruins with pillars, oasis with a small pond and palms/cacti); procedural cacti,
  sandstone pillars and bleached rocks as set pieces; drifting sand motes and heat shimmer as
  ambient; field tint warm.
- Card back for Dunes decks: a generated golden sun over dunes in the style of the others.

## 2. Keywords

- **Sturdy**: takes 1 less damage from every hit.
  Exact rule: each time it would take damage, that damage is reduced by 1 (to a minimum of 0).
- **Bask**: at the end of your turn, if it didn't attack this turn, it gets +1/+1.
- Both: icon, colour, KeywordNotes text, tag chip, AI value; looks: Sturdy = stone plating
  shimmer on the body; Bask = a warm sun glow ring (and a sparkle when it grows).

## 3. Cards (about 30)

- 14 Sunny Dunes cards: ~8 creatures (Sturdy / Bask / armour / Dream Up), 2–3 buildings
  (armour watchtower, buff obelisk), 3 spells (incl. a Dream Up spell), field Heatwave.
- 4 per other land (16): each land gets 1–2 Dream Up cards and a few Sturdy/Bask users.
- Models: new free Quaternius models where possible, recoloured; buildings reuse building models
  in sandstone tints. Card art baked like the others. Spells get SpellKit recipes.

## 4. Decks

- Pre-built **Sun Fortress** (Sunny Dunes + Mushroom Forest), in deck choice, the deck builder and
  the AI rotation. The deck builder offers Dunes cards and Dunes lanes.

## 5. Balance

AI-vs-AI (Medium) over all five decks; tune numbers until every deck is 40–60%.

## Testing

Rules unit tests for the quirk, reactions, field, keywords and every new card's text/effects;
playback of every new spell; screenshots of the Dunes board and cards (desktop + Compatibility);
fps on Low; full suite; online version bump is automatic (rules stamp).
