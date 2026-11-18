# Board look 2 + Card expansion 2 — design

Date: 2026-11-18. Branch: feat/tabletop. Status: approved in chat section by section (sections 1–4 "ye"); section 5
and the written spec self-approved at the user's request ("i wont be here to approve so go on without me").

References: the user's Card Wars screenshots in `~/Desktop/model_creation_tests/reference_screenshots` (layout and feel
only — no art is copied). Card backs: the user's own designs in `~/Desktop/artcard/backs_v4`.

## 0. The user's list → where it is handled

| # | Request | Section |
|---|---|---|
| 1 | Lanes uneven and wobbly like a river, no empty space between lanes, widths change a bit each game | 1.1, 1.2 |
| 2 | Merging specific creatures into one with a combined ability | 4 |
| 3 | Hearthstone-style spells (e.g. damage your creature to buff it) | 5.2 |
| 4 | A dragged card tilts to lie parallel to the board (3D feel) | 3.2 |
| 5 | Lands with more character (volcano, long grass + lake, castle tower …) | 2 |
| 6 | Up to 3 different looks per land type | 2 |
| 7 | Enemy cards get a card back design (they are plain purple) | 3.1 |
| 8 | Lane separators appear after the start animation: each side one piece, then split into 4 | 1.3 |
| 9 | Boop button on the board, at the bottom side of the lane, after the start animation | 1.4 |
| 10 | Action history like Hearthstone: compact by default, full detail on hover | 3.3 |
| 11 | More cards | 5 |

## 1. Board

### 1.1 Layout (view only — the rules engine never sees it)
- New `BoardLayout` (view/board/board_layout.gd), built once per match from a seed (the match seed, so a replay looks
  the same). It owns 3 **border curves**, one between each pair of neighbouring lanes, running the full board length
  (rival's back edge → your back edge) so a border lines up across both halves.
- Curve i: `x(z) = base_i + shift_i + A·sin(z·k1 + φ1) + A2·sin(z·k2 + φ2)`.
  `base` = today's border positions (-2.7, 0, 2.7); `shift_i` random in ±0.30 (lane widths roughly 2.4–3.0 instead of
  2.7, outer lanes absorb the change against the straight tray edge); `A` 0.10–0.14, `k1` ≈ 2π/4.5 (one gentle bend over
  ~4.5 units), `A2` ≈ 0.03 with `k2` ≈ 2π/1.6 (small ripple). Outer lane edges stay straight against the frame
  (x = ±5.4).
- Every per-lane position derives from the layout: lane centre `centre_x(lane, z)` (midpoint of its two borders at z),
  roam rect (inset from the *narrowest* point of the lane over that half), building point, house point, boop plate,
  hero point, ambient particle boxes, ground cover scatter and hit tests (`lane_at(x, z)` = which pair of curves
  brackets x). `Board.LANE_X` is replaced by layout queries everywhere it is used.

### 1.2 Tiles meet, separated only by lines
- Tiles stay 8 separate `Island`s (keeps land morph, highlight, field weather, props per tile). Each tile mesh is wide
  enough to cover its lane at the widest point; the lane shader clips to its own **left and right curve** (same formula,
  passed as uniforms in tile-local space), so neighbours meet exactly: no soil gap.
- The wavy painted edge/rim of today is dropped on lane sides (kept on the far/near ends). The tray base under the tiles
  no longer shows between lanes.
