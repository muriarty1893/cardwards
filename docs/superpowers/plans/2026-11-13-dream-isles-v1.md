# Dream Isles v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> Also load the installed Godot skills where a task names them: `godot-gdscript`, `godot-gdscript-headless-testing`, `godot-resources`, `godot-3d-essentials`, `godot-ui-control`, `godot-animation`, `godot-signals-groups`, `godot-shaders`.

**Goal:** A playable Godot 4.7 desktop game in which you pick a pre-made deck and difficulty, then play a full 4-lane card battle against an AI on a 3D toy-diorama board.

**Architecture:** A pure rules engine (`core/`, no scene-tree nodes) takes `Action`s, mutates a `GameState` and returns `GameEvent`s. The AI (`ai/`) produces the same `Action`s. The 3D view (`view/`) sends actions and plays the returned events back as animations, never touching state directly. All randomness comes from seeds, so a match is replayable (ready for online play later).

**Tech Stack:** Godot 4.7.2 (`godot` on PATH), GDScript 2.0 with static typing, custom `Resource` data in `.tres`, headless SceneTree test runner.

**Spec:** `docs/superpowers/specs/2026-11-13-dream-isles-card-battler-design.md`

## Global Constraints

- All content original: no Adventure Time / Card Wars names, characters, land names, art or UI art.
- Godot 4.7, GDScript only, statically typed (`godot-gdscript` rules: no `:=` from Variant; use `maxi`/`clampi`, etc.).
- `core/` and `ai/` must not reference `Node`, `Node3D`, `Control` or the scene tree. They may use `Resource`, `RefCounted`, `RandomNumberGenerator`.
- Hero health 25 (cap 25). Starting hand 5. Hand limit 7. Magic set to 2 each turn, no carry-over. Deck 30 cards + 4 lands. Empty-deck draw = 2 hero damage.
- Timing: crit ×1.5 rounded up; normal ×1; glance ×0.5 rounded down, minimum 1. Block halves (rounded down). No tap within 2.0 s → normal / no block.
- AI hit rates (green/yellow/red): easy 15/50/35, medium 30/50/20, hard 50/40/10. AI block success: easy 15%, medium 30%, hard 50%.
- Land display names: "Mushroom Forest", "Ember Flats", "Candy Hills", "Frostpeak".
- Tests: `godot --headless --path . --script res://tests/run_tests.gd` must exit 0. Run `godot --headless --path . --import` first after adding `class_name` scripts.
- Commit after every task with a message ending in `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **A creature with effective ATK 0** (Snowmite 1 ATK opposite a Frost Spire): attacks deal 0 damage. The glance "minimum 1" never turns 0 into 1. Test lives in Task 6.
2. **A building removed under a damaged creature** (Sugar Sprite returning a Glowcap Lantern): the creature's max HP drops, and if damage ≥ new max HP it is destroyed right away. Test lives in Task 5.
3. **A targeted card with no legal target** (Fireball with no creatures on the board, Regrowth with no creature in discard, Lollibat booped with no empty lane, Swap Trick with fewer than 2 own creatures): validate rejects it with "No valid target" and no magic is spent. Test lives in Task 5.
4. **A card returned to a full hand** (7 cards, then Regrowth or Sugar Sprite): the card is discarded with a `card_burned` event instead of entering the hand. Test lives in Task 5.
5. **Any action after the game is over:** rejected with "Game is over". The view stops input and shows results. Test lives in Task 6.

---

## File map

```
project.godot                     main scene res://menus/main_menu.tscn, autoload Session
core/card_data.gd                 class_name CardData (Resource)
core/deck_data.gd                 class_name DeckData (Resource)
core/card_db.gd                   class_name CardDB — loads data/cards, data/decks
core/game_state.gd                class_name GameState, PlayerState, LaneState, CreatureState (inner classes)
core/action.gd                    class_name Action
core/game_event.gd                class_name GameEvent
core/rules.gd                     class_name Rules (static)
core/combat.gd                    class_name Combat (static damage maths)
core/abilities.gd                 class_name Abilities (static)
ai/ai_player.gd                   class_name AIPlayer
ai/ai_runner.gd                   class_name AIRunner (headless full-turn driver)
data/cards/<id>.tres              40 files
data/decks/<id>.tres              4 files
view/match.tscn, view/match.gd    MatchController
view/board/board.gd               Board (slab, islands, scenery, environment)
view/board/island.gd              Island
view/pieces/creature_view.gd      CreatureView + LOOKS table
view/pieces/building_view.gd      BuildingView
view/ui/hud.gd, hand.gd, card_widget.gd, timing_bar.gd, toast.gd, results.gd
view/fx/damage_number.gd, poof.gd, camera_rig.gd
view/event_player.gd              EventPlayer
view/input_controller.gd          InputController (drag, targeting)
menus/main_menu.tscn, main_menu.gd
autoload/session.gd               Session
tests/run_tests.gd, tests/test_case.gd, tests/fixtures.gd, tests/test_*.gd
tools/screenshot.gd               dev screenshot helper
```

---

### Task 1: Project skeleton and test runner

**Files:**
- Create: `project.godot`, `icon.svg`, `tests/run_tests.gd`, `tests/test_case.gd`, `tests/test_smoke.gd`, `tools/check_scripts_compile.gd` (copy of `~/.agents/skills/godot-gdscript/assets/check_scripts_compile.gd`)

**Interfaces:**
- Produces: `TestCase` (`tests/test_case.gd`, `class_name TestCase extends RefCounted`) with `passed: int`, `failed: int`, `assert_eq(actual, expected, label: String) -> void`, `assert_true(cond: bool, label: String) -> void`. Each test is a method named `test_*` returning `bool` (`true` on its last line).
- Produces: runner `tests/run_tests.gd` (`extends SceneTree`): finds every `res://tests/test_*.gd`, instantiates it, calls every method starting with `test_`. A call that returns non-`true` counts as a failure. Supports `-- --only=<substring>` from `OS.get_cmdline_user_args()` to filter by file or method name. Prints `Results: N passed, M failed` and calls `quit(1 if failed > 0 else 0)`. Follows Pattern 1 of `godot-gdscript-headless-testing`.

