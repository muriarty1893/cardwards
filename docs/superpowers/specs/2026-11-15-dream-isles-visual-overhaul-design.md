# Dream Isles: visual and audio overhaul

Date: 2026-11-15
Status: design approved in chat, awaiting spec review

## 1. Why

v1 plays correctly (561 headless checks), but the user judged the look and feel far below
what they expected: emoji card art, stock models that don't match their cards, flat lane
textures, tween-only animation, no spell effects, a generic environment and no sound.

The target is the quality and kind of look in the user's reference screenshot
(`~/Desktop/WIP.png`, a Card Wars match with the hero portraits and hand blanked out):

- a cartoon look with dark ink outlines and painted ground;
- the board seen from high up, filling the screen between the top corners and the hand;
- lanes as painted ground with wavy borders and grass and props on them;
- an attack number and a current/max health bar above every creature;
- an ability button on each lane;
- hero portraits with health bars in the top corners, the hand along the bottom.

We match that quality and style of presentation, not its content. All names, creatures,
lands and art stay Dream Isles' own (original-IP rule from the v1 spec).

## 2. Decisions

| Topic | Decision |
|---|---|
| Art source | Free online packs, found and fetched by Claude. CC0 wherever possible; the spell icons are CC BY 3.0 and are credited. |
| Approach | Cartoon shading and ink outlines on 3D models, all packs drawn in the same style. Card pictures are rendered from the same models. |
| Setting | The board sits on a painted meadow under a cartoon sky (no floating islands or slab). The camera is higher and closer. |
| Rules and AI | Behaviour unchanged. One additive, informational event (`ability_triggered`, see 6.3) so the view knows what caused an effect. |
| Sound | Added (there is none today): sound effects, two music loops, volume sliders. |
| Performance | 60 fps at 1280x720 on the user's Intel HD 620, with a Low graphics option. |

Out of scope: rule or balance changes, new cards, online play, new modes, voice acting,
mobile builds.

## 3. Asset sources

Only files the game actually uses are committed. `assets/CREDITS.md` lists every file
group with author, licence and source URL, and the main menu gets a Credits panel showing
the same list (needed for CC BY).

| Need | Source | Licence |
|---|---|---|
| Creatures | Quaternius "Ultimate Monsters" (50 animated monsters, glTF), 24 used today | CC0 |
| Buildings | Quaternius "Ultimate Fantasy RTS" (already in `assets/buildings`) | CC0 |
| Meadow and lane props | Quaternius "Stylized Nature MegaKit" (grass, flowers, mushrooms, rocks, bushes, trees) | CC0 |
| Candy props | Kenney "Food Kit" (cupcakes, donuts, sweets) | CC0 |
| Hero portraits | KayKit "Adventurers" (Kay Lousberg), rendered to images | CC0 |
| Effect textures | Kenney "Particle Pack" (flames, smoke, sparks, stars, magic) | CC0 |
| Spell icons | game-icons.net (Lorc, Delapouite and others) | CC BY 3.0 |
| Font | Lilita One (Google Fonts) | OFL |
| Sound effects | Kenney "Interface Sounds", "Impact Sounds", "RPG Audio", "Casino Audio" (card sounds), "Music Jingles" | CC0 |
| Music | OpenGameArt: "Happy Clappy Loop" by OwlishMedia (menu), "Happy Adventure (Loop)" by TinyWorlds (match) | CC0 |

Fallbacks if a source can't be downloaded or lacks a needed piece:

- Candy props: build them from primitives (striped cylinders and spheres) in the cartoon style.
- Ice crystals and lava rocks: build crystals from primitives; use nature-kit rocks with a land tint.
- Hero portraits: render two big monsters (`Big/Ninja`, `Big/Tribal`).
- Any sound: use a CC0 sound from OpenGameArt and credit it.

## 4. Look

### 4.1 Cartoon shading and outlines

- **Toon material** (`view/look/toon.gdshader`): light and shadow in 3 flat bands, a soft rim
  light, the model's own albedo texture, an optional land tint, and support for flash
  (white hit flash) and fade (death). `Toon.apply(node, tint)` swaps every imported
  material on a model for this shader, keeping each one's albedo texture. It is used on
  every creature, building, prop and hero model.
- **Ink outline** (`view/look/outline.gdshader`): a full-screen pass that draws dark lines
  where depth or normals change sharply. It runs as a quad in front of the camera that reads
  the depth and normal-roughness textures (Forward+). Line width scales with resolution.
  This one pass outlines everything consistently, including low-poly models where
  inverted-hull outlines break.

### 4.2 Camera and setting

- The camera is pitched about 55° down and moved closer, so the 4x2 lane block fills the
  space between the top HUD corners and the hand tray at 1280x720, 1366x768 and 1920x1080. It keeps
  the existing shake, and gains a quick zoom for crits.
