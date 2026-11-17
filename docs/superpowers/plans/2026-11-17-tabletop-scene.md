# Tabletop Scene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put the match on a big wooden table in a sunny cottage room with the rival seated across, a seat camera with zoom and cinematic moves, a bigger board with small wandering pieces, and a wood-and-brass UI that keeps the board clear.

**Architecture:** Presentation-only change. `core/` and `ai/` and the event stream are untouched. A new `view/room/` builds the room, rival and card stacks; `Board` shrinks to the tray of 8 tiles with zone queries; a `Wanderer` node moves each `CreatureView` inside its zone and yields to the event player through the existing `busy` flag; `CameraRig` gains views, zoom and cinematics; the HUD, hand and overlay are restyled and re-laid out.

**Tech Stack:** Godot 4.7.2, GDScript (static typing), headless test runner `tests/run_tests.gd`, Mobile renderer on desktop, Compatibility renderer on the web. CC0 KayKit Furniture Bits 1.0 and Restaurant Bits 1.0.

**Spec:** `docs/superpowers/specs/2026-11-17-tabletop-scene-design.md`

## Global Constraints

- Branch `feat/tabletop`. One commit per task; every commit message ends with the session's attribution lines. Push only when the user asks; do not re-export `web/` unless the user asks.
- `core/`, `ai/` and the event stream are unchanged. Wandering never touches `GameState.rng`.
- Only CC0 assets; each new pack credited in `assets/CREDITS.md`; only assets the code loads are committed (`tests/test_assets_used.gd` must pass, extended for new folders).
- Nothing from Adventure Time or Card Wars: no characters, names, logos, props or look. Composition only.
- Room and board materials go through `Toon` (no per-instance shader uniforms: WebGL fits only ~256 of them) and the `Outline` pass.
- Layout targets 1280×720, 1366×768 and 1920×1080.
- Performance: ≥ 55 fps average on Low on the user's Intel HD 620 during a live turn with 8 creatures, measured with `--fps-log`.
- Test commands: one suite `godot --headless --path . --script res://tests/run_tests.gd -- --only=<file or test substring>`; full suite `timeout 900 godot --headless --path . --script res://tests/run_tests.gd`, which must print `Results: N passed, 0 failed`. After adding a `class_name` file run `godot --headless --path . --import` once.
- Screenshots: `godot --path . res://view/match.tscn -- --shot=$SHOTS/<name>.png --shot-frames=180 --seed=7 [--demo-board] [--zoom=<0..1>] [--sweep-at=<s>]` with `$SHOTS` a scratchpad dir; any `SHADER ERROR` or `SCRIPT ERROR` in the output is a failure.
- Ledger: `.superpowers/sdd/2026-11-17-tabletop/progress.md` (task status, rulings, numbers tuned at checkpoints).
- User checkpoints after Tasks 4, 8 and 14: stop, send screenshots and fps, wait for the user's go.

## Review Focus

1. **Window resized mid-match** (or a size other than the three targets): corners, END TURN, hand and tags re-anchor on the next frame and the board still fits; nothing stays at the old size. Test in Task 10.
2. **Input during cinematic camera moves**: a click or wheel during the opening sweep only skips it (never plays a card or starts an aim); wheel input during an attack close-up is ignored and the camera returns to the zoom the player had. Tests in Tasks 4 and 8.
3. **A creature moved to another lane** (Lollibat boop, Swap Trick): its wanderer zone switches to the new half-lane and it ends inside it; it never walks back to the old lane. Test in Task 7.
4. **A creature destroyed, returned or bounced while walking, aimed at or claimed**: no errors, no orphan tag, ring or boop button, and the aim is cancelled. Tests in Tasks 7 and 12.
5. **Web renderer**: room, tray and dressing render without per-instance uniforms and with blob shadows where sun shadows are off. Test in Tasks 2 and 6.

---

## Stage 1: room and camera

### Task 1: Settings for the camera

**Files:**
- Modify: `autoload/settings.gd`
- Test: `tests/test_settings.gd`

**Interfaces:**
- Produces: `Settings.battle_closeups: bool` (default `true`), `Settings.zoom_speed: float` (default `1.0`, clamped to `[0.25, 2.0]`), both saved/loaded under keys `"battle_closeups"` and `"zoom_speed"` in `SECTION`; `changed` emitted on set via `set_battle_closeups(on: bool)` and `set_zoom_speed(v: float)`.

