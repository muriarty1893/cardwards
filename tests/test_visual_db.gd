extends TestCase
## Every card has a visual entry, and every model file it names exists.


func test_entries_cover_all_cards() -> bool:
	assert_eq(VisualDB.ids().size(), 41, "41 entries")
	for c: CardData in CardDB.all_cards():
		assert_true(VisualDB.ENTRIES.has(c.id), "entry for %s" % c.id)
		if c.kind != CardData.Kind.SPELL:
			assert_true(ResourceLoader.exists(VisualDB.model_path(c.id)), "model exists for %s" % c.id)
		assert_true(VisualDB.TINTS.has(VisualDB.ENTRIES[c.id].get("tint", &"none")), "tint name ok for %s" % c.id)
	return true


func test_buildings_have_badge_icons() -> bool:
	for c: CardData in CardDB.all_cards():
		if c.kind == CardData.Kind.BUILDING:
			assert_true(ResourceLoader.exists(VisualDB.badge_icon(c.id)), "badge icon for %s" % c.id)
	return true