- **Meadow:** a large painted ground plane (`view/look/ground.gdshader`: soft colour noise
  and brush-like variation, no tiling seams) running to the horizon, and a gradient cartoon
  sky with slowly drifting toon-shaded cloud puffs.
- **Scenery:** nature-kit trees, bushes, rocks and flowers placed with a fixed seed in a ring
  around the board, kept out of the camera's view of the lanes. Grass sways (vertex wind in
  the toon shader).
- The purple slab, floating islets and cloud sea are removed. A low painted rim (stone and
  turf) frames the board.

### 4.3 Lanes

- The lane shader (`view/board/lane.gdshader`) is rewritten. Each land is painted
  procedurally, and lane borders are wavy, outlined strips like the reference.
- **Props** (`view/board/lane_dressing.gd`): each land places its props along the lane
  edges and back, away from where creatures, buildings and stat bars sit.
  - Mushroom Forest: mossy grass, mushroom clumps, clover, tall grass tufts.
  - Ember Flats: dark cracked rock with glowing, pulsing lava cracks; dark tinted rocks.
  - Candy Hills: pink frosting ground with sprinkles; sweets and lollipops on the edges
    (replaces the pink stripes).
  - Frostpeak: snow with blue shading; ice crystals and snowy rocks.
- **Ambient particles** (`view/board/ambient.gd`): fireflies and spores over the forest,
  embers rising from Ember Flats, snowfall on Frostpeak, sparkles over Candy Hills. They are
  halved on Low quality.
- **Highlights:** valid lanes get a glowing animated outline; targets get a pulsing,
  differently coloured outline. This replaces the tint.

## 5. Creatures, cards and HUD

### 5.1 Visual table

All per-card visuals live in one table, `view/visual_db.gd` (`VisualDB`), keyed by card id:
model path, tint, card-picture path, effect kind and sound set. Nothing card-specific is
hard-coded anywhere else. A test checks the table is complete (section 8).

### 5.2 Creature models

Proposed mapping. The final choice is made from a contact sheet of all 24 creatures,
which the user approves before the models are wired in (stage 2).

| Card | Lvl | Model (Ultimate Monsters) | Tint |
|---|---|---|---|
| Sporeling | 1 | Blob/Mushnub | none |
| Mossback | 1 | Blob/GreenSpikyBlob | moss green |
| Puffcap | 1 | Blob/Cactoro | pale cream |
| Glimmer Morel | 2 | Blob/Mushnub_Evolved | none |
| Rootstalker | 2 | Big/Cactoro | bark brown |
| Elder Shroomhulk | 3 | Big/MushroomKing | none |
| Cinderpup | 1 | Blob/Dog | ember |
| Ashmite | 1 | Flying/Armabee | ash grey |
| Flarebeak | 1 | Blob/Chicken | ember |
| Magmaw | 2 | Big/Demon | none |
| Blazehorn | 2 | Big/Dino | ember |
| Inferno Drake | 3 | Flying/Dragon_Evolved | ember |
| Gumdrop | 1 | Blob/PinkBlob | none |
| Taffy Snail | 1 | Blob/GreenBlob | taffy yellow |
| Lollibat | 1 | Flying/Demon | candy purple |
| Sugar Sprite | 2 | Flying/Ghost | candy cyan |
| Jellywobble | 2 | Flying/Glub | candy blue |
| Bonbon Behemoth | 3 | Big/Bunny | candy pink |
| Snowmite | 1 | Blob/Yeti | none |
| Iceling | 1 | Flying/Hywirl | icy |
| Frostfang | 1 | Blob/Cat | icy |
| Glacier Tortoise | 2 | Flying/Goleling_Evolved | icy |
| Rimewing | 2 | Flying/Pigeon | icy |
| Blizzard Titan | 3 | Big/Yeti | none |

- Standing heights by level: 1.0, 1.3 and 1.7 world units, so strength reads at a glance.
- Creatures keep their three-quarter turn toward the enemy (faces stay visible), play their idle loop, and every 6–12 s (random) play a
  fidget clip the model has (`Wave`, `Yes`, `Dance`).
- Buildings keep their Quaternius models with the toon material and a land tint.

### 5.3 On-board stats and boop buttons

A screen-space overlay (`view/ui/unit_overlay.gd`, on its own CanvasLayer) follows each
piece by projecting its world position every frame:

- **Creatures:** a big outlined attack number, and a health bar with "current/max" text.
  The bar drains smoothly over 0.3 s; it is green above 60%, yellow at 30–60% and red below
  30%. Its values come from game state after each event, never from the animation.
- **Buildings:** a small badge with a game-icons.net icon for their effect (heal, +ATK, +HP,
  shield, magic, smoke).
