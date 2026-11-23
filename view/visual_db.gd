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
}

## Creatures: "model" is relative to res://assets/monsters (Quaternius "Ultimate Monsters", CC0).
## Merged forms: "merge" = [big partner, rider partner] (CreatureView builds the pair; the model path is the big one's).
## Buildings use res://assets/buildings/<id>.gltf, or <"building">.gltf when set. Spells have no model.
const ENTRIES: Dictionary = {
	# Mushroom Forest
	&"sporeling": {"model": "blob/Mushnub", "tint": &"none"},
	&"mossback": {"model": "blob/GreenSpikyBlob", "tint": &"moss"},
	&"puffcap": {"model": "blob/Cactoro", "tint": &"cream"},
	&"glimmer_morel": {"model": "blob/Mushnub_Evolved", "tint": &"none"},
	&"rootstalker": {"model": "big/Cactoro", "tint": &"bark"},
	&"elder_shroomhulk": {"model": "big/MushroomKing", "tint": &"none"},
	&"spore_hut": {"tint": &"b_forest"},
	&"glowcap_lantern": {"tint": &"b_forest"},
	&"rain_of_spores": {},
	&"regrowth": {},
	# Ember Flats
	&"cinderpup": {"model": "blob/Dog", "tint": &"ember"},
	&"ashmite": {"model": "flying/Armabee", "tint": &"ash"},
	&"flarebeak": {"model": "blob/Chicken", "tint": &"ember"},
	&"magmaw": {"model": "big/Demon", "tint": &"none"},
	&"blazehorn": {"model": "big/Dino", "tint": &"ember"},
	&"inferno_drake": {"model": "flying/Dragon_Evolved", "tint": &"ember"},
	&"kiln_tower": {"tint": &"b_ember"},
	&"smokestack": {"tint": &"b_ember"},
	&"fireball": {},
	&"ember_rain": {},
	# Candy Hills
	&"gumdrop": {"model": "blob/PinkBlob", "tint": &"none"},
	&"taffy_snail": {"model": "blob/GreenBlob", "tint": &"taffy"},
	&"lollibat": {"model": "cute/Bat.fbx", "tint": &"candy_purple"},
	&"sugar_sprite": {"model": "flying/Ghost", "tint": &"candy_cyan"},
	&"jellywobble": {"model": "flying/Glub", "tint": &"candy_blue"},
	&"bonbon_behemoth": {"model": "big/Bunny", "tint": &"candy_pink"},
	&"sugar_shack": {"tint": &"b_candy"},
	&"candy_mill": {"tint": &"b_candy"},
	&"sugar_rush": {},
	&"swap_trick": {},
	# Frostpeak
	&"snowmite": {"model": "blob/Yeti", "tint": &"none"},
	&"iceling": {"model": "flying/Hywirl", "tint": &"icy"},
	&"frostfang": {"model": "blob/Cat", "tint": &"icy"},
	&"glacier_tortoise": {"model": "flying/Goleling_Evolved", "tint": &"icy"},
	&"rimewing": {"model": "flying/Pigeon", "tint": &"icy"},
	&"blizzard_titan": {"model": "big/Yeti", "tint": &"none"},
	&"ice_wall": {"tint": &"b_frost"},
	&"frost_spire": {"tint": &"b_frost"},
	&"cold_snap": {},
	&"avalanche": {},
	# Card expansion 2: free models of their own (Ultimate Monsters glTF; "cute/*.fbx" = Cute Animated Monsters)
	&"glowmoth": {"model": "flying/Alpaking", "tint": &"none"},
	&"barkbeetle": {"model": "cute/Tree.fbx", "tint": &"none"},
	&"pain_shroom": {"model": "cute/Mushroom.fbx", "tint": &"none"},
	&"emberkit": {"model": "cute/Demon.fbx", "tint": &"none"},
	&"cinder_wisp": {"model": "cute/Skull.fbx", "tint": &"none"},
	&"hot_head": {"model": "cute/YellowDragon.fbx", "tint": &"none"},
	&"gummy_cub": {"model": "cute/Panda.fbx", "tint": &"gummy_red"},
	&"cotton_puff": {"model": "flying/Squidle", "tint": &"none"},
	&"sugar_smuggler": {"model": "cute/Alien.fbx", "tint": &"none"},
	&"frostwisp": {"model": "cute/Alien_Tall.fbx", "tint": &"none"},
	&"snow_pup": {"model": "cute/Yeti.fbx", "tint": &"none"},
	&"ice_sage": {"model": "blob/Wizard", "tint": &"icy"},
	&"snowman": {"model": "cute/Ghost.fbx", "tint": &"none"},
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
	&"spell_power": "res://assets/icons/spark-spirit.svg",
}
## Badge colour behind each keyword icon.
const KEYWORD_COLORS: Dictionary = {
	&"guard": Color("#c9a24a"), &"bubble": Color("#4ab8e8"), &"dash": Color("#e8803a"), &"venom": Color("#5ab83a"),
	&"leech": Color("#c8304a"), &"flurry": Color("#8a6ae0"), &"hidden": Color("#5a5a7a"), &"second_wind": Color("#e8c84a"),
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


static func tint(id: StringName) -> Color:
	var e: Dictionary = ENTRIES.get(id, {})
	if e.has("merge"):
		return tint(e["merge"][0])
	return TINTS.get(e.get("tint", &"none"), TINTS[&"none"])


static func art_path(id: StringName) -> String:
	return "res://assets/card_art/%s.png" % id
