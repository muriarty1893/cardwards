# Dream Isles: Tabletop scene design

Date: 2026-11-17. Status: draft for user review. Branch: `feat/tabletop` (from master `ef073ab`).

## 1. Why

The user feels the match is too close and too bare: the camera sits on top of the board, there is
no world around it, the pieces fill their lanes, and the UI is generic and covers a third of the
board. They gave ten reference screenshots (from the Card Wars mobile game and the Adventure
Time show) for camera angle, framing and placement. We take **composition only** from them:
a board on a table in a room, the rival seated across, a camera from the player's seat, long
lanes with small pieces, slim hand, compact hero corners, tags over pieces. Room, rival, art and
colours are our own; no Adventure Time characters, logos, props or look.

Goal (user's words, condensed): the match should feel like a little living world on a table that
you command, polished enough to show the user's grandmother and friends.

This is part 1 of 2. Part 2, **land quirks** (rules where lands and creatures interact, shown by
how creatures behave there), gets its own spec after this ships.

## 2. Decisions (user-approved in chat)

| Topic | Decision |
|---|---|
| Setting | A cosy **cottage room in afternoon sun**; the board lies on a big wooden table. |
| Rival | The rival hero model (KayKit Barbarian) sits across the table holding cards and reacts. |
| Camera | Seat view + mouse-wheel/pinch zoom to a "lean in" view; opening sweep; attack close-ups (can be turned off). |
| Board | Long lanes, pieces at about 40% of today's size, buildings at the back of each half-lane. |
| Wandering | Creatures roam their own half-lane; position is cosmetic, rules unchanged. |
| UI | Fix all four: hand covers board, creature labels, hard to follow, generic look. |
| Room build | Real 3D room from CC0 KayKit packs + our toon shading and outlines; walls etc. built in code. |
| Order | This spec → land quirks (part 2) → Rules 2.0 Stage 4 (keyword visuals, Dream Up picker) and Stage 5 (web parity). |

## 3. The room

### 3.1 Layout

- A rectangular cottage room. The camera's seat is on one long side of the table; the **window
  wall** is behind the rival, so the rival is lit from behind with sunbeams falling across the
  table towards the player.
- **Window wall:** two or three tall windows with wooden frames. Outside: painted-sky gradient,
  rolling hills and trees (existing Quaternius nature models), and one small floating island in
  the distance (the Dream Isles).
- **Left side:** a stove with pots, a kitchen counter, shelves of jars.
- **Right side:** bookshelf with books and plants, an armchair with a **napping cat**, a standing
  lamp, picture frames.
- **Floor:** wooden planks with a large rug under the table. **Ceiling:** exposed wooden beams.
- **Table:** a big wooden table. On it: the board (section 4), each player's deck and discard
  pile as real card stacks at their own right-hand side, a snack bowl, a mug and a candle
  near the corners, never overlapping the board or the hand area on screen.

### 3.2 Assets

- **KayKit Furniture Bits 1.0** and **KayKit Restaurant Bits 1.0** (CC0, same maker as the hero
  models): chairs, table, shelves, books, plants, lamps, rug, picture frames, armchair, stove,
  counters, jars, pots, bowls, mug, food.
- Walls, floor planks, beams, window frames and the window view: built in code (boxes and planes
  with small procedural wood and plaster shaders).
- Cat: a CC0 animal model with a sleep/idle loop. If no fitting CC0 cat is found, use a different
  small animal (dog or fox) and say so at the Stage 1 checkpoint.
- Everything goes through `Toon` (cartoon shading) and the screen-space `Outline` pass, like the
  pieces. Credits added to `assets/CREDITS.md`.

### 3.3 Light and atmosphere

- One directional **sun** from behind-left of the windows; warm colour. Soft ambient fill so the
  room never goes dark; the table is the brightest area.
- **Sunbeams:** additive, soft-edged transparent shapes from each window to the floor and table,
  plus slow floating **dust motes** (particles) in them. No real-time GI.
- Real-time shadows only for the table area (board, pieces, rival, table props). Room furniture
  uses painted-on contact shadows (blob shadows), so the shadow map stays small.
- Old meadow, clouds and outdoor scenery ring are removed.

### 3.4 Rival

- KayKit Barbarian (already in `assets/heroes/`) seated in a chair across the table, using the
  pack's `Sit_Chair_Idle`. A small fan of card backs is attached to the hand bone.
- Reactions blend the **upper body** over the seated legs (bone-filtered blend):
  - plays a card → `Interact` (leans in),
  - damages your hero → `Cheer`,
  - takes hero damage → `Hit_A`,
  - its turn, thinking → slow head turn / look at the cards (idle variation),
  - loses → slumps (head down, procedural spine/head bend held), wins → `Cheer` loop.
- The rival is also an attack target: dropping an attack on the rival's model counts as targeting
  the enemy hero (section 6.2).

## 4. The board

### 4.1 Shape and scale

- The board is a wooden tray on the table holding **8 land tiles**: 4 lanes, each split at the
  middle into your half (near) and the rival's half (far). A thin **glowing seam** marks the
  middle line; a wooden frame with brass corners runs around the tray and between lanes.
- **Proportions:** each half-lane is about 2.6 wide × 5.4 deep in board units (today 2.32 ×
  4.5). Creature heights shrink to about 40% of today's (`HEIGHTS` 1.0/1.0/1.3/1.7 → about
  0.42/0.42/0.55/0.72), buildings likewise. A level-1 creature then takes about a fifth of a
  lane's width. Exact numbers are tuned at the Stage 2 checkpoint by screenshot.
