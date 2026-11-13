# Dream Isles — 3D Lane Card Battler (v1 Design)

Date: 2026-11-13
Status: Draft for review

## 1. Goal

A playable 3D card battler for the user and friends, playing like the Card Wars
mobile game but with an entirely original world, cards and art. v1 is single
player against a computer opponent. The rules engine is kept separate from the
visuals so online multiplayer can be added later without rewriting the rules.

Success for v1: you can launch the game, pick a pre-made deck and difficulty,
play a full match against the AI on a 3D board, and the match feels good:
satisfying hops, lunges, hits and the timing bar.

### Constraints

- Mechanics may resemble Card Wars. All content must be original: no Adventure
  Time characters, land names, card names, art, UI art or look.
- Engine: Godot 4 (4.7.2 installed), GDScript, desktop build.
- Art is built from code and simple shapes at first. Creature visuals live in
  swappable scenes so real models can replace them later.

### Out of scope for v1

Online play, deck builder, card leveling, packs/shop/currency, campaign map,
sound design beyond placeholder SFX, mobile builds.

## 2. Look and feel

- **Style:** "toy diorama". Bright sky, soft shadows, cartoon meadow and trees
  in the background, chunky blob creatures that idle-hop.
- **Board:** a floating wooden slab. The rival's 4 lands are at the back and
  yours are at the front, divided by a centre line. The camera is tilted behind
  your side (as in `board-layout.html` mockup).
- **Lands:** round floating island tiles coloured by type, each with small
  decorations: mushrooms, lava rocks, lollipops, ice crystals.
- **HUD:** rival panel top-left (health, magic, cards in hand, deck count). Your
  panel on the left at mid-height (health, magic as current/max). Turn counter
  top-right, END TURN button on the right.
- **Hand:** cards fanned along the bottom. Hovering raises a card. Dragging it
  onto a valid land highlights the land (glowing ring) and drops the card.
- **Combat feel:** the attacker leaps across the lane, the target shakes, a
  floating damage number appears ("CRIT!" styling on criticals), with a small
  camera kick. Destroyed creatures poof into particles.

## 3. World: Dream Isles

| Land type | Colour | Theme |
|---|---|---|
| Mushroom Forest | green | healing, toughness |
| Ember Flats | orange | direct damage, aggression |
| Candy Hills | pink | card draw, magic, tricks |
| Frostpeak | ice blue | freezing, defence |

## 4. Rules

### 4.1 Setup

- Each player uses a pre-made deck: 30 cards plus 4 lands.
- Lands are placed in lanes 1–4 in the order the deck defines.
- Hero health: 25. Shuffle the deck with the match seed and draw 5 cards.
- A coin flip (from the seed) decides who goes first.

### 4.2 Turn structure

1. **Magic:** set to 2. Unused magic does not carry over. Some effects add magic
   for the current turn.
2. **Start of turn:** trigger start-of-turn effects (for example Candy Mill
   adds 1 magic on top of the 2).
3. **Draw** 1 card. The first player skips this draw on turn 1. Drawing from an
   empty deck deals 2 damage to your hero instead. The hand limit is 7; a card
   drawn into a full hand is discarded.
4. **Main phase,** in any order, as many times as allowed:
   - **Play a creature** (pay cost) onto one of your lands with no creature.
     Requirement: the number of your lands matching the creature's type must be
     at least the creature's level (L1/L2/L3). Creatures may be placed on any
     land type.
   - **Play a building** (pay cost) onto one of your lands with no building.
     There is at most one creature and one building per lane.
   - **Cast a spell** (pay cost), resolve its effect, then discard it.
   - **Boop** a creature that has not attacked or booped this turn and is not
     frozen. Its boop ability resolves and it cannot attack this turn.
5. **Attack phase:** pressing END TURN starts it. Every eligible creature
   attacks (see 4.3). There is no separate ATTACK button.
6. **End of turn:** trigger end-of-turn effects, clear freezes that were active
   this turn (see 4.5), then pass the turn.