- [ ] **Step 1:** Create `project.godot` (`config/name="Dream Isles"`, `config/features=PackedStringArray("4.7")`, renderer `forward_plus`, window 1280×720, stretch mode `canvas_items`, aspect `expand`). No main scene yet.
- [ ] **Step 2:** Write `tests/test_smoke.gd` with `test_math()` asserting `assert_eq(2 + 2, 4, "math")` and, temporarily, `test_broken()` asserting `assert_eq(1, 2, "deliberate")`.
- [ ] **Step 3:** Write `tests/test_case.gd` and `tests/run_tests.gd`.
- [ ] **Step 4:** Run `godot --headless --path . --import && godot --headless --path . --script res://tests/run_tests.gd; echo exit=$?`. Expected: `1 passed, 1 failed`, `exit=1`. This proves the runner fails.
- [ ] **Step 5:** Delete `test_broken`. Run again. Expected `Results: 1 passed, 0 failed`, `exit=0`.
- [ ] **Step 6:** Run `godot --headless --path . --script res://tools/check_scripts_compile.gd`. Expected `broken: 0`.
- [ ] **Step 7:** Commit `chore: Godot project skeleton and headless test runner`.

---

### Task 2: Card and deck data (all 40 cards, 4 decks)

Load skill `godot-resources`.

**Files:**
- Create: `core/card_data.gd`, `core/deck_data.gd`, `core/card_db.gd`, `data/cards/*.tres` (40), `data/decks/*.tres` (4), `tests/test_data.gd`

**Interfaces:**
- Produces `CardData extends Resource`:
  - `enum Kind { CREATURE, BUILDING, SPELL }`
  - `enum Land { MUSHROOM, EMBER, CANDY, FROST }`
  - `const LAND_NAMES := ["Mushroom Forest", "Ember Flats", "Candy Hills", "Frostpeak"]`
  - `@export` fields: `id: StringName`, `display_name: String`, `kind: Kind`, `land: Land`, `level: int` (0 for non-creatures), `cost: int`, `attack: int`, `health: int`, `trigger: StringName`, `ability_id: StringName`, `target: StringName`, `text: String`
  - `trigger` ∈ `&"", &"on_play", &"on_boop", &"on_destroyed", &"on_deal_damage", &"start_of_turn", &"end_of_turn", &"passive"`
  - `target` ∈ `&"none", &"any_creature", &"own_creature", &"own_empty_lane", &"own_two_creatures", &"discard_creature"`
- Produces `DeckData extends Resource`: `id: StringName`, `display_name: String`, `lands: Array[int]` (4 `CardData.Land` values, lane order), `cards: Array[CardData]` (30).
- Produces `CardDB` (static): `static func card(id: StringName) -> CardData`, `static func all_cards() -> Array[CardData]`, `static func deck(id: StringName) -> DeckData`, `static func all_decks() -> Array[DeckData]`. Results are cached in static vars. A missing id raises `push_error` naming the id and returns `null`.

**Card ids and ability ids.** The id is the snake_case display name (e.g. `elder_shroomhulk`). Stats, costs and levels come from spec §5. Ability, trigger and target per card:

| id | trigger | ability_id | target |
|---|---|---|---|
| sporeling | on_boop | heal_self_2 | none |
| mossback | — | — | none |
| puffcap | on_boop | heal_hero_2 | none |
| glimmer_morel | on_boop | heal_all_own_1 | none |
| rootstalker | on_play | heal_hero_2 | none |
| elder_shroomhulk | on_boop | heal_all_own_3 | none |
| spore_hut | start_of_turn | heal_lane_creature_1 | none |
| glowcap_lantern | passive | lane_max_hp_3 | none |
| rain_of_spores | on_play | heal_target_4 | own_creature |
| regrowth | on_play | return_from_discard | discard_creature |
| cinderpup, flarebeak | — | — | none |
| ashmite | on_boop | dmg_opposing_1 | none |
| magmaw | on_boop | dmg_enemy_hero_2 | none |
| blazehorn | on_play | dmg_opposing_2 | none |
| inferno_drake | on_boop | dmg_all_enemy_2 | none |
| kiln_tower | passive | lane_atk_2 | none |
| smokestack | end_of_turn | dmg_enemy_hero_1 | none |
| fireball | on_play | dmg_target_3 | any_creature |
| ember_rain | on_play | dmg_all_enemy_2 | none |
| gumdrop | on_boop | draw_1 | none |
| taffy_snail | on_play | gain_magic_1 | none |
| lollibat | on_boop | move_self | own_empty_lane |
| sugar_sprite | on_boop | bounce_opposing_building | none |
| jellywobble | on_destroyed | draw_2 | none |
| bonbon_behemoth | on_boop | draw_2 | none |
| sugar_shack | passive | lane_atk_1_hp_1 | none |
| candy_mill | start_of_turn | gain_magic_1 | none |
| sugar_rush | on_play | draw_2 | none |
| swap_trick | on_play | swap_two | own_two_creatures |
| snowmite | on_boop | freeze_opposing | none |
| iceling, glacier_tortoise | — | — | none |
| frostfang | on_deal_damage | freeze_damaged | none |
| rimewing | on_play | freeze_opposing | none |
| blizzard_titan | on_boop | freeze_all_enemy | none |
| ice_wall | passive | lane_damage_minus_1 | none |
| frost_spire | passive | opposing_atk_minus_1 | none |
| cold_snap | on_play | freeze_target | any_creature |
| avalanche | on_play | dmg_target_3_freeze | any_creature |

Decks follow spec §5.1. Ids: `grove_guard`, `blaze_rush`, `sugar_storm`, `deep_freeze`. Lands are in lane order main, main, splash, main.

