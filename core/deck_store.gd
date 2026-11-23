class_name DeckStore
extends RefCounted
## The player's own decks (deck builder), saved as JSON in user://. Any cards may be mixed:
## lanes start bare, so the only limits are 30 cards, at most 2 of each, and no Star Shard (the
## player going second always gets one).

const DECK_SIZE := 30
const MAX_COPIES := 2
const ID_PREFIX := "custom_"

## Where the decks are saved (tests point it elsewhere).
static var path: String = "user://decks.json"
static var _decks: Array[DeckData] = []
static var _loaded_from: String = ""


## Why these cards aren't a legal deck, or "" when they are.
static func validate(cards: Array[CardData]) -> String:
	if cards.size() != DECK_SIZE:
		return "A deck needs %d cards (%d now)" % [DECK_SIZE, cards.size()]
	var counts: Dictionary = {}
	for c: CardData in cards:
		if c.land == CardData.Land.NEUTRAL or not c.collectible:
			return "%s can't go in a deck" % c.display_name
		counts[c.id] = int(counts.get(c.id, 0)) + 1
		if counts[c.id] > MAX_COPIES:
			return "At most %d of %s" % [MAX_COPIES, c.display_name]
	return ""


static func can_add(cards: Array[CardData], c: CardData) -> bool:
	if c.land == CardData.Land.NEUTRAL or not c.collectible or cards.size() >= DECK_SIZE:
		return false
	return cards.count(c) < MAX_COPIES


static func is_custom(id: StringName) -> bool:
	return String(id).begins_with(ID_PREFIX)


## A DeckData for these cards; its lands (shown in menus) are the two lands with most cards.
static func make(id: StringName, display_name: String, cards: Array[CardData]) -> DeckData:
	var d := DeckData.new()
	d.id = id
	d.display_name = display_name
	d.cards = cards.duplicate()
	var counts: Array[int] = [0, 0, 0, 0, 0, 0]
	for c: CardData in cards:
		if c.land != CardData.Land.NEUTRAL:
			counts[c.land] += 1
	var order: Array[int] = CardData.REAL_LANDS.duplicate()
	order.sort_custom(func(a: int, b: int) -> bool: return counts[a] > counts[b] if counts[a] != counts[b] else a < b)
	var main: int = order[0]
	var second: int = order[1] if counts[order[1]] > 0 else main
	d.lands = [main, main, second, main]
	return d


static func all() -> Array[DeckData]:
	_ensure_loaded()
	return _decks.duplicate()


static func find(id: StringName) -> DeckData:
	_ensure_loaded()
	for d: DeckData in _decks:
		if d.id == id:
			return d
	return null


## Adds or replaces a deck (by id) and saves.
static func put(d: DeckData) -> void:
	_ensure_loaded()
	for i: int in _decks.size():
		if _decks[i].id == d.id:
			_decks[i] = d
			save()
			return
	_decks.append(d)
	save()


static func remove(id: StringName) -> void:
	_ensure_loaded()
	_decks = _decks.filter(func(d: DeckData) -> bool: return d.id != id)
	save()


static func new_id() -> StringName:
	_ensure_loaded()
	var n: int = _decks.size() + 1
	while find(StringName("%s%d" % [ID_PREFIX, n])) != null:
		n += 1
	return StringName("%s%d" % [ID_PREFIX, n])


static func save() -> void:
	var out: Array = []
	for d: DeckData in _decks:
		var ids: Array[String] = []
		for c: CardData in d.cards:
			ids.append(String(c.id))
		out.append({"id": String(d.id), "name": d.display_name, "cards": ids})
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("DeckStore: can't write %s" % path)
		return
	f.store_string(JSON.stringify(out, "\t"))


## Reads the decks again (tests, or after `path` changes).
static func refresh() -> void:
	_loaded_from = ""
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _loaded_from == path:
		return
	_loaded_from = path
	_decks.clear()
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Array:
		push_warning("DeckStore: %s is not a deck list" % path)
		return
	for entry: Variant in data:
		if not entry is Dictionary:
			continue
		var cards: Array[CardData] = []
		for cid: Variant in (entry as Dictionary).get("cards", []):
			if CardDB.has_card(StringName(str(cid))):
				cards.append(CardDB.card(StringName(str(cid))))
		var id := StringName(str((entry as Dictionary).get("id", "")))
		if not is_custom(id):
			continue
		_decks.append(make(id, str((entry as Dictionary).get("name", "My deck")), cards))
