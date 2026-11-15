# Dream Isles Visual and Audio Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring Dream Isles from prototype look to the cartoon quality of the user's reference
(`~/Desktop/WIP.png`). It gets toon-shaded and outlined CC0 models, a meadow board with painted
lanes, on-board stat bars and boop buttons, rendered card art, spell effects and sound.

**Architecture:** One shared toon light function (`view/look/toon_light.gdshaderinc`) is used by the
model, ground and lane shaders. A full-screen ink-outline pass sits on the camera. Every
per-card visual is looked up in `VisualDB`. Effects are reusable nodes in `view/fx/`, chosen by
a pure `FxDirector.choose()` from (source, event) pairs. The source comes from a new
informational `ability_triggered` event. Sounds go through an `Audio` autoload with named
sound sets. Rules and AI behaviour do not change.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript with static typing, the headless runner
`tests/run_tests.gd`, and CC0 assets (Quaternius, Kenney, KayKit, OpenGameArt), plus
game-icons.net (CC BY 3.0) and Lilita One (OFL).

**Spec:** `docs/superpowers/specs/2026-11-15-dream-isles-visual-overhaul-design.md`

## Global Constraints

- Work on branch `feat/visual-overhaul` cut from `master`.
- **Rules and AI:** behaviour is unchanged. The only `core/` change is `ability_triggered {player, lane, card}` appended as the first line of `Abilities.run` (lane is -1 for spells).
- **Original IP:** no Card Wars or Adventure Time names, characters or art. The reference only sets the quality bar and layout.
- **Licences:** all art and sound is CC0, except game-icons.net (CC BY 3.0) and Lilita One (OFL). Commit only files the game uses. Every source goes in `assets/CREDITS.md` with author, licence and URL.
- **Downloads:** each source goes in its own new empty directory under the session scratchpad (`$DL/<source>/`). Never execute anything from a download, and run any Python that reads downloads with `python3 -I`. Copy only the needed files into `assets/`.
- **Imports:** after adding or changing files under `assets/`, run `godot --headless --path . --import` before tests. Commit the generated `.import` files (the repo tracks them).
- **Per-card visuals:** model, tint, art, effect and sound live only in `view/visual_db.gd`.
- **Performance:** 60 fps at 1280x720 on the user's Intel HD 620. The Low preset sets SSAO off, glow off, shadow map 1024, MSAA off and ambient particles halved.
- **Layout:** must hold at 1280x720, 1366x768 and 1920x1080.
- **Tests:** all existing checks (561 at plan time) keep passing after every task. Run `godot --headless --path . --script res://tests/run_tests.gd`; it must report `Results: N passed, 0 failed`.
- **Screenshots:** take them with `godot --path . res://view/match.tscn -- --shot=$SHOTS/<name>.png --shot-frames=180 --seed=7 [--demo-board]` (windowed run; `$SHOTS` is a scratchpad dir). Treat any `SHADER ERROR` or `SCRIPT ERROR` in the output as a failure.
- **Commits:** messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Other resolutions:** at 1366x768 (common laptops) the board, stat bars, boop buttons and hover card must stay on screen and clear of the HUD. Covered by the 1366x768 cases in Task 3 and Task 8.
2. **Effects outliving their target:** a creature can die, or the scene can reload for a rematch, while a projectile, burst or ice shell is still alive. The effect must free itself without errors. Covered by `test_projectile_survives_freed_target` in Task 14.
3. **Clicking during playback:** clicking boop buttons while events play or during the AI turn must do nothing. Covered by `test_boop_buttons_disabled_while_busy` in Task 8.
4. **Moved creatures:** after Lollibat's boop or Swap Trick, stat bars and boop buttons must follow the creature to its new lane. Covered by `test_overlay_follows_swap` in Task 8.
5. **Bad settings file:** a corrupted or hand-edited `settings.cfg` must fall back to defaults, not crash or make the game silent. Covered by `test_corrupt_file_gives_defaults` in Task 1.

## File map

| File | Responsibility |
|---|---|
| `autoload/settings.gd` (new, autoload `Settings`) | Quality and volumes, saved to `user://settings.cfg` |
| `autoload/audio.gd` (new, autoload `Audio`) | SFX pool, music crossfade, named sound sets |
| `view/look/toon_light.gdshaderinc` (new) | Banded light and rim, shared by all lit shaders |
| `view/look/toon.gdshader`, `toon.gd` (new) | Model material, `Toon.apply` |
| `view/look/outline.gdshader`, `outline.gd` (new) | Full-screen ink outline |
| `view/look/ground.gdshader` (new) | Painted meadow |
| `view/board/board.gd` | Meadow, sky, clouds, scenery ring, rim, quality |
| `view/board/lane.gdshader`, `island.gd` | Painted lanes, wavy borders, highlights |
| `view/board/lane_dressing.gd` (new) | Per-land props with keep-out zones |
| `view/board/ambient.gd` (new) | Per-land ambient particles |
| `view/visual_db.gd` (new) | Per-card model, tint, art, effect, sound |
| `view/pieces/creature_view.gd`, `building_view.gd` | Models via VisualDB and Toon, fidgets, flash, dissolve, ice shell |
| `view/ui/unit_overlay.gd` (new) | Stat bars, building badges, boop buttons, hover card |
| `view/ui/card_widget.gd`, `hand.gd` | New card frame, art, hover enlarge |
| `view/ui/hud.gd`, `results.gd`, `timing_bar.gd`, `ui_style.gd`, `menu_buttons.gd` | Cartoon restyle, hero portraits and bars |
| `view/ui/settings_panel.gd`, `credits_panel.gd` (new) | Settings and Credits panels |
| `view/fx/burst.gd`, `projectile.gd`, `ice_shell.gd`, `rain.gd`, `banner.gd`, `screen_flash.gd`, `flying_card.gd`, `confetti.gd` (new) | Effects library (`poof.gd` deleted) |
| `view/fx/fx_director.gd` (new) | `choose()` and `play()` for effect events |
| `view/event_player.gd` | Short dispatcher: source tracking, sequences |
| `core/abilities.gd` | `ability_triggered` event |
| `tools/bake_card_art.gd/.tscn` (new), `tools/contact_sheet.gd`, `tools/screenshot.gd` | Art baking, model sheet, `--fps-log` |

---

## Stage 1: Look

### Task 1: Settings autoload

**Files:**
- Create: `autoload/settings.gd`
- Modify: `project.godot` (add the autoload `Settings="*res://autoload/settings.gd"` before `Screenshot`)
- Test: `tests/test_settings.gd`

**Interfaces:**
- Produces:
  - Script `class_name GameSettings extends Node`, registered as the autoload `Settings`. Tests and other code use `GameSettings.Quality` and `GameSettings.DEFAULT_QUALITY` for constants, and the `Settings` instance for live values.
  - `GameSettings.Quality { HIGH, LOW }`, `const DEFAULT_QUALITY: Quality = Quality.HIGH` (Task 5 may change it).
  - `signal changed`, `var music_volume: float = 0.8`, `var sfx_volume: float = 0.9`, `var quality: Quality`, `var path: String = "user://settings.cfg"`.
  - `func load_settings() -> void`, `func save_settings() -> void`, `func reset() -> void`.
  - `func set_value(key: StringName, value: Variant) -> void`: keys `&"music_volume"`, `&"sfx_volume"` and `&"quality"`. It clamps volumes to 0..1, maps an unknown quality to HIGH, saves and emits `changed`.
  - Dev override: the command-line arg `--quality=low|high` wins over the file, for that run only.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func _make(p: String, wipe: bool) -> GameSettings:
	var s := GameSettings.new()
	s.path = p
	if wipe:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	return s

func test_defaults() -> bool:
	var s: GameSettings = _make("user://t_settings_a.cfg", true)
	s.load_settings()
	assert_eq(s.music_volume, 0.8, "music default")
	assert_eq(s.sfx_volume, 0.9, "sfx default")
	assert_eq(s.quality, GameSettings.DEFAULT_QUALITY, "quality default")
	s.free()
	return true

func test_round_trip_and_clamp() -> bool:
	var s: GameSettings = _make("user://t_settings_b.cfg", true)
	s.set_value(&"music_volume", 1.4)
	s.set_value(&"sfx_volume", -1.0)
	s.set_value(&"quality", GameSettings.Quality.LOW)
	var t: GameSettings = _make("user://t_settings_b.cfg", false)
	t.load_settings()
	assert_eq(t.music_volume, 1.0, "clamped high")
	assert_eq(t.sfx_volume, 0.0, "clamped low")
	assert_eq(t.quality, GameSettings.Quality.LOW, "LOW kept")
	s.free(); t.free()
	return true

func test_corrupt_file_gives_defaults() -> bool:
	var s: GameSettings = _make("user://t_settings_c.cfg", true)
	var f := FileAccess.open("user://t_settings_c.cfg", FileAccess.WRITE)
	f.store_string("garbage[[[ = \nquality=7\n")
	f.close()
	s.load_settings()
	assert_eq(s.music_volume, 0.8, "music default after corrupt file")
	assert_eq(s.quality, GameSettings.Quality.HIGH, "HIGH after junk quality")
	s.free()
	return true