- [ ] **Step 1: Write failing tests** in `tests/test_data.gd`:
  - `test_card_count`: `CardDB.all_cards().size() == 40`; 10 per land.
  - `test_card_shapes`: every creature has `level` 1–3, `attack >= 0`, `health > 0`; every card has `cost` 0–2; buildings and spells have `level == 0`; `target` is in the allowed set; `trigger != &""` implies `ability_id != &""`.
  - `test_spot_values`: `card(&"elder_shroomhulk")` is level 3, cost 2, 5/10; `card(&"swap_trick").cost == 0`; `card(&"blazehorn").attack == 6`.
  - `test_decks`: 4 decks; each has 30 cards and 4 lands; `deck(&"blaze_rush").lands == [EMBER, EMBER, CANDY, EMBER]`; for every deck, each non-main-land card is level ≤ 1.
- [ ] **Step 2:** Run with `--only=test_data`. Expected: FAIL (CardDB not declared).
- [ ] **Step 3:** Implement the three scripts and write the 44 `.tres` files using the text format of `godot-resources` Pattern 2. Leave out `uid=`. Deck `.tres` files reference card `.tres` files as `ExtResource`.
- [ ] **Step 4:** Run `--import`, then the tests. Expected PASS.
- [ ] **Step 5:** Commit `feat: card and deck data for 40 cards and 4 decks`.

---

### Task 3: Game state, actions, events and turn start

**Files:**
- Create: `core/game_state.gd`, `core/action.gd`, `core/game_event.gd`, `core/rules.gd`, `tests/fixtures.gd`, `tests/test_turns.gd`

**Interfaces:**
- Produces `GameState extends RefCounted`:
  - `enum Phase { MAIN, ATTACK, OVER }`
  - `var players: Array[PlayerState]` (size 2), `active: int`, `first_player: int`, `turn: int` (global count, starts at 1), `phase: Phase`, `winner: int = -1`, `rng: RandomNumberGenerator`
  - `func clone() -> GameState` is a deep copy. Cards are shared because they are immutable; the rng copies `seed` and `state`.
  - `func opponent(p: int) -> int`
  - Inner classes:
    - `PlayerState`: `hero_hp: int = 25`, `magic: int`, `magic_cap: int`, `deck: Array[CardData]`, `hand: Array[CardData]`, `discard: Array[CardData]`, `lanes: Array[LaneState]` (4)
    - `LaneState`: `land: int`, `creature: CreatureState` (nullable), `building: CardData` (nullable)
    - `CreatureState`: `card: CardData`, `damage: int`, `freeze_turn: int = -1` (frozen when ≥ 0), `acted: bool` (attacked or booped this turn), `played_turn: int`
- Produces `Action extends RefCounted`: `enum Type { PLAY_CARD, BOOP, BEGIN_ATTACKS, ATTACK, END_TURN }`, `enum Hit { NORMAL, CRIT, GLANCE }`, fields `type`, `player: int`, `hand_index: int = -1`, `lane: int = -1`, `targets: Array[Dictionary]`, `hit: Hit`, `blocked: bool`.
  - A target is `{"player": int, "lane": int}` for creatures and lanes, or `{"discard": int}` for a discard index.
  - Static constructors: `play(p, hand_index, lane, targets := [])`, `boop(p, lane, targets := [])`, `begin_attacks(p)`, `attack(p, lane, hit, blocked)`, `end_turn(p)`.
  - `to_dict() -> Dictionary`, `static from_dict(d: Dictionary) -> Action`.
- Produces `GameEvent extends RefCounted`: `type: StringName`, `data: Dictionary`, `to_dict()`.
  - Event types: `turn_started{player,turn}`, `magic_changed{player,value}`, `card_drawn{player,card}`, `card_burned{player,card}`, `fatigue{player,amount}`, `creature_played{player,lane,card}`, `building_played{player,lane,card}`, `spell_cast{player,card}`, `booped{player,lane}`, `phase_changed{phase}`, `attack{player,lane,hit,target}` (target `"creature"`/`"hero"`), `creature_damaged{player,lane,amount,hit,blocked}`, `hero_damaged{player,amount}`, `creature_healed{player,lane,amount}`, `hero_healed{player,amount}`, `frozen{player,lane}`, `unfrozen{player,lane}`, `creature_destroyed{player,lane,card}`, `building_returned{player,lane,card}`, `creature_moved{player,from,to}`, `card_returned{player,card}`, `game_over{winner}`.
  - `card` values are card id `StringName`s.
- Produces `Rules` (static):
  - `static func setup(deck_a: DeckData, deck_b: DeckData, seed: int) -> GameState`: shuffles copies of each deck with `state.rng`, places lands, draws 5 each, flips a coin with the rng for `first_player`, sets `active = first_player`, `turn = 1`.
  - `static func start_turn(state: GameState) -> Array[GameEvent]`, in order: `turn_started`; magic := 2; start-of-turn triggers (they call `Abilities`, which Task 5 adds; until then there is a no-op hook `_run_lane_triggers(state, p, &"start_of_turn", events)`); `magic_cap := magic`; `magic_changed`; draw 1, except when `turn == 1`.
  - `static func draw(state, p, events) -> void`: deck empty → `hero_hp -= 2` + `fatigue`; hand size 7 → `card_burned`; otherwise `card_drawn`.
  - `static func validate(state: GameState, a: Action) -> String` (`""` = legal) and `static func apply(state: GameState, a: Action) -> Array[GameEvent]` (`push_warning` and return `[]` if not legal). This task implements only phase and turn checks plus END_TURN; later tasks fill in the rest.
- Produces `Fx` (`tests/fixtures.gd`, static):
  - `blank(lands_a: Array[int], lands_b: Array[int]) -> GameState`: empty decks, hands and lanes, `turn = 3`, `active = 0`, `phase = MAIN`, magic 2, rng seeded 1.
  - `put_creature(state, p, lane, id: StringName, damage := 0) -> void`
  - `put_building(state, p, lane, id) -> void`
  - `give(state, p, id) -> int` returns the hand index
  - `types(events) -> Array[StringName]`

