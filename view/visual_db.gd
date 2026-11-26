class_name VisualDB
extends RefCounted
## Every per-card visual in one place: model, tint, card picture (and later effect and sound).
## Nothing card-specific is hard-coded anywhere else in the view.

## Tints for models (alpha = how strongly the tint replaces the original colours).
const TINTS: Dictionary = {
	&"none": Color(1, 1, 1, 0),
	&"ember": Color("#ff6a2a", 0.55),
	&"ash": Color("#6a6a72", 0.6),
	&"icy": Color("#9fdcff", 0.55),
	&"moss": Color("#5aa34a", 0.5),
	&"cream": Color("#f2e6c8", 0.5),
	&"bark": Color("#7a5a3a", 0.5),
	&"taffy": Color("#ffd84a", 0.55),
	&"candy_purple": Color("#b06cff", 0.5),
	&"candy_cyan": Color("#7fe0ff", 0.5),
	&"candy_blue": Color("#4ad0ff", 0.5),
	&"candy_pink": Color("#ff8ad8", 0.5),
	&"b_forest": Color("#7bd36a", 0.25),
	&"b_ember": Color("#ff7a3a", 0.25),
	&"b_candy": Color("#ff9fcf", 0.25),
	&"b_frost": Color("#9fd8ff", 0.25),
	&"gummy_red": Color("#ff4a5a", 0.5),
	&"b_forge": Color("#ff5a1a", 0.35),
	&"b_fairy": Color("#c8ff8a", 0.35),
	&"b_ginger": Color("#c8853a", 0.4),
	&"b_lookout": Color("#cfeeff", 0.35),
	&"sand": Color("#e8c27a", 0.45),
	&"sun_gold": Color("#ffc94a", 0.5),
	&"djinn": Color("#6a9cff", 0.5),
	&"bone": Color("#f2e6cc", 0.35),
	&"leaf": Color("#7ad15a", 0.45),
	&"pink": Color("#ff9fd8", 0.5),
	&"snowy": Color("#e8f4ff", 0.55),
	&"b_sandstone": Color("#e2b878", 0.55),
	&"b_cairn": Color("#bfe8ff", 0.45),
}

