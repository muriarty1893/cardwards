# Dream Isles visual overhaul: build ledger

Plan: `docs/superpowers/plans/2026-11-15-dream-isles-visual-overhaul.md`  
Spec: `docs/superpowers/specs/2026-11-15-dream-isles-visual-overhaul-design.md`

## Measurements (Intel HD 620, 1280x720, Mobile renderer)

| Scene | Low (default on integrated GPUs) | High |
|---|---|---|
| Board at rest (`--demo-board --demo-results`) | 58.6 fps, worst frame 31.7 ms | 38.6 fps, worst 46.7 ms |
| Live AI turn with effects (`--demo-board`) | 56.3 fps, worst frame 62 ms | 37.9 fps, worst 68 ms |
| v1 before the overhaul (Forward+, same probe) | 23.4 fps | |

Headless checks: 561 before the overhaul, 1781 after (0 failing).

## Rulings made during the build

Each line: what was decided, why, and what it costs if wrong.

- - T11→T15: Hand.last_drop_pos produced in T11; T15's Modify list repeats it. Ruling: T11 adds it, T15 only consumes — duplicate listing — cost if wrong: none.
- Task 2: Ruling: outline normal_threshold 0.75 -> 0.55 and line width 1.5 -> 2.0 px per 720 — plan allowed tuning; 0.75 drew scribbles on faces, thicker lines read closer to the reference — cost if wrong: two constants in outline.gdshader.
- Task 2: Ruling: Toon.material gains a vertex_color flag (shader use_vertex_color) — nature/food kits may colour by vertex; plan said keep albedo — cost if wrong: one unused uniform.
- Task 2: Ruling: added tools/compile_shaders.gd (godot-shaders skill pattern) as the headless shader compile check — not in plan file list — cost if wrong: one dev script.
- Task 3: Ruling: test _rig awaits one process_frame before projecting — CameraRig builds its camera in _ready; plan's test omitted the wait — cost if wrong: none (test only).
- Task 3: Ruling: camera HOME (0,8.5,9.5), LOOK (0,0,0.9), fov 30 (~42° tilt, spec said ~55°) — solved numerically: at 55° the board can't fill ≥72% width while keeping human buildings above the tray — cost if wrong: retune three constants.
- Task 3: Ruling: toon shader is double-sided (all Quaternius glTFs are doubleSided) plus a toon_cutout variant for MASK materials — leaves and grass need alpha test — cost if wrong: back-face fill cost on HD 620, measured in Task 5.
- Task 3: Ruling: nature subset copied with normal maps stripped and textures downscaled to 512 px; TwistedTree_2 and Bush_Common dropped (dark red leaves looked wrong) — repo and VRAM budget — cost if wrong: re-copy from the kit.
- Task 3: Ruling: clouds at y 5–11, radius 45–85 (plan: 16–26 / 40–80); menu orbit radius 14, height 6, looking at y 1.5 (plan: height 10); ground plane 600 (plan: 220) — the match camera never sees the sky, the menu only sees a low horizon, and a 220 plane showed its edge — cost if wrong: constants.
- Task 4: Ruling: Kenney packs fetched from Kenney's own OpenGameArt mirrors — kenney.nl's signed download endpoint refuses scripted requests (and bypassing it was denied) — cost if wrong: none, same CC0 files.
- Task 4: Ruling: particle PNGs converted to white + luminance-as-alpha at 128 px — the pack is white-on-black, which drew black squares with mix blending — cost if wrong: re-copy.
- Task 4: Ruling: wave = 0.05*sin(z*2.6)+0.015*sin(z*7) (plan said "9 waves per unit", which reads as zig-zag noise, not the reference's gentle curves); candy #ff9dcc/#f57ab4 and snow #e6f2ff/#a9cdef deeper than plan values; forest props drop grass tufts and Laetiporus (scribbly outlines, oversized) — screenshot-driven — cost if wrong: shader constants.
- Task 4: Ruling: sun energy 1.25 -> 0.9, ambient 0.55 -> 0.38 — plan values clipped pale colours to white under linear tonemap — cost if wrong: two constants.
- Task 4: Ruling: outline fades out between 110 and 150 units — distant grazing ground drew a thick band on the menu horizon — cost if wrong: one line.
- Task 5: Ruling: project renderer Forward+ -> Mobile (spec/plan said Forward+) — on the HD 620 Forward+ tops out at ~41 fps even on Low (v1 baseline 23); Mobile Low 59 fps / 29 ms worst; look nearly identical (loses SSAO on High and normal-based inner crease lines; Outline picks outline_depth.gdshader automatically) — cost if wrong: one project setting back to forward_plus.
- Task 5: Ruling: default quality from GameSettings.default_quality(): Low on integrated GPUs, High otherwise (DEFAULT_QUALITY stays HIGH as fallback); settings tests compare to default_quality() — plan's single constant would force Low on every friend's PC or miss 60 here — cost if wrong: one function.
- Task 5: Ruling: perf fixes before cutting visuals (spec risk 10): NoiseBank seamless noise textures replace per-pixel fbm/voronoi in ground and lane shaders; meadow built as 4 tiles around the board (no overdraw under lanes); shadows 2 splits, 30 units, hard filter on Low — cost if wrong: crack/noise look slightly different (screenshot-checked).
- Task 5: Ruling: --fps-log renders into a fixed 1280x720 SubViewport and reports gpu/cpu ms — the tiling window manager opened the game at 1280x1360 — cost if wrong: none (dev tool).
- Task 6: Ruling: toon tint formula -> mix(base, tint.rgb * (0.6 + 0.8*luma), a) — plan's luma*tint*1.35 turned dark models muddy (Sugar Sprite navy, Taffy olive) — cost if wrong: one shader line.
- Task 6: Ruling: contact sheet sent to the user and Task 7 continues meanwhile; vetoes will be applied as VisualDB edits when they reply, and unused alternate models are deleted only after approval — approval is non-destructive data, waiting would stall the build — cost if wrong: re-tuning a few entries.
- Task 8: Ruling: UnitOverlay.bar_rect_at(cam, head, avoid: Array[Rect2] = []) clamps bars inside the viewport and pushes them sideways out of the hero corners (new Hud.corner_rects()); test passes the corner rects — at the tuned camera, tall rival creatures' heads are above the screen top and the corners cover the outer rival lanes, so a fixed above-head spot can't satisfy the plan's own fit test — cost if wrong: bars for tall rival creatures sit over their heads instead of above.
- Task 8: Ruling: overlay CanvasLayer layer 1, HUD layer 2 (plan: "under the HUD layer") and request_boop() ignores clicks when input is disabled — cost if wrong: none.
- Task 9: Ruling: icons chosen — fireball, burning-meteor (Ember Rain), pollen-dust (Rain of Spores; repo has no "spores"), sprout (Regrowth), wrapped-sweet (Sugar Rush), card-exchange (Swap Trick), snowflake-2 (Cold Snap), falling-rocks (Avalanche); badges health-increase, heart-plus, crossed-swords, chimney, cut-diamond, checked-shield, sword-break — closest names that exist — cost if wrong: swap SVGs.
- Task 9: Ruling: UiStyle.title(c: Control) -> Control (plan: Label -> Label) so buttons can use it too — cost if wrong: casts at call sites.
- Task 9: Ruling: KayKit Mage/Barbarian .glb (3.6 MB each, mostly animations) committed so the bake tool can re-render portraits — cost if wrong: 7 MB of repo.
- Task 10: Ruling: creatures/buildings stand on a strip of their own painted land under a land-coloured sky (VisualDB.ART_SKY added); spells framed by a fixed box (sprites have no mesh bounds); heroes framed by hand (skinned bounds include held items) — screenshot-checked — cost if wrong: rebake with --only.
- Task 11: Ruling: creature rules text panel is y 134–168 (plan: 134–176 for every card) with 9 px font for text over 34 chars — the stat badges at the bottom corners would cover longer text — cost if wrong: layout constants.
- Task 11: Ruling: the hovered card is clamped inside the hand region (REGION_LEFT .. width - REGION_RIGHT), not just the screen — otherwise the last card's 1.6x face covers BATTLE! — cost if wrong: none.
- Task 12: Ruling: hero health bars sit at (corner x + 112, 14), 300x30, overlapping the corner's top strip and running toward the centre; corner layout portrait 96x96 / orb 44 / name / plate 116x24 inside 236x120 — plan gave sizes, not positions — cost if wrong: constants.
- Task 12: Ruling: stat bars avoid the hero health bars too (Hud.corner_rects() returns corners + bars); wide rects push bars down, tall rects push sideways, three passes; test_bars_fit_view also checks no two stat bars overlap — sideways pushes off the rival health bar stacked two rival bars on top of each other — cost if wrong: none.
- Task 12: Ruling: SettingsPanel.make(with_close := true), embedded without CLOSE in the pause box; main menu panels open over a dim layer and close on `closed` — cost if wrong: none.
- Task 14: Ruling: Confetti.rain_cloud(parent, at := Vector2.ZERO) takes an optional anchor point and CreatureView gains is_frozen_visual() — results panel placement and tests need them — cost if wrong: none.
- Task 15: Ruling: VisualDB.EFFECTS is its own table (plan: an "effect" key in each ENTRIES row) and FxDirector.OWNS lists the event types each kind draws; anything else is plain — keeps unrelated events in the same batch (turn draw after Candy Mill) from reusing the source's effect — cost if wrong: none.
- Task 15: Ruling: gem_pop / magic draw only the first magic_changed of their source (EventPlayer clears the source after it) — Candy Mill's own gain is followed by the turn's magic update — cost if wrong: none.
- Task 15: Ruling: every await in FxDirector's static coroutines is followed by an is_instance_valid(m) guard — tests (and a rematch/quit mid-effect) freed the match while effects waited, logging "previously freed" script errors (Review Focus 2); verified 0 SCRIPT ERROR in the full-suite log — cost if wrong: none.
- Task 15: Ruling: rival-side damage/heal numbers and the CRIT stamp sit at anchor + (0, 0.7, 1.0) — above-head spots for the top row were off screen — cost if wrong: constant.
- Task 15: Ruling: --auto-attack dev demo now forces the human's MAIN phase (it failed "Not your turn" when the rival moved first) — cost if wrong: none (dev only).
- Task 16: Ruling: downloads moved to the git-ignored plan workspace (.superpowers/sdd/<plan>/dl, with .gdignore files) — the session scratchpad disappeared mid-run — cost if wrong: none.
- Task 16: Ruling: sources — Kenney Interface Sounds, 50 RPG sound effects, 54 casino sound effects and 85 short music jingles (OGA mirrors; kenney.nl refuses scripts) plus rubberduck's 75 CC0 hit SFX in place of Kenney "Impact Sounds" (no mirror found); music kept as .mp3 (menu.mp3 / match.mp3, loop on) rather than .ogg — cost if wrong: swapping files.
- Task 16: Ruling: sounds chosen by file name only (Claude cannot listen); victory = jingles_NES00, defeat = jingles_NES09, turn_start = bong_001 are guesses — flag to the user — cost if wrong: one SETS line each.
- Task 16: Ruling: GameSettings.set_value() always calls apply_audio() — under the test runner autoloads are not inside the tree yet, so an is_inside_tree guard skipped it — cost if wrong: none.
- Task 17: Ruling: VisualDB.SOUNDS holds the extra cast sound per spell (plan: a "sound" key in entries); projectile launch sounds come from FxDirector.SHOT_SOUND by element; damage from any source uses hit_crit / hit_heavy (>= 4) / hit_light — cost if wrong: table edits.

## Notes

- Task 5: Note: live AI turn averages 56.5 fps but has ~140 ms hitches (CPU, on piece/hand rebuild); revisit in Tasks 7/11 and re-measure in Task 18.
- Task 6: Note: wide flyers (Rimewing, Lollibat, Inferno Drake) exceed lane width at their level height — cap width in Task 7.
- Task 15: Note: test_effects_playback passed against the old event player too (characterisation guard); the RED test for this task was test_fx_director.
