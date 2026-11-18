class_name CardDB
extends RefCounted
## Loads and caches every card and deck from res://data.

const CARD_DIR := "res://data/cards"
const DECK_DIR := "res://data/decks"
const DECK_ORDER: Array[StringName] = [&"grove_guard", &"blaze_rush", &"sugar_storm", &"deep_freeze"]

static var _cards: Dictionary[StringName, CardData] = {}
static var _card_list: Array[CardData] = []
static var _decks: Dictionary[StringName, DeckData] = {}


static func has_card(id: StringName) -> bool:
	_ensure_loaded()
	return _cards.has(id)


static func card(id: StringName) -> CardData:
	_ensure_loaded()
	if not _cards.has(id):
		push_error("CardDB: unknown card id '%s'" % id)
		return null
	return _cards[id]


static func all_cards() -> Array[CardData]:
	_ensure_loaded()
	return _card_list.duplicate()


## Cards that can go in decks (not merged forms or tokens).
static func collectible_cards() -> Array[CardData]:
	var out: Array[CardData] = []
	for c: CardData in all_cards():
		if c.collectible:
			out.append(c)
	return out


## Every card that merges into `into` (its two partners), in display order.
static func merge_partners(into: StringName) -> Array[CardData]:
	var out: Array[CardData] = []
	for c: CardData in all_cards():
		if c.merges_into == into:
			out.append(c)
	return out


## Tests: adds a card to the database until remove_test_card.
static func add_test_card(c: CardData) -> void:
	_ensure_loaded()
	_cards[c.id] = c
	if not c in _card_list:
		_card_list.append(c)


static func remove_test_card(id: StringName) -> void:
	if _cards.has(id):
		_card_list.erase(_cards[id])
		_cards.erase(id)


## Cards Dream Up may offer: never neutral ones or non-collectible ones. -1 means any kind / any land.
static func dream_up_pool(filter_kind: int, filter_land: int) -> Array[CardData]:
	var out: Array[CardData] = []
	for c: CardData in collectible_cards():
		if c.land == CardData.Land.NEUTRAL:
			continue
		if (filter_kind < 0 or c.kind == filter_kind) and (filter_land < 0 or c.land == filter_land):
			out.append(c)
	return out


static func deck(id: StringName) -> DeckData:
	_ensure_loaded()
	if DeckStore.is_custom(id):
		var custom: DeckData = DeckStore.find(id)
		if custom and DeckStore.validate(custom.cards) == "":
			return custom
		push_warning("CardDB: custom deck '%s' missing or not legal; using %s" % [id, DECK_ORDER[0]])
		return _decks[DECK_ORDER[0]]
	if not _decks.has(id):
		push_error("CardDB: unknown deck id '%s'" % id)
		return null
	return _decks[id]


static func all_decks() -> Array[DeckData]:
	_ensure_loaded()
	var out: Array[DeckData] = []
	for id: StringName in DECK_ORDER:
		if _decks.has(id):
			out.append(_decks[id])
	return out


static func _ensure_loaded() -> void:
	if not _card_list.is_empty():
		return
	var files: PackedStringArray = ResourceLoader.list_directory(CARD_DIR)
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var c := load(CARD_DIR.path_join(file)) as CardData
		if c == null:
			push_error("CardDB: %s is not a CardData resource" % file)
			continue
		_cards[c.id] = c
		_card_list.append(c)
	_card_list.sort_custom(func(a: CardData, b: CardData) -> bool:
		return a.land < b.land if a.land != b.land else _ORDER.find(a.id) < _ORDER.find(b.id))
	for file: String in ResourceLoader.list_directory(DECK_DIR):
		if not file.ends_with(".tres"):
			continue
		var d := load(DECK_DIR.path_join(file)) as DeckData
		if d == null:
			push_error("CardDB: %s is not a DeckData resource" % file)
			continue
		_decks[d.id] = d


## Display order inside each land (matches the spec tables).
const _ORDER: Array[StringName] = [
	&"sporeling", &"mossback", &"puffcap", &"glimmer_morel", &"rootstalker", &"elder_shroomhulk", &"spore_hut", &"glowcap_lantern", &"rain_of_spores", &"regrowth", &"bark_shield", &"spore_bloom",
	&"cinderpup", &"ashmite", &"flarebeak", &"magmaw", &"blazehorn", &"inferno_drake", &"kiln_tower", &"smokestack", &"fireball", &"ember_rain", &"volcano",
	&"gumdrop", &"taffy_snail", &"lollibat", &"sugar_sprite", &"jellywobble", &"bonbon_behemoth", &"sugar_shack", &"candy_mill", &"sugar_rush", &"swap_trick", &"candy_shell", &"sugar_rain",
	&"snowmite", &"iceling", &"frostfang", &"glacier_tortoise", &"rimewing", &"blizzard_titan", &"ice_wall", &"frost_spire", &"cold_snap", &"avalanche", &"snowstorm",
	&"star_shard",
]