## Creatures: "model" is relative to res://assets/monsters; every creature has its own model under forged/,
## made in Blender from the recipes in art_src/forge (forged/<id>.glb, untinted).
## Merged forms: "merge" = [big partner, rider partner] (CreatureView builds the pair; the model path is the big one's).
## Buildings use res://assets/buildings/<id>.gltf, or <"building">.gltf when set. Spells have no model.
const ENTRIES: Dictionary = {
	# Mushroom Forest
	&"sporeling": {"model": "forged/sporeling.glb", "tint": &"none"},
	&"mossback": {"model": "forged/mossback.glb", "tint": &"none"},
	&"puffcap": {"model": "forged/puffcap.glb", "tint": &"none"},
	&"glimmer_morel": {"model": "forged/glimmer_morel.glb", "tint": &"none"},
	&"rootstalker": {"model": "forged/rootstalker.glb", "tint": &"none"},
	&"elder_shroomhulk": {"model": "forged/elder_shroomhulk.glb", "tint": &"none"},
	&"spore_hut": {"tint": &"b_forest"},
	&"glowcap_lantern": {"tint": &"b_forest"},
	&"rain_of_spores": {},
	&"regrowth": {},
	# Ember Flats
	&"cinderpup": {"model": "forged/cinderpup.glb", "tint": &"none"},
	&"ashmite": {"model": "forged/ashmite.glb", "tint": &"none"},
	&"flarebeak": {"model": "forged/flarebeak.glb", "tint": &"none"},
	&"magmaw": {"model": "forged/magmaw.glb", "tint": &"none"},
	&"blazehorn": {"model": "forged/blazehorn.glb", "tint": &"none"},
	&"inferno_drake": {"model": "forged/inferno_drake.glb", "tint": &"none"},
	&"kiln_tower": {"tint": &"b_ember"},
	&"smokestack": {"tint": &"b_ember"},
	&"fireball": {},
	&"ember_rain": {},
	# Candy Hills
	&"gumdrop": {"model": "forged/gumdrop.glb", "tint": &"none"},
	&"taffy_snail": {"model": "forged/taffy_snail.glb", "tint": &"none"},
	&"lollibat": {"model": "forged/lollibat.glb", "tint": &"none"},
	&"sugar_sprite": {"model": "forged/sugar_sprite.glb", "tint": &"none"},
	&"jellywobble": {"model": "forged/jellywobble.glb", "tint": &"none"},
	&"bonbon_behemoth": {"model": "forged/bonbon_behemoth.glb", "tint": &"none"},
	&"sugar_shack": {"tint": &"b_candy"},
	&"candy_mill": {"tint": &"b_candy"},
	&"sugar_rush": {},
	&"swap_trick": {},
	# Frostpeak
	&"snowmite": {"model": "forged/snowmite.glb", "tint": &"none"},
	&"iceling": {"model": "forged/iceling.glb", "tint": &"none"},
	&"frostfang": {"model": "forged/frostfang.glb", "tint": &"none"},
	&"glacier_tortoise": {"model": "forged/glacier_tortoise.glb", "tint": &"none"},
	&"rimewing": {"model": "forged/rimewing.glb", "tint": &"none"},
	&"blizzard_titan": {"model": "forged/blizzard_titan.glb", "tint": &"none"},
	&"ice_wall": {"tint": &"b_frost"},
	&"frost_spire": {"tint": &"b_frost"},
	&"cold_snap": {},
	&"avalanche": {},
	# Card expansion 2
	&"glowmoth": {"model": "forged/glowmoth.glb", "tint": &"none"},
	&"barkbeetle": {"model": "forged/barkbeetle.glb", "tint": &"none"},
	&"pain_shroom": {"model": "forged/pain_shroom.glb", "tint": &"none"},
	&"emberkit": {"model": "forged/emberkit.glb", "tint": &"none"},
	&"cinder_wisp": {"model": "forged/cinder_wisp.glb", "tint": &"none"},
	&"hot_head": {"model": "forged/hot_head.glb", "tint": &"none"},
	&"gummy_cub": {"model": "forged/gummy_cub.glb", "tint": &"none"},
	&"cotton_puff": {"model": "forged/cotton_puff.glb", "tint": &"none"},
	&"sugar_smuggler": {"model": "forged/sugar_smuggler.glb", "tint": &"none"},
	&"frostwisp": {"model": "forged/frostwisp.glb", "tint": &"none"},
	&"snow_pup": {"model": "forged/snow_pup.glb", "tint": &"none"},
	&"ice_sage": {"model": "forged/ice_sage.glb", "tint": &"none"},
	&"snowman": {"model": "forged/snowman.glb", "tint": &"none"},
	&"sporemoth": {"merge": [&"sporeling", &"glowmoth"]},
	&"mossback_colossus": {"merge": [&"barkbeetle", &"mossback"]},
	&"twinflame_hound": {"merge": [&"cinderpup", &"emberkit"]},
	&"magma_wraith": {"merge": [&"magmaw", &"cinder_wisp"]},
	&"gummy_goliath": {"merge": [&"gumdrop", &"gummy_cub"]},
	&"candyfloss_bat": {"merge": [&"cotton_puff", &"lollibat"]},
	&"glacial_wisp": {"merge": [&"iceling", &"frostwisp"]},
	&"snowfang_alpha": {"merge": [&"frostfang", &"snow_pup"]},
	&"bellows_forge": {"building": "smokestack", "tint": &"b_forge"},
	&"fairy_ring": {"building": "glowcap_lantern", "tint": &"b_fairy"},
	&"gingerbread_gate": {"building": "sugar_shack", "tint": &"b_ginger"},
	&"frost_lookout": {"building": "frost_spire", "tint": &"b_lookout"},
	&"stoke": {}, &"overheat": {}, &"finish_off": {}, &"ember_pact": {},
	&"deep_roots": {}, &"bark_coat": {}, &"thorn_lash": {}, &"grove_roar": {},
	&"taffy_pull": {}, &"sugar_shiv": {}, &"jawbreaker": {}, &"sugar_high": {},
	&"crack_the_ice": {}, &"whiteout": {}, &"icicle": {}, &"snowmanify": {},
	# Neutral
	&"star_shard": {},
	# Living board: field spells and armour spells
	&"volcano": {}, &"snowstorm": {}, &"spore_bloom": {}, &"sugar_rain": {},
	&"bark_shield": {}, &"candy_shell": {},
	# Sunny Dunes and the second new-card batch
	&"sand_scuttler": {"model": "forged/sand_scuttler.glb", "tint": &"none"},
	&"meerkeep": {"model": "forged/meerkeep.glb", "tint": &"none"},
	&"sand_fox": {"model": "forged/sand_fox.glb", "tint": &"none"},
	&"sun_scarab": {"model": "forged/sun_scarab.glb", "tint": &"none"},
	&"dune_raptor": {"model": "forged/dune_raptor.glb", "tint": &"none"},
	&"sandwraith": {"model": "forged/sandwraith.glb", "tint": &"none"},
	&"oasis_alpaca": {"model": "forged/oasis_alpaca.glb", "tint": &"none"},
	&"lamp_djinn": {"model": "forged/lamp_djinn.glb", "tint": &"none"},
	&"sun_obelisk": {"building": "frost_spire", "tint": &"b_sandstone"},
	&"sandstone_watchtower": {"building": "kiln_tower", "tint": &"b_sandstone"},
	&"sun_shield": {}, &"sandstorm": {}, &"mirage": {}, &"heatwave": {},
	&"bog_toad": {"model": "forged/bog_toad.glb", "tint": &"none"},
	&"leaf_finch": {"model": "forged/leaf_finch.glb", "tint": &"none"},
	&"moss_oracle": {"model": "forged/moss_oracle.glb", "tint": &"none"},
	&"seed_pod": {},
	&"ember_wyrmling": {"model": "forged/ember_wyrmling.glb", "tint": &"none"},
	&"magma_hog": {"model": "forged/magma_hog.glb", "tint": &"none"},
	&"spark_scroll": {}, &"kindle": {},
	&"jelly_fish": {"model": "forged/jelly_fish.glb", "tint": &"none"},
	&"taffy_serpent": {"model": "forged/taffy_serpent.glb", "tint": &"none"},
	&"cotton_sheep": {"model": "forged/cotton_sheep.glb", "tint": &"none"},
	&"lucky_wrapper": {},
	&"snow_wolf": {"model": "forged/snow_wolf.glb", "tint": &"none"},
	&"frost_cairn": {"building": "ice_wall", "tint": &"b_cairn"},
	&"snow_globe": {}, &"ice_armor": {},
	# Dark Moon expansion
	&"spore_drifter": {"model": "forged/spore_drifter.glb", "tint": &"none"},
	&"grave_toad": {"model": "forged/grave_toad.glb", "tint": &"none"},
	&"moss_ape_matriarch": {"model": "forged/moss_ape_matriarch.glb", "tint": &"none"},
	&"mycel_gravekeeper": {"model": "forged/mycel_gravekeeper.glb", "tint": &"none"},
	&"mycelia_spore_weaver": {"model": "forged/mycelia_spore_weaver.glb", "tint": &"none"},
	&"ancient_hollowneck": {"model": "forged/ancient_hollowneck.glb", "tint": &"none"},
	&"ember_hornet": {"model": "forged/ember_hornet.glb", "tint": &"none"},
	&"flame_tiki": {"model": "forged/flame_tiki.glb", "tint": &"none"},
	&"ignis_ember_storm": {"model": "forged/ignis_ember_storm.glb", "tint": &"none"},
	&"cinder_fiend": {"model": "forged/cinder_fiend.glb", "tint": &"none"},
	&"magma_chieftain": {"model": "forged/magma_chieftain.glb", "tint": &"none"},
	&"molten_titan": {"model": "forged/molten_titan.glb", "tint": &"none"},
	&"sprinkle_sprite": {"model": "forged/sprinkle_sprite.glb", "tint": &"none"},
	&"gumdrop_baker": {"model": "forged/gumdrop_baker.glb", "tint": &"none"},
	&"bonbon_unicorn_queen": {"model": "forged/bonbon_unicorn_queen.glb", "tint": &"none"},
	&"twinstripe_peppermare": {"model": "forged/twinstripe_peppermare.glb", "tint": &"none"},
	&"taffy_wolf_matron": {"model": "forged/taffy_wolf_matron.glb", "tint": &"none"},
	&"cakequake_behemoth": {"model": "forged/cakequake_behemoth.glb", "tint": &"none"},
	&"snowdrift_sage": {"model": "forged/snowdrift_sage.glb", "tint": &"none"},
	&"glacier_shark": {"model": "forged/glacier_shark.glb", "tint": &"none"},
	&"aurora_skywhale": {"model": "forged/aurora_skywhale.glb", "tint": &"none"},
	&"glacial_archmage": {"model": "forged/glacial_archmage.glb", "tint": &"none"},
	&"tundra_stomper": {"model": "forged/tundra_stomper.glb", "tint": &"none"},
	&"rimeback_stegosaur": {"model": "forged/rimeback_stegosaur.glb", "tint": &"none"},
	&"sand_pickpocket": {"model": "forged/sand_pickpocket.glb", "tint": &"none"},
	&"dune_bandit": {"model": "forged/dune_bandit.glb", "tint": &"none"},
	&"alpaking_thief_king": {"model": "forged/alpaking_thief_king.glb", "tint": &"none"},
	&"sandglider_sphinx": {"model": "forged/sandglider_sphinx.glb", "tint": &"none"},
	&"caravan_master": {"model": "forged/caravan_master.glb", "tint": &"none"},
	&"dune_leviathan": {"model": "forged/dune_leviathan.glb", "tint": &"none"},
	&"gluttonous_dreamer": {"model": "forged/gluttonous_dreamer.glb", "tint": &"none"},
	&"shadow_peddler": {"model": "forged/shadow_peddler.glb", "tint": &"none"},
	&"shiba_shepherd": {"model": "forged/shiba_shepherd.glb", "tint": &"none"},
	&"sleeper_beneath": {"model": "forged/sleeper_beneath.glb", "tint": &"none"},
	&"herald_of_the_sleeper": {"model": "forged/herald_of_the_sleeper.glb", "tint": &"none"},
	&"moonlit_stalker": {"model": "forged/moonlit_stalker.glb", "tint": &"none"},
	&"dusk_wasp": {"model": "forged/dusk_wasp.glb", "tint": &"none"},
	&"moon_guppy": {"model": "forged/moon_guppy.glb", "tint": &"none"},
	&"dark_moon": {},
	&"moon_left": {},
	&"moon_right": {},
	&"fungal_feast": {},
	&"mycelium_call": {},
	&"rot_harvest": {},
	&"grave_bloom": {},
	&"necrospore": {},
	&"spore_burst": {},
	&"firestorm": {},
	&"cinder_barrage": {},
	&"overcharge": {},
	&"hex_of_cinders": {},
	&"smolder": {},
	&"lava_wave": {},
	&"kindle_pups": {},
	&"bakery_rush": {},
	&"cookie_jar": {},
	&"sweet_treat": {},
	&"cavity_hex": {},
	&"toothache": {},
	&"party_favors": {},
	&"gumdrop_parade": {},
	&"rime_dart": {},
	&"hoarfrost": {},
	&"blizzard_echo": {},
	&"permafrost": {},
	&"snow_call": {},
	&"swindle": {},
	&"lure_of_gold": {},
	&"hex_of_the_dunes": {},
	&"cursed_coin": {},
	&"grand_heist": {},
	&"mirage_army": {},
	&"night_market": {},
	&"bad_dream": {},
	&"nightmare": {},
	&"lullaby": {},
	&"shooting_stars": {},
	&"moon_elixir": {},
	&"moonwell": {},
	&"twin_guardians": {},
	# Legends & Grudges (2026-11-25)
	&"bog_biter": {"model": "forged/bog_biter.glb", "tint": &"none"},
	&"bloodbow_ranger": {"model": "forged/bloodbow_ranger.glb", "tint": &"none"},
	&"nocturna_velvet_queen": {"model": "forged/nocturna_velvet_queen.glb", "tint": &"none"},
	&"carrion_hound": {"model": "forged/carrion_hound.glb", "tint": &"none"},
	&"mawra_grave_glutton": {"model": "forged/mawra_grave_glutton.glb", "tint": &"none"},
	&"the_rot_king": {"model": "forged/the_rot_king.glb", "tint": &"none"},
	&"vexa_grudgekeeper": {"model": "forged/vexa_grudgekeeper.glb", "tint": &"none"},
	&"bastion_last_wall": {"model": "forged/bastion_last_wall.glb", "tint": &"none"},
	&"sugar_hoarder": {"model": "forged/sugar_hoarder.glb", "tint": &"none"},
	&"duchess_bonbonpaw": {"model": "forged/duchess_bonbonpaw.glb", "tint": &"none"},
	&"grand_fence": {"model": "forged/grand_fence.glb", "tint": &"none"},
	&"hailmother_ysra": {"model": "forged/hailmother_ysra.glb", "tint": &"none"},
	&"pyrrhos_spellstorm": {"model": "forged/pyrrhos_spellstorm.glb", "tint": &"none"},
	&"grudge_bolt": {}, &"last_stand": {}, &"shield_bash": {},
	&"snowball": {}, &"mourning_toll": {},
}


