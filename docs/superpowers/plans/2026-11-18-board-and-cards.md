# Board look 2 + Card expansion 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** River-like seamless lanes with a split reveal, characterful land variants, a 3D boop plate, deck card backs,
a tilting 3D drag card, a Hearthstone-style log, creature merging and 41 new cards.

**Architecture:** View-only `BoardLayout` drives every lane position; tiles clip to shared curves. Land variants are
built by a `SetPieces` kit inside `LaneDressing`. Rules gain merge + new ops/whos/conds in `core/`; content is `.tres`
data, VisualDb entries and baked card art.

**Tech Stack:** Godot 4.7.2, GDScript, Mobile renderer, headless tests (`tests/run_tests.gd`).

**Spec:** `docs/superpowers/specs/2026-11-18-board-and-cards-design.md`

## Global Constraints
- Run tests: `godot --headless --path . --script res://tests/run_tests.gd [-- --only=<substring>]`; baseline 5650/0.
- Screenshots: `godot --path . res://view/match.tscn -- --shot=<png> [--shot-frames=n]` (1280×720 offscreen).
- Performance: live turn on Low ≥ 55 fps on the HD 620 (`--fps-log=<s>`).
- Original names only; no Card Wars / Hearthstone names or art. Card backs from `~/Desktop/artcard/backs_v4` only.
- No web/ re-export, no push. Commit per task on feat/tabletop with the Co-Authored-By line.
- Rules engine (core/) never depends on view code; the layout is view-only.
- Ledger: `.superpowers/sdd/2026-11-18-board-and-cards/progress.md` (rulings + task status).

## Review Focus
- A narrow lane (border shifts toward each other) must still fit creature roam rect, building, house and boop plate:
  test min lane width ≥ 2.3 for 200 seeds (Task 1) and that zone rects don't overlap (Task 4).
- Clicking exactly on a separator line must pick one lane, never none: `lane_at` covers the whole board width (Task 1).
- Merging onto a frozen / hushed / damaged partner keeps those states; merging onto the *rival's* partner is illegal (Task 15).
- Taffy Pull on a creature whose owner has a full hand discards it, and on a merged form returns the merged form (not the partners) — merged forms aren't collectible but may sit in hand (Task 14).
- Snowmanify on a merged creature / Overheat with Second Wind: doomed creature returning via Second Wind is not doomed again (Task 14).

---

## Stage A — Board