- **Separator**: a thin raised ribbon (~0.07 wide, 0.025 high, rounded, cream `#fff3c9` with an ink outline) following
  each curve over the full board length (built as a strip mesh from the curve samples). The side colours (yellow
  yours / cyan rival's) remain as the highlight rims drawn by the lane shader.

### 1.3 One piece, then split
- At match start every lane is bare Meadow, so with the ribbons hidden each side reads as one slab.
- Ribbons are hidden while the opening sweep runs. When the sweep ends (or is skipped, or when there is no sweep —
  tests/screenshots skip straight to the end state), the ribbons **draw in** from the middle seam outward (0.6 s,
  ease-out) and the 8 tiles do a small staggered settle (drop 0.03, back up with a slight overshoot, 0.08 s stagger).
- `Board.reveal_split(animate)`; called by MatchController after the sweep.

### 1.4 Boop plate (replaces the floating 2D boop button)
- One pill-shaped 3D plate (0.9 × 0.34, brass rim, coloured top, "BOOP" label baked as a Label3D lying flat) on each of
  *your* lanes, centred across the lane at the lane's centre line, between the roam zone and the building row (the roam
  zone's back edge moves forward by 0.45 to make room). Rival lanes get none.
- Sunk below the surface until the split reveal ends, then rises (0.35 s, back ease).
- States: **dim** (no un-hushed boop on the lane's creature, or it can't boop now), **lit** (can boop: warm glow + slow
  pulse), **pressed** (on click: sinks 0.03 and springs back). Hovering a lit plate brightens it and shows the boop's
  card text tooltip (the old button's tooltip).
- Clicks: a ray-pick against the plate's area (no physics) → `input.request_boop(lane)`.

## 2. Land character: 3 variants per land

- `LaneDressing.build(land, player, slot, density, variant)` gets a `variant` (0–2). The variant and the set-piece
  corner (left/right back corner) are rolled per tile from the layout seed each time the land is set or changed.
- Placement rules: set pieces go in a back corner beside the building spot; ridges/slopes hug the lane's side edges;
  nothing enters the roam rect, the building footprint, the house spot or the boop plate. On your side (near the camera)
  tall set pieces are scaled ×0.8.
- Bare Meadow keeps today's single look.
- Set pieces are built from primitives in the toon style (Toon materials + ink outline) plus existing CC0 nature
  models. A CC0 model may replace a primitive build if it looks clearly better.
- Low quality: fewer small props, eruption/vent particles halved.

| Land | Variant 0 | Variant 1 | Variant 2 |
|---|---|---|---|
| Ember Flats | **Volcano**: cone with glowing crater + lava trickle; erupts every 12–25 s (smoke puff, sparks, 3–5 lava blobs arc out, crater flares) | **Lava Rift**: glowing lava crack along one side, tiny stone bridge, basalt column cluster, rising embers | **Ash Slopes**: raised dark rocky ridges along the edges, smoking vents that puff now and then, charred stumps |
| Mushroom Forest | **Pond Glade**: pond with rippling water, lily pads, reeds; long swaying grass along the edges | **Giant Shroom Grove**: 2–3 giant mushrooms, fallen log, ferns, fairy ring of tiny mushrooms | **Mossy Knoll**: raised mossy mound with a big tree, clover patches, stepping-stone path |
| Frostpeak | **Castle Corner**: small toy castle (keep, two turrets, wall, tiny banner), snow drifts | **Frozen Lake**: cracked shiny ice pond, snowy pines, lone watchtower | **Glacier Ridge**: raised ice ridges along the edges, crystal spikes, icy boulders |
| Candy Hills | **Chocolate River**: chocolate stream along one side with a wafer bridge, gumdrop rocks | **Lollipop Grove**: lollipop trees, candy-cane fence, pink frosting hills | **Sundae Peak**: big drippy sundae mountain in a corner, sprinkles, donut ring |

- Animated bits (water ripple, lava pulse, volcano eruptions, vents, swaying long grass) live in a small
  `SetPieceFx` helper per tile so they stop when the tile's dressing is freed.
- A land change pops set pieces up as the sweep passes (same as props today).

## 3. Cards UI

### 3.1 Card backs
- 4 backs from `~/Desktop/artcard/backs_v4`, resized to 256×356 PNG into `assets/card_backs/`:
  Ember = 01 Ember Reign, Frost = 03 Frostbound, Mushroom = 04 Verdant Bloom, Candy = 14 Candy Realm.
- `CardBacks.for_deck(deck)` → the deck's main land (most cards of one land; ties → its first lane's land) → texture.
- Used on: the rival's fanned hand (3D), both draw piles on the table (top face), the rival card reveal flip, and the
  deck viewer/builder header. Discard piles keep showing faces.

### 3.2 Drag tilt
- Over the hand strip the dragged card stays the 2D upright card.
- Once over the board it becomes a **3D card**: a quad textured with the card's widget (rendered once into a
  SubViewport), following the mouse ray at 0.9 above the tile surface, rotated to lie almost parallel to the board
  (tilted 18° up toward the camera so it stays readable), so perspective makes the far edge narrower.
- It sways with horizontal mouse speed (roll up to ±10°, pitch wobble up to 6°, smoothed) and eases between upright and
  flat over 0.12 s. Back over the hand → 2D card again. Drop → the play animation starts from the drop point.
- Replaces today's shrink-to-token. The lane drop highlight stays visible under it.

### 3.3 Hearthstone-style log
- A slim column of square tiles (56 px, 6 px gap) at the left edge, max 8, newest on top; older tiles slide down and
  the 8th fades out.