### 4.3 Attacking

- Creatures **may** attack on the turn they are played.
- The first player cannot attack on turn 1.
- Attacks resolve lane by lane, from lane 1 to lane 4, for each eligible creature
  (not booped this turn, not frozen).
- If the opposite lane has a creature, the attacker deals damage to it. If not,
  it deals damage to the enemy hero.
- There is no counter-damage. Damage on creatures persists between turns.
  A creature at 0 health is destroyed and goes to its owner's discard pile.

### 4.4 Timing bar

- **Attacker bar** (every creature attack, including hero hits): a needle sweeps
  across a bar. Where it stops sets the hit:
  - green → **critical**, ×1.5, rounded up
  - yellow → **normal**, ×1
  - red → **glancing**, ×0.5, rounded down, minimum 1
- **Defender bar** (only when a creature is attacked, not the hero): green →
  **block**, damage halved after the attacker multiplier (rounded down);
  anything else → no change.
- If the player does not tap within 2 seconds, the result is "normal" for an
  attacker and "no block" for a defender.
- The view resolves the bar and passes the result into the attack action. The
  rules engine never runs timing logic.
- AI hit rates per difficulty (green / yellow / red):
  easy 15/50/35, medium 30/50/20, hard 50/40/10. AI blocks succeed at 15% / 30% / 50%.

### 4.5 Status: Frozen

A frozen creature cannot attack or boop during its owner's next turn. The freeze
clears at the end of that turn.

### 4.6 Winning

A hero at 0 health or below loses. If both reach 0 at the same moment, the
active player wins.

## 5. Card pool (v1: 40 cards)

ATK/HP refer to creatures. "Opposing" means the enemy lane directly across.

### Mushroom Forest

| Card | Type | Lvl | Cost | ATK/HP | Ability |
|---|---|---|---|---|---|
| Sporeling | Creature | 1 | 1 | 2/4 | Boop: heal this creature 2. |
| Mossback | Creature | 1 | 1 | 1/6 | — |
| Puffcap | Creature | 1 | 1 | 2/5 | Boop: heal your hero 2. |
| Glimmer Morel | Creature | 2 | 1 | 3/6 | Boop: heal all your creatures 1. |
| Rootstalker | Creature | 2 | 2 | 4/7 | On play: heal your hero 2. |
| Elder Shroomhulk | Creature | 3 | 2 | 5/10 | Boop: heal all your creatures 3. |
| Spore Hut | Building | — | 1 | — | Start of your turn: heal the creature in this lane 1. |
| Glowcap Lantern | Building | — | 1 | — | Creature in this lane has +3 max HP. |
| Rain of Spores | Spell | — | 1 | — | Heal one of your creatures 4. |
| Regrowth | Spell | — | 2 | — | Return a creature from your discard pile to your hand. |

### Ember Flats

| Card | Type | Lvl | Cost | ATK/HP | Ability |
|---|---|---|---|---|---|
| Cinderpup | Creature | 1 | 1 | 3/2 | — |
| Ashmite | Creature | 1 | 1 | 2/3 | Boop: deal 1 damage to the opposing creature. |
| Flarebeak | Creature | 1 | 1 | 4/3 | — |
| Magmaw | Creature | 2 | 1 | 4/4 | Boop: deal 2 damage to the enemy hero. |
| Blazehorn | Creature | 2 | 2 | 6/4 | On play: deal 2 damage to the opposing creature. |
| Inferno Drake | Creature | 3 | 2 | 7/6 | Boop: deal 2 damage to all enemy creatures. |
| Kiln Tower | Building | — | 1 | — | Creature in this lane has +2 ATK. |
| Smokestack | Building | — | 1 | — | End of your turn: deal 1 damage to the enemy hero. |
| Fireball | Spell | — | 1 | — | Deal 3 damage to a creature. |
| Ember Rain | Spell | — | 2 | — | Deal 2 damage to all enemy creatures. |

### Candy Hills