- **Boop button:** shown on the near edge of each of the human's lanes whose creature has a
  boop ability. It glows when `Rules.validate` allows the boop, and is greyed out when not
  (already acted this turn, frozen, not your turn). Clicking it runs exactly the current
  boop-and-target flow. Clicking the creature itself still works.
- **Hover:** hovering any creature or building on the board shows its full card, enlarged,
  beside it.

### 5.4 Cards

- **Picture:** baked once to `assets/card_art/<id>.png` (320x240) by
  `tools/bake_card_art.tscn`, which runs windowed, renders each subject in a SubViewport
  with the toon material, outline and a painted land backdrop, and saves PNGs. The game
  only loads images.
  - Creatures and buildings: their own model in a three-quarter pose.
  - Spells: a game-icons.net icon chosen to match the spell's name, white with a dark
    outline, over a radial glow in its land's colour (the effects library comes later,
    in stage 4).
- **Frame:** coloured by land with a thick dark outline, the picture in the top half, the
  name on a ribbon, a cost gem top-left, sword and heart badges (creatures), and the ability
  text printed on the card. Fonts: Lilita One for names and numbers, the current UI font
  for rules text.
- **Hand:** cards grow from 120x168 to 140x196. A hovered card lifts and scales to 1.6x so
  its text is readable; this replaces the tooltip. Unplayable cards are dimmed as today.

### 5.5 HUD and menus

- **Hero corners:** cartoon portraits rendered from two KayKit Adventurers characters (the
  human is the Mage, the rival the Barbarian), baked like card art, with a wide health bar
  along the top edge (as in the reference), the magic orb and the cards-in-hand count.
- **Tray, buttons, BATTLE!, pause menu, timing bar and results screen:** restyled with the
  same outlined cartoon panels and Lilita One.
- **Main menu:** shows the new board scene behind it. Deck buttons show the deck's best
  creature's card picture. Adds Credits and Settings buttons.

## 6. Animation and effects

### 6.1 Effects library (`view/fx/`)

Reusable, parameterised pieces with Kenney particle textures. They are created on demand
and freed when done.

- `burst.gd`: a one-shot particle burst; presets `sparks`, `stars`, `dust_ring`, `leaves`,
  `embers`, `sprinkles`, `snow`, `smoke`, `heal`.
- `projectile.gd`: an object that travels an arc from A to B with a trail and an impact
  burst. Elements: `spore`, `fire`, `candy`, `ice`, `boulder`.
- `ice_shell.gd`: a see-through, cracked ice shell around a frozen creature; shatters into
  shards on thaw.
- `rain.gd`: falling particles over a set of lanes (Ember Rain, Rain of Spores).
- `banner.gd`: the big "YOUR TURN" / "RIVAL'S TURN" banner that sweeps across.
- `screen_flash.gd`: a coloured screen-edge flash (red when a hero is hit).
- Damage numbers get a cartoon pop and outline. Crits get a "CRIT!" stamp.

### 6.2 Sequences

- **Attack:** wind-up squash (0.12 s), then a leap with a trail. On impact: hit-stop (both
  pieces freeze 0.07 s), white flash on the target, a `sparks` + `stars` burst, camera
  shake scaled to damage, and the damage number. A crit adds a bigger burst, the CRIT
  stamp and a 0.25 s camera zoom-in. A glancing hit gets only a `dust_ring`. Hitting the
  hero leaps toward the hero's side, flashes the screen edge red and shakes the portrait.
- **Play creature:** the card flies from the hand to the lane, then the creature drops in
  with a `dust_ring` and its land's burst (`leaves`/`embers`/`sprinkles`/`snow`).
- **Play building:** it rises out of the ground with a `dust_ring` and a short shake.
- **Death:** death clip (capped at 0.9 s), then `smoke` + land burst while the toon fade
  runs, then removal.
- **Freeze / thaw:** a frost puff, then the ice shell forms. On thaw it shatters.
- **Spells:** each has a signature effect.
  - Fireball: `fire` projectile from the caster's side, explosion with `smoke`.
  - Ember Rain: `rain` of embers on every enemy lane.
  - Rain of Spores: glowing spore `rain` on the target, then `heal`.
  - Regrowth: vines sprout at the caster's side and the card rises to the hand.
  - Sugar Rush: a `sprinkles` burst and two cards fly to the hand.
  - Swap Trick: a candy-smoke puff; the two creatures spin while swapping.
  - Cold Snap: a frost wave to the target, then the ice shell.
  - Avalanche: `boulder` projectiles tumble onto the target, then the ice shell.
- **Boops, on-play, on-destroyed and building triggers:** chosen by what the ability does,
  coloured by the source's land.
  - Damage: a projectile of the land's element from the source to each target.
  - Heal: `heal` sparkles rising on each target.
  - Card draw: card backs fly from the deck to the hand.
  - Gain magic: a magic gem pops and flies to the magic orb.
  - Move lane: the creature hops to the new lane.
  - Return building: the building pops up and flies to its owner's hand.
  - Freeze: a frost wave, then the ice shell.
  - Smokestack shoots a smoke puff at the enemy hero, Spore Hut puffs spores, Candy Mill
    pops a gem.