## Spell card pictures: a game-icons.net icon (CC BY 3.0) over a glow in its land's colour.
const SPELL_ICONS: Dictionary = {
	&"rain_of_spores": "res://assets/icons/pollen-dust.svg",
	&"regrowth": "res://assets/icons/sprout.svg",
	&"fireball": "res://assets/icons/fireball.svg",
	&"ember_rain": "res://assets/icons/burning-meteor.svg",
	&"sugar_rush": "res://assets/icons/wrapped-sweet.svg",
	&"swap_trick": "res://assets/icons/card-exchange.svg",
	&"cold_snap": "res://assets/icons/snowflake-2.svg",
	&"avalanche": "res://assets/icons/falling-rocks.svg",
	&"star_shard": "res://assets/icons/star-swirl.svg",
	&"volcano": "res://assets/icons/volcano.svg",
	&"snowstorm": "res://assets/icons/snowing.svg",
	&"spore_bloom": "res://assets/icons/mushrooms-cluster.svg",
	&"sugar_rain": "res://assets/icons/spiral-lollipop.svg",
	&"bark_shield": "res://assets/icons/round-shield.svg",
	&"candy_shell": "res://assets/icons/spiral-shell.svg",
	&"stoke": "res://assets/icons/flame-claws.svg",
	&"overheat": "res://assets/icons/heat-haze.svg",
	&"finish_off": "res://assets/icons/guillotine.svg",
	&"ember_pact": "res://assets/icons/burning-book.svg",
	&"deep_roots": "res://assets/icons/root-tip.svg",
	&"bark_coat": "res://assets/icons/leaf-swirl.svg",
	&"thorn_lash": "res://assets/icons/thorny-vine.svg",
	&"grove_roar": "res://assets/icons/wolf-howl.svg",
	&"taffy_pull": "res://assets/icons/back-forth.svg",
	&"sugar_shiv": "res://assets/icons/stiletto.svg",
	&"jawbreaker": "res://assets/icons/punch.svg",
	&"sugar_high": "res://assets/icons/lightning-frequency.svg",
	&"crack_the_ice": "res://assets/icons/shattered-glass.svg",
	&"whiteout": "res://assets/icons/frozen-orb.svg",
	&"icicle": "res://assets/icons/ice-bolt.svg",
	&"snowmanify": "res://assets/icons/snowman.svg",
	&"sun_shield": "res://assets/icons/shield-reflect.svg",
	&"sandstorm": "res://assets/icons/sandstorm.svg",
	&"mirage": "res://assets/icons/mirror-mirror.svg",
	&"heatwave": "res://assets/icons/sun-radiations.svg",
	&"seed_pod": "res://assets/icons/acorn.svg",
	&"spark_scroll": "res://assets/icons/scroll-unfurled.svg",
	&"kindle": "res://assets/icons/match-tip.svg",
	&"lucky_wrapper": "res://assets/icons/present.svg",
	&"snow_globe": "res://assets/icons/crystal-ball.svg",
	&"ice_armor": "res://assets/icons/ice-shield.svg",
	&"dark_moon": "res://assets/icons/evil-moon.svg",
	&"moon_left": "res://assets/icons/anticlockwise-rotation.svg",
	&"moon_right": "res://assets/icons/clockwise-rotation.svg",
	&"fungal_feast": "res://assets/icons/carnivorous-plant.svg",
	&"mycelium_call": "res://assets/icons/spotted-mushroom.svg",
	&"rot_harvest": "res://assets/icons/sickle.svg",
	&"grave_bloom": "res://assets/icons/grave-flowers.svg",
	&"necrospore": "res://assets/icons/death-zone.svg",
	&"spore_burst": "res://assets/icons/burst-blob.svg",
	&"firestorm": "res://assets/icons/flame-tunnel.svg",
	&"cinder_barrage": "res://assets/icons/flaming-arrow.svg",
	&"overcharge": "res://assets/icons/power-lightning.svg",
	&"hex_of_cinders": "res://assets/icons/ember-shot.svg",
	&"smolder": "res://assets/icons/burning-embers.svg",
	&"lava_wave": "res://assets/icons/lava.svg",
	&"kindle_pups": "res://assets/icons/dog-house.svg",
	&"bakery_rush": "res://assets/icons/cupcake.svg",
	&"cookie_jar": "res://assets/icons/cookie.svg",
	&"sweet_treat": "res://assets/icons/candy-canes.svg",
	&"cavity_hex": "res://assets/icons/tooth.svg",
	&"toothache": "res://assets/icons/toothbrush.svg",
	&"party_favors": "res://assets/icons/party-popper.svg",
	&"gumdrop_parade": "res://assets/icons/jelly-beans.svg",
	&"rime_dart": "res://assets/icons/ice-spear.svg",
	&"hoarfrost": "res://assets/icons/snowflake-1.svg",
	&"blizzard_echo": "res://assets/icons/ice-spell-cast.svg",
	&"permafrost": "res://assets/icons/frozen-block.svg",
	&"snow_call": "res://assets/icons/igloo.svg",
	&"swindle": "res://assets/icons/two-coins.svg",
	&"lure_of_gold": "res://assets/icons/crown-coin.svg",
	&"hex_of_the_dunes": "res://assets/icons/cursed-star.svg",
	&"cursed_coin": "res://assets/icons/coins.svg",
	&"grand_heist": "res://assets/icons/robber.svg",
	&"mirage_army": "res://assets/icons/desert-camp.svg",
	&"night_market": "res://assets/icons/shop.svg",
	&"bad_dream": "res://assets/icons/dream-catcher.svg",
	&"nightmare": "res://assets/icons/screaming.svg",
	&"lullaby": "res://assets/icons/musical-notes.svg",
	&"shooting_stars": "res://assets/icons/falling-star.svg",
	&"moon_elixir": "res://assets/icons/bubbling-flask.svg",
	&"moonwell": "res://assets/icons/well.svg",
	&"twin_guardians": "res://assets/icons/guards.svg",
	&"grudge_bolt": "res://assets/icons/screaming.svg",
	&"last_stand": "res://assets/icons/checked-shield.svg",
	&"shield_bash": "res://assets/icons/round-shield.svg",
	&"snowball": "res://assets/icons/frozen-orb.svg",
	&"mourning_toll": "res://assets/icons/grave-flowers.svg",
}
## Glow behind spell icons, by land.
const SPELL_GLOW: Array[Color] = [Color("#b6ff7a"), Color("#ffb03a"), Color("#ff9fe0"), Color("#bfe8ff"), Color("#ffe07a"), Color("#ffd27a")]
## Background sky behind card pictures, by land.
const ART_SKY: Array[Color] = [Color("#bfe9a8"), Color("#ffc59a"), Color("#ffd3ec"), Color("#d6efff"), Color("#fff1c2"), Color("#ffe2a8")]