- [ ] **Step 1: Write failing tests** in `tests/test_turns.gd`:
  - `test_setup`: `Rules.setup(deck(&"grove_guard"), deck(&"blaze_rush"), 42)`; each hand 5, deck 25, hero 25, lands match the decks. The same seed gives the same hands and first player twice; seed 43 gives a different order for at least one player.
  - `test_first_turn_no_draw`: after `setup` + `start_turn`, the active player's hand is 5 and magic is 2.
  - `test_second_turn_draws`: END_TURN from turn 1 flows into the opponent's `start_turn`. `turn == 2`, the opponent has hand 6, and events include `card_drawn`.
  - `test_fatigue`: empty deck → hero 23, event `fatigue{amount:2}`.
  - `test_hand_limit`: hand of 7 → card goes to discard, event `card_burned`, hand still 7.
  - `test_not_your_turn`: `validate(state, Action.end_turn(1))` with active 0 → `"Not your turn"`.
  - `test_action_roundtrip`: `Action.from_dict(a.to_dict())` keeps every field.
- [ ] **Step 2:** Run with `--only=test_turns`. Expected: FAIL.
- [ ] **Step 3:** Implement. END_TURN in this task is legal in MAIN or ATTACK, and: runs end-of-turn triggers (hook), clears freezes (Task 6 fills this in), resets `acted`, flips `active`, `turn += 1`, sets phase MAIN, and returns `start_turn` events appended. (Task 6 tightens END_TURN to ATTACK only.)
- [ ] **Step 4:** Run. Expected PASS. Run the compile check.
- [ ] **Step 5:** Commit `feat: game state, actions, events and turn flow`.

---

### Task 4: Playing creatures, buildings and spells

**Files:**
- Modify: `core/rules.gd`
- Create: `tests/test_play.gd`

**Interfaces:**
- Consumes: Task 3 types, `CardDB`.
- Produces in `Rules`:
  - `static func matching_lands(state, p, land: int) -> int`
  - `static func valid_targets(state, p, card: CardData, source_lane := -1) -> Array[Dictionary]`. For `own_two_creatures` it returns single creatures; validate checks that 2 distinct ones are chosen.
- Validation messages, exact and checked in this order: `"Game is over"`, `"Not your turn"`, `"Can't do that now"` (wrong phase), `"No such card"`, `"Not enough magic"`, `"Needs %d %s lands" % [level, LAND_NAMES[land]]`, `"Lane already has a creature"`, `"Lane already has a building"`, `"No valid target"`, `"Invalid target"`.
- PLAY_CARD effects: pay cost → `magic_changed`; remove from hand. Creature: placed with `played_turn = turn` → `creature_played` → on_play trigger. Building: placed → `building_played`. Spell: `spell_cast` → ability → discard. Spell abilities and on_play triggers call `Abilities.run(state, p, lane, card, targets, events)`; until Task 5 that hook is a stub that does nothing.

- [ ] **Step 1: Write failing tests:**
  - `test_play_creature`: L1 creature to an empty lane; magic 2 → 1; `creature_played`.
  - `test_not_enough_magic`: magic 0 → `"Not enough magic"`, state unchanged.
  - `test_level_requirement`: an Ember L2 creature with 1 Ember land → `"Needs 2 Ember Flats lands"`; with 2 Ember lands it succeeds even when placed on a Frostpeak land.
  - `test_lane_occupied`: second creature on the same lane → `"Lane already has a creature"`; building + creature on one lane is allowed; a second building → `"Lane already has a building"`.
  - `test_spell_discarded`: Sugar Rush leaves the hand and ends up in discard; `spell_cast`.
  - `test_wrong_phase`: phase ATTACK → PLAY_CARD gives `"Can't do that now"`.
- [ ] **Step 2:** Run `--only=test_play`. FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run all tests. PASS.
- [ ] **Step 5:** Commit `feat: playing creatures, buildings and spells`.

---

### Task 5: Abilities, boop and passive modifiers

**Files:**
- Create: `core/abilities.gd`, `tests/test_abilities.gd`
- Modify: `core/rules.gd` (BOOP action, trigger hooks, death check)

**Interfaces:**
- Produces `Abilities` (static): `static func run(state: GameState, p: int, lane: int, card: CardData, targets: Array[Dictionary], events: Array[GameEvent]) -> void`. It dispatches on `card.ability_id` (table in Task 2). If a target vanished, it does nothing and calls `push_warning`.
- Produces in `Rules`:
  - `static func effective_attack(state, p, lane) -> int`: base + own lane `lane_atk_2` (+2) / `lane_atk_1_hp_1` (+1), minus 1 if the **opposing** lane's building is `opposing_atk_minus_1`; min 0.
  - `static func effective_max_hp(state, p, lane) -> int`: base + `lane_max_hp_3` (+3) / `lane_atk_1_hp_1` (+1).
  - `static func deal_creature_damage(state, p, lane, amount, events, hit := Action.Hit.NORMAL, blocked := false) -> void`
  - `static func heal_creature(...)`, `static func damage_hero(state, p, amount, events)`, `static func heal_hero(...)` (cap 25)
  - `static func resolve_deaths(state, events) -> void`: damage ≥ effective max HP → `creature_destroyed`, run on_destroyed (Jellywobble draws 2 for its owner), card to owner's discard. Then any hero ≤ 0 → phase OVER, winner = the other player, or `active` if both are ≤ 0 → `game_over`. Call it after every action and every trigger.
  - `static func return_to_hand(state, p, card, events)`: hand 7 → discard + `card_burned`; else `card_returned`.
- BOOP: legal when MAIN, own creature present, not `acted`, not frozen (`"Creature is frozen"`, `"Creature already acted"`), and its trigger is `on_boop` (`"No boop ability"`). It sets `acted = true` → `booped` → runs the ability.
- "Opposing" = the same lane index on the opponent's side. `dmg_all_enemy_2`, `freeze_all_enemy` and `heal_all_own_*` touch only lanes with creatures.
- Freeze (`frozen` event) sets `freeze_turn = state.turn`.

