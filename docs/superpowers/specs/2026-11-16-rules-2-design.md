# Dream Isles: Rules 2.0 design

Date: 2026-11-16. Status: agreed in chat section by section; this document awaits review.

## 1. Why

The user and their friends find Dream Isles too thin: turns lack decisions, the card pool is
small, there are no big swing moments, and friends who play Hearthstone want more depth. The
answer is Hearthstone-style mechanics on the Dream Isles board, with our own names and cards.

This is the first of three projects:

1. **Rules 2.0** (this document): growing magic, Hearthstone combat, 12 mechanics, abilities as
   data, the 40 cards rebalanced, a stronger AI, and the screens and effects for all of it.
2. **Card expansion:** new cards built on these mechanics.
3. **Deckbuilding:** collection and deck editor.

## 2. Decisions

| Topic | Decision |
|---|---|
| Magic | Starts at 1, +1 max per turn, cap **8**, refills each turn |
| Combat | **Full Hearthstone**: attack any enemy creature or the hero; defender hits back |
| Timing bar | **Kept**: attacker crit/normal/glance and defender block on every creature attack |
| Mechanics | 8 keywords plus Hush, Dream Up, Combo, Spell Power (all 12 in this project) |
| Hero powers, secrets | Not wanted |
| Engine approach | Evolve the current engine; abilities become data built from small blocks |
| Names | Our own; Hearthstone names appear here only as reference |

## 3. Rules

### 3.1 Setup

- Decks: 30 cards plus 4 lands, as now. Hero health 25 (also the maximum).
- Each player draws 5. The coin flip (from the seed) picks the first player.
- The second player also gets **Star Shard** in their opening hand.

### 3.2 Turn

1. **Magic:** max magic +1 (cap 8), then refill to max. "Gain magic" effects add magic for
   this turn only.
2. **Start of turn** effects.
3. **Draw** 1 (the first player skips this on turn 1). Empty deck: 2 damage to your hero.
   Hand limit **8**; a card drawn or added to a full hand is discarded.
4. **Main phase**, any order: play cards, attack, boop.
5. **END TURN:** end-of-turn effects, clear freezes that were active this turn, pass.

There is no separate attack phase. The BATTLE! button becomes END TURN.

### 3.3 Playing cards

- **Creature:** into one of your lanes with no creature. Level requirement unchanged: matching
  lands ≥ level.
- **Building:** into one of your lanes with no building; boosts the creature in that lane.
- **Spell:** resolve, then discard.
- "Opposing creature" means the creature in the enemy lane directly across. Only abilities use
  it.

### 3.4 Readiness, attacking and booping

- A creature is **ready** if it has been on your board since the start of your turn and is not
  frozen. A creature played (or brought back) this turn is not ready.
- Each turn a ready creature may **either** attack (once; twice with Flurry) **or** boop once.
  Booping uses up all its attacks. A creature with 0 effective ATK cannot attack.
- **Dash:** may attack enemy creatures (not the hero) on the turn it is played.
- **Target:** any enemy creature or the enemy hero, except that while the enemy has a Guard
  creature that is not Hidden, attacks must target one of those Guards. Hidden creatures cannot
  be chosen.
- **Damage to the target:** the attacker's effective ATK, then the attacker bar (crit ×1.5
  rounded up, glance ×0.5 rounded down with minimum 1), then Ice Wall (−1, minimum 1), then the
  defender block bar (halve, rounded down). Heroes have no block bar.
- **Hit-back:** if the target is a creature, it deals its effective ATK back to the attacker.
  Bars never change hit-back. Ice Wall on the attacker's lane reduces hit-back by 1 (minimum 1)
  when hit-back is above 0.
- Both damages land at the same moment; then deaths resolve.
- An attacking creature that is Hidden is revealed when it attacks or boops.

### 3.5 Deaths

Deaths resolve after each action, in lane order, active player's creatures first. Each death
runs "When destroyed" effects, then Second Wind if present.

### 3.6 Freeze and winning

Unchanged: a frozen creature cannot attack or boop during its owner's next turn. A hero at 0
or below loses; if both reach 0 at once, the active player wins.

## 4. Mechanics

