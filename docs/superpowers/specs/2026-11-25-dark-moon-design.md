# Dark Moon expansion — design

Date: 2026-11-25. All four design parts approved in chat. Branch `feat/dark-moon`.

## Goals

More variety and late-game depth, in the Hearthstone spirit: unique legendary effects, packs
(big creatures with a follower), stealing, curses, Dark Gift, deck-building conditions, spell
replays and bigger creatures. Plus three quality items: card text always fits, the aim arrow
flows, and mana grows to 10 (cards can push it to 15). Success: about 80 new cards that all
work, are readable, look finished, show up in normal play, and keep the 6 decks at 40–60% wins.

## 1. Quick wins

- **Mana**: `GameState.MAGIC_CAP` 8 → 10, `MAGIC_CAP_MAX` 10 → 15. Turn growth stops at 10;
  only cards (`grow_magic`, new ramp cards) raise the cap beyond, up to 15. HUD shows two digits.
- **Card text fits**: the card's description box shrinks its font step by step (current size
  down to a floor) until the text fits; for long texts the stats line also shrinks a little.
  Hand, zoom, deck builder, Dream Up / Dark Gift picker. A test renders every card at each
  card size and fails if any text overflows.
- **Aim arrow**: a chevron strip scrolling toward the target (shader UV scroll) on the existing
  attack/target arrow; turns red over a valid target. Mobile and Compatibility renderers.

## 2. Board rules

### 2.1 Packs and followers

- `LaneState` gets `follower: CreatureState` (null normally). Only a pack card fills it: a
  creature card with `follower_id` puts that token in the follower slot when it enters.
- A follower is a full independent creature: attacks, is attacked and targeted on its own,
  keeps its own keywords/damage/level, shares the lane's land bonus and building.
- Addressing: every creature reference `{player, lane}` gains an optional `slot` (0 main,
  1 follower; missing = 0). Attack actions get `target_slot` and `slot`. Targeting lists the
  follower as its own target.
- If the main creature dies while a follower lives, the follower moves to slot 0.
- Nothing else can be played into slot 1; a normal creature still needs an empty lane; merging
  only works on slot 0 as now.
- Move / swap / bounce / Dark Moon move the lane's creatures as a unit (main + follower). Bounce
  returns the main card; the follower token is removed (tokens never go to hand).
- Guard, auras, "adjacent", lane-wide effects count followers as creatures of that lane.

### 2.2 Dark Moon