- **Zones in each half-lane** (from the player's own edge towards the seam):
  - back 25%: **building spot** (the building sits here, centred),
  - front 75%: **roam zone** for the creature (inset 0.25 from lane edges and seam).
- A **boop button** spot is fixed at the near-left corner of each of your half-lanes (section 6.3).

### 4.2 Lane dressing

Dense, small-scale ground cover per land, drawn with MultiMesh so it stays cheap:

| Land | Dressing | Footstep puff |
|---|---|---|
| Mushroom Forest | tall grass tufts, tiny mushrooms, moss patches | spores/leaves |
| Ember Flats | cracked-earth ground, glowing vents with small ash plumes | ash/embers |
| Candy Hills | sprinkles, gumdrops, small lollipop trees | sprinkles |
| Frostpeak | snowdrifts, ice crystals | snow |

- Grass, tufts and crystals **bend away from creatures** that walk through them: the dressing
  shader gets up to 8 creature positions as a uniform array.
- Dressing never covers the building spot or the boop button spot.

## 5. Pieces and wandering

### 5.1 Wandering (cosmetic)

A new `Wanderer` component on each `CreatureView` drives movement inside the roam zone with its
**own RNG** (not the match RNG), so rules, AI and replays are untouched.

States:

| State | When | Behaviour |
|---|---|---|
| `ROAM` | ready, idle | Walk (`Walk`; flyers drift with `Flying_Idle`/`Fast_Flying`; blobs hop) to a random point in the zone; then `PAUSE`. |
| `PAUSE` | between walks | 1.5–4 s: face the enemy side, bounce on toes, or a fidget (`Wave`, `Yes`, look around). Occasionally waves at a neighbour within reach in the next lane. |
| `REST` | not ready (just played) | Stays put, slow idle, the "z" puffs (existing). |
| `HELD` | frozen, aiming, or claimed by the event player | Stands still; faces the aim target when aiming. |

- Speed by size class: small 0.6, medium 0.5, big 0.4 board units/s; turning is smoothed.
- Footsteps emit the land's puff (table above) at a low rate.
- A newly played creature appears where the card was dropped (clamped into the roam zone).

### 5.2 Attacks and events

- The event player **claims** a creature (`HELD`), plays the sequence from the creature's
  **current** position to the target's current position, then **releases** it; it jogs back into
  its zone and resumes.
- Creature → creature: run to the target (diagonally across lanes when needed), hit, hit-back,
  jog home. Timing bar unchanged.
- Creature → rival hero: run to the far edge, leap towards the rival; the rival flinches.
- Rival creature → your hero: run to your edge and leap at the camera; screen shake and red flash.
- Deaths, freezes, spell hits and projectiles use the creature's current position.

### 5.3 Buildings and labels

- Buildings sit on their building spot and are not moved by wandering.
- Ready ring and "z" puffs follow the creature (they already parent to it).

## 6. Camera and input

### 6.1 Camera

- **Seat view:** from the player's chair. The whole board fits in the lower ~60% of the screen
  above the hand strip; the rival's head and shoulders and the window wall are visible above the
  far edge. Roughly 38° pitch.
- **Lean-in view:** closer and steeper (roughly 55°); the board fills the screen width, the
  rival mostly out of frame.
- **Zoom:** mouse wheel / trackpad pinch moves a 0–1 value between the two views (position,
  pitch and FOV interpolated, eased). Default is the seat view. Zoom speed is a setting.
- **Opening sweep:** about 3 s from a room corner, past the rival, into the seat view, before the
  first turn. Any click or key skips it.
- **Attack close-up:** for each attack, the camera moves low behind the attacker looking at the
  target for the attack's duration (about 1 s), then returns to the player's current zoom. A
  "Battle close-ups" setting (default on) disables it.
- Existing shake and punch-zoom keep working in every view.

### 6.2 Input

- **Half-lane = piece.** Pressing anywhere on your half-lane picks its creature; dropping an
  attack anywhere on an enemy half-lane targets its creature; spell/ability targets use the same
  rule. `Board.lane_at_screen` already maps screen → half-lane and keeps doing so in both views
  and in between.
- **Hero target:** the rival's model, the rival's corner panel, and the table strip between the
  board's far edge and the rival all count as the enemy hero.
- While aiming, the chosen creature is `HELD` and the arrow starts from its current screen
  position.
- Card drag: dropping a creature or building on a valid half-lane plays it there (as now).

### 6.3 Boop button

A small brass button anchored to the fixed boop spot of each of your half-lanes (2D control
following the 3D point). It lights up when that creature can boop; hover shows what the boop does.
The rival's boop spots show only a small icon when used.

## 7. Screen and UI

### 7.1 Look

Wood, parchment and brass styling for all panels and buttons (StyleBox textures or flat styles
with wood/brass colours and bevels), warm palette, the existing Lilita One title font. Applies to
the HUD, hand, pause, settings, results and timing bar.

### 7.2 Layout (1280×720 reference; must also fit 1366×768 and 1920×1080)

| Element | Place | Behaviour |
|---|---|---|
| Hand | bottom edge, centre | Cards show their top third (name, cost, top of art), slight fan. Hover: card rises to full size, neighbours spread. Dragging onto the board: card shrinks to a small token; valid half-lanes light up. |
| Your corner | bottom-left | Round wooden portrait frame, heart with health number, health bar, magic gems. |
| Rival corner | top-right | Same, plus number of cards in hand. |
| END TURN | bottom-right | Big round brass button. While N ≥ 1 of your creatures can still attack or boop, shows "N can act". When no creature can act and no card in hand is affordable and playable, it glows and pulses. On the AI's turn it is greyed and reads "Rival's turn". |
| Deck / discard | 3D card stacks on the table | Hover: count tooltip. Click the discard stack: a panel with the discard pile's cards. The DECK/DISCARD plates go away. |
| Turn banner | centre | "Your turn" / "Rival's turn" sweeps across at each turn start (existing `Banner`). |
| Rival card reveal | left of the board | Each card the rival plays shows large for about 1.2 s before it lands. |
| Action log | left edge | Last 5 events as small rows (icon + short text, e.g. "Flarebeak hit Mossback for 3"); older rows fade; hover a row for details. |
| Pause | top-left | Small brass gear button. |

### 7.3 Creature tags

- A small tag floats over each creature's head and follows it: attack number in a small badge,
  thin health bar with "4/5" text (colour by health ratio as now).
- Hover over the creature (or its half-lane), or aim an attack at it: the tag grows and shows the
  name and keywords; the full card appears in the hover card spot at the screen side.
- Tags avoid overlapping each other (a small vertical nudge when two are close on screen).
- Damage/heal numbers pop from the creature's current position.

### 7.4 Settings

Add to the settings panel: **Battle close-ups** (on/off, default on) and **Zoom speed** (slider).
Both saved in `user://settings.cfg` with the others.

## 8. Architecture

Rules (`core/`), AI (`ai/`) and the event stream are unchanged. All work is in `view/`,
`autoload/settings.gd`, assets and tests.

| Unit | Change |
|---|---|
| `view/room/room.gd` (new) | Builds the cottage: shell, furniture, window view, sunbeams, dust, cat. Pure decoration; exposes table top height and table rect. |
| `view/room/rival_seat.gd` (new) | Rival model, chair, card fan, reaction API (`play_card()`, `cheer()`, `flinch()`, `think(on)`, `lose()`, `win()`), hero-target screen rect. |
| `view/board/board.gd` | Becomes the tray on the table: new lane geometry constants, zones per half-lane (`roam_rect(p, l)`, `building_point(p, l)`, `boop_point(p, l)`), seam and frame. Drops sky/meadow/clouds/scenery (moved or deleted). `lane_at_screen` keeps its contract. |
| `view/board/island.gd`, `lane_dressing.gd`, `lane.gdshader` | New size; MultiMesh dressing; creature-bend uniform. |
| `view/board/ambient.gd` | Keeps only small per-land particles over the lanes (dust in sunbeams belongs to `room.gd`). |
| `view/pieces/wanderer.gd` (new) | The state machine in 5.1; `claim()`/`release()`; reads `Board.roam_rect`. |
| `view/pieces/creature_view.gd`, `building_view.gd` | New scale; walk/hop/drift animation hooks; footstep puffs. |
| `view/fx/camera_rig.gd` | Seat/lean-in views, zoom value, opening sweep, attack close-up; shake and punch-zoom on top. |
| `view/event_player.gd` | Uses current positions; claims/releases creatures; rival reactions; close-up calls; hero leap targets (rival model / camera). |
| `view/input_controller.gd` | Holds the aimed creature; hero target includes rival rect; boop button source. |
| `view/ui/*` | New styling (`ui_style.gd`), slim hand, corners, END TURN, tags, boop buttons, log panel (new `action_log.gd`), rival card reveal, discard viewer (new), settings. |
| `view/match.gd` | Wires room, rival, camera states; removes tray assumptions. |
| `autoload/settings.gd` | `battle_closeups`, `zoom_speed`. |

Quality presets keep working: Low halves dust and dressing density and uses a shorter shadow
distance; web (Compatibility) gets the same room without glow.

## 9. Performance

Target on the user's Intel HD 620 (Mobile renderer, Low): **≥ 55 fps average** during a live turn
with 8 creatures wandering, measured with `--fps-log`. Budget levers, in order: dressing density,
dust count, shadow distance, room prop count. The web build is not re-exported in this project
unless the user asks.

## 10. Testing

Headless checks (existing runner) plus screenshots at each checkpoint:

- **Fit:** in the seat view at 1280×720, 1366×768 and 1920×1080, all 8 half-lanes are fully on
  screen above the hand strip and not covered by the corners or END TURN; the rival's head is on
  screen. In the lean-in view all 4 of your half-lanes are on screen.
- **Input:** `lane_at_screen` returns the right half-lane for the centre of each roam zone in the
  seat view, the lean-in view and halfway between; the rival's rect maps to the hero target.
- **Wandering:** over 120 simulated seconds per creature, positions always stay inside the roam
  zone; `REST` creatures do not move; `claim()` stops movement within one frame; `release()`
  resumes; wandering never touches the match RNG (same seed → same match log with and without
  wandering).
- **Events:** attack/death/spell sequences finish with every creature released and inside its
  zone; attacks from mid-roam positions end at the target.
- **Camera:** the opening sweep ends exactly at the seat view, skipping jumps there; close-ups
  return to the pre-attack zoom; close-ups off → camera never leaves the zoom path.
- **UI layout:** no overlaps between hand strip, corners, END TURN, log and hover card at the three
  resolutions; END TURN label states (`N can act`, pulse, rival's turn) follow the game state.
- **Settings:** new keys save and load; defaults correct.
- All existing tests keep passing (updated where they assert old positions/sizes).

## 11. Stages (user checkpoints with screenshots)

1. **Room and camera:** room, table, light, sunbeams, rival seated with reactions, seat/lean-in
   zoom, opening sweep. Board still at the old geometry. Checkpoint: screenshots of both views and
   a mid-sweep frame; fps.
2. **Board and pieces:** new board shape and dressing, small pieces, buildings at the back,
   wandering, attacks from current positions, hero leaps, close-ups. Checkpoint: screenshots with
   a full board, a close-up frame; fps with 8 creatures.
3. **UI:** styling, slim hand, corners, END TURN, tags, boop buttons, banner, rival card reveal,
   action log, discard viewer, settings. Checkpoint: screenshots at three resolutions; final
   review; fps.

## 12. Out of scope

- Land quirks (part 2), keyword visuals and Dream Up picker (Rules 2.0 Stage 4), web parity and
  redeploy (Stage 5).
- New card art, new creature models, room sounds and music changes.
- The player's own hero model or hands on screen.
