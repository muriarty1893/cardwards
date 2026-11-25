extends TestCase
## Decks sent over the network (DeckCodec).


func test_dunes_deck_is_valid_online() -> bool:
	var d: DeckData = CardDB.deck(&"sun_fortress")
	var enc: Dictionary = DeckCodec.encode(d)
	enc["lands"] = [CardData.Land.DUNES, CardData.Land.DUNES, CardData.Land.FROST, CardData.Land.DUNES]
	assert_eq(DeckCodec.check(enc), "", "a Sunny Dunes deck can be played online")
	enc["lands"] = [6, 0, 0, 0]
	assert_true(DeckCodec.check(enc) != "", "no land 6")
	return true