### 4.1 Keywords

| Keyword | Rule | (HS) |
|---|---|---|
| **Guard** | While you have a Guard that is not Hidden, enemy *attacks* must target a Guard. Spells and abilities ignore Guard. | Taunt |
| **Bubble** | Prevents the next damage above 0 from any source in full, then is lost. Damage prevented this way is 0, so Venom and Leech do not trigger. | Divine Shield |
| **Dash** | May attack enemy creatures the turn it is played. | Rush |
| **Venom** | Any damage above 0 this creature deals to a creature destroys that creature. | Poisonous |
| **Leech** | Whenever this creature deals damage, its owner's hero heals that much (up to 25). | Lifesteal |
| **Flurry** | May attack twice per turn. | Windfury |
| **Hidden** | Cannot be chosen by enemy attacks, spells or abilities until it attacks or boops. "All enemies" and "opposing" effects still hit it. | Stealth |
| **Second Wind** | The first time it is destroyed it returns to the same lane with 1 HP, its printed keywords except Second Wind, no gained changes, not ready. | Reborn |

Keywords come from the card (printed), from effects (gained) or from a building in the lane
(Glowcap Lantern's Guard). A building's keyword counts for every rule while the building stands
and is not removed by Hush.

### 4.2 Effects

- **Hush:** removes printed and gained keywords, abilities (effects) and stat changes from a
  creature, and unfreezes it. Base ATK/HP and damage taken stay. Building boosts still apply.
  A Hushed creature that later gains a keyword keeps that new keyword.
- **Dream Up (filter):** the engine draws 3 different random cards matching the filter from all
  cards in the game (Star Shard excluded) using the match RNG, and waits for the player to
  choose one. The chosen card goes to hand (discarded if the hand is full).
- **Combo:** an effect marked Combo runs only if its owner has already played another card this
  turn (any card, including Star Shard; attacks and boops do not count).
- **Spell Power +N:** while this creature is on the board, each instance of damage dealt by its
  owner's spells is +N. Values stack. Creature and building abilities are not affected.

## 5. Abilities as data

### 5.1 Card data

`CardData` keeps id, name, kind, land, level, cost, attack, health and gains:

- `keywords: Array[StringName]` from: guard, bubble, dash, venom, leech, flurry, hidden,
  second_wind.
- `spell_power: int` (default 0).
- `effects: Array[EffectData]`.

The old `trigger`, `ability_id`, `target` and `text` fields are removed; all 40 card files are
migrated. Land gets a `NEUTRAL` value for Star Shard (gold frame); every view that indexes
colours by land must handle it.

`EffectData` (a Resource):

| Field | Values |
|---|---|
| `when` | on_play, on_boop, on_destroyed, after_damage (this creature damaged a creature), start_of_turn, end_of_turn, aura (always on, for buildings and lasting boosts) |
| `op` | damage, heal, draw, freeze, gain_magic, hush, return_building, move, swap, dream_up, return_from_discard; auras: lane_atk, lane_hp, lane_keyword, lane_damage_taken, opposing_atk; plus buff (+ATK/+HP), give_keyword and destroy, which no Rules 2.0 card uses yet but the expansion needs (unit-tested only) |
| `amount` | int (damage, heal, cards, magic, ATK) |
| `amount2` | int (HP for buff) |
| `who` | chosen_creature, chosen_own_creature, chosen_own_empty_lane, chosen_two_own_creatures, chosen_discard_creature, self, opposing (creature or building across), damaged_creature, lane_creature, all_enemy_creatures, all_own_creatures, enemy_hero, own_hero, same_target (the previous effect's target) |
| `keyword` | for give_keyword and lane_keyword |
| `filter` | for dream_up: kind and/or land |
| `combo` | bool |

An effect list runs in order. Chosen targets are picked once per card when it is played or
booped and passed in the action, as now. **Summon** (put a creature into play) is deferred to the
card expansion, since no Rules 2.0 card uses it.

### 5.2 Card text

Card text is generated from keywords and effects ("Guard. Boop: Heal this creature 2."). The
generator is the only source of rules text, so text and behaviour cannot disagree. Hand-written
text is not stored.

### 5.3 Creature state

Each creature on the board tracks: card, damage, gained keywords, printed keywords hushed (bool),
ATK/HP changes, bubble up, hidden, second wind used, ready, attacks left this turn, frozen.

### 5.4 Engine

`Abilities` (one large `match` on ability ids) is replaced by an effect runner: one small
function per `op` and one resolver per `who`, each unit-tested. Building auras are read through
`Rules.effective_attack / effective_max_hp / damage_taken_modifier`. The rules engine stays free
of view code.

Actions: `PLAY_CARD`, `BOOP`, `ATTACK` (attacker lane, target: enemy lane or hero, hit, blocked),
`CHOOSE` (Dream Up choice index), `END_TURN`. `BEGIN_ATTACKS` is removed. While a Dream Up choice
is pending, `CHOOSE` is the only legal action.

New events for the view: attack (attacker, target, damage, hit_back), bubble_popped, revealed,
second_wind, hushed, keyword_gained, buffed, dream_up_offered, dream_up_chosen, magic_changed
(now with max), combo_active.

## 6. The 41 cards

Level-1 creatures cost 1–3, level-2 cost 3–5, level-3 cost 6–8; spells and buildings 1–5.
Costs and stats are a first pass, tuned by playtesting; they are data only.

### Mushroom Forest (sturdy, healing: Guard, Leech, Second Wind, Venom)

| Card | Type | Lvl | Cost | ATK/HP | Text | Was |
|---|---|---|---|---|---|---|
| Sporeling | Creature | 1 | 2 | 1/2 | Venom. Boop: Heal this creature 2. | 1 · 2/4 |
| Mossback | Creature | 1 | 2 | 1/5 | Guard. | 1 · 1/6 |
| Puffcap | Creature | 1 | 3 | 2/3 | Second Wind. Boop: Heal your hero 2. | 1 · 2/5 |
| Glimmer Morel | Creature | 2 | 3 | 3/4 | Boop: Heal all your creatures 2. | 1 · 3/6 |
| Rootstalker | Creature | 2 | 4 | 3/5 | Leech. On play: Heal your hero 2. | 2 · 4/7 |
| Elder Shroomhulk | Creature | 3 | 7 | 5/8 | Guard. Second Wind. Boop: Heal all your creatures 3. | 2 · 5/10 |
| Spore Hut | Building | — | 2 | — | Start of your turn: Heal the creature in this lane 2. | 1 |
| Glowcap Lantern | Building | — | 3 | — | The creature in this lane has +2 HP and Guard. | 1 |
| Rain of Spores | Spell | — | 1 | — | Heal one of your creatures 4. | 1 |
| Regrowth | Spell | — | 2 | — | Return a creature from your discard pile to your hand. | 2 |

### Ember Flats (aggressive: Dash, Spell Power)

| Card | Type | Lvl | Cost | ATK/HP | Text | Was |
|---|---|---|---|---|---|---|
| Cinderpup | Creature | 1 | 1 | 2/1 | Dash. | 1 · 3/2 |
| Ashmite | Creature | 1 | 2 | 2/2 | Spell Power +1. Boop: Deal 1 damage to the opposing creature. | 1 · 2/3 |
| Flarebeak | Creature | 1 | 3 | 3/3 | Dash. | 1 · 4/3 |
| Magmaw | Creature | 2 | 4 | 4/4 | Boop: Deal 2 damage to the enemy hero. | 1 · 4/4 |
| Blazehorn | Creature | 2 | 5 | 5/4 | Dash. On play: Deal 2 damage to the opposing creature. | 2 · 6/4 |
| Inferno Drake | Creature | 3 | 7 | 6/6 | Spell Power +1. Boop: Deal 2 damage to all enemy creatures. | 2 · 7/6 |
| Kiln Tower | Building | — | 2 | — | The creature in this lane has +2 ATK. | 1 |
| Smokestack | Building | — | 2 | — | End of your turn: Deal 1 damage to the enemy hero. | 1 |
| Fireball | Spell | — | 2 | — | Deal 3 damage to a creature. | 1 |
| Ember Rain | Spell | — | 4 | — | Deal 2 damage to all enemy creatures. | 2 |

### Candy Hills (tricky: Hidden, Flurry, Combo, Dream Up)

| Card | Type | Lvl | Cost | ATK/HP | Text | Was |
|---|---|---|---|---|---|---|
| Gumdrop | Creature | 1 | 2 | 2/4 | Boop: Draw a card. | 1 · 2/3 |
| Taffy Snail | Creature | 1 | 2 | 3/4 | On play: Gain 1 magic. | 1 · 1/5 |
| Lollibat | Creature | 1 | 3 | 2/4 | Flurry. Boop: Move this creature to one of your empty lanes. | 1 · 3/3 |
| Sugar Sprite | Creature | 2 | 3 | 3/3 | Hidden. On play, Combo: Return the opposing building to its owner's hand. | 1 · 3/4 (Boop) |
| Jellywobble | Creature | 2 | 4 | 4/6 | When destroyed: Draw 2 cards. | 2 · 4/6 |
| Bonbon Behemoth | Creature | 3 | 6 | 6/7 | On play: Dream Up a Candy Hills card. Boop: Draw 2 cards. | 2 · 5/8 |
| Sugar Shack | Building | — | 1 | — | The creature in this lane has +1 ATK and +1 HP. | 1 |
| Candy Mill | Building | — | 2 | — | Start of your turn: Gain 1 magic. | 1 |
| Sugar Rush | Spell | — | 1 | — | Draw 2 cards. | 1 |
| Swap Trick | Spell | — | 1 | — | Swap two of your creatures between lanes. Combo: Draw a card. | 0 |

### Frostpeak (control: Bubble, Hush, Freeze)

| Card | Type | Lvl | Cost | ATK/HP | Text | Was |
|---|---|---|---|---|---|---|
| Snowmite | Creature | 1 | 2 | 1/3 | Boop: Freeze the opposing creature. | 1 · 1/4 |
| Iceling | Creature | 1 | 2 | 2/3 | Bubble. | 1 · 2/5 |
| Frostfang | Creature | 1 | 3 | 3/3 | After this damages a creature, freeze it. | 1 · 3/4 |
| Glacier Tortoise | Creature | 2 | 3 | 3/6 | Bubble. | 1 · 2/9 |
| Rimewing | Creature | 2 | 4 | 4/4 | On play: Hush the opposing creature. | 2 · 4/5 (freeze) |
| Blizzard Titan | Creature | 3 | 7 | 6/8 | Bubble. Boop: Freeze all enemy creatures. | 2 · 6/9 |
| Ice Wall | Building | — | 2 | — | The creature in this lane takes 1 less damage from attacks and hit-back (minimum 1). | 1 |
| Frost Spire | Building | — | 2 | — | The opposing creature has −1 ATK (minimum 0). | 1 |
| Cold Snap | Spell | — | 1 | — | Freeze a creature. Draw a card. | 0 |
| Avalanche | Spell | — | 3 | — | Deal 3 damage to a creature and freeze it. | 2 |

### Neutral

| Card | Type | Cost | Text |
|---|---|---|---|
| Star Shard | Spell | 0 | Gain 1 magic. (Given to the second player; not in decks, not in Dream Up.) |

Balance pass 2026-11-16 (user-approved, after the AI suites): Sugar Storm and Deep Freeze
cards above were buffed; Medium-vs-Medium win rates over 120 games per deck went from
65/65/22/26% to 60/63/39/36% (Grove Guard / Blaze Rush / Sugar Storm / Deep Freeze).

Every mechanic appears on at least one card. The four pre-made decks keep their current lists
(the deck rules in the v1 spec, section 5.1) with these new numbers.

## 7. AI

- **Evaluation** of a state: hero HP both sides; each creature's value from ATK, HP and
  keywords (Guard, Venom, Bubble, Leech, Flurry, Second Wind, Spell Power weighted); cards in
  hand; the threat of enemy lethal next turn; a win/loss is ±1000.
- **Easy:** best single next action by evaluation, but 25% of the time a random legal action
  instead.
- **Medium:** best single next action by evaluation.
- **Hard:** plans the turn with a beam search over action sequences (play, attack, boop,
  choose), keeping the best 6 states per step and visiting at most 1,500 states per decision
  (both tuned in stage 2). It always checks for lethal first.
- Dream Up: the AI picks the offered card that evaluates best in hand.
- Timing bar rates per difficulty are unchanged (hit 15/50/35, 30/50/20, 50/40/10; block 15/30/50%).
- **Speed:** the search cap is a number of states, so it is deterministic and testable; a
  headless benchmark prints the time per decision so the cap can be tuned for the user's laptop
  (Intel HD 620).
- **Proof:** seeded AI-vs-AI suites. Every match ends without errors and with only legal
  actions; Hard beats Easy at least 70% and Medium beats Easy at least 60% over the suite.

## 8. On screen

All of this is code, shaders and particles on the current models and icons; no new illustrated
art is needed.

- **Attacking:** press-and-drag from a ready creature; a chunky ink-outlined arrow follows the
  pointer. Valid targets glow, invalid ones dim, enemy Guards pulse. Release to attack: the
  creature leaps to the target (any lane, or the hero portrait), timing bar, impact, damage
  numbers on both sides for hit-back. AI attacks show the same arrow; the block bar appears as
  now.
- **Readiness:** a soft glowing ring under ready creatures; a sleepy "z" puff on creatures
  played this turn; creatures that have acted are slightly dimmed.
- **Keywords:** an icon badge on each creature's stat bar plus an on-model effect: Guard
  (see-through shield wall in front), Bubble (soap bubble that pops in a burst), Dash (speed
  lines and dust when it lands), Venom (green drips; its kills turn green while dissolving),
  Leech (red wisps from the hit to the hero portrait), Flurry (double swoosh), Hidden
  (see-through shimmer, burst on reveal), Second Wind (small halo; dissolve then re-form),
  Hush (grey wave, badges fade), Spell Power (spark badge "+N"; spell effects glow brighter).
- **Cards:** keywords in bold in the generated text; hovering a keyword shows its rule. Combo
  text is grey until active, then lights up.
- **HUD:** magic as 8 gems (filled/empty); END TURN replaces BATTLE! and pulses when nothing is
  left to do; the hand tray fits 8 cards.
- **Dream Up:** 3 cards rise to screen centre; click one; the others fly away.
- **Star Shard:** gold neutral frame with a star icon.
- The browser build (Compatibility renderer) must match the desktop look, as now.

## 9. Testing

- Unit tests for every `op`, every `who`, every keyword, and the edge cases: Bubble vs Venom,
  Bubble vs Leech, Hidden + Guard, Second Wind + When destroyed, Flurry + Freeze, Flurry + boop,
  Dash vs hero, Hush on Bubble/Guard/aura-boosted creatures, mutual kills, Ice Wall on attack and
  hit-back, Frost Spire on hit-back, Spell Power stacking, Combo counting, Dream Up with a full
  hand, the magic curve and cap, Star Shard, hand limit 8.
- Card data: every card file validates (known ops, who, keywords; targets present when needed);
  a snapshot of every card's generated text.
- AI: the suites in section 7, legal actions only, search cap respected.
- Existing tests that assume the old rules (flat 2 magic, attack phase, ability ids) are
  updated, not deleted, unless the rule they cover is gone.
- Visual: screenshots at each stage on desktop and in the browser renderer; frame rate on Low
  stays near 60 fps on the user's laptop.

## 10. Stages (user checkpoints)

1. **Engine:** data model, effect runner, rules, 41 migrated cards, generated text, tests.
   Checkpoint: headless match logs.
2. **AI:** evaluation, three difficulties, suites. Checkpoint: win-rate report.
3. **Play screen:** drag-to-attack, readiness, hit-back numbers, magic gems, END TURN, 8-card
   hand. Checkpoint: screenshots and a playable build.
4. **Mechanic visuals:** keyword badges and effects, Dream Up picker, Combo highlight, tooltips,
   Star Shard. Checkpoint: screenshots per mechanic.
5. **Web and polish:** browser build check, performance pass, redeploy. Checkpoint: live link.

## 11. Out of scope

New cards beyond Star Shard (card expansion), collection and deck editor (deckbuilding), hero
powers, secrets, online play.