### Task 1: BoardLayout
**Files:** Create `view/board/board_layout.gd`; Test `tests/test_board_layout.gd`
**Interfaces — Produces:**
- `class_name BoardLayout extends RefCounted`; `static func make(seed: int) -> BoardLayout`; `static func straight() -> BoardLayout` (no shift, no wave — for tests that need today's numbers).
- `func border_x(i: int, z: float) -> float` (i 0..2), `func left_x(lane, z)`, `func right_x(lane, z)` (lane 0's left = -HALF_W, lane 3's right = +HALF_W, `const HALF_W := 5.4`), `func centre_x(lane, z) -> float`, `func width(lane, z) -> float`, `func min_width(lane, z0, z1) -> float`, `func lane_at(x: float, z: float) -> int` (-1 only outside ±HALF_W), `func curve_params(i) -> Vector4` and `func curve_params2(i) -> Vector4` (shift+base, A, k1, φ1 / A2, k2, φ2, 0 for the shader).
- Constants from spec 1.1: BASE [-2.7, 0, 2.7], SHIFT 0.30, A 0.10–0.14, K1 2π/4.5, A2 0.03, K2 2π/1.6.
- [ ] Tests: `test_layout_deterministic` (same seed → same border_x at 5 z), `test_widths_in_range` (200 seeds: every lane width over z∈[-5.55,5.55] in [2.3, 3.2]), `test_lane_at_round_trip` (centre_x(l,z) → lane l), `test_lane_at_covers_board` (sample x step 0.01 across ±5.39 at 7 z: never -1), `test_straight_matches_old` (straight().centre_x(l, z) == old LANE_X[l]).
- [ ] Implement, run `--only=board_layout`, commit `feat: BoardLayout river curves`.

### Task 2: Seamless wavy tiles on the layout
**Files:** Modify `view/board/board.gd`, `view/board/island.gd`, `view/board/lane.gdshader`, `view/board/ambient.gd`, `view/board/lane_dressing.gd`, `view/event_player.gd`, `view/match.gd` (build with layout), tests using `LANE_X` (`test_board_fit`, `test_lanes`, `test_ui_layout`), `tools/diag/cam_scan_node.gd`.
**Interfaces:** Consumes Task 1. Produces `Board.layout: BoardLayout`; `Board.build(lands, layout := BoardLayout.straight())`; `Board.lane_x(lane) -> float` (centre at the tile middle, replaces `LANE_X[l]`); every existing Board query keeps its signature. `Island.setup(..., layout, lane)` passes the two curves to the shader as uniforms `left_curve/left_curve2/right_curve/right_curve2` + `tile_z` (tile centre z) + `outer_left/outer_right` flags.
- Shader: clip with `p.x` against `left_x(z)-tile_x` / `right_x(z)-tile_x` (no wave on lane sides, keep end waves); mesh width = max lane width + 0.1. Side rims stay as highlight rims along the curve.
- `_build_tray`: drop the low dividers. Roam rect uses `min_width` inset by ROAM_INSET; building/house/boop points use `centre_x` at their z.
- MatchController builds with `BoardLayout.make(seed)` from the match seed.
- [ ] Tests: `test_tiles_share_edges` (for each p and inner border, island(p,l) right curve uniform == island(p,l+1) left curve uniform), `test_roam_inside_lane` (roam rect corners within left/right at their z, 50 seeds), update old `LANE_X` tests to `lane_x`.
- [ ] Screenshot `board_seamless.png` (sweep skipped): lanes touch, no soil gap. Full suite green. Commit `feat: seamless river lanes`.

### Task 3: Separator ribbons + split reveal
**Files:** Create `view/board/separators.gd`; Modify `board.gd`, `view/match.gd` (after sweep); Test `tests/test_separators.gd`.
**Interfaces:** `class_name Separators extends Node3D`; `func build(layout: BoardLayout) -> void` (3 strip meshes, 64 samples over z∈[-5.6,5.6], width 0.07, height 0.025, cream `#fff3c9` + ink outline); `func set_reveal(t: float)` (0 hidden … 1 full; draws outward from z=0 via shader `reveal` uniform); `Board.reveal_split(animate: bool) -> void` (0.6 s ribbons + tile settle drop 0.03, stagger 0.08 s); `Board.split_revealed: bool`; signal `Board.split_done`.
- MatchController: `reveal_split(true)` after `rig.play_sweep()`; `reveal_split(false)` when no sweep.
- [ ] Tests: `test_hidden_before_reveal` (built board: reveal 0, split_revealed false), `test_reveal_instant` (reveal_split(false) → reveal 1, true, tile y back to base), `test_ribbon_follows_curve` (strip vertex x at sample z within 0.04 of border_x).
- [ ] Screenshots with `--sweep-at` before/after. Commit `feat: lane separators split in after the intro`.

### Task 4: Boop plates
**Files:** Create `view/board/boop_plate.gd`; Modify `board.gd` (BOOP point: centred, roam back edge forward 0.45), `view/ui/unit_overlay.gd` (remove 2D boop buttons; keep tooltip via plate hover), `view/input_controller.gd` (click pick), `view/match.gd`; Test `tests/test_boop_plate.gd`, update tests that used `unit_overlay.boop_button`.
**Interfaces:** `class_name BoopPlate extends Node3D`; `enum State { HIDDEN, DIM, LIT }`; `func set_state(s: State, animate := true)`; `func press()`; `func rise(animate: bool)`; `func contains(world: Vector3) -> bool` (pill 0.9×0.34). `Board.boop_plate(lane) -> BoopPlate`; `Board.boop_point(lane)` now centre_x at plate z. `UnitOverlay.refresh` sets plate states (LIT iff `input.can_boop(l)` and creature has un-hushed boop and not busy). `InputController` on click: if a LIT plate contains the ground hit → `request_boop(lane)` before attack-drag handling.
- [ ] Tests: `test_plates_hidden_until_split`, `test_plate_states` (no creature → DIM; boop creature ready → LIT; hushed → DIM), `test_click_plate_boops` (InputController with fixture state), `test_plate_clear_of_zones` (plate rect ∩ roam rect = ∅, ∩ building footprint = ∅, 50 seeds).
- [ ] Screenshot with a boop creature (`--demo-board`). Commit `feat: boop plates on the board`.

## Stage B — Land character

### Task 5: Variant framework + set-piece kit
**Files:** Create `view/board/set_pieces.gd` (primitive builders: `cone`, `blob_mound`, `ridge(along_edge, len)`, `pond(radius, kind)`, `tower`, `castle`, `bridge`, `column_cluster`, `vent` … returning Node3D with Toon materials + outline), `view/board/set_piece_fx.gd` (timers/particles for eruption, vents, sway, ripples; quality-aware); Modify `lane_dressing.gd` (`build(land, player, slot, density, variant := 0, corner := 0, layout_info := {})`), `island.gd` (rolls `variant = rng.randi()%3`, `corner = rng.randi()%2` per land set, from `hash(layout seed, p, lane, change count)`); Test `tests/test_land_variants.gd`.
**Interfaces:** `LaneDressing.VARIANTS := 3`; `LaneDressing.set_piece_rects(root) -> Array[Rect2]` (tile-local footprints); `Island.variant: int`, `Island.corner: int`; free zones per spec 2 (back corner beside building, side edges); player-side tall pieces ×0.8.
- [ ] Tests: `test_variant_rolls_spread` (rolls over 60 changes hit all 3), `test_set_pieces_clear` (all 4 lands × 3 variants × 2 players × 2 corners: footprints don't intersect roam rect/building/house/plate), `test_meadow_single_look`, `test_fx_freed_with_dressing`.
- [ ] Commit `feat: land variant framework and set-piece kit`.

### Task 6–9: Land variants (one task per land: Ember, Mushroom, Frost, Candy)
**Files:** Modify `lane_dressing.gd` (+ `set_pieces.gd` builders as needed), `lane.gdshader` (painted features: lava trickle/crack, chocolate stream, ice sheen, stepping stones, path), `set_piece_fx.gd`.
- Ember 0 Volcano (eruption every 12–25 s: smoke, sparks, 3–5 lava blobs, crater flare), 1 Lava Rift, 2 Ash Slopes. Mushroom 0 Pond Glade (+ long swaying grass), 1 Giant Shroom Grove, 2 Mossy Knoll. Frost 0 Castle Corner, 1 Frozen Lake (+ watchtower), 2 Glacier Ridge. Candy 0 Chocolate River, 1 Lollipop Grove, 2 Sundae Peak.
- Painted features use a `variant` + `corner` uniform on the lane shader (sampled in tile-local coords).
- [ ] Per land: contact shot of its 3 variants via `tools/room_preview` (new `--variants=<land>` flag lays the 3 variants on your side), view, fix, `test_set_pieces_clear` green, commit `feat: <land> land variants`.

### Task 10: Stage B check
- [ ] `--fps-log=20` on Low with all 4 lands × variants on the board ≥ 55 fps; if not, cut props/particles at Low. Full suite. Ledger entry. Commit if changes.

## Stage C — Cards UI

### Task 11: Card backs
**Files:** Create `assets/card_backs/{ember,frost,mushroom,candy}.png` (256×356 from backs_v4 01/03/04/14), `view/card_backs.gd`; Modify `view/room/rival_seat.gd`, `view/room/card_stacks.gd`, rival reveal in `view/fx/flying_card.gd` (or wherever the reveal flip lives), `menus/deck_builder.gd` (header), `view/match.gd` (pass decks); Test `tests/test_card_backs.gd`.
**Interfaces:** `class_name CardBacks`; `static func main_land(deck: DeckData) -> int`; `static func texture_for(deck: DeckData) -> Texture2D`; `RivalSeat.set_back(tex)`, `CardStacks.set_backs(tex0, tex1)`.
- [ ] Tests: main_land for the 4 starters (Blaze Rush → EMBER …), tie → first lane's land, custom deck; rival seat card material uses the texture. Credits: add the user's card backs line to CREDITS.md. Commit.

### Task 12: Drag tilt 3D card
**Files:** Create `view/ui/drag_card_3d.gd`; Modify `view/ui/hand.gd` (`_follow`: over board → hide 2D widget, drive 3D card), `view/match.gd`; Test `tests/test_drag_card.gd`.
**Interfaces:** `class_name DragCard3D extends Node3D`; `func show_card(c: CardData)` (renders a CardWidget into a SubViewport once, 300×420); `func follow(cam: Camera3D, screen: Vector2, delta: float)` (ray to plane y = Island.TOP_Y + 0.9; basis = board-flat tilted 18° toward camera; roll ≤ 10°, pitch wobble ≤ 6° from smoothed horizontal speed); `func set_flat(on: bool)` (0.12 s ease); `func hide_card()`. Hand signal `drag_over_board(on: bool)`.
- [ ] Tests: `test_card_lies_near_flat` (after follow + settle: card normal·UP ≥ cos(25°)), `test_sway_capped` (huge mouse delta → roll ≤ 10°), `test_back_to_hand_hides_3d`. Screenshot mid-drag (screenshot tool: new `--drag-card=<i>,<x>,<y>`). Commit.

### Task 13: Hearthstone-style log
**Files:** Rewrite `view/ui/action_log.gd` (keep `class_name ActionLog`, `describe()` reused for detail lines); Modify `view/match.gd` / `event_player.gd` (feed one batch per action); Test update `tests/test_*` that use `ActionLog.rows()`.
**Interfaces:** `func add_action(events: Array[GameEvent], s: GameState) -> void` (groups into one entry `{card, side, badge, lines}`); `func entries() -> Array[Dictionary]`; `static func summarize(events, s) -> Dictionary` (badge in `&"attack", &"spell", &"built", &"merged", &"boop", &"destroyed", &"land", &"play"`); tiles 56 px, gap 6, max 8, newest on top; hover panel with CardWidget + lines.
- [ ] Tests: `test_one_tile_per_action` (fireball that kills → 1 entry, badge destroyed, lines include "3 damage" and "destroyed"), `test_max_eight`, `test_no_tile_for_turn_start`, `test_hover_shows_panel`. Screenshot with hover (`--hover-log=0`). Commit.

## Stage D — Rules

### Task 14: Engine additions
**Files:** Modify `core/game_state.gd` (CreatureState `temp_atk`, `doomed`; PlayerState `spell_discount`, `magic_cap` + clone), `core/effect_data.gd` (`cond`, `card_id`), `core/effects.gd` (ops `temp_atk`, `doom`, `grow_magic`, `bounce`, `spell_discount`, `transform`; cond check), `core/targeting.gd` (new chosen whos + `other_enemies`), `core/rules.gd` (effective_attack adds temp_atk; end turn clears temp_atk/discount and destroys own doomed; spell cost uses discount in validate + _play + legal_actions; magic growth uses magic_cap), `core/card_text.gd`, `ai/ai_planner.gd` (if it hardcodes whos); Test `tests/test_new_ops.gd`.
- [ ] Tests (fixtures-built states): temp_atk gone next turn; doom destroys at owner's end of turn only; grow_magic raises max and cap (≤10); bounce returns to owner hand / discards when hand full / merged form returns as itself; spell_discount applies once then clears, never below 0, not to creatures; transform keeps lane, clears buffs/keywords/damage, becomes Snowman; cond target_frozen/not_frozen (Icicle both branches); each new who's valid() list; other_enemies excludes last target and includes hero; Second Wind + doom; card text for each new op. Commit `feat: rules for trade-off spells`.

### Task 15: Merge rules
**Files:** Modify `core/card_data.gd` (`merge_with`, `merges_into`, `collectible`), `core/rules.gd` (`_validate_play` allows partner lane; `_merge()`), `core/game_event.gd` if event list is enumerated, `core/card_text.gd` (merge lines), `core/card_db.gd` (`collectible_cards()`; deck builder / Dream Up / random pools use it), `menus/deck_builder.gd`; Test `tests/test_merge.gd` (with two fixture cards + merged fixture).
**Interfaces:** `static func can_merge(s, p, lane, c: CardData) -> bool`; event `creature_merged {player, lane, from, card, into}`.
- [ ] Tests: legal only onto own partner; illegal onto rival's partner / non-partner / empty-lane variant still plays normally; carry-over (damage, level, xp, buffs, gained, frozen, hushed, attacks_used, booped, ready); fresh printed Bubble/Hidden; When merged runs with targets; combo counter increments; merged death discards only the merged card; legal_actions contains merges; AI picks a clearly good merge in a fixture. Commit `feat: creature merging rules`.

## Stage E — Content

### Task 16: New card data
**Files:** Create 41 `.tres` in `data/cards/` (spec 5.1–5.3 + Snowman, merged forms `collectible = false`), modify 8 existing partners (merge fields), `view/visual_db.gd` (models/tints for 12 new creatures, `merge` entries for 8 forms, building models, spell icons), download extra Quaternius monsters into `assets/monsters/` + CREDITS; Test `tests/test_new_cards.gd`.
- [ ] Tests: every new card loads, texts match spec wording (key fragments), merge partners symmetric and merged form's stats per spec, all non-collectible excluded from `collectible_cards()`; `test_data` validation passes for all cards; every creature has a visual entry. Commit.

### Task 17: Merge look
**Files:** Modify `view/pieces/creature_view.gd` (composite model for `merge` entries), `view/event_player.gd` (`creature_merged` playback: hop-in, spin, sparkle burst, swap view), `view/input_controller.gd` (drop on own partner → play with lane; merge highlight), `view/board/island.gd` (Highlight.MERGE: two-colour swirl ring), `view/ui/action_log.gd` (merged badge); Test `tests/test_merge_view.gd`.
- [ ] Tests: dropping partner on partner lane builds a play action for that lane; merge highlight shown only on partner tiles; playback replaces the view with a composite (2 model roots). Screenshot merged creature. Commit.

### Task 18: Card art
- [ ] `godot --path . res://tools/bake_card_art.tscn` for the new cards (creatures from models/composites, spells/buildings per existing pipeline); `test_card_art` green; contact sheet of the 41 new cards viewed. Commit.

### Task 19: Decks, builder, AI, balance
**Files:** Modify `data/decks/*.tres` (swap ~6 per deck incl. a full merge pair), tune card numbers as needed.
- [ ] `tools/deck_balance` Medium vs Medium sims; each starter 40–60 % (record in ledger). AI soak (`tools/soak.gd`) 20 games: no errors. Full suite. Commit.

### Task 20: Final pass
- [ ] Full suite green; fps-log Low ≥ 55; screenshots of every feature; fresh whole-branch review on the most capable model; fix findings; update memory + ledger; final commit (no push, no web export).