## What a card's ability looks like when it fires (FxDirector.KINDS). Spells have their own.
const EFFECTS: Dictionary = {
	&"sporeling": &"heal", &"puffcap": &"heal", &"glimmer_morel": &"heal", &"rootstalker": &"heal", &"elder_shroomhulk": &"heal",
	&"ashmite": &"damage", &"magmaw": &"damage", &"blazehorn": &"damage", &"inferno_drake": &"damage",
	&"gumdrop": &"draw", &"jellywobble": &"draw", &"bonbon_behemoth": &"draw",
	&"taffy_snail": &"magic", &"lollibat": &"move", &"sugar_sprite": &"return_building",
	&"snowmite": &"freeze", &"frostfang": &"freeze", &"rimewing": &"freeze", &"blizzard_titan": &"freeze",
	&"smokestack": &"smoke_puff", &"spore_hut": &"spore_puff", &"candy_mill": &"gem_pop",
	&"rain_of_spores": &"rain_of_spores", &"regrowth": &"regrowth", &"fireball": &"fireball", &"ember_rain": &"ember_rain",
	&"sugar_rush": &"sugar_rush", &"swap_trick": &"swap_trick", &"cold_snap": &"cold_snap", &"avalanche": &"avalanche",
	&"star_shard": &"magic",
	&"bark_shield": &"armour", &"candy_shell": &"armour",
	&"volcano": &"field", &"snowstorm": &"field", &"spore_bloom": &"field", &"sugar_rain": &"field",
	&"pain_shroom": &"draw", &"cinder_wisp": &"damage", &"hot_head": &"damage", &"gummy_cub": &"draw",
	&"sugar_smuggler": &"draw", &"frostwisp": &"freeze", &"snow_pup": &"freeze",
	&"sporemoth": &"heal", &"mossback_colossus": &"armour", &"magma_wraith": &"damage", &"gummy_goliath": &"draw",
	&"candyfloss_bat": &"move", &"glacial_wisp": &"freeze", &"snowfang_alpha": &"freeze",
	&"bellows_forge": &"damage", &"frost_lookout": &"freeze",
	&"stoke": &"fireball", &"ember_pact": &"damage", &"deep_roots": &"magic", &"thorn_lash": &"damage",
	&"taffy_pull": &"regrowth", &"sugar_shiv": &"damage", &"jawbreaker": &"damage", &"whiteout": &"cold_snap",
	&"icicle": &"avalanche",
	&"meerkeep": &"armour", &"sun_scarab": &"armour", &"sandstone_watchtower": &"armour", &"oasis_alpaca": &"heal",
	&"sandstorm": &"damage", &"heatwave": &"field", &"kindle": &"fireball",
	&"dune_raptor": &"draw", &"lamp_djinn": &"draw", &"moss_oracle": &"draw", &"mirage": &"draw", &"seed_pod": &"draw",
	&"spark_scroll": &"draw", &"lucky_wrapper": &"draw", &"snow_globe": &"draw",
	&"spore_drifter": &"heal", &"grave_toad": &"damage", &"mycel_gravekeeper": &"heal", &"mycelia_spore_weaver": &"heal", &"ancient_hollowneck": &"heal", &"ember_hornet": &"damage", &"flame_tiki": &"damage", &"ignis_ember_storm": &"damage", &"cinder_fiend": &"magic", &"molten_titan": &"damage", &"sprinkle_sprite": &"draw", &"gumdrop_baker": &"draw", &"bonbon_unicorn_queen": &"draw", &"twinstripe_peppermare": &"magic", &"cakequake_behemoth": &"draw", &"snowdrift_sage": &"draw", &"glacier_shark": &"freeze", &"aurora_skywhale": &"freeze", &"glacial_archmage": &"magic", &"rimeback_stegosaur": &"freeze", &"sand_pickpocket": &"draw", &"dune_bandit": &"draw", &"alpaking_thief_king": &"draw", &"sandglider_sphinx": &"move", &"dune_leviathan": &"draw", &"gluttonous_dreamer": &"draw", &"shadow_peddler": &"draw", &"herald_of_the_sleeper": &"armour", &"moonlit_stalker": &"draw", &"dusk_wasp": &"damage", &"moon_guppy": &"magic", &"dark_moon": &"swap_trick", &"moon_left": &"swap_trick", &"moon_right": &"swap_trick", &"fungal_feast": &"draw", &"mycelium_call": &"regrowth", &"rot_harvest": &"damage", &"grave_bloom": &"regrowth", &"necrospore": &"damage", &"spore_burst": &"damage", &"firestorm": &"ember_rain", &"cinder_barrage": &"ember_rain", &"overcharge": &"magic", &"hex_of_cinders": &"fireball", &"smolder": &"damage", &"lava_wave": &"damage", &"kindle_pups": &"regrowth", &"bakery_rush": &"draw", &"cookie_jar": &"draw", &"sweet_treat": &"heal", &"cavity_hex": &"draw", &"toothache": &"damage", &"party_favors": &"draw", &"gumdrop_parade": &"regrowth", &"rime_dart": &"avalanche", &"hoarfrost": &"draw", &"blizzard_echo": &"cold_snap", &"permafrost": &"cold_snap", &"snow_call": &"regrowth", &"swindle": &"draw", &"lure_of_gold": &"move", &"hex_of_the_dunes": &"draw", &"cursed_coin": &"damage", &"grand_heist": &"draw", &"mirage_army": &"regrowth", &"night_market": &"draw", &"bad_dream": &"draw", &"nightmare": &"damage", &"lullaby": &"draw", &"shooting_stars": &"ember_rain", &"moon_elixir": &"magic", &"moonwell": &"magic", &"twin_guardians": &"regrowth",
	&"bog_biter": &"damage", &"bloodbow_ranger": &"damage", &"nocturna_velvet_queen": &"damage", &"carrion_hound": &"heal",
	&"mawra_grave_glutton": &"heal", &"the_rot_king": &"damage", &"vexa_grudgekeeper": &"damage", &"bastion_last_wall": &"armour",
	&"sugar_hoarder": &"draw", &"duchess_bonbonpaw": &"draw", &"grand_fence": &"draw", &"hailmother_ysra": &"freeze",
	&"pyrrhos_spellstorm": &"damage",
}


