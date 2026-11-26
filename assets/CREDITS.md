# Third-party assets

Thanks to everyone below. All assets are free; licences are listed per source.
Files were trimmed (unused files left out, textures downscaled) but are otherwise unchanged
unless noted.

## Quaternius (https://quaternius.com), CC0 1.0

- `monsters/` (`blob/Cat.gltf`): the room's cat, from the "Ultimate Monsters" pack.
- `buildings/`: "Ultimate Fantasy RTS" pack (files renamed to card ids).
- `nature/`: "Stylized Nature MegaKit" (Standard), https://quaternius.com/packs/stylizednaturemegakit.html,
  downloaded from the OpenGameArt mirror https://opengameart.org/content/stylized-nature-megakit.
  Normal maps dropped and textures downscaled to 512 px.

## Kenney (https://kenney.nl), CC0 1.0

- `candy/`: "Food Kit" (lollypop, cupcake, donut-sprinkles, ice-cream, popsicle, candy-bar,
  cookie-chocolate, sundae + `Textures/colormap.png`), from the OpenGameArt mirror
  https://opengameart.org/content/food-kit.
- `fx/` (`fx/particles/`): "Particle Pack", from the OpenGameArt mirror
  https://opengameart.org/content/particle-pack-80-sprites. Downscaled to 128 px and
  converted to white with brightness as alpha.

## Sound and music, CC0 1.0

- `audio/` (`audio/sfx/`), by **Kenney**: "Interface Sounds" (https://opengameart.org/content/interface-sounds),
  "50 RPG sound effects" (https://opengameart.org/content/50-rpg-sound-effects),
  "54 casino sound effects" (https://opengameart.org/content/54-casino-sound-effects-cards-dice-chips),
  "85 short music jingles" (https://opengameart.org/content/85-short-music-jingles).
- `audio/sfx/`, by **rubberduck**: "75 CC0 breaking / falling / hit sfx"
  (https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx).
- `audio/music/menu.mp3`: "Happy Clappy Loop" by **OwlishMedia** (https://opengameart.org/content/happy-clappy-loop).
- `audio/music/match.mp3`: "Happy Adventure (Loop)" by **TinyWorlds** (https://opengameart.org/content/happy-adventure-loop).
- Files were renamed to `<sound set>_<n>.ogg`; the mapping lives in `autoload/audio.gd`.

## Kay Lousberg, KayKit (https://www.kaylousberg.com), CC0 1.0

- `heroes/`: "KayKit Character Pack: Adventurers" 1.0 (Mage, Barbarian),
  https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 (see `heroes/LICENSE.txt`).
- `room/`: "KayKit Furniture Bits" 1.0 (table, chair, armchair, couch, cabinet, shelf, lamp, picture
  frames, rug, cactus, books), https://github.com/KayKit-Game-Assets/KayKit-Furniture-Bits-1.0, and
  "KayKit Restaurant Bits" 1.0 (kitchen counters, wall cabinet, stove, bowl, plate, door),
  https://github.com/KayKit-Game-Assets/KayKit-Restaurant-Bits-1.0. Both CC0 1.0.

## game-icons.net (https://game-icons.net), CC BY 3.0

Licence: https://creativecommons.org/licenses/by/3.0/ . Source: https://github.com/game-icons/icons .
Change: the black background square was removed so the icons are white on transparent.

- `icons/`, by **Lorc** (https://lorcblog.blogspot.com): fireball, burning-meteor, pollen-dust,
  sprout, wrapped-sweet, snowflake-2, crossed-swords, cut-diamond, checked-shield, sword-break,
  star-swirl, snowing, spiral-shell, volcano, flame-claws, heat-haze, guillotine, burning-book, root-tip,
  leaf-swirl, thorny-vine, wolf-howl, back-forth, stiletto, punch, lightning-frequency, shattered-glass,
  frozen-orb, ice-bolt, snowman, bubbles, sprint, dripping-goo, heart-drop, crossed-slashes, hood,
  angel-wings, spark-spirit, shield-reflect, mirror-mirror, sun-radiations, acorn, scroll-unfurled, match-tip,
  crystal-ball, ice-shield, sundial, stone-tower, ice-cube, stone-block, sunbeams,
  evil-moon, spotted-mushroom, death-zone, burst-blob, flame-tunnel, flaming-arrow, power-lightning, ember-shot,
  burning-embers, tooth, ice-spear, snowflake-1, frozen-block, crown-coin, cursed-star, screaming, bubbling-flask,
  crown, haunting.
- `icons/`, by **Delapouite** (https://delapouite.com): card-exchange, falling-rocks, chimney,
  mushrooms-cluster, spiral-lollipop, sandstorm, present, anticlockwise-rotation, clockwise-rotation,
  carnivorous-plant, sickle, grave-flowers, dog-house, cupcake, cookie, candy-canes, party-popper, jelly-beans,
  ice-spell-cast, igloo, two-coins, coins, robber, desert-camp, shop, dream-catcher, musical-notes, falling-star,
  well, guards.
- `icons/`, by **Sbed**: lava. By **Caro Asercion**: toothbrush.
- `icons/`, by **Willdabeast** (https://wjbstories.blogspot.com): round-shield.
- `icons/`, by **Sbed** (https://opengameart.org/content/95-game-icons): health-increase.
- `icons/`, by **Zeromancer**: heart-plus.

## Fonts

- `fonts/`: "Lilita One" by Juan Montoreano, SIL Open Font License 1.1 (see `fonts/OFL.txt`),
  https://fonts.google.com/specimen/Lilita+One .

## Project art

- `icons/heart.svg`, `icons/sparkle.svg`: simple shapes drawn for this game.

- `card_backs/`: card back designs made for this game by the project owner (backs_v4 set: Ember Reign,
  Frostbound, Verdant Bloom, Candy Realm), resized to 256x358. `card_backs/dunes.png` is Frostbound recoloured to sand gold
  (tools/make_dunes_back.gd).
- `monsters/forged/`: every creature, modelled, rigged and animated for this game in Blender. Mycelia
  (`mycelia_spore_weaver.glb`, source `art_src/Mycelia.blend`) was made by hand; the rest are built by the
  recipes in `art_src/forge/creatures/` (run them in Blender, see `art_src/forge/core.py`).