```

- [ ] **Step 2: Run them and see them fail**

Run: `godot --headless --path . --script res://tests/run_tests.gd -- --only=test_settings`
Expected: FAIL (`GameSettings` is not declared).

- [ ] **Step 3: Implement `autoload/settings.gd`** with ConfigFile, section `[settings]`. `_ready()` calls `load_settings()` and then applies the `--quality=` arg. If parsing fails, `load_settings` falls back to `reset()`.
- [ ] **Step 4: Run the full suite.** Expected: all pass (561 + new).
- [ ] **Step 5: Commit** `feat: settings autoload for quality and volumes`

### Task 2: Toon material and ink outline

**Files:**
- Create: `view/look/toon_light.gdshaderinc`, `view/look/toon.gdshader`, `view/look/toon.gd`, `view/look/outline.gdshader`, `view/look/outline.gd`
- Modify: `tools/contact_sheet.gd` (apply `Toon.apply` to each model, and `Outline.attach` to its camera)
- Test: `tests/test_look.gd`

**Interfaces:**
- Produces:
  - `class_name Toon extends RefCounted`.
  - `const SHADER_PATH := "res://view/look/toon.gdshader"` and `const NO_TINT := Color(1, 1, 1, 0)`.
  - `static func material(tex: Texture2D, color: Color, tint: Color = NO_TINT, sway: float = 0.0) -> ShaderMaterial`: cached by its arguments.
  - `static func plain(color: Color, sway: float = 0.0) -> ShaderMaterial`: for primitive meshes.
  - `static func apply(root: Node, tint: Color = NO_TINT, sway: float = 0.0) -> void`: replaces every surface of every MeshInstance3D under `root`, keeping each one's `albedo_texture` and `albedo_color`.
  - `static func set_flash(root: Node, v: float) -> void` and `static func set_dissolve(root: Node, v: float) -> void`: set the instance uniforms `flash` and `dissolve` on every GeometryInstance3D under `root`.
  - `class_name Outline extends MeshInstance3D`, with `static func attach(cam: Camera3D) -> Outline` and `var use_normals: bool` (its setter writes the shader param).
- Shader values (from the spec):
  - **`toon_light.gdshaderinc`:** `light()` uses NdotL × ATTENUATION in 3 bands, with thresholds 0.05 and 0.55, levels 0.45 / 0.75 / 1.0 and edge softness 0.03.
  - **`toon.gdshader`:**
    - Uniforms: `albedo_tex`, `albedo_color`, `tint: vec4` and `sway`. Instance uniforms: `flash` and `dissolve`.
    - Rim: `pow(1 - dot(NORMAL, VIEW), 3.0) * 0.25`, added to EMISSION.
    - Tint: `mix(base, vec3(luma(base)) * tint.rgb * 1.35, tint.a)`.
    - Flash: `mix(albedo, vec3(1), flash)`.
    - Dissolve: discard when a hash noise of world position × 6 is below `dissolve`.
    - Sway: `x += sin(TIME * 1.7 + world.x * 0.8) * sway * max(VERTEX.y, 0)`.
  - **`outline.gdshader`:**
    - A 2x2 quad with `POSITION = vec4(VERTEX.xy, 1.0, 1.0)` (Godot 4.3+ reverse-Z; follow the "Advanced post-processing" doc).
    - Reads `hint_depth_texture` and `hint_normal_roughness_texture`. Samples 4 neighbours at `line_px = max(1.0, VIEWPORT_SIZE.y / 720.0 * 1.5)`.
    - It is an edge where the linear depth difference is > 0.06 × linear depth, or where `use_normals` and the normal dot product is < 0.75.
    - Colour `Palette.INK`. The MeshInstance3D sets `extra_cull_margin = 16384`.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func _surfaces(root: Node) -> Array[Material]:
	var out: Array[Material] = []
	for mi: Node in root.find_children("*", "MeshInstance3D", true, false):
		for i: int in (mi as MeshInstance3D).mesh.get_surface_count():
			out.append((mi as MeshInstance3D).get_active_material(i))
	return out

func test_toon_apply_replaces_all_materials() -> bool:
	var inst := (load("res://assets/monsters/blob/Mushnub.gltf") as PackedScene).instantiate()
	Toon.apply(inst, Color("#ff6a2a", 0.55))
	var mats: Array[Material] = _surfaces(inst)
	assert_true(mats.size() > 0, "has surfaces")
	for m: Material in mats:
		var sm := m as ShaderMaterial
		assert_true(sm != null and sm.shader.resource_path == Toon.SHADER_PATH, "toon shader")
		assert_true(sm.get_shader_parameter("albedo_tex") != null, "keeps albedo texture")
		assert_eq(sm.get_shader_parameter("tint"), Color("#ff6a2a", 0.55), "tint set")
	inst.free()
	return true

func test_material_cache() -> bool:
	assert_true(Toon.plain(Color.RED) == Toon.plain(Color.RED), "same args, same material")
	assert_true(Toon.plain(Color.RED) != Toon.plain(Color.BLUE), "different args, different material")
	return true

func test_outline_attach() -> bool:
	var cam := Camera3D.new()
	var o: Outline = Outline.attach(cam)
	assert_true(o.get_parent() == cam, "child of camera")
	assert_true(o.extra_cull_margin >= 16000.0, "never culled")
	cam.free()
	return true
```

- [ ] **Step 2: Run** with `--only=test_look`. Expected: FAIL (`Toon` is not declared).
- [ ] **Step 3: Implement** the four shader and script files listed above.
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Visual check.** Run `godot --path . res://tools/contact_sheet.tscn -- --group=blob --shot=$SHOTS/toon_blob.png`. Expected: flat banded shading, dark outlines around every model, no `SHADER ERROR`. Tune band values or line width only if the result looks muddy.
- [ ] **Step 6: Commit** `feat: toon material and screen-space ink outline`

### Task 3: Camera, meadow, sky and scenery

**Files:**
- Fetch: Quaternius "Stylized Nature MegaKit", Standard (glTF). Use quaternius.com, whose Drive folder downloads with `gdown --folder`, or the itch.io page. Copy only these into `assets/nature/`, with the textures they reference: 3 tree kinds, 2 bushes, 3 rocks, 2 flower clumps, 3 grass tufts, and any mushroom models. Add a CREDITS entry.
- Delete: `assets/scenery/` (replaced).
- Create: `view/look/ground.gdshader` (includes `toon_light.gdshaderinc`)
- Modify: `view/board/board.gd`, `view/fx/camera_rig.gd`, `view/ui/hud.gd` (`TRAY_H := 214.0`, so cards can grow in Task 11), `menus/main_menu.gd` (orbit radius 14, height 10, so the meadow and scenery show)
- Test: `tests/test_board_fit.gd`

**Interfaces:**
- Consumes: `Toon.apply`, `Toon.plain`, `Outline.attach` (Task 2).
- Produces:
  - Unchanged on `Board`: `build(lands)`, `island()`, `anchor()`, `hero_point()`, `lane_at_screen()`, `LANE_X`, `STRIP_Z`, `SIDE_Z`.
  - New on `Board`: `const INNER_CLEAR := Rect2(-6.4, -6.0, 12.8, 12.0)` (on x and z), `func scenery_positions() -> Array[Vector3]` and `var env: Environment`.
  - `CameraRig` keeps `HOME`, `LOOK`, `camera` and `kick()`. Starting values: `fov = 40`, `HOME = Vector3(0, 12.2, 8.6)`, `LOOK = Vector3(0, 0, 0.7)`. Tune these until the test passes and the screenshot matches the reference framing. `_ready` calls `Outline.attach(camera)`.
- Values:
  - **Sky:** ProceduralSkyMaterial, top `#4aa3ff`, horizon `#dff3ff`, sun disc off.
  - **Lighting and post:** ambient colour `#ffffff` at energy 0.55; tonemap Linear; glow intensity 0.3, threshold 1.0; SSAO intensity 1.0. Sun `#fff4e0` at energy 1.25 with shadows, looking from (5, 12, 7).
  - **Ground:** 220x220 plane, colours base `#8fd16a`, dark `#6cb552`, light `#b5e58a`.
  - **Clouds:** 14 toon puff clusters (white `Toon.plain`) at y 16–26 in a ring of radius 40–80, drifting +x at 0.3 u/s and wrapping at ±90.
  - **Scenery:** seed 2026, 70 props (20 trees, 16 bushes, 14 rocks, 20 flowers). Rejection-sample in |x| ≤ 24, |z| ≤ 22, outside `INNER_CLEAR`, scale 0.8–1.3. Trees, bushes and flowers get `sway` 0.04.
  - **Rim:** 4 box segments around the lane block, 10.4 x 9.9 outside, 0.35 wide, 0.22 high. Stone `#c7b48e` with a turf top strip `#74c257`.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase
const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]

func _rig(size: Vector2i) -> Array:
	var vp := SubViewport.new()
	vp.size = size
	(Engine.get_main_loop() as SceneTree).root.add_child(vp)
	var rig := CameraRig.new(); vp.add_child(rig)
	var board := Board.new(); vp.add_child(board)
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	board.build(lands)
	return [vp, rig, board]