- [ ] **Step 1: Write failing tests** with one assertion group per ability id. Name each `test_<ability_id>` and use exact numbers from the spec. Examples:
  - `test_heal_self_2`: Sporeling with damage 3 → boop → damage 1; `acted` true.
  - `test_dmg_all_enemy_2`: Inferno Drake boop vs two enemy creatures at 2 HP and 5 HP → first destroyed (`creature_destroyed`), second damage 2.
  - `test_lane_max_hp_3`: Mossback on Glowcap Lantern → effective max HP 9.
  - `test_opposing_atk_minus_1`: Snowmite opposite Frost Spire → effective attack 0.
  - `test_draw_2_on_destroyed`: Jellywobble dies → its owner draws 2.
  - `test_swap_two`, `test_move_self`, `test_return_from_discard`, `test_bounce_opposing_building`, `test_gain_magic_1` (Candy Mill at start of turn → magic 3 and `magic_cap` 3), `test_dmg_enemy_hero_1` (Smokestack at end of turn).
  - `test_boop_blocks`: second boop → `"Creature already acted"`; a frozen creature → `"Creature is frozen"`; Mossback → `"No boop ability"`.
  - **Review Focus 2** `test_building_removed_kills`: Mossback (6 HP) with damage 7 on Glowcap Lantern; the enemy Sugar Sprite boops → building returned, Mossback destroyed.
  - **Review Focus 3** `test_no_valid_target`: Fireball with no creatures anywhere; Regrowth with no creature in discard; Lollibat boop with no empty own lane; Swap Trick with 1 own creature. Each → `"No valid target"`, magic unchanged, card still in hand.
  - **Review Focus 4** `test_return_to_full_hand`: hand of 7 (after paying for Regrowth, refill to 7) → the returned creature goes to discard, `card_burned`.
- [ ] **Step 2:** Run `--only=test_abilities`. FAIL.
- [ ] **Step 3:** Implement `Abilities.run` and the Rules helpers. Replace Task 3/4 stubs with real calls.
- [ ] **Step 4:** Run all tests. PASS.
- [ ] **Step 5:** Commit `feat: abilities, boop and building modifiers`.

---

### Task 6: Attack phase, freeze lifecycle and winning

**Files:**
- Create: `core/combat.gd`, `tests/test_combat.gd`
- Modify: `core/rules.gd`

**Interfaces:**
- Produces `Combat` (static):
  - `static func attack_damage(attack: int, hit: Action.Hit, blocked: bool, ice_wall: bool) -> int`. Order: if `attack == 0` return 0; apply hit (CRIT `ceili(attack * 1.5)`, GLANCE `maxi(1, attack / 2)`); if `ice_wall`, `maxi(1, d - 1)`; if `blocked`, `d / 2`.
  - `static func hero_damage(attack: int, hit: Action.Hit) -> int`: same without ice wall or block.
- Produces in `Rules`:
  - `static func attackers(state) -> Array[int]`: active player's lanes with a creature that is not `acted` and not frozen. Returns `[]` when `turn == 1`.
  - `static func has_defender(state, lane) -> bool`
- BEGIN_ATTACKS: MAIN only → phase ATTACK → `phase_changed`.
- ATTACK: phase ATTACK only, and `lane in attackers(state)` (`"Can't attack"`) → `acted = true` → `attack` event. Then either `deal_creature_damage` to the opposing creature with `Combat.attack_damage`, plus `freeze_damaged` (Frostfang) if damage > 0, or `damage_hero` with `Combat.hero_damage` → `resolve_deaths`. `blocked` is ignored for hero hits.
- END_TURN: phase ATTACK only (`"Can't do that now"`) → end-of-turn triggers → for the active player's creatures with `0 <= freeze_turn < state.turn`, set `freeze_turn = -1` → `unfrozen` → reset `acted` → next player's `start_turn`.

- [ ] **Step 1: Write failing tests:**
  - `test_damage_table`: `attack_damage(4, NORMAL, false, false) == 4`; `(4, CRIT) == 6`; `(5, CRIT) == 8`; `(5, GLANCE) == 2`; `(1, GLANCE) == 1`; `(6, NORMAL, true, false) == 3`; `(6, CRIT, true, false) == 4`; `(3, NORMAL, false, true) == 2`; `(1, NORMAL, false, true) == 1`.
  - **Review Focus 1** `test_zero_attack`: `attack_damage(0, GLANCE, false, false) == 0`, also with CRIT. Snowmite opposite Frost Spire attacks → `creature_damaged` amount 0 (or no damage event) and the defender is unchanged.
  - `test_empty_lane_hits_hero`: Cinderpup, empty opposing lane, CRIT → enemy hero 25 − 5 = 20.
  - `test_first_turn_no_attack`: `turn == 1` → `attackers == []`.
  - `test_booped_cannot_attack`: a booped creature is not in `attackers`.
  - `test_frostfang_freezes`: the damaged defender gets `freeze_turn`. On the defender's next turn it is not in `attackers` and boop gives `"Creature is frozen"`. After that turn's END_TURN it is unfrozen.
  - `test_cold_snap_own_turn`: Cold Snap on the enemy during my turn → frozen through the enemy's next turn, then cleared.
  - `test_win`: enemy hero 3, Flarebeak hits → phase OVER, `game_over{winner:0}`.
  - `test_simultaneous_death`: set both `hero_hp` to 0 directly, call `Rules.resolve_deaths` → winner == `active`.
  - **Review Focus 5** `test_after_game_over`: every action type → `"Game is over"`.
- [ ] **Step 2:** Run `--only=test_combat`. FAIL.
- [ ] **Step 3:** Implement. Update Task 3's END_TURN test to go through BEGIN_ATTACKS first.
- [ ] **Step 4:** Run all tests. PASS.
- [ ] **Step 5:** Commit `feat: attack phase, damage maths, freeze and win conditions`.

---

### Task 7: Legal actions and seeded replay

**Files:**
- Modify: `core/rules.gd`
- Create: `tests/test_replay.gd`

**Interfaces:**
- Produces `Rules.legal_actions(state) -> Array[Action]`: during MAIN, every PLAY_CARD (each hand card × each lane × each valid target combination; spells use lane −1) and every BOOP that passes `validate`, plus BEGIN_ATTACKS. During ATTACK: one ATTACK per attacker with hit NORMAL, plus END_TURN. Empty when OVER.

- [ ] **Step 1: Write failing tests:**
  - `test_legal_actions_all_valid`: across 200 random steps from `setup(…, 7)`, every element of `legal_actions` validates as `""`.
  - `test_replay_identical`: play a match with an rng seeded 99 choosing random legal actions until OVER or 400 actions. Record the action dicts. Replay them from `setup(same decks, same seed)` via `Action.from_dict` and assert the final `hero_hp`s, `turn` and the concatenated event type list are identical.