- [ ] **Step 1: Write failing tests** `test_camera_settings_defaults` (fresh instance → `true`, `1.0`), `test_camera_settings_roundtrip` (set `false`, `1.7`; save to a temp path; load into a new instance → `false`, `1.7`), `test_zoom_speed_clamped` (`set_zoom_speed(9.0)` → `2.0`, `set_zoom_speed(0.0)` → `0.25`).
- [ ] **Step 2: Run** `--only=test_settings` → the three fail.
- [ ] **Step 3: Implement** the two fields, setters and save/load lines.
- [ ] **Step 4: Run** `--only=test_settings` → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: battle close-up and zoom speed settings`.

### Task 2: The cottage room

**Files:**
- Create: `view/room/room.gd`, `view/room/wood.gdshader` (planks/plaster by uniform), `assets/room/` (only the KayKit `.gltf`/`.bin` used plus the two texture atlases), `tests/test_room.gd`
- Modify: `view/board/board.gd` (remove `_build_environment`, `_build_ground`, `_build_clouds`, `_build_scenery`, `env`, `scenery_positions`; `apply_quality` keeps only the ambient part), `view/match.gd` (create `Room` before `Board`), `menus/main_menu.gd` (room + board backdrop, slow drift camera over the table from the player's side towards the rival), `assets/CREDITS.md`, `tests/test_assets_used.gd`, tests that used `board.env` or `scenery_positions`

**Interfaces:**
- Produces: `class_name Room extends Node3D` with
  - `const SCALE := 10.0` (board units per metre; KayKit models are in metres),
  - `const TABLE_RECT := Rect2(-9.0, -8.0, 18.0, 16.0)` (tabletop in world x/z; top surface at y = 0, the board sits on it),
  - `const BOARD_CLEAR := Rect2(-6.4, -6.4, 12.8, 12.8)` (no prop may enter),
  - `const SEAT_Z := -9.6` (rival chair centre z),
  - `var env: Environment`, `var sun: DirectionalLight3D`,
  - `func build(quality: int) -> void`, `func apply_quality(q: int) -> void` (Low: no SSAO, no glow, 1024 atlas, half the dust, shadow distance 30 → 22),
  - `func props() -> Array[Node3D]` (every placed prop, for tests).
- Layout per spec 3.1: window wall at −z behind the rival (2–3 windows, sunbeams, outside view: sky gradient plane, hills and trees from `assets/nature/`, one small floating island), stove/counter/jars at −x, bookshelf/plants/armchair/lamp/frames at +x, planks floor and rug, ceiling beams, table props (snack bowl, mug, candle) inside `TABLE_RECT` but outside `BOARD_CLEAR`. The cat is added in Task 3.
- Sunbeams: additive unshaded soft-edged quads from each window; dust motes `GPUParticles3D` (CPU fallback on Compatibility like `Ambient`) inside the beams.
- Sun: from behind-left of the windows, warm colour; shadows only within `directional_shadow_max_distance` covering the table; room props get `BlobShadow`s.

- [ ] **Step 1: Download** KayKit Furniture Bits and Restaurant Bits (`gh api` raw files from `KayKit-Game-Assets/KayKit-Furniture-Bits-1.0` and `...-Restaurant-Bits-1.0`, path `addons/<pack>/Assets/gltf/`) into a scratch dir; copy only the models you place into `assets/room/`; add credits.
- [ ] **Step 2: Write failing tests** in `tests/test_room.gd`:
  - `test_room_builds_one_environment` — after `build`, exactly one `WorldEnvironment` in the room's subtree and `room.sun != null`.
  - `test_props_clear_of_board` — every prop's world AABB (x/z) does not intersect `Room.BOARD_CLEAR`.
  - `test_table_props_on_table` — props tagged `"table"` (meta) lie inside `TABLE_RECT`.
  - `test_room_uses_no_instance_fx` — no material in the room uses `Toon.FX_PATH`/`FX_CUTOUT_PATH` (same rule as `test_board_uses_no_instance_fx`).
  - `test_low_quality_halves_dust` — dust `amount` at Low ≤ 55% of High.
- [ ] **Step 3: Run** `--only=test_room` → fail (no `Room`).
- [ ] **Step 4: Implement** `Room`, strip the meadow from `Board`, wire `match.gd` and `main_menu.gd`, update `test_assets_used` for `assets/room/` and fix tests that referenced removed board members.
- [ ] **Step 5: Run** `--only=test_room` → pass; full suite → `0 failed`.
- [ ] **Step 6: Screenshot** the match (`--seed=7`) and the main menu; check the room reads as a bright cottage, nothing black or washed out, no prop over the board.
- [ ] **Step 7: Commit** `feat: cottage room around the table`.

### Task 3: Rival at the table and the cat

**Files:**
- Create: `view/room/rival_seat.gd`, `tests/test_rival_seat.gd`
- Modify: `view/room/room.gd` (chair + cat), `view/match.gd` (`var rival: RivalSeat`), `assets/CREDITS.md` (cat source)

**Interfaces:**
- Produces: `class_name RivalSeat extends Node3D` with
  - `func setup(model_path: String) -> void` (match passes `res://assets/heroes/Barbarian.glb`); seated at `Vector3(0, chair_seat_y, Room.SEAT_Z)` facing +z, scaled by `Room.SCALE`; a fan of 5 card backs attached to the right hand bone.
  - `func play_card() -> void`, `func cheer() -> void`, `func flinch() -> void`, `func think(on: bool) -> void`, `func lose() -> void`, `func win() -> void`.
  - `func upper_anim() -> StringName` — the upper-body clip playing now (`&"Sit_Chair_Idle"` when none).
  - `func hero_rect(cam: Camera3D) -> Rect2` — screen rect from the tabletop up to the top of the head, full shoulder width.
  - `func hand_point() -> Vector3` — world point of the card fan.