func test_board_fits_view() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = _rig(size)
		var cam: Camera3D = (r[1] as CameraRig).camera
		var board: Board = r[2]
		var w: float = size.x; var h: float = size.y
		var corner_l := Rect2(Vector2(12, 10), Hud.CORNER)
		var corner_r := Rect2(Vector2(w - 12 - Hud.CORNER.x, 10), Hud.CORNER)
		for p: int in 2:
			for l: int in 4:
				var a: Vector2 = cam.unproject_position(board.anchor(p, l))
				assert_true(Rect2(0, 0, w, h - Hud.TRAY_H - 40).has_point(a), "anchor p%d l%d visible at %s" % [p, l, size])
				var head: Vector2 = cam.unproject_position(board.anchor(p, l) + Vector3(0, 2.2, 0))
				assert_true(not corner_l.has_point(head) and not corner_r.has_point(head), "head clear of corners p%d l%d at %s" % [p, l, size])
		var far_y: float = cam.unproject_position(Vector3(0, 0, Board.STRIP_Z[1] - Island.LENGTH / 2.0)).y
		assert_true(far_y >= 0.0 and far_y <= 0.14 * h, "far edge near top at %s (%f)" % [size, far_y])
		var lx: float = cam.unproject_position(Vector3(Board.LANE_X[0] - Island.WIDTH / 2.0, 0, Board.SIDE_Z[0])).x
		var rx: float = cam.unproject_position(Vector3(Board.LANE_X[3] + Island.WIDTH / 2.0, 0, Board.SIDE_Z[0])).x
		assert_true(rx - lx >= 0.72 * w, "board fills width at %s (%f)" % [size, rx - lx])
		(r[0] as Node).free()
	return true

func test_scenery_outside_board() -> bool:
	var r: Array = _rig(Vector2i(1280, 720))
	var board: Board = r[2]
	assert_true(board.scenery_positions().size() == 70, "70 props")
	for v: Vector3 in board.scenery_positions():
		assert_true(not Board.INNER_CLEAR.has_point(Vector2(v.x, v.z)), "prop %s outside board" % v)
	(r[0] as Node).free()
	return true
```

- [ ] **Step 2: Run** with `--only=test_board_fit`. Expected: FAIL (framing assertions and the missing `scenery_positions`).
- [ ] **Step 3: Fetch the nature kit, implement, and tune the camera** until the tests pass.
- [ ] **Step 4: Run the full suite.** Expected: all pass, including `test_input_flow` (`lane_at_screen` with the new camera).
- [ ] **Step 5: Visual check.** Take the match screenshot with `--demo-board`, plus a menu screenshot. Compare framing with `~/Desktop/WIP.png`: the board should fill the middle and the meadow and scenery should show only around it.
- [ ] **Step 6: Commit** `feat: meadow setting, cartoon sky and closer high camera`

### Task 4: Painted lanes, dressing and ambient particles

**Files:**
- Fetch:
  - Kenney "Food Kit" (glTF), into `assets/candy/`: 6–8 sweets (cupcake, donut, candy, lollipop and so on).
  - Kenney "Particle Pack", into `assets/fx/particles/`: only the PNGs used here and in Task 14.
  - Add CREDITS entries for both.
- Modify: `view/board/lane.gdshader` (rewrite; include `toon_light.gdshaderinc`), `view/board/island.gd` (mesh width `WIDTH + 0.12` for the wavy edge; hit-test `WIDTH` unchanged; adds the dressing as a child)
- Create: `view/board/lane_dressing.gd`, `view/board/ambient.gd`
- Modify: `view/board/board.gd` (adds `Ambient.build(lands, Settings.quality)`)
- Test: `tests/test_lanes.gd`

**Interfaces:**
- Consumes: `Settings.quality`, `Toon.apply`, `Board.SIDE_Z`, `Board.STRIP_Z`, `BuildingView.OFFSET`.
- Produces:
  - `class_name LaneDressing`, with:
    - `static func build(land: int, player: int, seed: int) -> Node3D`: lane-local positions.
    - `static func is_clear(local: Vector3, player: int) -> bool`.
    - `static func prop_positions(root: Node3D) -> Array[Vector3]`.
  - `class_name Ambient extends Node3D`, with:
    - `const AMOUNTS: Array[int] = [6, 10, 6, 12]` (forest fireflies, ember embers, candy sparkles, frost snow, per lane).
    - `static func build(lands: Array[Array], quality: int) -> Ambient`.
    - `func amount_total() -> int` and `func set_quality(q: int) -> void`. LOW uses `maxi(1, n / 2)`.
  - `Island.set_highlight(mode)` is unchanged. The shader gets `highlight` 0 / 1 / 2.
- Keep-out zones (lane-local x, z; `s` = 1 for the human, -1 for the rival; `cz = SIDE_Z[p] - STRIP_Z[p]`):
  - creature disc at (0, cz), r 0.8;
  - building disc at (`OFFSET.x * s`, `cz + OFFSET.z * s`), r 0.6;
  - boop-button disc at (0, cz + 0.95), r 0.5, human only.
  - Props: 7–10 per lane, seeded with `player * 4 + lane`.
- Lane paint values (spec 4.3):
  - **Forest:** `#79c95a`, moss `#5aa84a`, clover `#a6e07a`.
  - **Ember:** rock `#4a3030`; cracks `#ff7a1a` at emission 2.0 × (0.6 + 0.4·sin(TIME·2.4)).
  - **Candy:** frosting `#ffb8da`, swirl `#ff9fcf`, sprinkles `#ff5a5a #ffd84a #5ad1ff #7aff7a #ffffff`.
  - **Frost:** snow `#f0f8ff`, shade `#bcdcf5`.
  - **Border:** wavy, amplitude 0.05, 9 waves per unit, ink band 0.045, light bevel 0.03.
  - **Highlights:** VALID is an animated gold `#ffe14a` outline; TARGET is a `#ff5a5a` outline pulsing at 3 Hz.
  - **Side rim:** the per-player `edge_color` stays as a thin inner rim.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func test_props_clear_of_pieces() -> bool:
	for land: int in 4:
		for p: int in 2:
			var root: Node3D = LaneDressing.build(land, p, p * 4 + land)
			var pos: Array[Vector3] = LaneDressing.prop_positions(root)
			assert_true(pos.size() >= 7 and pos.size() <= 10, "7-10 props land %d p%d" % [land, p])
			for v: Vector3 in pos:
				assert_true(LaneDressing.is_clear(v, p), "prop %s clear land %d p%d" % [v, land, p])
			root.free()
	return true

func test_ambient_amounts() -> bool:
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	var hi: Ambient = Ambient.build(lands, GameSettings.Quality.HIGH)
	assert_eq(hi.amount_total(), 68, "high total")
	hi.set_quality(GameSettings.Quality.LOW)
	assert_eq(hi.amount_total(), 34, "low total")
	hi.free()
	return true
```

- [ ] **Step 2: Run** with `--only=test_lanes`. Expected: FAIL (`LaneDressing` is not declared).
- [ ] **Step 3: Fetch the Food Kit and Particle Pack and implement.** If the Food Kit lacks sweets, use the spec's fallback: striped toon cylinders and spheres.
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Visual check.** Take the `--demo-board` screenshot. Check that the 4 lands read clearly, borders are wavy and outlined, props never cover creatures or buildings, and the pink stripes are gone.
- [ ] **Step 6: Commit** `feat: painted lanes with wavy borders, land props and ambient particles`

### Task 5: Quality presets and frame-rate measurement

**Files:**
- Modify: `view/board/board.gd` (`apply_quality`, connected to `Settings.changed`), `tools/screenshot.gd` (`--fps-log=<seconds>`), `autoload/settings.gd` (`DEFAULT_QUALITY` from the measurement)
- Test: `tests/test_lanes.gd` (adds `test_quality_presets`)

**Interfaces:**
- Produces: `Board.apply_quality(q: int) -> void`.
  - **LOW:** `env.ssao_enabled = false`, `env.glow_enabled = false`, `RenderingServer.directional_shadow_atlas_set_size(1024, true)`, viewport `msaa_3d = MSAA_DISABLED`, ambient halved.
  - **HIGH:** SSAO and glow on, shadow atlas 4096, MSAA 2x, full ambient.
- `--fps-log=N`: skip 2 s of warm-up, sample for N s, print `FPS avg %.1f, worst frame %.1f ms`, then quit.

- [ ] **Step 1: Write the failing test** `test_quality_presets`. Build a Board, call `apply_quality(LOW)`, and assert `env.ssao_enabled == false`, `env.glow_enabled == false`, `get_viewport().msaa_3d == Viewport.MSAA_DISABLED` and ambient `amount_total() == 34`. Then `apply_quality(HIGH)` and assert the reverse with 68.
- [ ] **Step 2: Run.** Expected: FAIL (`apply_quality` is not declared).
- [ ] **Step 3: Implement** `apply_quality` and `--fps-log`.
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Measure on this machine (Intel HD 620, window 1280x720)**

Run: `godot --path . res://view/match.tscn -- --demo-board --seed=7 --quality=high --fps-log=10`, then the same with `--quality=low`.
Expected: two `FPS avg` lines.
- Set `DEFAULT_QUALITY = HIGH` if High averages ≥ 58 fps with worst frame ≤ 33 ms; otherwise set it to LOW.
- If Low misses that bar, follow spec risk 10: set `Outline.use_normals = false` on Low, then re-measure. Record the numbers in the commit message.