- [ ] **Step 2:** Run. FAIL.
- [ ] **Step 3:** Implement `legal_actions`.
- [ ] **Step 4:** Run all tests. PASS.
- [ ] **Step 5:** Commit `feat: legal action enumeration and deterministic replay`.

---

### Task 8: AI opponent

**Files:**
- Create: `ai/ai_player.gd`, `ai/ai_runner.gd`, `tests/test_ai.gd`

**Interfaces:**
- Produces `AIPlayer extends RefCounted`:
  - `enum Difficulty { EASY, MEDIUM, HARD }`
  - `func _init(player: int, difficulty: Difficulty, seed: int)`
  - `func choose_main_action(state: GameState) -> Action`: the best-scoring legal MAIN action with score > current, else BEGIN_ATTACKS.
  - `func roll_hit() -> Action.Hit` and `func roll_block() -> bool`, using the Global Constraints rates.
  - `func evaluate(state: GameState) -> float`, from the AI's point of view:
    `(my_hp − foe_hp) * 1.0 + Σ_my_creatures (eff_atk + remaining_hp) * 0.5 − Σ_foe_creatures (eff_atk + remaining_hp) * 0.5 + my_hand * 0.3 + Σ_my_attackers expected_attack * 0.8`
    where `expected_attack` = `effective_attack` against the opposing creature, or 1.2× if it hits the hero. A creature counts as an attacker only if it is in `attackers` as computed for this state's active player, ignoring the turn-1 rule. A win state scores +1000, a loss −1000.
  - Scoring a candidate: `evaluate(clone + apply)`.
- Produces `AIRunner` (static):
  - `static func play_turn(state: GameState, ai: AIPlayer, defender_ai: AIPlayer, events: Array[GameEvent]) -> void`: applies `ai.choose_main_action` until it returns BEGIN_ATTACKS (cap 30 actions, then forces BEGIN_ATTACKS). Then for each lane in `Rules.attackers`: hit = `ai.roll_hit()`, blocked = `defender_ai.roll_block()` if there is a defender, else false → ATTACK. Stops if OVER, otherwise END_TURN.
  - `static func play_match(state: GameState, ais: Array[AIPlayer], max_turns := 200) -> int`: calls `start_turn`, then `play_turn` alternately; returns the winner, or −1 if `max_turns` is reached.

- [ ] **Step 1: Write failing tests:**
  - `test_ai_takes_lethal`: AI has Flarebeak in hand, enemy hero 3 with an empty opposite lane, magic 2 → the AI plays it, and the match ends with the AI winning that turn.
  - `test_ai_prefers_kill`: given Fireball and an enemy 3-HP creature → the AI casts Fireball on it.
  - `test_hit_rates`: 10 000 `roll_hit` calls on HARD → crit share within 0.47–0.53.
  - `test_ai_vs_ai_100`: for seeds 1..100, every deck pair, cycling difficulties → `play_match` returns 0 or 1 (never −1). Print the per-deck win counts.
- [ ] **Step 2:** Run. FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run all tests. PASS. Note in the commit body if any deck wins more than 70% of matches, as balance feedback for the user.
- [ ] **Step 5:** Commit `feat: greedy AI and AI-vs-AI soak test`.

---

### Task 9: 3D board scene and screenshot harness

Load skills `godot-3d-essentials`, `godot-shaders`.

**Files:**
- Create: `view/match.tscn`, `view/match.gd` (stub that builds a Board), `view/board/board.gd`, `view/board/island.gd`, `view/fx/camera_rig.gd`, `tools/screenshot.gd`

**Interfaces:**
- Produces `Board extends Node3D`:
  - `func build(lands: Array[Array]) -> void`, where `lands[player][lane]` is a `CardData.Land`
  - `func island(player: int, lane: int) -> Island`
  - `func anchor(player: int, lane: int) -> Vector3`: the world position where a creature stands
  - `func lane_at_screen(cam: Camera3D, screen_pos: Vector2) -> Dictionary`: `{player, lane}` or `{}`. It intersects the camera ray with the plane y = 0 and picks the island whose centre is within radius 1.05.
  - Layout: lane x = −3.9, −1.3, 1.3, 3.9. Player 0 (human) at z = 1.6, player 1 at z = −2.8. Slab 11 × 0.5 × 8.6 at (0, −0.55, −0.6).
- Produces `Island extends Node3D`: `func setup(land: int) -> void` builds a cylinder top (r 1.05, h 0.28) with the land colour, a bottom, and decorations. Colours and decorations: mushroom `#7bd36a` mushrooms, ember `#ff7a3a` glowing rocks, candy `#ffb3dd` lollipops, frost `#dff4ff` crystals. `func set_highlight(mode: int)` with modes 0 off, 1 valid (white pulsing torus), 2 target (yellow).
- Produces `CameraRig extends Node3D`: camera at (0, 8.2, 10.5) looking at (0, 0, −0.6), FOV 42; `func kick(strength: float)` shake that decays over 0.25 s.
- Environment: WorldEnvironment with sky colour `#8fd3ff`, ACES tonemap, fog, a DirectionalLight with shadows, a meadow disc and 26 scattered trees (as in the mockup `.superpowers/brainstorm/*/content/board-layout.html`).
- Produces `tools/screenshot.gd`, an autoload added only in dev. When the user arg `--shot=<path>` is present, it waits for `--shot-frames=<n>` (default 60) frames, then saves the viewport image to the path and quits.

- [ ] **Step 1:** Build the scene so `view/match.gd` calls `board.build` with Blaze Rush vs Deep Freeze lands.
- [ ] **Step 2:** Verify headless: `godot --headless --path . --quit-after 120 res://view/match.tscn > run.log 2>&1; grep -nE "SCRIPT ERROR|^ERROR:" run.log`. Expected: no matches.
- [ ] **Step 3:** Verify visually: `godot --path . res://view/match.tscn -- --shot=/tmp/board.png`, then view the PNG. Expected: 8 islands in two rows on the slab, a sky background, visible shadows, nothing black or washed out. Compare against the mockup.
- [ ] **Step 4:** Commit `feat: 3D diorama board scene`.

