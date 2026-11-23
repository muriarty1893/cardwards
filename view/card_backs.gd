class_name CardBacks
extends RefCounted
## Card backs per deck (board look 2, spec 3.1): a deck shows its main land's back. Art: the user's own designs
## (~/Desktop/artcard/backs_v4: 01 Ember Reign, 03 Frostbound, 04 Verdant Bloom, 14 Candy Realm), resized; Sunny Dunes'
## back is generated (tools/make_dunes_back.gd). Indexed by CardData.Land (NEUTRAL's slot unused).

const PATHS: Array[String] = [
	"res://assets/card_backs/mushroom.png",
	"res://assets/card_backs/ember.png",
	"res://assets/card_backs/candy.png",
	"res://assets/card_backs/frost.png",
	"res://assets/card_backs/frost.png",
	"res://assets/card_backs/dunes.png",
]


## The land with the most cards in the deck; ties (and decks of only neutral cards) go to its first lane's land.
static func main_land(deck: DeckData) -> int:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0]
	for c: CardData in deck.cards:
		if c and c.land != CardData.Land.NEUTRAL:
			counts[c.land] += 1
	var best: int = counts.max()
	var first: int = deck.lands[0] if deck.lands.size() > 0 else 0
	if first in CardData.REAL_LANDS and counts[first] == best:
		return first
	return counts.find(best)


static func texture_for(deck: DeckData) -> Texture2D:
	return texture_for_land(main_land(deck))


static func texture_for_land(land: int) -> Texture2D:
	if not land in CardData.REAL_LANDS:
		land = 0
	return load(PATHS[land]) as Texture2D