- [ ] **Step 6: Commit** `feat: high/low graphics presets and fps probe` (with the measured numbers)
- [ ] **Step 7: User checkpoint (stage 1).** Show the user the menu and match screenshots with the fps numbers.

---

## Stage 2: Creatures

### Task 6: Monster models, VisualDB and contact sheet approval

**Files:**
- Fetch: list the Ultimate Monsters Drive folder (`18m4KpzpEzhC9wl7jzr6dUc0N8Jozr79C`) with gdown. Download into `$DL/monsters/` the glTF files and their atlases for `Blob/Chicken`, `Blob/GreenSpikyBlob`, `Flying/Armabee`, `Flying/Demon`, `Flying/Ghost`, `Flying/Glub` and `Flying/Goleling_Evolved`, plus any alternates the user asks for. Copy them into `assets/monsters/{blob,flying,big}/`.
- Create: `view/visual_db.gd`
- Modify: `tools/contact_sheet.gd` (adds a `--cards` mode)
- Test: `tests/test_visual_db.gd`

**Interfaces:**
- Produces: `class_name VisualDB extends RefCounted`.
  - `const TINTS: Dictionary`:

    | Name | Value |
    |---|---|
    | `&"none"` | `Color(1,1,1,0)` |
    | `&"ember"` | `Color("#ff6a2a",0.55)` |
    | `&"ash"` | `Color("#6a6a72",0.6)` |
    | `&"icy"` | `Color("#9fdcff",0.55)` |
    | `&"moss"` | `Color("#5aa34a",0.5)` |
    | `&"cream"` | `Color("#f2e6c8",0.5)` |
    | `&"bark"` | `Color("#7a5a3a",0.5)` |
    | `&"taffy"` | `Color("#ffd84a",0.55)` |
    | `&"candy_purple"` | `Color("#b06cff",0.5)` |
    | `&"candy_cyan"` | `Color("#7fe0ff",0.5)` |
    | `&"candy_blue"` | `Color("#4ad0ff",0.5)` |
    | `&"candy_pink"` | `Color("#ff8ad8",0.5)` |
    | `&"b_forest"` | `Color("#7bd36a",0.25)` |
    | `&"b_ember"` | `Color("#ff7a3a",0.25)` |
    | `&"b_candy"` | `Color("#ff9fcf",0.25)` |
    | `&"b_frost"` | `Color("#9fd8ff",0.25)` |

  - `const ENTRIES: Dictionary`, keyed by all 40 card ids. Each value is a Dictionary:
    - creatures: `{"model": "blob/Mushnub", "tint": &"none"}`, using the spec 5.2 table;
    - buildings: `{"tint": &"b_<land>"}`;
    - spells: `{}`.
    - Later tasks add `"effect"` (Task 15) and `"sound"` (Task 17).
  - `static func model_path(id) -> String`: `res://assets/monsters/<model>.gltf` for creatures, `res://assets/buildings/<id>.gltf` for buildings, `""` for spells.
  - `static func tint(id) -> Color`.
  - `static func art_path(id) -> String`: `res://assets/card_art/<id>.png`.
  - `static func ids() -> Array[StringName]`.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func test_entries_cover_all_cards() -> bool:
	assert_eq(VisualDB.ids().size(), 40, "40 entries")
	for c: CardData in CardDB.all_cards():
		assert_true(VisualDB.ENTRIES.has(c.id), "entry for %s" % c.id)
		if c.kind != CardData.Kind.SPELL:
			assert_true(ResourceLoader.exists(VisualDB.model_path(c.id)), "model exists for %s" % c.id)
		assert_true(VisualDB.TINTS.has(VisualDB.ENTRIES[c.id].get("tint", &"none")), "tint name ok for %s" % c.id)
	return true
```


- [ ] **Step 2: Run** with `--only=test_visual_db`. Expected: FAIL.
- [ ] **Step 3: Fetch the models, write `VisualDB`, and add `--cards` to the contact sheet.** That mode shows 24 creatures in 4 land rows × 6, each scaled to its level height (1.0 / 1.3 / 1.7), with `Toon.apply(tint)` and the outline, labelled "<Name> L<level>".
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: User checkpoint.** Run `godot --path . res://tools/contact_sheet.tscn -- --cards --shot=$SHOTS/creatures.png` and show the image to the user. Apply any vetoes by changing `ENTRIES` (fetching alternates if needed) and re-shoot until approved. Then delete monster files no entry uses.
- [ ] **Step 6: Commit** `feat: VisualDB with approved creature models and tints`

### Task 7: Pieces use VisualDB and the toon material

**Files:**
- Modify:
  - `view/pieces/creature_view.gd`: remove `LOOKS`, `MODELS`, the blob builder and the Label3D badge.
  - `view/pieces/building_view.gd`.
  - `view/event_player.gd`: the death burst colour becomes `Palette.LAND_CARD[v.card.land]`.
  - `view/match.gd`: `refresh_pieces` stops calling `set_stats`; the overlay takes over in Task 8.
- Test: `tests/test_pieces.gd`

**Interfaces:**
- Consumes: `VisualDB.model_path`, `VisualDB.tint`, `Toon.apply`, `Toon.set_flash`, `Toon.set_dissolve`.
- Produces on `CreatureView`:
  - `const HEIGHTS: Array[float] = [1.0, 1.0, 1.3, 1.7]`, indexed by level.
  - `const FIDGET_ANIMS: Array[StringName] = [&"Wave", &"Yes", &"Dance"]`.
  - `static func create(c: CardData, model_override: String = "") -> CreatureView`. If the model is missing it falls back to a land-coloured toon `CapsuleMesh` of the same height.
  - `func fidget() -> bool`: false when busy or no clip exists. It fires from a timer every 6–12 s at random.
  - `func flash(duration: float = 0.12) -> void`.
  - `func dissolve(duration: float = 0.35) -> void` (awaitable).
  - `play_attack()`, `play_hit()`, `play_death()` and `set_frozen()` are kept.
  - Facing keeps the tuned three-quarter turn (human `PI * 0.62`, rival `PI * -0.12`), so faces stay visible.
- `BuildingView.create` calls `Toon.apply(model, VisualDB.tint(c.id))`.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func test_creature_heights_and_toon() -> bool:
	for c: CardData in CardDB.all_cards():
		if not c.is_creature():
			continue
		var v := CreatureView.create(c)
		var h: float = Palette.bounds(v.body).size.y * v.body.scale.y
		assert_true(absf(h - CreatureView.HEIGHTS[c.level]) < 0.03, "%s height %f" % [c.id, h])
		for mi: Node in v.body.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).get_active_material(0) as ShaderMaterial
			assert_true(m != null and m.shader.resource_path == Toon.SHADER_PATH, "%s toon" % c.id)
		v.free()
	return true

func test_missing_model_fallback() -> bool:
	var v := CreatureView.create(CardDB.card(&"cinderpup"), "res://nope.gltf")
	assert_true(v.body != null, "fallback body")
	v.free()
	return true

func test_fidget_respects_busy() -> bool:
	var v := CreatureView.create(CardDB.card(&"gumdrop"))
	v.busy = true
	assert_true(not v.fidget(), "no fidget while busy")
	v.free()
	return true
```

- [ ] **Step 2: Run** with `--only=test_pieces`. Expected: FAIL (height and toon assertions).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite.** Expected: all pass, including `test_full_match` and `test_input_flow`.
- [ ] **Step 5: Commit** `feat: creatures and buildings from VisualDB with toon shading, sizes by level, fidgets`

### Task 8: Stat bars, boop buttons and hover card

**Files:**
- Create: `view/ui/unit_overlay.gd`
- Modify:
  - `view/match.gd`: builds the overlay on its own CanvasLayer under the HUD layer; `refresh_pieces` calls `overlay.refresh(state)`.
  - `view/input_controller.gd`: move the click-to-boop branch into `request_boop`.
  - `tests/fixtures.gd`: move `_load_match` there as `static func load_match() -> MatchController`, returning null if the human turn isn't reached. `test_input_flow.gd` uses it.
- Test: `tests/test_overlay.gd`; also extend `tests/test_board_fit.gd`.

**Interfaces:**
- Produces:
  - `MatchController.overlay: UnitOverlay`, created in `_build_ui`.
  - `InputController.can_boop(lane: int) -> bool`. True when `enabled` and the lane has a human creature with `trigger == &"on_boop"`, and `Rules.validate(state, Action.boop(HUMAN, lane, []))` returns `""` or `"Invalid target"` (as the current click code does).
  - `InputController.request_boop(lane: int) -> void`, the exact current boop flow.
  - `class_name UnitOverlay extends Control` (full rect, `MOUSE_FILTER_IGNORE`; the buttons stop the mouse):
    - `func setup(m: MatchController) -> void` and `func refresh(s: GameState) -> void`.
    - `func entry(p: int, l: int) -> Dictionary` returns `{"visible": bool, "atk": int, "hp": int, "max": int, "bar_color": Color}`.
    - `func boop_button(l: int) -> Button`.
    - `func piece_at(screen: Vector2) -> Dictionary` returns `{"player", "lane", "kind": &"creature"|&"building"}` or `{}`.
    - `static func bar_rect_at(cam: Camera3D, head: Vector3) -> Rect2`: a 110x40 rect centred 24 px above the projected head.
  - `CreatureView` exposes `height` (it already does), so the overlay places bars at `global_position + (0, height + 0.15, 0)`.
- Values:
  - The bar drains over 0.3 s. Colours: > 60% `#3ad16a`, 30–60% `#ffcf3a`, < 30% `#e5384f`.
  - The attack number is Lilita One 30 px with an ink outline (use `UiStyle.bold` until Task 9 lands the font).
  - Boop button: 96x34, text `BOOP`, centred at the projection of `anchor(HUMAN, l) + (0, 0, 0.95)`. Ready: gold `#ffcf3a` with a glow; not ready: grey `#8a86a8`.
  - Hover card: a `CardWidget` at scale 1.6, placed to the right of the piece (to the left if it would leave the screen), clamped on screen, hidden while dragging or targeting.
  - Building badge: a 30 px circle with an icon (text glyph until Task 9).

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func test_stats_match_state() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "match loaded")
	Fx.put_creature(m.state, 0, 1, &"magmaw", 2)
	Fx.put_creature(m.state, 1, 2, &"mossback", 0)
	Fx.put_building(m.state, 0, 1, &"kiln_tower")
	m.sync_all()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var e: Dictionary = m.overlay.entry(0, 1)
	assert_eq(e["atk"], Rules.effective_attack(m.state, 0, 1), "atk with kiln")
	assert_eq(e["hp"], 2, "hp left 4-2")
	assert_eq(e["max"], 4, "max hp")
	assert_eq(e["bar_color"], Color("#ffcf3a"), "50% is yellow")
	assert_true(not m.overlay.entry(0, 0)["visible"], "empty lane hidden")
	m.queue_free()
	return true

