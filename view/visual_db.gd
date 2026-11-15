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
}

## Creatures: "model" is relative to res://assets/monsters (Quaternius "Ultimate Monsters", CC0).
## Buildings use res://assets/buildings/<id>.gltf. Spells have no model.
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
	&"lollibat": {"model": "flying/Demon", "tint": &"candy_purple"},
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
}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in ENTRIES:
		out.append(k)
	return out


static func model_path(id: StringName) -> String:
	var e: Dictionary = ENTRIES.get(id, {})
	if e.has("model"):
		return "res://assets/monsters/%s.gltf" % e["model"]
	if e.has("tint"):
		return "res://assets/buildings/%s.gltf" % id
	return ""


static func tint(id: StringName) -> Color:
	var e: Dictionary = ENTRIES.get(id, {})
	return TINTS.get(e.get("tint", &"none"), TINTS[&"none"])


static func art_path(id: StringName) -> String:
	return "res://assets/card_art/%s.png" % id