| Card | Type | Lvl | Cost | ATK/HP | Ability |
|---|---|---|---|---|---|
| Gumdrop | Creature | 1 | 1 | 2/3 | Boop: draw a card. |
| Taffy Snail | Creature | 1 | 1 | 1/5 | On play: gain 1 magic. |
| Lollibat | Creature | 1 | 1 | 3/3 | Boop: move this creature to one of your empty lanes. |
| Sugar Sprite | Creature | 2 | 1 | 3/4 | Boop: return the opposing building to its owner's hand. |
| Jellywobble | Creature | 2 | 2 | 4/6 | When destroyed: draw 2 cards. |
| Bonbon Behemoth | Creature | 3 | 2 | 5/8 | Boop: draw 2 cards. |
| Sugar Shack | Building | — | 1 | — | Creature in this lane has +1 ATK and +1 max HP. |
| Candy Mill | Building | — | 1 | — | Start of your turn: gain 1 magic. |
| Sugar Rush | Spell | — | 1 | — | Draw 2 cards. |
| Swap Trick | Spell | — | 0 | — | Swap two of your creatures between lanes. |

### Frostpeak

| Card | Type | Lvl | Cost | ATK/HP | Ability |
|---|---|---|---|---|---|
| Snowmite | Creature | 1 | 1 | 1/4 | Boop: freeze the opposing creature. |
| Iceling | Creature | 1 | 1 | 2/5 | — |
| Frostfang | Creature | 1 | 1 | 3/4 | After it damages a creature, freeze that creature. |
| Glacier Tortoise | Creature | 2 | 1 | 2/9 | — |
| Rimewing | Creature | 2 | 2 | 4/5 | On play: freeze the opposing creature. |
| Blizzard Titan | Creature | 3 | 2 | 6/9 | Boop: freeze all enemy creatures. |
| Ice Wall | Building | — | 1 | — | Creature in this lane takes 1 less damage from attacks (minimum 1). |
| Frost Spire | Building | — | 1 | — | Opposing creature has −1 ATK (minimum 0). |
| Cold Snap | Spell | — | 0 | — | Freeze a creature. |
| Avalanche | Spell | — | 2 | — | Deal 3 damage to a creature and freeze it. |

Balance is a first pass. Numbers will be tuned after playtesting; they live in
data files so tuning needs no code changes.

### 5.1 Pre-made decks

Each deck uses 3 lands of its main type and 1 land of a splash type. Contents:

- 2× each of the 10 main-type cards (20 cards)
- 2× each of the first three level-1 creatures listed for the splash type in
  the table above (6 cards)
- 2× the splash type's first building in the table (2 cards)
- 2× the splash type's first spell in the table (2 cards)

| Deck | Main (3 lands) | Splash (1 land) |
|---|---|---|
| Grove Guard | Mushroom Forest | Frostpeak |
| Blaze Rush | Ember Flats | Candy Hills |
| Sugar Storm | Candy Hills | Mushroom Forest |
| Deep Freeze | Frostpeak | Ember Flats |

Lane order for lands: main, main, splash, main.

## 6. Architecture

```
cardwars/                    (Godot project root)
  project.godot
  core/                      pure rules engine (no Node3D, no scene tree)
    game_state.gd            players, lanes, hands, decks, discard, magic, turn
    actions.gd               action classes: PlayCard, Boop, Attack, EndTurn
    rules.gd                 validate(action) -> error or OK; apply(action) -> events
    abilities.gd             ability implementations keyed by ability id
    events.gd                event classes (CardDrawn, CreaturePlayed, DamageDealt, ...)
    rng.gd                   seeded RNG wrapper (shuffles, coin flip)
  data/
    cards/*.tres             one CardData resource per card
    decks/*.tres             one DeckData resource per pre-made deck
    card_data.gd, deck_data.gd   resource class definitions
  ai/
    ai_player.gd             chooses actions from a GameState; returns actions
  view/
    match.tscn / match.gd    owns a Rules instance, plays back events
    board/                   slab, islands, background scenery
    creatures/*.tscn         one scene per creature (built from primitives)
    ui/                      hand, card widget, HUD, timing bar, end-turn button
    fx/                      damage numbers, poof particles, camera shake
  menus/
    main_menu.tscn           Play vs AI → deck pick → difficulty → match
    results.tscn             win/lose screen, rematch, back to menu
  tests/
    run_tests.gd             minimal headless test runner
    test_*.gd                rule tests
```