---

### Task 10: Creature and building pieces; state sync

**Files:**
- Create: `view/pieces/creature_view.gd`, `view/pieces/building_view.gd`
- Modify: `view/match.gd`

**Interfaces:**
- Produces `CreatureView extends Node3D`:
  - `static func create(card: CardData) -> CreatureView`: if `res://view/pieces/creatures/<id>.tscn` exists, instance that; otherwise build a blob from `LOOKS[id]`.
  - `LOOKS` is a `Dictionary` mapping each of the 24 creature ids to `{color: Color, scale: float, feature: StringName}`. Features: `&"none", &"cap", &"horns", &"ears", &"spikes", &"wings", &"shell"`. The colour is derived from the land palette with variation; level-3 creatures use scale 1.3.
  - `func set_stats(atk: int, hp_left: int, max_hp: int) -> void` updates a floating Label3D badge "⚔ x ❤ y".
  - `func set_frozen(on: bool)` gives an icy tint plus a translucent cube.
  - `func idle(t: float)` hop: `y = 0.58 + max(0, sin(t*2.6 + phase)) * 0.15` with squash.
  - Human creatures face −z, AI creatures face +z.
- Produces `BuildingView extends Node3D`: `static func create(card: CardData) -> BuildingView` (tower and roof coloured by land), placed at the island offset (0.62, 0, −0.45), scale 0.75.
- Produces `MatchController` (`view/match.gd`):
  - `var state: GameState`
  - `func sync_all() -> void` rebuilds all pieces from `state`. It is used at start and as a fallback; animations use EventPlayer (Task 12).

- [ ] **Step 1:** Write a dev seed path in `match.gd` that runs `Rules.setup` and plays 6 AI turns via `AIRunner` when `--demo-board` is passed, then calls `sync_all()`.
- [ ] **Step 2:** Run the headless check from Task 9 Step 2. Expected: clean log.
- [ ] **Step 3:** Take a screenshot with `-- --demo-board --shot=/tmp/pieces.png` and view it. Expected: creatures on several islands on both sides with readable stat badges and at least one building.
- [ ] **Step 4:** Commit `feat: creature and building pieces synced from game state`.

---

### Task 11: HUD, hand, drag-to-play and targeting

Load skills `godot-ui-control`, `godot-signals-groups`.

**Files:**
- Create: `view/ui/hud.gd`, `view/ui/hand.gd`, `view/ui/card_widget.gd`, `view/ui/toast.gd`, `view/input_controller.gd`, `tests/test_ui_layout.gd`
- Modify: `view/match.gd`, `view/match.tscn`

**Interfaces:**
- Produces `Hud extends Control`:
  - `func refresh(state: GameState) -> void`
  - Rival panel top-left: avatar, "Rival", ❤ hp, ✦ magic, 🂠 hand count, deck count.
  - Your panel left at mid-height: ❤ hp, "✦ magic/magic_cap".
  - "Turn N" top-right. END TURN button on the right at mid-height.
  - `signal end_turn_pressed`
  - `func set_input_enabled(on: bool)`
  - Style: white rounded panels, 3 px `#223333` border, bottom shadow, yellow END TURN `#ffcf3a`.
- Produces `CardWidget extends Control` (120×168): cost bubble, art block (land colour + emoji per card from a `ICONS` dictionary), name, type label, ⚔/❤ for creatures, rules `text` shown on hover via a tooltip panel. `func set_playable(on: bool)` dims unplayable cards.
- Produces `Hand extends Control`:
  - `func show_hand(cards: Array[CardData], playable: Array[bool])` fans cards along the bottom (x offset 95 px, rotation 4.8° per step); hover raises a card 50 px.
  - `signal card_drag_started(index: int)`, `signal card_dropped(index: int, screen_pos: Vector2)`
- Produces `InputController extends Node`:
  - It owns the interaction mode: `IDLE`, `DRAGGING`, `TARGETING`.
  - On drag start, it highlights the islands where `Rules.validate(play)` is `""`.
  - On drop over an island, it builds `Action.play`. If the card needs targets, it enters TARGETING: valid target islands are highlighted yellow and clicking them collects targets (2 for `own_two_creatures`; spells target after dropping anywhere on the board). Right-click or Esc cancels.
  - Clicking your own creature with an on_boop ability during MAIN triggers a boop, entering TARGETING first for Lollibat.
  - `signal action_requested(action: Action)`
  - Rejected actions call `Toast.show(message)`, which displays the validate string for 1.5 s near the top centre.
- Layout test (`godot-ui-control` headless layout check): `test_hud_fits`, at 1280×720 and 1920×1080 instantiate the HUD and Hand, then assert no panel rect leaves the viewport and END TURN does not overlap the hand.

- [ ] **Step 1:** Write `tests/test_ui_layout.gd`. Run it. FAIL.
- [ ] **Step 2:** Implement the HUD, hand and card widget. Run. PASS.
- [ ] **Step 3:** Implement InputController and wire `action_requested` → `Rules.apply` → `sync_all()` + `hud.refresh()` (temporary, until Task 12).
- [ ] **Step 4:** Run the game windowed (`godot --path . res://view/match.tscn`) and play a few cards. Then take a resting screenshot with `-- --demo-board --shot=/tmp/hud.png` and check the hand fan and HUD placement against the mockup.
- [ ] **Step 5:** Commit `feat: HUD, hand, drag-to-play, targeting and boop input`.

---

### Task 12: Event playback and effects

Load skill `godot-animation`.

**Files:**
- Create: `view/event_player.gd`, `view/fx/damage_number.gd`, `view/fx/poof.gd`
- Modify: `view/match.gd`