Spell, Neutral, cost 4, legendary. On play the player picks **Left** or **Right** (a choice like
Dream Up's, two options).

- The ring of 8 lands: your lanes 0→3, then the rival's lanes 3→0, back to your lane 0.
  "Left"/"Right" is from the caster's view: Right = along that order, Left = against it.
- Collect the occupied lands in ring order; each land's creatures (main + follower as one unit)
  move to the next occupied land in the chosen direction, once. Empty lands stay empty.
- A unit that ends on the other side changes owner (damage, buffs, freeze, level, keywords
  travel with it). Buildings stay. Moved creatures are not "played" (no on-play), keep `ready`
  only if they stay on the same side; a creature that switched sides can't attack this turn.

### 2.3 Stealing

New effect ops: `steal_hand` (random card from rival hand, or the N most expensive),
`copy_rival` (copy a random card from rival deck or hand into your hand), `steal_creature`
(take control of an enemy creature with attack ≤ amount into your empty lane, chosen or
leftmost; fails without an empty lane). The history counts cards stolen.

### 2.4 Legendaries and neutrals

- `CardData.legendary: bool`; at most 1 copy per deck; gold-crowned frame; short camera push and
  burst when played.
- Neutral (`Land.NEUTRAL`) cards become deck-legal; only Star Shard stays out (new flag
  `CardData.deck_legal`, false for Star Shard). Neutral creatures get no land bonus or penalty.

## 3. Mechanics

### 3.1 Changed copies (approach A)

`CardData.base_id` (the original card's id, `&""` for printed cards) and runtime copies made
with `CardDB.variant(base, changes)`: a duplicate CardData with changed cost / attack / health /
extra effects / flags (`dark_gift`, `curse`). Copies are never saved, never shown in the deck
builder. `GameState._dump` writes a copy as id plus its changed fields so the online digest
covers them; both peers create identical copies (deterministic). Every place that compares cards
by identity or looks them up by id must use `base_id` where it means "the same card"
(MAX_COPIES, Dream Up exclusions, VisualDB look-up, card art).

### 3.2 History

`PlayerState.history`: `spells_played: Array[CardData]` (in order), `deaths_own`, `deaths_all`
(counts; both players' creatures), `stolen` count, `start_size`, `start_no_dupes`,
`start_ids` (set of base ids the deck started with).

### 3.3 New triggers, keywords and ops

- **Last Breath** (`when = on_destroyed`, already in the engine): used widely, shown as a
  keyword-like marker; Hush turns it off.
- **Echo**: aura "your on-play effects happen twice" (any creature with the aura in play).
- **While held**: `when = in_hand` effects recomputed whenever the state changes:
  `cost_per_death` (costs 1 less per creature died this game), `grow_on_spell` (+1/+1 when you cast a
  spell, applied by making a changed copy).
- **Curse**: card flag; `when = on_draw` runs (and the card is discarded) for curses that
  trigger when drawn; others just sit in the hand (playable to get rid of, cost shown).
- **Dark Gift**: `dream_up` with `gift = true`: picks 3 creatures; the chosen one becomes a
  changed copy with one random bonus from: +2/+2, Guard, Leech, cost −2, Last Breath: summon 2/2.
- **Conditions** (EffectData `cond`): `start_no_dupes`, `start_40`, `started_with:<id>`,
  `holding_land:<land>`, `holding_big` (creature with 6+ attack), `max_magic_at_least:<n>`,
  `deaths_at_least:<n>`, `spells_of_land_at_least:<land>:<n>`.
- **Ops**: `split_damage` (amount split one at a time randomly among enemies: creatures and hero),
  `double_stats`, `next_spell_twice`, `replay_spells` (filter by land; random legal targets),
  `add_to_hand` (card_id, count), `shuffle_into_deck` (card_id, count, own/rival),
  `summon` (card_id, count, into your empty lanes left to right), `buff_hand` (creatures in
  hand +a/+b), `give_curse` (curse card into rival hand or deck), `steal_*` (2.3),
  `dark_moon` (2.2).
- **40-card decks**: cards with `allows_40 = true`. DeckStore accepts 30 cards, or exactly 40
  when the deck holds one of them; the deck builder shows "x/40" then.

## 4. Cards (~80)

- ~20–25 Neutral (any deck): Dark Moon, most curses, the 40-card cards (legendary *Gluttonous
  Dreamer*), generic packs, summon spells, Dark Gift creatures.
- ~11 per land × 5 lands. Each land: 2 legendaries, 2 big late creatures (7–10 cost, at least
  one a pack), 1–2 mid packs, 1–2 summon spells, the rest new-mechanic cards in its theme:
  Mushroom Last Breath / deaths, Ember split damage / burn, Candy hand buffs / card makers,
  Frost spell replays / holding Frost, Dunes thieves.
- Legendary seeds: Mushroom spore god (Last Breath: summon each Last Breath creature that died
  this game); Ember split-damage storm that repeats with 5+ Ember spells cast; Candy "if your deck
  started with no duplicates, fill your board with 4/4 sweets"; Frost "cast every Frost spell you
  played this game if you have 10+ max mana"; Dunes thief king (steal the 2 most expensive cards
  in the rival's hand).
- The full card sheet (names, costs, stats, text) lives in the plan ledger and is fixed while
  building; every card gets a test.
- **Deck 6 "Moonlit Bandits"** (Dunes/Ember + neutrals: thieves, curses, Dark Moon). Each of the
  5 existing decks gets 4–6 new cards.

## 5. AI and balance

- The AI already scores moves by simulating them; new choices it must make: Dark Moon direction,
  Dark Gift picks, follower/slot targets. Its board score adds changed hand cards, held curses
  (negative) and pending Last Breath value.
- Balance sims across all 6 decks: each 40–60% overall; no runaway combo; games reaching 15 mana
  must still end (turn limit draws counted).

## 6. Visuals

| Thing | Look |
|---|---|
| Follower | smaller model beside the leader in the same lane, own tag; leader shifts aside |
| Dark Moon | table dims under a purple moon; creatures glide along the ring, arcing across the middle when they change sides |
| Steal | shadowy hand pulls the card/creature across |
| Curse | purple-black frame with a drip; purple burst when drawn |
| Dark Gift | purple glow on choices, "+ bonus" line on the card |
| Last Breath | small wisp icon on the tag; ghostly wisps when it triggers |
| Changed copies | changed numbers green (better) / red (worse) and a small marker |
| Legendary | gold-crowned frame; camera push-in and burst on play |
| Start-of-game condition | short glowing banner when met |

New creature models: free CC0 sources used before (Quaternius etc.); followers may reuse a
smaller model. Action log, tooltips and deck builder cover all of the above.

## 7. Testing

Headless tests for every rule, op, condition and card; online lockstep digest test with changed
copies, followers and Dark Moon; text-fit test for every card; screenshots for every new visual;
fps check on Low and Compatibility; balance sims. Suite must stay green.