- **End of match:** confetti on victory, a small rain cloud over the results panel on
  defeat.

### 6.3 Knowing what caused an effect

Spells, boops, on-play, on-destroyed, on-deal-damage and building triggers all resolve
through `Abilities.run`. Its first line appends
`ability_triggered {player, lane, card}` (lane is -1 for spells). The event changes no
state, is ignored by the AI, and keeps replays deterministic.

`EventPlayer` keeps the latest `ability_triggered` as the current source. The effect events
that follow (damaged, healed, frozen, drawn, moved, returned, magic) are drawn as coming
from that source, using `VisualDB`'s effect kind for it. The source is cleared at the next
`ability_triggered`, `attack`, `turn_started` or the end of the batch. Events with no source
fall back to plain effects (number pop plus burst).

`fx/fx_director.gd` turns (source, event) pairs into effect calls, so `event_player.gd`
stays a short dispatcher.

## 7. Sound

- **`autoload/audio.gd`:** a pool of 8 SFX players and 2 music players for crossfades.
  `Audio.sfx(&"hit_heavy")` picks a random variant from that sound's set with a slight
  pitch variation. Buses: Master, Music, SFX.
- **Sound sets:** UI click and hover, card draw / deal / flip / play, creature land,
  building rise, attack whoosh, hit light / heavy / crit, hero hit, death, heal chime,
  freeze crackle, ice shatter, fire whoosh, explosion, candy pop, magic gain, turn start,
  victory and defeat jingles.
- **Music:** one loop for the menu and one for matches, crossfaded over 1 s.
- **`autoload/settings.gd`:** music volume, SFX volume and graphics quality (High/Low),
  saved to `user://settings.cfg` and editable in the pause menu and main-menu Settings.

## 8. Performance and testing

- **Budget:** 60 fps at 1280x720 on the user's Intel HD 620 (Forward+).
  `--fps-log=<seconds>` (dev flag in the existing Screenshot autoload) prints average and
  worst frame time for a scripted demo turn. Measured at the end of every stage.
- **Low quality:** SSAO off, glow off, shadow map 1024, MSAA off, ambient particles halved.
  The default is High if it holds 60 fps on the user's machine at stage 1, otherwise Low.
- **Existing checks:** all 561 headless checks keep passing after every stage.
- **New headless checks:**
  - `VisualDB` covers all 40 cards, and every model, picture, icon and sound file it names
    exists.
  - Stat bars show the same attack and health as the game state after event playback
    (extends `verify_views`).
  - Boop buttons are visible and enabled exactly when `Rules.validate` allows the boop.
  - `ability_triggered` is emitted once per `Abilities.run` call, and replays stay
    identical.
  - Settings save and load.
  - The UI layout check passes at 1280x720, 1366x768 and 1920x1080 (no overlap between hero corners,
    board, overlay and tray).
- **Visual checks:** Claude takes screenshots (`--shot`) after each stage, compares them
  with the reference, and shows the user the key ones.

## 9. Stages

One implementation plan covers all five stages, in this order. Each stage is built, tested,
screenshot-checked and committed before the next starts.
The user sees screenshots at the end of each.

1. **Look:** asset fetch for the nature kit, Food Kit and Particle Pack; toon material,
   outline pass, camera, meadow, sky, lanes, props, ambient particles, quality setting and
   fps measurement.
2. **Creatures:** fetch the remaining monsters; contact sheet for user approval;
   `VisualDB`; model remap with tints and heights; idle fidgets; stat overlay; boop
   buttons; hover card.
3. **Cards and HUD:** fetch icons, font and heroes; card-art bake tool; new card frame and
   hand; hero portraits; restyled tray, menus, timing bar, results; Credits panel.
4. **Animation and effects:** `ability_triggered` event; effects library; FX director;
   attack, play, death, freeze, spell and ability sequences; turn banner; end-of-match
   effects.
5. **Sound:** fetch audio; Audio and Settings autoloads; sound sets wired to events and UI;
   music; volume sliders.

## 10. Risks

- **Downloads:** Google Drive rate limits or itch.io download pages can block fetching.
  Mirrors exist (OpenGameArt, Godot Asset Library GitHub repos); section 3's fallbacks
  cover the rest.
- **Integrated GPU:** if the outline pass plus particles miss 60 fps even on Low, drop the
  normal-based edges (depth only) and halve the outline resolution before cutting anything
  visible.
- **Stock models:** they will still read as cute low-poly, not hand-drawn. Toon shading,
  tints and outlines narrow the gap; they don't close it. The user knows this.
