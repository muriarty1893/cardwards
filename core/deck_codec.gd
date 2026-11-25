class_name DeckCodec
extends RefCounted
## A deck as plain data for the network: {"name", "lands", "cards"} with card ids as strings.

const NAME_MAX := 24


static func encode(d: DeckData) -> Dictionary:
	var ids: Array = []
	for c: CardData in d.cards:
		ids.append(String(c.id))
	return {"name": d.display_name.left(NAME_MAX), "lands": d.lands.duplicate(), "cards": ids}


## Why this isn't a deck that can be played online, or "" when it is.
static func check(d: Variant) -> String:
	if not d is Dictionary:
		return "Not a deck"
	var dict: Dictionary = d
	if not dict.get("name") is String or not dict.get("lands") is Array or not dict.get("cards") is Array:
		return "Not a deck"
	var lands: Array = dict["lands"]
	if lands.size() != 4:
		return "Not a deck"
	for l: Variant in lands:
		if not (l is int or l is float) or int(l) != l or int(l) < 0 or int(l) > CardData.Land.DUNES:
			return "Not a deck"
	var cards: Array[CardData] = []
	for id: Variant in dict["cards"]:
		if not id is String or not CardDB.has_card(StringName(id)):
			return "Unknown card %s" % str(id)
		cards.append(CardDB.card(StringName(id)))
	return DeckStore.validate(cards)


## Only for data that passed check().
static func decode(d: Dictionary, id: StringName) -> DeckData:
	var deck := DeckData.new()
	deck.id = id
	deck.display_name = String(d["name"]).left(NAME_MAX)
	var lands: Array[int] = []
	for l: Variant in d["lands"]:
		lands.append(int(l))
	deck.lands = lands
	for cid: Variant in d["cards"]:
		deck.cards.append(CardDB.card(StringName(cid)))
	return deck