func test_boop_button_matches_rules() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")    # on_boop
	Fx.put_creature(m.state, 0, 1, &"cinderpup")  # no boop
	m.sync_all(); m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(m.overlay.boop_button(0).visible and not m.overlay.boop_button(0).disabled, "gumdrop boop ready")
	assert_true(not m.overlay.boop_button(1).visible, "no button without boop")
	m.overlay.boop_button(0).pressed.emit()
	await (Engine.get_main_loop() as SceneTree).create_timer(1.0).timeout
	assert_true(m.state.players[0].lanes[0].creature.acted, "boop resolved via button")
	m.queue_free()
	return true

func test_boop_buttons_disabled_while_busy() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")
	m.sync_all()
	m.busy = true
	m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(m.overlay.boop_button(0).disabled, "disabled while busy")
	m.queue_free()
	return true

func test_overlay_follows_swap() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")
	Fx.put_creature(m.state, 0, 3, &"magmaw")
	m.sync_all()
	var i: int = Fx.give(m.state, 0, &"swap_trick")
	m.state.players[0].magic = 5
	await m.perform(Action.play(0, i, -1, [{"player": 0, "lane": 0}, {"player": 0, "lane": 3}]))
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_eq(m.overlay.entry(0, 0)["atk"], Rules.effective_attack(m.state, 0, 0), "lane 0 shows magmaw now")
	assert_true(m.overlay.boop_button(3).visible, "gumdrop's button moved to lane 3")
	m.queue_free()
	return true

func test_piece_at_finds_creature() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 1, 2, &"mossback")
	m.sync_all()
	var at: Vector2 = m.rig.camera.unproject_position(m.board.anchor(1, 2) + Vector3(0, 0.5, 0))
	var hit: Dictionary = m.overlay.piece_at(at)
	assert_eq(hit.get("lane", -1), 2, "lane"); assert_eq(hit.get("player", -1), 1, "player")
	m.queue_free()
	return true
```

(`CreatureState.acted` is the existing "attacked or booped this turn" flag.) Also add `test_bars_fit_view` to `tests/test_board_fit.gd`, at the three sizes. For all 8 anchors, `UnitOverlay.bar_rect_at(cam, anchor + (0, 1.85, 0))` must lie inside the screen, intersect neither hero corner rect, and sit above `H - Hud.TRAY_H`.

- [ ] **Step 2: Run** with `--only=test_overlay`. Expected: FAIL (`m.overlay` does not exist).
- [ ] **Step 3: Implement** the overlay, the input refactor and the fixtures move.
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Visual check.** Take a `--demo-board` screenshot and compare with WIP.png: an attack number and bar above each creature, BOOP buttons on your lanes.
- [ ] **Step 6: Commit** `feat: on-board stat bars, boop buttons and hover card`
- [ ] **Step 7: User checkpoint (stage 2).** Show the user the screenshot.

---

## Stage 3: Cards and HUD

### Task 9: Font, icons, hero models and Credits panel

**Files:**
- Fetch:
  - Lilita One (`https://github.com/google/fonts/raw/main/ofl/lilitaone/LilitaOne-Regular.ttf`, plus its `OFL.txt`) into `assets/fonts/`.
  - game-icons.net SVGs from the `game-icons/icons` GitHub repo into `assets/icons/`, one per spell and per building effect. Suggested: `lorc/fireball`, `lorc/spores`, `lorc/sprout`, `delapouite/wrapped-sweet`, `delapouite/card-exchange`, `lorc/snowflake-2`, plus a meteor-rain and a falling-rocks icon. Badges: `lorc/health-normal`, `lorc/crossed-swords`, `lorc/heart-plus`, `lorc/checked-shield`, a gem icon and a smoke or chimney icon. Verify each name against the repo and substitute the closest match if one is missing.
  - KayKit Adventurers (Mage, Barbarian, with their textures and rig) into `assets/heroes/`. Fallback: `Big/Ninja` and `Big/Tribal` monsters.
- Create: `view/ui/credits_panel.gd`
- Modify:
  - `view/ui/ui_style.gd`: adds `static func title(l: Label) -> Label` (applies Lilita One) and `const TITLE_FONT := "res://assets/fonts/LilitaOne-Regular.ttf"`.
  - `assets/CREDITS.md`: rewritten with one section per source: author, licence, URL and the files covered. It says that game-icons.net is CC BY 3.0 and names each icon's author.
- Test: `tests/test_credits.gd`

**Interfaces:**
- Produces: `class_name CreditsPanel extends PanelContainer`, with `static func make() -> CreditsPanel`. It shows `res://assets/CREDITS.md` in a scrolling RichTextLabel and has a CLOSE button that emits `closed`.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func test_credits_cover_every_asset_dir() -> bool:
	var text: String = FileAccess.get_file_as_string("res://assets/CREDITS.md")
	for d: String in DirAccess.get_directories_at("res://assets"):
		if d == "card_art":
			continue  # baked by us from credited models
		assert_true(("assets/%s" % d) in text or ("`%s/`" % d) in text, "CREDITS mentions %s" % d)
	for s: String in ["Quaternius", "Kenney", "game-icons.net", "CC BY 3.0", "Lilita One", "KayKit"]:
		assert_true(s in text, "credits mention %s" % s)
	return true

func test_title_font_loads() -> bool:
	var l: Label = UiStyle.title(Label.new())
	assert_true(l.get_theme_font("font") is FontFile, "Lilita One applied")
	l.free()
	return true
```

- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Fetch, write CREDITS and the panel, and add `UiStyle.title`.**
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Commit** `feat: cartoon font, icons, hero models and credits panel`

### Task 10: Card art bake tool

**Files:**
- Create: `tools/bake_card_art.gd`, `tools/bake_card_art.tscn`
- Output (committed): `assets/card_art/<id>.png` for all 40 cards at 320x240, plus `assets/card_art/hero_you.png` and `hero_rival.png` at 256x256.
- Test: `tests/test_card_art.gd`

**Interfaces:**
- Consumes: `VisualDB.model_path`, `VisualDB.tint`, `Toon.apply`, `Outline.attach`, `lane.gdshader` (as the backdrop, with `land` set), and the icon SVGs from Task 9.
- Produces: `VisualDB.art_path(id)` files. Add `const SPELL_ICONS: Dictionary` (spell id → icon path) and `const SPELL_GLOW: Array[Color]` (one per land: `#b6ff7a`, `#ffb03a`, `#ff9fe0`, `#bfe8ff`) to `VisualDB`.
- Bake rules:
  - Render in a SubViewport at 640x480 and downscale to 320x240 with Lanczos.
  - Camera at 25° above, from front-right, looking at the subject's centre.
  - Creatures: idle clip seeked to 0.3 s.
  - Spells: the white icon with an ink outline, on a radial glow in the land's `SPELL_GLOW` colour, over the land backdrop.
  - Heroes: Mage (you) and Barbarian (rival), head and shoulders, 256x256.
- Command: `godot --path . res://tools/bake_card_art.tscn [-- --only=<id>]`. It prints `baked N images` and quits.

- [ ] **Step 1: Write the failing test.** `test_all_card_art_present`: for every card id, `ResourceLoader.exists(VisualDB.art_path(id))` and the image size is 320x240. For both hero files, the size is 256x256.
- [ ] **Step 2: Run.** Expected: FAIL (no images).
- [ ] **Step 3: Implement the tool, run it (windowed), then run `godot --headless --path . --import`.**
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Visual check.** Open 6 baked images (one per land, one building, one spell). The subject is centred, outlined and not cropped. Fix framing and rebake with `--only` as needed.
- [ ] **Step 6: Commit** `feat: baked cartoon card art for all 40 cards and hero portraits`