- Animation: `AnimationTree` with `Sit_Chair_Idle` as base and an `AnimationNodeOneShot` filtered to the spine bone and its children for `Interact` (play card), `Cheer`, `Hit_A`; `think(true)` loops a slow head turn; `lose()` holds a head-down/spine bend via bone pose override; `win()` loops `Cheer`.
- Cat: a CC0 animal with a sleep or idle loop on the armchair; if no fitting cat is found use a dog or fox and note it in the ledger for the Stage 1 checkpoint.

- [ ] **Step 1: Write failing tests**: `test_rival_seated_idle` (after `setup`, `upper_anim() == &"Sit_Chair_Idle"`), `test_rival_reactions` (`play_card()` → `&"Interact"`, `cheer()` → `&"Cheer"`, `flinch()` → `&"Hit_A"`, each back to `&"Sit_Chair_Idle"` after the clip length + 0.1 s), `test_rival_win_loops` (`win()` → still `&"Cheer"` after 3 s), `test_rival_beyond_table` (the spine bone's global z < `Room.TABLE_RECT.position.y`: the body sits behind the far table edge; only arms and cards may reach over it).
- [ ] **Step 2: Run** `--only=test_rival_seat` → fail.
- [ ] **Step 3: Implement** `RivalSeat`, chair, card fan, cat; match creates it.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: rival seated at the table with reactions, napping cat`.

### Task 4: Camera views, zoom and cinematics

**Files:**
- Modify: `view/fx/camera_rig.gd`, `view/input_controller.gd` (ignore board input while `rig.in_cinematic`; first click/key skips the sweep), `view/match.gd` (`await rig.play_sweep()` before the first turn), `tests/test_board_fit.gd` (rewritten), `tools/screenshot.gd` (pass-through of `--zoom`/`--sweep-at` is via user args; nothing else)
- Test: `tests/test_board_fit.gd`, `tests/test_camera.gd` (new)

**Interfaces:**
- Consumes: `Settings.battle_closeups`, `Settings.zoom_speed` (Task 1); `RivalSeat.hero_rect` (Task 3).
- Produces on `CameraRig`:
  - `const SEAT_POS := Vector3(0, 9.0, 13.5)`, `SEAT_LOOK := Vector3(0, 0.5, -1.5)`, `SEAT_FOV := 42.0`, `LEAN_POS := Vector3(0, 11.0, 7.0)`, `LEAN_LOOK := Vector3(0, 0.0, 0.8)`, `LEAN_FOV := 40.0` — starting values, tuned until the fit tests pass; tuned values go in the ledger.
  - `var zoom: float` (0 = seat, 1 = lean-in), `func set_zoom(z: float, instant: bool = false) -> void`, `func zoom_by(steps: float) -> void` (one wheel notch = `0.15 * Settings.zoom_speed`, eased over 0.25 s; `InputEventMagnifyGesture` maps to the same).
  - `func pose_at(z: float) -> Transform3D`, `func fov_at(z: float) -> float`.
  - `var in_cinematic: bool`; `func play_sweep() -> void` (awaitable, ~3 s path from a room corner past the rival to `pose_at(zoom)`), `func skip_sweep() -> void`.
  - `func close_up(from: Vector3, to: Vector3, duration: float) -> void` (awaitable; low behind `from` looking at `to`, then back to `pose_at(zoom)`; returns immediately without moving when `Settings.battle_closeups` is false); `var close_up_count: int` counts close-ups actually played.
  - `kick()` and `punch_zoom()` keep their signatures and apply on top of the current base pose.
  - User args: `--zoom=<f>` sets the starting zoom; `--sweep-at=<s>` holds the sweep at `s` seconds; under `--shot=` without `--sweep-at`, and when `DisplayServer.get_name() == "headless"`, the match skips the sweep (tests call `play_sweep()` themselves).

- [ ] **Step 1: Rewrite `tests/test_board_fit.gd`** (shared helper `_tile_corners(board, p, l) -> Array[Vector3]` from `Board.LANE_X`, `Board.STRIP_Z`, `Island.WIDTH`, `Island.LENGTH`, `Island.TOP_Y`):
  - `test_seat_view_fits` — at the three sizes, zoom 0: every tile corner projects to `x ∈ [0.03w, 0.97w]`, `y ∈ [0.22h, 0.80h]`.
  - `test_rival_head_visible` — zoom 0: `rival.hero_rect(cam)` top `≥ 0.04h` and `≤ 0.30h`, horizontally centred within `0.1w`.
  - `test_lean_view_fits_near_half` — zoom 1: the 4 near tiles' corners in `x ∈ [0, w]`, `y ∈ [0.08h, 0.82h]`.
  - keep `test_board_uses_no_instance_fx`.
- [ ] **Step 2: Write `tests/test_camera.gd`**:
  - `test_sweep_ends_at_seat` — after `await play_sweep()`, camera transform equals `pose_at(0)` within 0.001 and `in_cinematic == false`.
  - `test_skip_jumps_to_seat` — start `play_sweep()`, after 0.5 s call `skip_sweep()`; next frame transform equals `pose_at(0)`.
  - `test_close_up_returns_to_zoom` — `set_zoom(0.6, true)`; `await close_up(a, b, 0.5)` → transform equals `pose_at(0.6)`.
  - `test_close_ups_off_never_moves` — `Settings.battle_closeups = false`; sample the camera every frame during `close_up` → always `pose_at(zoom)`.
  - `test_zoom_ignored_during_cinematic` (Review Focus 2) — during `close_up`, `zoom_by(3)` leaves `zoom` unchanged.
  - `test_click_during_sweep_only_skips` (Review Focus 2) — load the match, start `play_sweep()`, send a left click on a hand card's position through `InputController`: the sweep ends, `m.input.mode` stays idle and the hand size is unchanged.
- [ ] **Step 3: Run** both suites → fail.
- [ ] **Step 4: Implement** the rig, input gating and match wiring; tune the six constants until the fit tests pass at all three sizes (board still at the old geometry).
- [ ] **Step 5: Run** both suites → pass; full suite → `0 failed`.
- [ ] **Step 6: Checkpoint (user)** — screenshots: seat view, `--zoom=1`, `--sweep-at=1.2`, main menu; fps on Low (`--fps-log=10 --quality=low`). Record in the ledger. Commit `feat: seat and lean-in camera, zoom, opening sweep, close-ups`, then stop for the user's go.

## Stage 2: board and pieces

### Task 5: Board tray, zones and piece scale

**Files:**
- Modify: `view/board/board.gd`, `view/board/island.gd`, `view/board/lane.gdshader` (size uniform only), `view/pieces/creature_view.gd`, `view/pieces/building_view.gd`, `view/match.gd` (`place_building` uses `building_point`), `view/fx/camera_rig.gd` (retune constants for the new tray)
- Test: `tests/test_lanes.gd` (zones), `tests/test_board_fit.gd`, `tests/test_pieces.gd`, plus any test asserting old positions

**Interfaces:**
- Produces on `Board`:
  - `const LANE_X: Array[float] = [-4.05, -1.35, 1.35, 4.05]`, `const SEAM := 0.3`, `const STRIP_Z: Array[float] = [2.85, -2.85]`, `const TRAY_RECT := Rect2(-6.0, -6.1, 12.0, 12.2)`; `Island.WIDTH := 2.6`, `Island.LENGTH := 5.4`.
  - `func roam_rect(p: int, l: int) -> Rect2` — world x/z: the half-lane's front 75% (seam side), inset 0.25 from the lane edges and the seam.
  - `func building_point(p: int, l: int) -> Vector3` — centre of the back 25% (own-edge side), at `Island.TOP_Y`.
  - `func boop_point(l: int) -> Vector3` — human side only: `(LANE_X[l] - 0.85, Island.TOP_Y, building_point(0, l).z)`.
  - `func anchor(p, l) -> Vector3` — centre of `roam_rect(p, l)` at `CREATURE_Y` (existing callers keep working).
  - `func hero_point(p, lane) -> Vector3` — just past the tray edge on `p`'s side (`z = ±6.6`).
  - `lane_at_screen(cam, screen_pos) -> Dictionary` — unchanged contract.
  - Wooden frame with brass corners around `TRAY_RECT`, thin dividers between lanes, emissive seam strip along z = 0.
- `CreatureView.HEIGHTS := [0.42, 0.42, 0.55, 0.72]`, `MAX_WIDTH := 0.8`; `BuildingView.HEIGHT := 0.45`, `MAX_WIDTH := 0.9`, positioned at `building_point`; `CreatureView.BASE_Y` stays equal to `Board.CREATURE_Y`.

- [ ] **Step 1: Write failing tests** in `tests/test_lanes.gd`:
  - `test_zones_inside_tiles` — for all 8, `roam_rect` lies inside the tile rect (`LANE_X ± WIDTH/2`, `STRIP_Z ± LENGTH/2`) and `building_point` too.
  - `test_zones_disjoint` — building footprint (circle r 0.6 at `building_point`) and boop spot (circle r 0.4 at `boop_point`) do not intersect `roam_rect`.
  - `test_lane_at_screen_zone_centres` — for zoom 0, 0.5, 1 and all half-lanes on screen in that view, `lane_at_screen(unproject(anchor))` returns that `{player, lane}`.
  - `test_tray_inside_room_clear` — `Room.BOARD_CLEAR.encloses(Board.TRAY_RECT)`.
  - in `tests/test_pieces.gd`: `test_piece_heights` — a level-1 view's model AABB height within 10% of 0.42, level-3 of 0.72; a building's within 10% of 0.45.
- [ ] **Step 2: Run** `--only=test_lanes`, `--only=test_pieces` → fail.
- [ ] **Step 3: Implement** the geometry, frame, seam, piece scale; retune the camera constants so `test_board_fit` passes again; update tests that pinned old numbers.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: bigger board tray with zones and small pieces`.

### Task 6: Dense lane dressing that bends

**Files:**
- Modify: `view/board/lane_dressing.gd`, `view/board/island.gd`, `view/board/board.gd`, `view/board/ambient.gd` (per-land particles over the new tiles only), `view/match.gd` (feed bend points each frame)
- Create: `view/board/dressing.gdshader` (toon-lit, wind sway, bend)
- Test: `tests/test_lanes.gd`

**Interfaces:**
- Produces: `static func LaneDressing.build(land: int, player: int, seed: int, density: float) -> Node3D` — one `MultiMeshInstance3D` per prop kind; base counts per half-lane at High `DENSITY := [160, 90, 120, 110]` (Mushroom, Ember, Candy, Frost) × `density` (1.0 High, 0.5 Low); tall props (lollipop trees, vents, crystals) only within 0.35 of the lane's long edges; nothing within r 0.75 of `building_point` or r 0.45 of `boop_point`.
- `func Board.set_bend_points(points: PackedVector3Array) -> void` — up to 8 creature positions; each dressing material gets `uniform vec4 bend_points[8]` (xyz + radius 0.35, w = 0 for unused); instances within the radius tilt away by up to 35°.
- Land looks per spec 4.2 (grass tufts/mushrooms/moss; cracked ground with emissive vents and ash plumes; sprinkles/gumdrops/lollipop trees; snowdrifts/ice crystals).

- [ ] **Step 1: Write failing tests**: `test_dressing_avoids_spots` (every MultiMesh instance origin is outside both exclusion circles for all 8 tiles), `test_low_density_halves` (Low total ≤ 55% of High), `test_bend_points_uniform` (after `set_bend_points` with 3 points, a dressing material's `bend_points` has 8 entries, the first 3 matching, rest w = 0), `test_dressing_no_instance_fx` (dressing materials do not use instance uniforms; Review Focus 5).
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`; `--fps-log=10 --quality=low` on `--demo-board` ≥ 55 fps (else lower `DENSITY`, record in ledger).
- [ ] **Step 5: Commit** `feat: dense per-land lane dressing that bends around creatures`.

### Task 7: Wandering creatures

**Files:**
- Create: `view/pieces/wanderer.gd`, `tests/test_wanderer.gd`
- Modify: `view/pieces/creature_view.gd` (owns a `Wanderer`; `var aiming: bool`, `var aim_at: Vector3`; `func play_move(on: bool) -> void`), `view/match.gd` (`place_creature(p, l, c, drop := Vector3.INF)`; zone on lane change; `set_bend_points` from creature positions), `view/event_player.gd` (`move_piece` calls `set_zone` then hops to the new anchor)

**Interfaces:**
- Produces: `class_name Wanderer extends Node`:
  - `enum State { ROAM, PAUSE, REST, HELD }`, `var state: State`.
  - `func setup(view: CreatureView, zone: Rect2, seed: int) -> void` (own `RandomNumberGenerator`; match seeds it with `hash([match_seed, p, l, play_count])`).
  - `func set_zone(zone: Rect2) -> void`, `func set_resting(on: bool) -> void`.
  - `func step(delta: float) -> void` — called from `_process`; tests call it directly.
  - HELD whenever `view.busy`, `view.aiming` or `view.is_frozen_visual()`; within the same `step`, movement stops. When aiming, it turns to face `view.aim_at`.
  - Speeds by level `SPEEDS := [0.6, 0.6, 0.5, 0.4]` board units/s, turn rate 6 rad/s; PAUSE 1.5–4.0 s with face-enemy, bounce or a fidget; 25% chance to `Wave` at a same-side neighbour within 1.2 units when a PAUSE starts.
  - Footsteps: `Burst.spawn` with the land preset from `EventPlayer.LAND_BURSTS` every 0.35 s while walking (0.7 s on Low).
- `CreatureView.play_move(on)`: `Walk` (or `Run`), flyers `Fast_Flying`/`Flying_Idle`, blob-group models add a hop bob on `body.position.y`; `on = false` returns to idle.
- Readiness → wanderer: `READY`/`SPENT`/`NONE` → ROAM/PAUSE cycle; `SLEEPING` → `set_resting(true)`.

- [ ] **Step 1: Write failing tests** in `tests/test_wanderer.gd` (a real `CreatureView` in a `SubViewport`, stepping at 1/30 s):
  - `test_stays_in_zone_120s` — over 3600 steps, x/z always inside the zone (tolerance 0.01).
  - `test_rest_does_not_move` — `set_resting(true)`; position unchanged over 300 steps.
  - `test_claim_stops_within_one_step` — mid-walk set `view.busy = true`; after one step `state == HELD` and the next 30 steps move < 0.001.
  - `test_release_resumes` — clear `busy`; within 5 s of steps the position changes.
  - `test_aim_faces_target` — `aiming = true`, `aim_at` to the right; after 30 steps the view's forward points within 15° of it.
  - `test_never_touches_match_rng` — build a match `GameState`; record `state.rng.state`; run 8 wanderers for 60 s; `state.rng.state` unchanged.
  - `test_lane_move_updates_zone` (Review Focus 3) — load the match with a Lollibat in lane 0, apply its boop to lane 3 through the event player; afterwards the view's wanderer zone equals `board.roam_rect(0, 3)` and after 60 s of steps the view is still inside it.
  - `test_freed_mid_walk_is_safe` (Review Focus 4) — `queue_free()` the view mid-walk and step the tree 10 frames: no errors, no leftover ring/footstep nodes under the board.
- [ ] **Step 2: Run** `--only=test_wanderer` → fail.
- [ ] **Step 3: Implement** `Wanderer`, `play_move`, match/event-player wiring; new creatures appear at the drop point clamped into `roam_rect`.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: creatures wander their half-lane`.

### Task 8: Attacks from where they stand, hero leaps, rival reactions, close-ups

**Files:**
- Modify: `view/event_player.gd`, `view/input_controller.gd`, `view/match.gd`, `view/fx/fx_director.gd` (any position read from `anchor` that should be the view's current position)
- Test: `tests/test_effects_playback.gd`, `tests/test_input_flow.gd`, `tests/test_fx_director.gd`

**Interfaces:**
- Consumes: `CameraRig.close_up` (Task 4), `RivalSeat` reactions and `hero_rect` (Task 3), `Wanderer` via `busy`/`aiming` (Task 7).
- Event player rules:
  - `_attack`: claim attacker and target creature (`busy = true`); start = attacker's current position; end = target view's current position (creature), `board.hero_point(foe, lane)` then a leap toward `rival.hand_point()` (human attacks hero) or toward the camera to 35% of the way (AI attacks your hero) with `rig.kick(0.6)` and the red `ScreenFlash`; run `rig.close_up(start, end, attack_duration)` in parallel; jog back to `start`; release both.
  - Every other sequence that moves or animates a creature (death, freeze, spell hit, `move_piece`) uses the view's current position and holds `busy` for its duration.
  - Rival: `card played` by AI → `rival.play_card()` (before the flying card leaves `rival.hand_point()`); `hero_damaged` on the human → `rival.cheer()`; `hero_damaged` on the AI → `rival.flinch()`; AI turn start/end → `think(true/false)`; `game_over` → `win()`/`lose()`.
- Input: pressing anywhere on your half-lane (via `board.lane_at_screen`) picks its creature for aim or boop, not only its model; `_aim_origin()` = unprojected current view position; aiming sets `view.aiming`/`aim_at` and clears both on release/cancel; `_target_at(pos)` returns −1 when `pos` is in `rival.hero_rect(cam)`, `hud.hero_rect(false)`, or the projected table strip `Rect2(TRAY_RECT.position.x, Room.TABLE_RECT.position.y, TRAY_RECT.size.x, TRAY_RECT.position.y - Room.TABLE_RECT.position.y)` at y = 0.

- [ ] **Step 1: Write failing tests**:
  - `test_attack_from_mid_roam_ends_at_target` — move attacker and target to off-centre spots in their zones; play an attack; sample the attacker's closest approach to the target's position: < 0.6.
  - `test_all_released_after_sequences` — after attack, death, spell and swap sequences, every live view has `busy == false`, `aiming == false`, and is inside its `roam_rect`.
  - `test_target_at_rival_rect`, `test_target_at_table_strip` — `_target_at` → −1 at the centre of each.
  - `test_press_anywhere_on_half_lane_picks` — with the creature walked to the zone's left end, pressing at the projected right end of the same half-lane and dragging starts an aim from that creature.
  - `test_rival_reacts_to_events` — feed the event player an AI `creature_played`, a `hero_damaged` on the human and on the AI: `rival.upper_anim()` is `Interact`, `Cheer`, `Hit_A` in turn.
  - `test_close_up_per_attack` — with close-ups on, the rig's close-up counter rises by 1 per attack; with them off it stays 0.
  - `test_aim_cancelled_when_attacker_dies` (Review Focus 4) — start an aim, destroy the attacker through rules + event player: input mode back to idle, arrow cleared, no errors.
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Checkpoint (user)** — screenshots: `--demo-board` seat view, `--zoom=1`, a close-up frame (`--auto-attack` with `--shot-frames` timed into the attack), menu; fps on Low with 8 creatures. Commit `feat: attacks from wandering positions, hero leaps, rival reactions, close-ups`, then stop for the user's go.

## Stage 3: UI

### Task 9: Wood, parchment and brass style kit

**Files:**
- Modify: `view/ui/ui_style.gd`, `view/ui/settings_panel.gd` (+ the two new controls), `view/ui/results.gd`, `view/ui/timing_bar.gd`, `view/ui/toast.gd`, `view/ui/menu_buttons.gd`, `view/palette.gd` (remove `TRAY*` once unused)
- Test: `tests/test_ui_layout.gd`, `tests/test_settings.gd`

**Interfaces:**
- Produces on `UiStyle`: colours `WOOD := Color("#8a5a34")`, `WOOD_DARK := Color("#5b3a22")`, `BRASS := Color("#e0b04a")`, `BRASS_DARK := Color("#9c6f22")`, `PARCHMENT := Color("#f6e7c4")`, `INK := Color("#3b2a1a")`; `static func wood_panel(radius: int = 14) -> StyleBoxFlat`, `static func parchment_panel(radius: int = 10) -> StyleBoxFlat`, `static func brass_button(b: Button, diameter: float = 0.0) -> void` (normal/hover/pressed/disabled styles; round when `diameter > 0`).
- Settings panel: `CheckButton` "Battle close-ups" ↔ `Settings.set_battle_closeups`; `HSlider` "Zoom speed" 0.25–2.0 ↔ `Settings.set_zoom_speed`.

- [ ] **Step 1: Write failing tests**: `test_settings_panel_camera_controls` (toggling/sliding writes `Settings`), `test_no_tray_colours_left` (no `Palette.TRAY` reference in `view/ui/*.gd` source).
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement** the kit and restyle the listed panels.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: wood and brass UI style kit, camera settings controls`.

### Task 10: HUD layout, END TURN states, card stacks, discard viewer

**Files:**
- Create: `view/room/card_stacks.gd`, `view/ui/discard_viewer.gd`
- Modify: `view/ui/hud.gd` (tray removed), `view/match.gd`, `view/ui/magic_gems.gd` (brass/crystal look)
- Test: `tests/test_ui_layout.gd`

**Interfaces:**
- `Hud`: `const CORNER := Vector2(250, 104)`; your corner bottom-left (`Rect2(12, h - 116, 250, 104)`: round wooden portrait frame, heart + health number + bar, magic gems); rival corner top-right (same plus "N cards"); `const END_TURN_D := 118.0` brass disc at bottom-right (12 px margins); pause gear 48×48 top-left. `TRAY_H` removed; `const HAND_STRIP_H := 96.0` (used by the hand and fit tests).
  - `static func end_turn_state(s: GameState, human: int) -> Dictionary` → `{"text": String, "pulse": bool, "enabled": bool}`: AI's turn → `{"Rival's turn", false, false}`; N ≥ 1 creatures with `Rules.can_attack` or `Rules.can_boop` → `{"%d can act" % N, false, true}`; otherwise `{"END TURN", nothing_affordable, true}` where `nothing_affordable` = no hand card passes `Rules.validate` for any lane/target.
  - `deck_screen_pos()`/`discard_screen_pos()` now unproject `CardStacks.deck_point(human)`/`discard_point(human)`; `hero_rect(false)` is the rival corner.
  - Re-anchors on `get_viewport().size_changed`.
- `class_name CardStacks extends Node3D`: `func set_counts(deck: Array[int], discard: Array[int]) -> void` (stack height 0.02 per card), `func deck_point(p: int) -> Vector3`, `func discard_point(p: int) -> Vector3` (yours at the player's right of the board inside `TABLE_RECT`, the rival's mirrored), `func stack_at(cam: Camera3D, screen: Vector2) -> Dictionary` (`{"player", "kind": &"deck"|&"discard"}` or `{}`); hover shows a count tooltip; clicking your discard opens `DiscardViewer`.
- `class_name DiscardViewer extends Control`: `func show_cards(cards: Array[CardData]) -> void` (parchment panel, grid of `CardWidget`s, close button), `signal closed`.

- [ ] **Step 1: Write failing tests** in `tests/test_ui_layout.gd`:
  - `test_hud_no_overlap` — at the three sizes, the rects of your corner, rival corner, END TURN, pause and the hand strip (`Rect2(corner right + 8, h - HAND_STRIP_H, END_TURN left − corner right − 16, HAND_STRIP_H)`) do not intersect each other.
  - `test_board_clear_of_hud` — with the real match at each size, every tile corner of all 8 tiles is outside all HUD rects.
  - `test_end_turn_states` — fixtures: a ready creature → `"1 can act"`; none ready and no affordable card → `"END TURN"` with `pulse`; AI's turn → `"Rival's turn"`, disabled.
  - `test_stacks_follow_counts` — `set_counts([20, 18], [0, 3])` → your deck stack taller than the rival's; `stack_at` on your discard returns `{player 0, discard}`.
  - `test_discard_viewer_lists_cards` — 3 discarded cards → 3 `CardWidget`s.
  - `test_resize_reanchors` (Review Focus 1) — in a `SubViewport` at 1280×720, change size to 1920×1080, wait a frame: your corner's rect bottom is at `1080 − 12`, END TURN's right edge at `1920 − 12`.
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement**; remove DECK/DISCARD plates; update flying-card sources.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: corner HUD, brass END TURN with states, card stacks on the table, discard viewer`.

### Task 11: Slim hand

**Files:**
- Modify: `view/ui/hand.gd`, `view/input_controller.gd` (half-lane highlights while dragging)
- Test: `tests/test_ui_layout.gd`, `tests/test_input_flow.gd`

**Interfaces:**
- `Hand`: `const PEEK := 0.36` (visible fraction of card height at rest), `const HOVER_SCALE := 1.5` (hovered card fully on screen, bottom edge 8 px above the screen bottom), `const TOKEN_SCALE := 0.45` (while the dragged card is over the board), region between your corner and END TURN; neighbours of the hovered card slide apart by 40 px.
- While dragging a creature/building card, every valid half-lane gets `Island.Highlight.VALID`.

- [ ] **Step 1: Write failing tests**: `test_hand_peeks_at_rest` (each card's on-screen visible height within ±4 px of `PEEK × CardWidget.SIZE.y`), `test_hovered_card_fully_visible` (at the three sizes), `test_hand_inside_strip` (rest rects inside the hand strip from Task 10), `test_drag_token_over_board` (dragging over a tile → scale `TOKEN_SCALE`; valid tiles highlighted, invalid not).
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: slim peeking hand with drag token and lane highlights`.

### Task 12: Creature tags and boop buttons

**Files:**
- Modify: `view/ui/unit_overlay.gd`
- Test: `tests/test_overlay.gd`

**Interfaces:**
- Tag: `const BAR_SIZE := Vector2(66, 22)` — ATK badge (22 px circle) + health bar 40×8 with "4/5" (11 px) — placed above the view's current head (`global_position + (0, height + 0.08, 0)`); hover over the creature or its half-lane, or aim at it → scale 1.6 and a second line with name + keywords; the hover card appears at the screen side as now.
- `static func nudge(rects: Array[Rect2], gap: float = 2.0) -> Array[Rect2]` — resolves overlaps by moving later rects up until separated by `gap`.
- Boop button: `const BOOP_SIZE := Vector2(64, 26)`, brass, at `unproject(board.boop_point(l))`; tooltip = the card's boop text; the rival's boops flash a small icon at their lane's mirrored spot when used.
- Tags, rings and boop buttons hide the frame their creature view is freed.

- [ ] **Step 1: Write failing tests**: `test_tag_follows_view` (move a view 1 unit in x, process a frame → tag x moves by the projected delta ±2 px), `test_nudge_separates` (two overlapping rects → no overlap, gap ≥ 2), `test_boop_button_at_spot` (button centre within 2 px of `unproject(boop_point(l))`), `test_hover_grows_tag` (hovered tag scale 1.6 and name visible), `test_tag_hidden_when_view_freed` (Review Focus 4).
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: small following creature tags and fixed boop buttons`.

### Task 13: Turn banner, rival card reveal, action log

**Files:**
- Create: `view/ui/card_reveal.gd`, `view/ui/action_log.gd`
- Modify: `view/event_player.gd`, `view/match.gd`
- Test: `tests/test_overlay.gd` (or new `tests/test_follow_ui.gd`)

**Interfaces:**
- Turn banner: on `turn_started`, `Banner` with "Your turn" or "Rival's turn".
- `class_name CardReveal extends Control`: `func show_card(c: CardData, seconds: float = 1.2) -> void` (awaitable; a `CardWidget` at scale 1.4 left of the board, vertically centred, slide-in/out); the event player awaits it for every card the AI plays (creature, building, spell) before the card lands.
- `class_name ActionLog extends VBoxContainer`: `const MAX := 5`; `func add(e: GameEvent, s: GameState) -> void` (ignores events `describe` returns `""` for); `static func describe(e: GameEvent, s: GameState) -> String`; rows are parchment strips with a small icon, older rows at lower alpha, hover shows a detail tooltip. Texts:
  - `attack` + following damage: `"<Attacker> hit <Target> for <N>"` (target "Rival" or "You" for heroes),
  - `creature_played` / `building_played` / `spell_cast`: `"<Who> played <Card>"` (`Who` = "You"/"Rival"),
  - `booped`: `"<Creature> booped"`, `creature_destroyed`: `"<Creature> was defeated"`, `frozen`: `"<Creature> was frozen"`,
  - everything else → `""`.

- [ ] **Step 1: Write failing tests**: `test_describe_texts` (one per text rule above with fixture states), `test_log_keeps_five` (add 7 → 5 rows, newest last), `test_banner_text_per_turn`, `test_reveal_only_for_ai_cards` (human play → no reveal; AI play → `CardReveal` visible during the wait).
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** → pass; full suite → `0 failed`.
- [ ] **Step 5: Commit** `feat: turn banner, rival card reveal and action log`.

### Task 14: Finish and checkpoint

**Files:**
- Modify: ledger, `docs/superpowers/specs/2026-11-17-tabletop-scene-design.md` (only if rulings changed numbers), memory notes

- [ ] **Step 1: Full suite** → `0 failed`.
- [ ] **Step 2: fps** — `--fps-log=15 --quality=low --demo-board` ≥ 55 average; if not, apply the spec's levers in order (dressing density, dust, shadow distance, prop count) and re-measure.
- [ ] **Step 3: Screenshots** at 1280×720, 1366×768 and 1920×1080 (seat view), `--zoom=1`, a close-up, menu, results; compare against the reference framing (board in the lower ~60%, rival above it, slim hand).
- [ ] **Step 4: Whole-branch review** (fresh reviewer on the most capable model) and fix findings; full suite again.
- [ ] **Step 5: Checkpoint (user)** — send the screenshots and numbers; commit `chore: tabletop scene ledger and final measurements`; wait for the user's call on merging and pushing.