**Interfaces:**
- Produces `EventPlayer extends Node`:
  - `func play(events: Array[GameEvent]) -> void` is a coroutine. It awaits each event's animation in order using Tweens and holds a reference to the views by `(player, lane)`.
  - Durations: `creature_played` 0.45 s (drop from y+3 with bounce); `building_played` 0.35 s; `spell_cast` 0.5 s (card flies to the centre and bursts); `booped` 0.3 s (squash and glow); `attack` 0.75 s (lunge arc to the opposing anchor or the enemy hero edge at z ±4.4, then return); `creature_damaged` 0.35 s (shake + DamageNumber, "CRIT!" gold on crit, grey on glance, "BLOCK" tag when blocked); `hero_damaged` 0.4 s (HUD shake + number); `creature_destroyed` 0.4 s (Poof + remove view); `frozen`/`unfrozen` 0.25 s; `card_drawn` 0.2 s; `game_over` → results overlay (Task 14).
  - Camera kick: 0.15 on hit, 0.3 on crit.
  - Other events → `hud.refresh` with no wait.
  - `signal finished`
- Produces `DamageNumber extends Label3D`: `static func spawn(parent: Node3D, pos: Vector3, text: String, color: Color)` rises 0.8 over 1.2 s and fades.
- Produces `Poof extends GPUParticles3D` (or CPUParticles3D for headless safety): one-shot burst of 24 soft spheres, freed on finish.
- MatchController flow: `action_requested` → `Rules.validate` → `Rules.apply` → `await event_player.play(events)` → `hud.refresh` and refresh the hand → re-enable input. Input stays disabled while playing.

- [ ] **Step 1:** Implement EventPlayer plus FX. Replace the `sync_all` call after actions with playback (keep `sync_all` for match start).
- [ ] **Step 2:** Headless check (Task 9 Step 2) with `--demo-board` → clean log.
- [ ] **Step 3:** Play windowed and visually confirm each listed animation once. Screenshot the moment after a damage number spawns (`--shot-frames` tuned by an `--auto-attack` dev flag that runs one attack on load).
- [ ] **Step 4:** Commit `feat: animated event playback and hit effects`.

---

### Task 13: Timing bar and turn orchestration (human and AI)

**Files:**
- Create: `view/ui/timing_bar.gd`, `tests/test_timing_bar.gd`
- Modify: `view/match.gd`

**Interfaces:**
- Produces `TimingBar extends Control` (380×90 panel at the upper centre, like the mockup):
  - `func run_attack() -> Action.Hit` and `func run_block() -> bool` are coroutines.
  - The needle sweeps back and forth across the bar with a 1.25 s period. Bar zones as fractions: red 0–0.30, yellow 0.30–0.44, green 0.44–0.56, yellow 0.56–0.70, red 0.70–1.0.
  - Input: left click or Space stops the needle. With no input after 2.0 s it returns NORMAL / false.
  - Block mode shows the title "BLOCK! tap in the green" and only the green zone counts.
  - `static func zone_at(x: float) -> Action.Hit`, where `x` is 0..1.
  - `func simulate(result) -> void` animates the needle stopping at the zone for AI rolls (0.8 s) so the human sees what the AI got.
- MatchController turn flow:
  - **Human END TURN:** `BEGIN_ATTACKS` → for each lane in `Rules.attackers`: `hit = await timing_bar.run_attack()`, `blocked` = AI `roll_block()` if there is a defender → apply ATTACK → play events, stopping if OVER → END_TURN → play events → AI turn.
  - **AI turn:** loop `choose_main_action` with 0.6 s pauses → play events, until BEGIN_ATTACKS → for each attacker: `hit = ai.roll_hit()` shown via `simulate`; if the human has a defender, `blocked = await timing_bar.run_block()` → ATTACK → END_TURN → human's turn.

- [ ] **Step 1: Write failing tests** `test_zone_at`: `zone_at(0.5) == CRIT`, `zone_at(0.35) == NORMAL`, `zone_at(0.65) == NORMAL`, `zone_at(0.1) == GLANCE`, `zone_at(0.95) == GLANCE`, `zone_at(0.44) == CRIT`. Also a timeout test: instantiate the bar in the tree, `await run_attack()` with no input, and expect NORMAL after about 2 s (allow 1.9–2.3 s).
- [ ] **Step 2:** Run. FAIL. Implement. PASS.
- [ ] **Step 3:** Wire the turn flow. Play a full match windowed against the AI on easy.
- [ ] **Step 4:** Commit `feat: timing bar and full human/AI turn orchestration`.

---

### Task 14: Menus, session and results

**Files:**
- Create: `autoload/session.gd`, `menus/main_menu.tscn`, `menus/main_menu.gd`, `view/ui/results.gd`
- Modify: `project.godot` (main scene, autoload), `view/match.gd`

**Interfaces:**
- Produces autoload `Session`: `var player_deck: StringName = &"grove_guard"`, `var ai_deck: StringName` (random among the other 3 unless chosen), `var difficulty: AIPlayer.Difficulty = MEDIUM`, `var seed: int` (from `Time.get_ticks_usec()` at match start unless `--seed=` is passed).
- Main menu over a slowly orbiting board backdrop:
  - Title "Dream Isles" and a PLAY button.
  - Deck picker: 4 deck cards with name, main/splash land icons and a one-line flavour: Grove Guard "Outlast them with healing.", Blaze Rush "Burn fast, hit hard.", Sugar Storm "Draw, trick, overwhelm.", Deep Freeze "Lock the board down."
  - Difficulty segmented control (Easy / Medium / Hard) and a QUIT button.
- Results overlay: "VICTORY!" or "DEFEAT", turn count, REMATCH (same decks, new seed) and MENU buttons.

- [ ] **Step 1:** Implement and set `run/main_scene="res://menus/main_menu.tscn"`.
- [ ] **Step 2:** Run the full headless test suite, the compile check, and a headless smoke run of the main menu (`--quit-after 120`). All clean.
- [ ] **Step 3:** Play from the menu through to victory or defeat and rematch. Screenshot the menu and results.
- [ ] **Step 4:** Commit `feat: main menu, deck and difficulty selection, results screen`.

---

## Done criteria

- `godot --headless --path . --script res://tests/run_tests.gd` exits 0, including 100 AI-vs-AI matches.
- `tools/check_scripts_compile.gd` reports `broken: 0`.
- A human can play a full match from the main menu to the results screen with every card playable and every animation visible.