- **One tile per action**: the events from one `Rules.apply` (a play, an attack, a boop, a merge, a field, a land
  change by a card) are grouped. The tile shows the acting card's art, a gold (you) or lilac (rival) border and a
  corner badge: attack ⚔, spell ✦, built ⌂, merged ⧉, boop ●, destroyed ☠ (when the action's main result was a death).
- Hover → a panel beside the column: the full card (CardWidget) plus 1–4 detail lines built from the grouped events
  (targets as mini card names with results, e.g. "→ Gumdrop: 3 damage, destroyed", "lane 2 became Frostpeak",
  "+2 armour").
- Turn start, game over and similar non-card events are not tiles (game over has its own banner).

## 4. Merging

### 4.1 Data
- `CardData` gets `merge_with: StringName` (the partner's id), `merges_into: StringName` (the merged form's id) and
  `collectible: bool = true`. Both partners carry both fields (symmetric). Merged forms and tokens have
  `collectible = false` (never in decks, deck builder, Dream Up offers or random pools).
- Card text: partners get a line "Merges with X." Merged forms show "Merged form of A + B." and "When merged:" for their
  on_play.

### 4.2 Rules
- Playing a creature card whose `merge_with` partner is in the target lane of the **same player** is legal (instead of
  "Lane already has a creature") and merges. Cost = the hand card's cost. Land level requirement = the hand card's.
- Merge: the lane's CreatureState gets `card = merged form`; carries over damage, level, xp, atk_bonus, hp_bonus,
  gained keywords, freeze, hush, attacks_used, booped, ready (so a ready creature stays ready). Printed keywords of the
  merged form switch on fresh (Bubble up, Hidden on). `played_turn` is unchanged (no Dash bonus from merging unless the
  board creature was played this turn).
- Events: `creature_merged {player, lane, from (board card id), card (hand card id), into}`; then the merged form's
  on_play runs ("When merged:") with the action's targets; counts as playing a card for Combo and `cards_played`; the
  hand card goes nowhere (it is absorbed). When the merged creature dies, only the merged form goes to the discard.
- Targets: validated against the merged form's on_play.
- AI: merges appear in `legal_actions` like any play, so the planner scores them by simulation.

### 4.3 Look
- Dragging a merge partner over its partner on the board: that tile gets a swirling two-colour ring and a "MERGE" hint
  instead of the normal drop highlight.
- Drop: the hand creature's model hops in, the two spin together in a sparkle burst, then the merged view appears.
- Merged view: the bigger partner's model (×1.15) with the smaller one riding on its back/head (×0.6), both keeping their
  tints, with a soft two-colour aura ring. VisualDb gains `"merge": [big_id, rider_id]` entries; card art for merged
  forms is baked from this composite like every other creature.

## 5. New cards (32 collectible + 8 merged forms + 1 token)

All names and numbers are original; mechanics are inspired by Hearthstone. "L1" = needs 1 lane of its land.

### 5.1 Merge pairs (8 new partners; existing partners are unchanged apart from the merge line)

| Land | Existing partner | New partner | Merged form |
|---|---|---|---|
| Mushroom | Sporeling | **Glowmoth** 2c 2/1 flyer, Hidden | **Sporemoth** 4/3 sprout: Venom, Hidden; Sporeling's boop and level-up |
| Mushroom | Mossback | **Barkbeetle** 3c 3/3 beast; When played: give a friendly creature +0/+2 | **Mossback Colossus** 4/8 blob: Guard; When merged: gain Mossback's armour and give your creatures +0/+1 |
| Ember | Cinderpup | **Emberkit** 2c 2/2 beast; After it takes damage: +1 attack | **Twinflame Hound** 4/3 beast: Dash; After damage: +1 attack; Cinderpup's on_play as When merged + its level-up |
| Ember | Magmaw | **Cinder Wisp** 2c 1/3 spirit; Boop: 1 damage to the enemy hero | **Magma Wraith** 5/6 spirit: Boop: Magmaw's boop damage, then 1 damage to the enemy hero |
| Candy | Gumdrop | **Gummy Cub** 1c 1/3 blob; When played: if you have another Blob, draw a card | **Gummy Goliath** 4/7 blob: Boop: draw a card; When merged: draw a card |
| Candy | Lollibat | **Cotton Puff** 2c 2/2 flyer, Bubble | **Candyfloss Bat** 4/5 flyer: Flurry, Bubble; Lollibat's boop |
| Frost | Iceling | **Frostwisp** 2c 1/3 spirit; Boop: freeze an enemy creature | **Glacial Wisp** 3/5 spirit: Bubble; Boop: freeze an enemy creature; Iceling's level-up |
| Frost | Frostfang | **Snow Pup** 3c 2/3 beast; When played: freeze an enemy creature | **Snowfang Alpha** 5/5 beast: Frostfang's after-damage freeze; When merged: freeze an enemy creature |

### 5.2 Hearthstone-style spells (16)

| Land | Card | Cost | Text |
|---|---|---|---|
| Ember | **Stoke** | 0 | Deal 1 damage to a friendly creature. Give it +2 attack. |
| Ember | **Overheat** | 1 | Give a friendly creature +4/+4. Destroy it at the end of your turn. |
| Ember | **Finish Off** | 2 | Destroy a damaged enemy creature. |
| Ember | **Ember Pact** | 1 | Your hero takes 3 damage. Draw 2 cards. |
| Mushroom | **Deep Roots** | 2 | +1 max magic (your cap rises by 1 too, up to 10). |
| Mushroom | **Bark Coat** | 2 | Give a creature +2/+2 and Guard. |
| Mushroom | **Thorn Lash** | 4 | Deal 4 damage to an enemy creature and 1 damage to every other enemy (creatures and hero). |
| Mushroom | **Grove Roar** | 3 | Your creatures get +2 attack this turn. |
| Candy | **Taffy Pull** | 2 | Return an enemy creature to its owner's hand (discarded if the hand is full). |
| Candy | **Sugar Shiv** | 0 | Deal 2 damage to an undamaged creature. |
| Candy | **Jawbreaker** | 2 | Deal 2 damage to a creature. Combo: deal 2 more. |
| Candy | **Sugar High** | 0 | Your next spell this turn costs 2 less. |
| Frost | **Crack the Ice** | 1 | Destroy a frozen enemy creature. |
| Frost | **Whiteout** | 3 | Freeze every enemy creature. |
| Frost | **Icicle** | 1 | Freeze a creature. If it was already frozen, deal 4 damage to it instead. |
| Frost | **Snowmanify** | 4 | Turn a creature into a 1/1 Snowman with no abilities. |

Damage spells use Spell Power as today.

### 5.3 Other creatures (4) and buildings (4)

| Land | Card | Stats | Text |
|---|---|---|---|
| Ember | **Hot Head** | 1c 3/2 beast | When played: your hero takes 2 damage. |
| Mushroom | **Pain Shroom** | 3c 1/4 sprout | After it takes damage: draw a card. |
| Candy | **Sugar Smuggler** | 2c 2/2 spirit, Hidden | Combo — When played: draw a card. |
| Frost | **Ice Sage** | 3c 2/4 spirit | Spell Power +1. |
| Ember | **Bellows Forge** (building) | 2c | Start of your turn: deal 1 damage to this lane's creature and give it +2 attack. |
| Mushroom | **Fairy Ring** (building) | 2c | This lane's creature has Leech. |
| Candy | **Gingerbread Gate** (building) | 2c | This lane's creature has Guard and +2 HP. |
| Frost | **Frost Lookout** (building) | 4c | End of your turn: freeze the opposing creature. |

Token: **Snowman** (Frost, 1/1, no abilities, not collectible).

### 5.4 Engine additions
- CreatureState: `temp_atk` (cleared at the end of each turn), `doomed` (destroyed at the end of its owner's turn).
- PlayerState: `spell_discount` (cleared at end of turn, consumed by the next spell), `magic_cap` (default 8, max 10).
- Effect ops: `temp_atk`, `doom`, `grow_magic`, `bounce`, `spell_discount`, `transform` (into `EffectData.card_id`).
- EffectData: `cond` — `&"target_frozen"` / `&"target_not_frozen"`, checked per target when the effect runs (Icicle
  orders damage-if-frozen before freeze-if-not-frozen).
- Targeting: chosen `chosen_enemy_creature`, `chosen_damaged_enemy`, `chosen_undamaged_creature`,
  `chosen_frozen_enemy`; automatic `other_enemies` (every enemy creature and the enemy hero except the last target).
- Card text generator, keyword/tooltips and AI targeting know all of the above.

### 5.5 Art
- New creatures use more models from the Quaternius "Ultimate Monsters" pack (CC0; same download source as the
  existing 24). Buildings are built from primitives in our style (like the existing building gltfs) or CC0 models.
- Spell art follows the existing spell art pipeline. All card art is baked with tools/bake_card_art.

### 5.6 Decks and balance
- Each starter deck swaps about 6 cards for its land's new cards, including at least one complete merge pair.
- All collectible new cards appear in the deck builder.
- Re-run AI-vs-AI balance sims (tools/deck_balance) and tune numbers so no starter deck is outside ~40–60 %.

## 6. Testing
- Headless tests for: layout curves (continuity, widths in range, outer edges straight, lane_at round-trips centres),
  every new op/who/cond, merge legality and carry-over, card text of every new card, card back choice, log grouping,
  boop plate states, variant rolls stay out of play zones, data validation of all 79 + 9 cards.
- Screenshots at each stage: board split before/after, all 12 land variants, drag tilt, log hover, merge, card backs.
- Performance: live turn on Low ≥ 55 fps on the HD 620 (fps-log tool) after land variants.

## 7. Out of scope
- New card types, tokens beyond Snowman, a 5th land, hero powers, secrets (user declined).
- Web build re-export and pushing (only when the user asks).