## Spell looks (look & feel spec 2): a SpellKit recipe per spell — kind (comet, beam, rain,
## vines, slash, spike, blizzard, circle, hero, swirl), colour, and for comets/rain a trail preset
## and size. Spells without an entry keep their FxDirector kind.
const SPELL_FX: Dictionary = {
	&"rain_of_spores": {"kind": &"circle", "color": Color("#8dff6a")},
	&"regrowth": {"kind": &"hero", "color": Color("#6adf5a")},
	&"bark_shield": {"kind": &"hero", "color": Color("#c89a5a")},
	&"bark_coat": {"kind": &"circle", "color": Color("#c89a5a")},
	&"deep_roots": {"kind": &"hero", "color": Color("#5ad16a")},
	&"grove_roar": {"kind": &"circle", "color": Color("#ffb03a")},
	&"thorn_lash": {"kind": &"vines", "color": Color("#4f9a3a")},
	&"stoke": {"kind": &"beam", "color": Color("#ff8a2a")},
	&"overheat": {"kind": &"circle", "color": Color("#ff4a2a")},
	&"ember_pact": {"kind": &"hero", "color": Color("#c8302a")},
	&"fireball": {"kind": &"comet", "color": Color("#ff7a1a"), "trail": &"embers", "size": 1.5, "sound": &"fire_whoosh"},
	&"finish_off": {"kind": &"slash", "color": Color("#ff5a3a")},
	&"ember_rain": {"kind": &"rain", "color": Color("#ff7a1a"), "trail": &"embers"},
	&"sugar_shiv": {"kind": &"slash", "color": Color("#ff8ad8")},
	&"sugar_high": {"kind": &"hero", "color": Color("#ff9fe0")},
	&"sugar_rush": {"kind": &"hero", "color": Color("#ffd84a")},
	&"jawbreaker": {"kind": &"comet", "color": Color("#ff5ab0"), "trail": &"sprinkles", "size": 1.2, "sound": &"candy_pop"},
	&"taffy_pull": {"kind": &"beam", "color": Color("#ff9fcf")},
	&"candy_shell": {"kind": &"hero", "color": Color("#ff9fe0")},
	&"cold_snap": {"kind": &"beam", "color": Color("#bfe8ff")},
	&"icicle": {"kind": &"spike", "color": Color("#bfe8ff")},
	&"crack_the_ice": {"kind": &"slash", "color": Color("#d6f2ff")},
	&"whiteout": {"kind": &"blizzard", "color": Color("#e8f6ff")},
	&"snowmanify": {"kind": &"swirl", "color": Color("#ffffff")},
	&"star_shard": {"kind": &"hero", "color": Color("#ffd84a")},
	&"sun_shield": {"kind": &"circle", "color": Color("#ffc94a")},
	&"sandstorm": {"kind": &"blizzard", "color": Color("#e8c27a")},
	&"mirage": {"kind": &"hero", "color": Color("#ffd27a")},
	&"seed_pod": {"kind": &"hero", "color": Color("#8dff6a")},
	&"spark_scroll": {"kind": &"hero", "color": Color("#ff8a2a")},
	&"kindle": {"kind": &"comet", "color": Color("#ff6a1a"), "trail": &"embers", "size": 1.0, "sound": &"fire_whoosh"},
	&"lucky_wrapper": {"kind": &"hero", "color": Color("#ff9fe0")},
	&"snow_globe": {"kind": &"hero", "color": Color("#bfe8ff")},
	&"ice_armor": {"kind": &"circle", "color": Color("#9fd8ff")},
	&"dark_moon": {"kind": &"swirl", "color": Color("#8a5aff")},
	&"fungal_feast": {"kind": &"vines", "color": Color("#5aa34a")},
	&"mycelium_call": {"kind": &"circle", "color": Color("#8dff6a")},
	&"rot_harvest": {"kind": &"blizzard", "color": Color("#7a8a4a")},
	&"grave_bloom": {"kind": &"hero", "color": Color("#b6ff7a")},
	&"necrospore": {"kind": &"blizzard", "color": Color("#9a6aff")},
	&"spore_burst": {"kind": &"circle", "color": Color("#b6ff7a")},
	&"firestorm": {"kind": &"rain", "color": Color("#ff6a1a")},
	&"cinder_barrage": {"kind": &"rain", "color": Color("#ff9a3a")},
	&"overcharge": {"kind": &"hero", "color": Color("#ffd84a")},
	&"hex_of_cinders": {"kind": &"beam", "color": Color("#c8302a")},
	&"smolder": {"kind": &"hero", "color": Color("#ff5a2a")},
	&"lava_wave": {"kind": &"blizzard", "color": Color("#ff5a1a")},
	&"kindle_pups": {"kind": &"circle", "color": Color("#ff8a2a")},
	&"bakery_rush": {"kind": &"hero", "color": Color("#ff9fe0")},
	&"cookie_jar": {"kind": &"hero", "color": Color("#ffd27a")},
	&"sweet_treat": {"kind": &"hero", "color": Color("#ffb0e0")},
	&"cavity_hex": {"kind": &"beam", "color": Color("#b06cff")},
	&"toothache": {"kind": &"hero", "color": Color("#b06cff")},
	&"party_favors": {"kind": &"hero", "color": Color("#ffd84a")},
	&"gumdrop_parade": {"kind": &"circle", "color": Color("#ff8ad8")},
	&"rime_dart": {"kind": &"spike", "color": Color("#bfe8ff")},
	&"hoarfrost": {"kind": &"hero", "color": Color("#d6f2ff")},
	&"blizzard_echo": {"kind": &"blizzard", "color": Color("#e8f6ff")},
	&"permafrost": {"kind": &"blizzard", "color": Color("#9fd8ff")},
	&"snow_call": {"kind": &"circle", "color": Color("#bfe8ff")},
	&"swindle": {"kind": &"hero", "color": Color("#ffc94a")},
	&"lure_of_gold": {"kind": &"beam", "color": Color("#ffc94a")},
	&"hex_of_the_dunes": {"kind": &"beam", "color": Color("#8a5aff")},
	&"cursed_coin": {"kind": &"hero", "color": Color("#8a5aff")},
	&"grand_heist": {"kind": &"hero", "color": Color("#ffc94a")},
	&"mirage_army": {"kind": &"circle", "color": Color("#e8c27a")},
	&"night_market": {"kind": &"hero", "color": Color("#8a5aff")},
	&"bad_dream": {"kind": &"beam", "color": Color("#6a4aaf")},
	&"nightmare": {"kind": &"hero", "color": Color("#6a4aaf")},
	&"lullaby": {"kind": &"swirl", "color": Color("#c8b0ff")},
	&"shooting_stars": {"kind": &"rain", "color": Color("#ffe07a")},
	&"moon_elixir": {"kind": &"swirl", "color": Color("#c8b0ff")},
	&"moonwell": {"kind": &"hero", "color": Color("#8ab0ff")},
	&"twin_guardians": {"kind": &"circle", "color": Color("#b6ff7a")},
	&"moon_left": {"kind": &"swirl", "color": Color("#8a5aff")},
	&"moon_right": {"kind": &"swirl", "color": Color("#8a5aff")},
	&"grudge_bolt": {"kind": &"comet", "color": Color("#ff3a4a"), "trail": &"embers", "size": 1.3, "sound": &"fire_whoosh"},
	&"last_stand": {"kind": &"hero", "color": Color("#ffd27a")},
	&"shield_bash": {"kind": &"slash", "color": Color("#ffc94a")},
	&"snowball": {"kind": &"comet", "color": Color("#e8f6ff"), "size": 1.4},
	&"mourning_toll": {"kind": &"rain", "color": Color("#9a7ad1")},
}