### Task 11: New card frame and hand

**Files:**
- Modify: `view/ui/card_widget.gd` (rewrite), `view/ui/hand.gd`, `tests/test_ui_layout.gd`

**Interfaces:**
- Consumes: `VisualDB.art_path`, `UiStyle.title`, `Palette.LAND_CARD`.
- Produces:
  - `CardWidget.SIZE := Vector2(140, 196)`.
  - `func art_texture() -> Texture2D` and `func text_label() -> Label`.
  - `show_tip` is removed.
  - `Hand.HOVER_SCALE := 1.6`, `Hand.MAX_STEP := 148.0`.
  - `func hovered_rect() -> Rect2`: the on-screen rect of the hovered card after scaling.
  - `func hover(i: int) -> void`: test helper with the same effect as mouse-enter.
  - `var last_drop_pos: Vector2`, set on drop and used in Task 15.
- Layout (px inside the 140x196 card):
  - Frame: land colour, 4 px ink border, radius 12.
  - Art: (8, 8)–(132, 101).
  - Name ribbon: y 92–118, Lilita One 15 (14 if the name has more than 13 characters).
  - Type line: y 120, 10 px, e.g. "CREATURE · L2".
  - Rules text panel (paper colour): y 134–176, 10 px with autowrap, for every card that has text.
  - Cost gem: a 36 px circle at (-8, -8).
  - Creatures: a sword badge (34 px circle) at bottom-left (-4, 166), and a heart badge mirrored at bottom-right.
  - Unplayable cards are dimmed as today.
- Hover: scale 1.6 with the pivot at bottom-centre, the card raised, z on top. The scaled rect is clamped inside the screen.

- [ ] **Step 1: Write the failing tests.**
  - Extend `test_ui_layout._check` to sizes 1280x720, 1366x768 and 1920x1080.
  - Add to the check: hover card 0, then the last card. `hand.hovered_rect()` must lie inside the screen and must not intersect `hud.end_turn_button`'s rect.
  - Add `test_card_faces`: for every card, `CardWidget.setup` → `art_texture() != null`, and `text_label().text == c.text` when `c.text != ""`.
- [ ] **Step 2: Run** with `--only=test_ui_layout`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Visual check.** Take a match screenshot plus one with a hovered card (add `--hover-card=<i>` to the screenshot autoload, which calls `hand.hover(i)`).
- [ ] **Step 6: Commit** `feat: illustrated card frames and readable hover in hand`

### Task 12: HUD, menus and settings panel restyle

**Files:**
- Create: `view/ui/settings_panel.gd`
- Modify:
  - `view/ui/hud.gd`: hero corners with baked portraits and top-edge health bars; the BlobPortrait is removed.
  - Delete `view/ui/blob_portrait.gd`.
  - `view/ui/ui_style.gd`: thicker 5 px ink border, 2 px inner highlight, Lilita One on titles and buttons.
  - `view/ui/menu_buttons.gd`, `view/ui/timing_bar.gd`, `view/ui/results.gd`, `view/ui/toast.gd`: restyle only.
  - `view/ui/unit_overlay.gd`: Lilita One on the attack numbers; building badges use the Task 9 icons instead of text glyphs.
  - Pause menu: adds the settings panel.
  - `menus/main_menu.gd`:
    - deck buttons show the deck's champion art (its highest-level creature, the first such in card order);
    - add SETTINGS and CREDITS buttons that open the panels.
- Test: `tests/test_ui_layout.gd` (extended), `tests/test_settings.gd` (extended)

**Interfaces:**
- Consumes: `Settings.set_value`, `CreditsPanel.make`, `VisualDB.art_path`.
- Produces:
  - `class_name SettingsPanel extends PanelContainer`, with `static func make() -> SettingsPanel`, `signal closed`, `var music_slider: HSlider`, `var sfx_slider: HSlider` (0..1, step 0.05) and `var quality_option: OptionButton` (High, Low). Every change calls `Settings.set_value`.
  - `Hud.panels()` now also returns the two hero health bars (`"YouBar"` and `"RivalBar"`).
- HUD values:
  - Corner panel: 236x120, portrait 96x96 framed in ink.
  - Health bar: 300x30 along the top edge from each corner toward the centre, with "♥ 25" in Lilita One 18. Fill colour `Palette.HP` on a dark track.
  - The magic orb and the plate are kept (restyled).
  - Update `Hud.CORNER` to `Vector2(236, 120)`; the Task 3 and Task 8 tests read it.

- [ ] **Step 1: Write the failing tests.**
  - `test_ui_layout`: all `hud.panels()` (now including the bars) lie inside the screen at the 3 sizes; neither hero bar intersects the other.
  - `test_settings_panel_writes_settings`: make the panel, set `music_slider.value = 0.25`, assert `Settings.music_volume == 0.25`, then restore the old value.
  - `test_main_menu_loads`: instance `menus/main_menu.tscn`, wait a frame, and assert each deck button has a non-null `icon` texture.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Visual check.** Take menu, match, pause and results (`--demo-results`) screenshots.
- [ ] **Step 6: Commit** `feat: cartoon HUD with hero portraits, restyled menus, settings and credits`
- [ ] **Step 7: User checkpoint (stage 3).** Show the user the screenshots.

---

## Stage 4: Animation and effects

### Task 13: `ability_triggered` event

**Files:**
- Modify: `core/abilities.gd`. The first statement of `run` is `ev.append(GameEvent.make(&"ability_triggered", {"player": p, "lane": lane, "card": card.id}))`.
- Test: `tests/test_abilities.gd` (new tests)

- [ ] **Step 1: Write the failing tests**

```gdscript
func _count(ev: Array[GameEvent], t: StringName) -> int:
	return Fx.types(ev).count(t)

func test_ability_triggered_on_boop() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"sporeling", 2)
	var ev: Array[GameEvent] = Rules.apply(s, Action.boop(0, 1, []))
	var i: int = Fx.types(ev).find(&"ability_triggered")
	assert_true(i >= 0 and i < Fx.types(ev).find(&"creature_healed"), "before the heal")
	assert_eq(ev[i].data, {"player": 0, "lane": 1, "card": &"sporeling"}, "data")
	return true

func test_ability_triggered_once_per_spell() -> bool:
	var s: GameState = Fx.blank()
	for l: int in 3:
		Fx.put_creature(s, 1, l, &"mossback")
	var i: int = Fx.give(s, 0, &"ember_rain")
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, i, -1, []))
	assert_eq(_count(ev, &"ability_triggered"), 1, "once for 3 targets")
	assert_eq(ev[Fx.types(ev).find(&"ability_triggered")].data["lane"], -1, "spell lane -1")
	return true

func test_ability_triggered_for_building() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_building(s, 0, 2, &"smokestack")
	Fx.fill_deck(s, 1, &"mossback", 3)
	Rules.apply(s, Action.begin_attacks(0))
	var ev: Array[GameEvent] = Rules.apply(s, Action.end_turn(0))
	assert_true(&"ability_triggered" in Fx.types(ev), "smokestack trigger")
	return true
```


- [ ] **Step 2: Run** with `--only=test_abilities`. Expected: the 3 new tests FAIL.
- [ ] **Step 3: Implement** the one line.
- [ ] **Step 4: Run the full suite.** Expected: all pass, including `test_replay_identical` and the AI soak.
- [ ] **Step 5: Commit** `feat: informational ability_triggered event for effect sourcing`

### Task 14: Effects library

**Files:**
- Create in `view/fx/`: `burst.gd`, `projectile.gd`, `ice_shell.gd`, `rain.gd`, `banner.gd`, `screen_flash.gd`, `flying_card.gd`, `confetti.gd`
- Delete: `view/fx/poof.gd`. Replace its call sites with `Burst.spawn`.
- Modify:
  - `view/fx/damage_number.gd`: Lilita One, outline 20, pop from 1.4 to 1.0; adds `static func stamp(parent, pos, text)` for "CRIT!".
  - `view/pieces/creature_view.gd`: `set_frozen` attaches or shatters an `IceShell` instead of the box.
- Test: `tests/test_fx.gd`