### 6.1 Data flow

1. The player (via the view) or the AI creates an **action**.
2. `rules.validate(state, action)` rejects illegal actions with a reason. The
   view uses the same check to show which lands and targets are valid.
3. `rules.apply(state, action)` mutates the state and returns an ordered list of
   **events**.
4. The view queues the events and plays them back as animations one after
   another. Input is locked during playback.

The view never mutates game state directly. The AI never touches the view.

### 6.2 Attack flow with timing bars

The attack phase is driven by the view. For each eligible attacker it shows the
attacker bar (or simulates it for the AI). If there is a defending creature,
it shows the defender bar (to the human if they are defending, simulated if the
AI is defending). It then sends `Attack(lane, attack_result, block_result)` to
the rules and plays back the events.

### 6.3 Abilities

`CardData` carries an `ability_id` and a `trigger` (on_play, on_boop,
on_destroyed, on_deal_damage, start_of_turn, end_of_turn, passive). Abilities
are small functions in `abilities.gd` that read and modify the state and append
events. Passive building modifiers are applied when computing effective ATK,
max HP and damage taken. They are not baked into stored stats.

### 6.4 Targeting

Spells and abilities that need a target ("a creature", "one of your creatures",
"one of your empty lanes", "two of your creatures") declare a target spec in
`CardData`. The view enters a targeting mode that highlights valid targets.
The AI picks targets through the same spec.

### 6.5 Online-ready rules

- All randomness comes from the seeded RNG in `GameState`.
- Actions and events are plain data that can be serialised to dictionaries.
- Given the same seed and the same action list, a match replays identically.
  This is tested.

## 7. AI (v1)

Greedy, one turn deep:

1. Evaluate each legal play (creature, building, spell, boop) with a simple
   score: damage dealt, enemy creatures killed, own creatures protected, hero
   damage, card advantage. Play the best one if its score is above 0, then
   repeat until nothing scores positive or magic runs out.
2. Boop decision: boop only if the boop's score beats the creature's expected
   attack value.
3. Attack with every eligible creature.
4. Timing results are drawn from the difficulty's probabilities (4.4).

The AI acts with short delays so the player can follow what it does.

## 8. Error handling

- Illegal actions from the view are rejected by `validate`, and the UI shows the
  reason briefly ("Needs 2 Ember lands", "Not enough magic").
- Missing or malformed card data fails loudly at startup with the file name, and
  is caught by a test that loads every card and deck.
- If an ability hits an unexpected state (for example its target disappeared),
  it does nothing and logs a warning. It does not crash the match.

## 9. Testing

- **Rules tests** run headless via `godot --headless --script tests/run_tests.gd`:
  level requirements, magic costs, one creature/building per lane, empty-lane
  hero hits, timing multipliers and rounding, block halving, freeze duration,
  boop prevents attack, first-turn attack ban, deck-out damage, hand limit,
  every ability, win conditions, and seed-replay determinism.
- **Data tests:** every card and deck loads, and every deck has 30 cards and 4 lands.
- **AI smoke test:** AI vs AI plays 100 seeded matches to completion without
  errors or stuck turns.
- **Visual checks:** run the game and take screenshots at key moments (board,
  hand drag, attack, results) to verify layout.

## 10. Build order (high level)

1. Godot project skeleton and test runner
2. Card/deck data plus all 40 cards and 4 decks
3. Rules engine with tests
4. AI with AI-vs-AI smoke test
5. 3D board, islands, creatures, HUD and hand (static)
6. Event playback, animations and timing bar
7. Menus, results screen and polish

The detailed plan comes next via writing-plans.