## Extra sound when a spell is cast (Audio.SETS names).
const SOUNDS: Dictionary = {
	&"fireball": &"fire_whoosh", &"ember_rain": &"fire_whoosh", &"rain_of_spores": &"heal", &"regrowth": &"card_draw",
	&"sugar_rush": &"candy_pop", &"swap_trick": &"candy_pop", &"cold_snap": &"freeze", &"avalanche": &"explosion",
	&"star_shard": &"candy_pop",
	&"bark_shield": &"building_rise", &"candy_shell": &"candy_pop",
	&"volcano": &"explosion", &"snowstorm": &"freeze", &"spore_bloom": &"heal", &"sugar_rain": &"candy_pop",
	&"stoke": &"fire_whoosh", &"overheat": &"fire_whoosh", &"finish_off": &"explosion", &"ember_pact": &"fire_whoosh",
	&"deep_roots": &"heal", &"bark_coat": &"building_rise", &"thorn_lash": &"explosion", &"grove_roar": &"heal",
	&"taffy_pull": &"candy_pop", &"sugar_shiv": &"candy_pop", &"jawbreaker": &"candy_pop", &"sugar_high": &"candy_pop",
	&"crack_the_ice": &"explosion", &"whiteout": &"freeze", &"icicle": &"freeze", &"snowmanify": &"freeze",
	&"sun_shield": &"building_rise", &"sandstorm": &"attack_whoosh", &"mirage": &"magic_gain", &"heatwave": &"fire_whoosh",
	&"seed_pod": &"heal", &"spark_scroll": &"magic_gain", &"kindle": &"fire_whoosh", &"lucky_wrapper": &"candy_pop",
	&"snow_globe": &"magic_gain", &"ice_armor": &"freeze",
	&"firestorm": &"fire_whoosh", &"cinder_barrage": &"fire_whoosh", &"hex_of_cinders": &"fire_whoosh", &"lava_wave": &"fire_whoosh", &"bakery_rush": &"candy_pop", &"cookie_jar": &"candy_pop", &"party_favors": &"candy_pop", &"gumdrop_parade": &"candy_pop", &"sweet_treat": &"candy_pop", &"rime_dart": &"freeze", &"blizzard_echo": &"freeze", &"permafrost": &"freeze", &"hoarfrost": &"freeze", &"snow_call": &"freeze", &"dark_moon": &"magic_gain", &"moonwell": &"magic_gain", &"overcharge": &"magic_gain", &"moon_elixir": &"magic_gain", &"shooting_stars": &"explosion", &"necrospore": &"explosion", &"rot_harvest": &"explosion", &"spore_burst": &"heal", &"grave_bloom": &"heal", &"mycelium_call": &"heal",
}