**Interfaces:**
- Produces (all nodes free themselves when done):
  - **`Burst`** (CPUParticles3D, billboard quads with Kenney textures): `static func spawn(parent: Node, preset: StringName, pos: Vector3, color: Color = Color.WHITE, scale: float = 1.0) -> Burst`.

    | Preset | Texture | Count | Life (s) | Notes |
    |---|---|---|---|---|
    | `sparks` | spark | 18 | 0.4 | |
    | `stars` | star | 8 | 0.6 | |
    | `dust_ring` | smoke | 14 | 0.5 | horizontal ring |
    | `leaves` | dirt | 12 | 0.7 | tint `#7bd36a` |
    | `embers` | spark | 14 | 0.8 | tint `#ff8a2a`, rising |
    | `sprinkles` | circle | 16 | 0.6 | random of the 5 candy colours |
    | `snow` | circle | 14 | 0.8 | white, falling |
    | `smoke` | smoke | 10 | 0.9 | grey `#8a8a92` |
    | `heal` | star and twirl | 14 | 0.8 | `#6aff7a`, rising |

  - **`Projectile`**: `signal arrived`, `const ELEMENTS: Array[StringName] = [&"spore", &"fire", &"candy", &"ice", &"boulder"]`, `static func launch(parent: Node, element: StringName, from: Vector3, to: Vector3, duration: float = 0.45) -> Projectile`. Arc height 1.2, trailing particles, impact burst by element (spore → `heal`; fire → `sparks` + `smoke`; candy → `sprinkles`; ice → `snow` + `sparks`; boulder → `dust_ring` + `smoke`). It emits `arrived` and frees itself even if `parent` or the target view is freed meanwhile.
  - **`IceShell`** (Node3D): `static func attach(target: CreatureView) -> IceShell` and `func shatter() -> void`. Translucent fresnel ice with cracks, sized to `target.height`; shatter makes shard `snow` + `sparks`, then frees it.
  - **`Rain`**: `static func over(parent: Node, points: Array[Vector3], preset: StringName, duration: float) -> Rain`.
  - **`Banner`** (Control): `static func show_turn(parent: Control, text: String, color: Color) -> Banner`. In 0.35 s, hold 0.6 s, out 0.3 s.
  - **`ScreenFlash`** (ColorRect with an edge vignette): `static func edge(parent: Control, color: Color, duration: float = 0.35) -> ScreenFlash`.
  - **`FlyingCard`** (Control): `static func fly(parent: Control, card: CardData, from: Vector2, to: Vector2, face_up: bool, duration: float = 0.3) -> FlyingCard`, with `signal landed`.
  - **`Confetti`** (CPUParticles2D): `static func burst(parent: Control) -> Confetti`. `static func rain_cloud(parent: Control) -> Node2D` gives the sad cloud.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func _root() -> Node3D:
	var n := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(n)
	return n

func _wait(t: float) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(t).timeout

func test_bursts_free_themselves() -> bool:
	var r: Node3D = _root()
	for p: StringName in [&"sparks", &"stars", &"dust_ring", &"leaves", &"embers", &"sprinkles", &"snow", &"smoke", &"heal"]:
		Burst.spawn(r, p, Vector3.ZERO)
	await _wait(1.6)
	assert_eq(r.get_child_count(), 0, "all bursts freed")
	r.free()
	return true

func test_projectile_arrives() -> bool:
	var r: Node3D = _root()
	var pr: Projectile = Projectile.launch(r, &"fire", Vector3.ZERO, Vector3(0, 0, -3), 0.3)
	var got: Array[bool] = [false]
	pr.arrived.connect(func() -> void: got[0] = true)
	await _wait(1.5)
	assert_true(got[0], "arrived emitted")
	assert_eq(r.get_child_count(), 0, "projectile and impact freed")
	r.free()
	return true

func test_projectile_survives_freed_target() -> bool:
	var r: Node3D = _root()
	var v := CreatureView.create(CardDB.card(&"gumdrop"))
	r.add_child(v)
	Projectile.launch(r, &"ice", Vector3.ZERO, v.global_position, 0.3)
	v.queue_free()
	await _wait(1.5)
	assert_eq(r.get_child_count(), 0, "no leftovers, no errors")
	r.free()
	return true

func test_ice_shell_attach_and_shatter() -> bool:
	var r: Node3D = _root()
	var v := CreatureView.create(CardDB.card(&"iceling"))
	r.add_child(v)
	var s: IceShell = IceShell.attach(v)
	assert_true(s.get_parent() == v, "on the creature")
	s.shatter()
	await _wait(1.5)
	assert_true(not is_instance_valid(s), "shell freed")
	r.free()
	return true
```

- [ ] **Step 2: Run** with `--only=test_fx`. Expected: FAIL.
- [ ] **Step 3: Implement** the library and replace the Poof call sites.
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Commit** `feat: effects library (bursts, projectiles, ice shell, rain, banner, flash, flying card, confetti)`

### Task 15: FxDirector and full sequences

**Files:**
- Create: `view/fx/fx_director.gd`
- Modify:
  - `view/event_player.gd`: tracks the source, dispatches to FxDirector, and handles the attack, play, death, freeze, turn and end sequences.
  - `view/visual_db.gd`: adds an `"effect"` key to every entry, and `static func effect(id) -> StringName`.
  - `view/fx/camera_rig.gd`: adds `punch_zoom(amount: float = 4.0, duration: float = 0.25)`, a temporary fov change.
  - `view/ui/hand.gd`: `last_drop_pos`.
  - `view/ui/results.gd`: confetti on a win, rain cloud on a loss.
- Test: `tests/test_fx_director.gd`, `tests/test_effects_playback.gd`

**Interfaces:**
- Consumes: Task 13's event, Task 14's library, `VisualDB`.
- Produces:
  - `const KINDS: Array[StringName]`:
    - spells: `&"fireball"`, `&"ember_rain"`, `&"rain_of_spores"`, `&"regrowth"`, `&"sugar_rush"`, `&"swap_trick"`, `&"cold_snap"`, `&"avalanche"`;
    - abilities: `&"damage"`, `&"heal"`, `&"draw"`, `&"magic"`, `&"move"`, `&"return_building"`, `&"freeze"`, `&"smoke_puff"`, `&"spore_puff"`, `&"gem_pop"`, `&"none"`;
    - also `&"attack_hit"` and `&"plain"`.
  - `VisualDB.effect(id)`: spells map to their own name. Creatures and buildings map by ability:
    - `damage`: ashmite, magmaw, blazehorn, inferno_drake;
    - `heal`: sporeling, puffcap, glimmer_morel, rootstalker, elder_shroomhulk;
    - `draw`: gumdrop, jellywobble, bonbon_behemoth;
    - `magic`: taffy_snail;
    - `move`: lollibat;
    - `return_building`: sugar_sprite;
    - `freeze`: snowmite, frostfang, rimewing, blizzard_titan;
    - `smoke_puff`: smokestack;
    - `spore_puff`: spore_hut;
    - `gem_pop`: candy_mill;
    - `none` for the rest.
  - `static func choose(source: Dictionary, e: GameEvent) -> StringName`, a pure function:
    - `source == {}` → `&"plain"`;
    - `source.kind == &"attack"` and `e.type == &"creature_damaged"` → `&"attack_hit"`;
    - `source.kind == &"ability"` → `VisualDB.effect(source.card)`.
  - `static func play(kind: StringName, source: Dictionary, e: GameEvent, m: MatchController) -> void` (awaitable): carries out the spec 6.2 visuals.
  - `const ELEMENT_BY_LAND: Array[StringName] = [&"spore", &"fire", &"candy", &"ice"]`.
- EventPlayer source rules (spec 6.3):
  - `ability_triggered` sets `{"kind": &"ability", "player", "lane", "card"}`;
  - `attack` sets `{"kind": &"attack", "player", "lane", "hit"}`;
  - `turn_started` and the end of `play()` clear it.
  - Effect events go through `FxDirector`: `creature_damaged`, `creature_healed`, `hero_damaged`, `hero_healed`, `frozen`, `card_drawn`, `card_returned`, `creature_moved`, `building_returned`, `magic_changed`.
- Sequence values:
  - Wind-up squash 0.12 s.
  - Hit-stop: `Engine.time_scale = 0.05` for `0.07 / speed` real seconds (a timer with `ignore_time_scale = true`), then restored.
  - Target `flash(0.12)`; shake `0.15 + 0.05 * amount`, capped at 0.45.
  - Crit: CRIT stamp and `punch_zoom`.
  - Glancing hit: `dust_ring` only.
  - Hero hit: `ScreenFlash.edge(red)` and `hud.shake_hero`.
  - Death: clip capped at 0.9 s, `smoke` + land burst, `dissolve(0.35)`.
  - Played creature: human cards use `FlyingCard` from `hand.last_drop_pos`; AI cards use a face-down card from the rival corner. Then the drop with `dust_ring` and the land burst (`leaves` / `embers` / `sprinkles` / `snow`).
  - Building: rises from y −1.2 with `dust_ring` and `kick(0.1)`.
  - `turn_started` shows `Banner.show_turn` ("YOUR TURN" in `#ffcf3a`, "RIVAL'S TURN" in `#b06cff`), replacing the toast.
  - All durations divide by `speed`.

- [ ] **Step 1: Write the failing tests**