## Building badge icons on the board (game-icons.net, CC BY 3.0).
const BADGES: Dictionary = {
	&"spore_hut": "res://assets/icons/health-increase.svg",
	&"glowcap_lantern": "res://assets/icons/heart-plus.svg",
	&"kiln_tower": "res://assets/icons/crossed-swords.svg",
	&"smokestack": "res://assets/icons/chimney.svg",
	&"sugar_shack": "res://assets/icons/crossed-swords.svg",
	&"candy_mill": "res://assets/icons/cut-diamond.svg",
	&"ice_wall": "res://assets/icons/checked-shield.svg",
	&"frost_spire": "res://assets/icons/sword-break.svg",
	&"bellows_forge": "res://assets/icons/crossed-swords.svg",
	&"fairy_ring": "res://assets/icons/heart-plus.svg",
	&"gingerbread_gate": "res://assets/icons/checked-shield.svg",
	&"frost_lookout": "res://assets/icons/snowflake-2.svg",
	&"sun_obelisk": "res://assets/icons/sundial.svg",
	&"sandstone_watchtower": "res://assets/icons/stone-tower.svg",
	&"frost_cairn": "res://assets/icons/ice-cube.svg",
}


## One icon per keyword (Keywords.ORDER) plus Spell Power, for creature tags, card tooltips and badges.
const KEYWORD_ICONS: Dictionary = {
	&"guard": "res://assets/icons/checked-shield.svg",
	&"bubble": "res://assets/icons/bubbles.svg",
	&"dash": "res://assets/icons/sprint.svg",
	&"venom": "res://assets/icons/dripping-goo.svg",
	&"leech": "res://assets/icons/heart-drop.svg",
	&"flurry": "res://assets/icons/crossed-slashes.svg",
	&"hidden": "res://assets/icons/hood.svg",
	&"second_wind": "res://assets/icons/angel-wings.svg",
	&"sturdy": "res://assets/icons/stone-block.svg",
	&"bask": "res://assets/icons/sunbeams.svg",
	&"spell_power": "res://assets/icons/spark-spirit.svg",
	&"last_breath": "res://assets/icons/haunting.svg",
}
## Badge colour behind each keyword icon.
const KEYWORD_COLORS: Dictionary = {
	&"last_breath": Color("#7a8ab8"),
	&"guard": Color("#c9a24a"), &"bubble": Color("#4ab8e8"), &"dash": Color("#e8803a"), &"venom": Color("#5ab83a"),
	&"leech": Color("#c8304a"), &"flurry": Color("#8a6ae0"), &"hidden": Color("#5a5a7a"), &"second_wind": Color("#e8c84a"),
	&"sturdy": Color("#9a8a72"), &"bask": Color("#ffb03a"),
	&"spell_power": Color("#b04ae8"),
}
## Symbols drawn as icons (the web build has no font with ♥ / ⚔ / ✦).
const ICON_HEART := "res://assets/icons/heart.svg"
const ICON_SWORDS := "res://assets/icons/crossed-swords.svg"
const ICON_SPARKLE := "res://assets/icons/sparkle.svg"


static func keyword_icon(kw: StringName) -> Texture2D:
	var path: String = KEYWORD_ICONS.get(kw, "")
	return load(path) as Texture2D if path != "" else null


static func badge_icon(id: StringName) -> String:
	return BADGES.get(id, "")


static func sound(id: StringName) -> StringName:
	return SOUNDS.get(id, &"")


static func effect(id: StringName) -> StringName:
	return EFFECTS.get(id, &"none")


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in ENTRIES:
		out.append(k)
	return out


static func model_path(id: StringName) -> String:
	var e: Dictionary = ENTRIES.get(id, {})
	if e.has("merge"):
		return model_path(e["merge"][0])
	if e.has("model"):
		var m: String = e["model"]
		return "res://assets/monsters/%s" % (m if m.get_extension() != "" else m + ".gltf")
	if e.has("building"):
		return "res://assets/buildings/%s.gltf" % e["building"]
	if e.has("tint"):
		return "res://assets/buildings/%s.gltf" % id
	return ""


## A merged form's [big partner, rider partner] ids, or [] for other cards.
static func merge_pair(id: StringName) -> Array:
	return ENTRIES.get(id, {}).get("merge", [])


## Degrees to turn a creature's model so it faces forward like the others (models from other packs).
static func turn(id: StringName) -> float:
	return float(ENTRIES.get(id, {}).get("turn", 0.0))


static func tint(id: StringName) -> Color:
	var e: Dictionary = ENTRIES.get(id, {})
	if e.has("merge"):
		return tint(e["merge"][0])
	return TINTS.get(e.get("tint", &"none"), TINTS[&"none"])


static func art_path(id: StringName) -> String:
	return "res://assets/card_art/%s.png" % id