```gdscript
# tests/test_fx_director.gd
extends TestCase

func _ab(card: StringName) -> Dictionary:
	return {"kind": &"ability", "player": 0, "lane": 0, "card": card}

func test_choose_table() -> bool:
	var dmg := GameEvent.make(&"creature_damaged", {"player": 1, "lane": 0, "amount": 3})
	assert_eq(FxDirector.choose({}, dmg), &"plain", "no source")
	assert_eq(FxDirector.choose({"kind": &"attack", "player": 0, "lane": 0, "hit": 1}, dmg), &"attack_hit", "attack")
	assert_eq(FxDirector.choose(_ab(&"fireball"), dmg), &"fireball", "fireball")
	assert_eq(FxDirector.choose(_ab(&"ashmite"), dmg), &"damage", "ashmite boop")
	assert_eq(FxDirector.choose(_ab(&"sporeling"), GameEvent.make(&"creature_healed", {})), &"heal", "heal boop")
	assert_eq(FxDirector.choose(_ab(&"snowmite"), GameEvent.make(&"frozen", {})), &"freeze", "freeze boop")
	assert_eq(FxDirector.choose(_ab(&"smokestack"), GameEvent.make(&"hero_damaged", {})), &"smoke_puff", "building")
	assert_eq(FxDirector.choose(_ab(&"candy_mill"), GameEvent.make(&"magic_changed", {})), &"gem_pop", "candy mill")
	return true

func test_every_card_has_known_effect() -> bool:
	for id: StringName in VisualDB.ids():
		assert_true(VisualDB.effect(id) in FxDirector.KINDS, "effect for %s" % id)
	return true
```

`tests/test_effects_playback.gd` uses `Fx.load_match()` with `m.player.speed = 20` and `m.pace = 20`:
- `test_every_spell_plays`: for each of the 8 spells, put suitable targets on both sides (a damaged own creature for heals, enemy creatures for damage, two own creatures for Swap Trick, a discard creature for Regrowth). Give the card, set magic to 5, and `await m.perform(Action.play(...))` with valid targets from `Rules.valid_targets`. After each, assert that every `creature_views[p][l] != null` exactly matches state, and that `Engine.time_scale == 1.0`.
- `test_every_boop_plays`: for each creature with `trigger == &"on_boop"`, perform its boop with valid targets and make the same assertions.

- [ ] **Step 2: Run** with `--only=test_fx_director` and `--only=test_effects_playback`. Expected: FAIL.
- [ ] **Step 3: Implement** FxDirector, the EventPlayer dispatcher and the sequences.
- [ ] **Step 4: Run the full suite.** Expected: all pass, including `test_full_match_through_view`.
- [ ] **Step 5: Visual check.** Record two short runs with `--auto-attack` (crit) and a seeded full match. Take screenshots at `--shot-frames` 60, 75 and 90 to catch the hit-stop, burst and stamp. Check that effects read clearly and that nothing lingers.
- [ ] **Step 6: Re-measure fps** (Task 5 Step 5 command) during a match with effects. If High drops below 58, reduce the burst counts by 30% (not the visual variety).
- [ ] **Step 7: Commit** `feat: effect director with attack, play, death, freeze, spell and ability sequences`
- [ ] **Step 8: User checkpoint (stage 4).** Show the user the screenshots.

---

## Stage 5: Sound

### Task 16: Audio autoload and sound assets

**Files:**
- Fetch: Kenney "Interface Sounds", "Impact Sounds", "RPG Audio", "Casino Audio" and "Music Jingles". Try kenney.nl first, then the OpenGameArt mirrors, then the Calinou GitHub mirrors. Also fetch OpenGameArt "Happy Clappy Loop" (OwlishMedia) and "Happy Adventure (Loop)" (TinyWorlds).
  - Copy 1–4 variants per sound set into `assets/audio/sfx/<set>_<n>.ogg`, choosing by file name.
  - Copy the music into `assets/audio/music/menu.ogg` and `match.ogg`, with loop on in their `.import` settings.
  - Add CREDITS entries.
- Create: `autoload/audio.gd` (`class_name GameAudio extends Node`; autoload `Audio`, after `Settings`), `default_bus_layout.tres` (buses Master, Music, SFX)
- Modify: `project.godot` (autoload and bus layout), `autoload/settings.gd` (`apply_audio()` on load and on change)
- Test: `tests/test_audio.gd`

**Interfaces:**
- Produces:
  - `const SETS: Dictionary`, StringName → `Array[String]` of paths, with exactly these 24 names: `ui_click`, `ui_hover`, `card_draw`, `card_deal`, `card_flip`, `card_play`, `creature_land`, `building_rise`, `attack_whoosh`, `hit_light`, `hit_heavy`, `hit_crit`, `hero_hit`, `death`, `heal`, `freeze`, `ice_shatter`, `fire_whoosh`, `explosion`, `candy_pop`, `magic_gain`, `turn_start`, `victory`, `defeat`.
  - `func sfx(name: StringName, pitch_jitter: float = 0.08) -> void`: uses a pool of 8 players on bus SFX. It picks a random variant and pitch `1 ± jitter`. An unknown name gives `push_warning` and no sound.
  - `func music(path: String, fade: float = 1.0) -> void`: crossfades 2 players on bus Music; calling it with the path already playing does nothing.
  - `var log_enabled: bool = false` and `var played: Array[StringName] = []`, for tests.
  - `Settings.apply_audio()`: bus volume is `linear_to_db(v)`, and the bus is muted when `v == 0`.

- [ ] **Step 1: Write the failing tests**

```gdscript
extends TestCase

func test_every_set_has_sounds() -> bool:
	var sets: Dictionary = GameAudio.SETS
	assert_eq(sets.size(), 24, "24 sets")
	for k: StringName in sets:
		assert_true((sets[k] as Array).size() >= 1, "%s has a file" % k)
		for p: String in sets[k]:
			assert_true(load(p) is AudioStream, "%s loads" % p)
	return true

func test_unknown_sound_is_safe() -> bool:
	var audio: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Audio")
	audio.set("log_enabled", true)
	audio.call("sfx", &"nope")
	assert_true(not (&"nope" in (audio.get("played") as Array)), "not played")
	audio.set("log_enabled", false)
	return true

func test_volume_to_bus() -> bool:
	var settings: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Settings")
	var old: float = settings.get("music_volume")
	settings.call("set_value", &"music_volume", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "0 mutes")
	settings.call("set_value", &"music_volume", 0.5)
	assert_true(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.5)) < 0.01, "0.5 maps")
	settings.call("set_value", &"music_volume", old)
	return true
```

- [ ] **Step 2: Run** with `--only=test_audio`. Expected: FAIL.
- [ ] **Step 3: Fetch the audio, implement, and import.**
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Commit** `feat: audio autoload, buses, sound sets and music`

### Task 17: Sounds wired to play

**Files:**
- Modify:
  - `view/fx/fx_director.gd` and `view/event_player.gd`: call `Audio.sfx` at the moments in the table below.
  - `view/visual_db.gd`: adds a `"sound"` key per spell or ability-kind override, and `static func sound(id) -> StringName`.
  - `view/ui/ui_style.gd`: adds `static func sound_button(b: BaseButton) -> void`, giving `ui_hover` on mouse enter and `ui_click` on press. Apply it in `MenuButtons.big`, Hud buttons, deck and difficulty buttons, and the boop buttons.
  - `view/ui/hand.gd`: `card_flip` on hover lift.
  - `menus/main_menu.gd` and `view/match.gd`: `Audio.music(menu/match)`.
  - `view/ui/results.gd`: `victory` or `defeat`.
- Test: `tests/test_full_match.gd` (extended)

**Sound moments:**

| Moment | Set |
|---|---|
| card drawn | `card_draw` |
| card played (any) | `card_play`; creature lands: `creature_land`; building: `building_rise` |
| attack leap | `attack_whoosh` |
| impact | `hit_crit` (crit), `hit_heavy` (amount ≥ 4), else `hit_light` |
| hero hit | `hero_hit` |
| death | `death` |
| heal | `heal` |
| frozen / thawed | `freeze` / `ice_shatter` |
| fire projectile / explosion | `fire_whoosh` / `explosion` |
| candy effects | `candy_pop` |
| magic gained | `magic_gain` |
| turn start | `turn_start` |

- [ ] **Step 1: Write the failing test.** In `test_full_match_through_view`, set `Audio.log_enabled = true` and clear `played` before the match. Afterwards, assert `played` contains `card_play`, `attack_whoosh`, `turn_start` and `death`, at least one of `hit_light`/`hit_heavy`/`hit_crit`, and one of `victory`/`defeat`. Then set `log_enabled = false`.
- [ ] **Step 2: Run** with `--only=test_full_match`. Expected: FAIL (nothing logged).
- [ ] **Step 3: Implement** the wiring.
- [ ] **Step 4: Run the full suite.** Expected: all pass.
- [ ] **Step 5: Commit** `feat: sound effects and music wired to play`

### Task 18: Final verification and handoff

- [ ] **Step 1:** Run the full suite. Expected: `Results: N passed, 0 failed`, with N ≥ 561 + the new checks.
- [ ] **Step 2:** Measure fps at High and Low (Task 5 Step 5). Expected: the default preset averages ≥ 58 fps with worst frame ≤ 33 ms. If not, apply spec risk 10 and re-measure.
- [ ] **Step 3:** Take final screenshots: menu, mid-match `--demo-board`, hover card, `--auto-attack` crit, results. Compare them with `~/Desktop/WIP.png` and the stage screenshots.
- [ ] **Step 4:** Update `docs/superpowers/plans/2026-11-13-dream-isles-v1-ledger.md` with any rulings made during this plan. Check that `assets/CREDITS.md` is complete (`test_credits` passes).
- [ ] **Step 5: Commit** `docs: visual overhaul ledger and final measurements`
- [ ] **Step 6: User checkpoint (final).** Show the screenshots and fps numbers, and offer the merge to `master` and a push.
