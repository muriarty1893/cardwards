extends TestCase
## Your own decks: the rules (30 cards, 2 of each, no Star Shard), saving and loading, playing a
## match with one, and the deck builder screen opened from the main menu.

const TEST_PATH := "user://t_decks.json"


func _use_test_store() -> String:
	var old: String = DeckStore.path
	DeckStore.path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	DeckStore.refresh()
	return old


func _restore(old: String) -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	DeckStore.path = old
	DeckStore.refresh()


func _thirty() -> Array[CardData]:
	var out: Array[CardData] = []
	for c: CardData in CardDB.all_cards():
		if c.land == CardData.Land.NEUTRAL or c.legendary or not c.collectible or not c.deck_legal or c.curse:
			continue
		for i: int in 2:
			if out.size() < 30:
				out.append(c)
	return out


func test_rules() -> bool:
	var cards: Array[CardData] = _thirty()
	assert_eq(DeckStore.validate(cards), "", "30 cards, 2 of each: legal")
	var short: Array[CardData] = cards.slice(0, 29)
	assert_true(DeckStore.validate(short).contains("30"), "29 cards: needs 30")
	var three: Array[CardData] = cards.slice(0, 29)
	three.append(cards[0])
	assert_true(DeckStore.validate(three).contains("At most"), "3 copies rejected")
	var star: Array[CardData] = cards.slice(0, 29)
	star.append(CardDB.card(&"star_shard"))
	assert_true(DeckStore.validate(star) != "", "no Star Shard")
	assert_true(not DeckStore.can_add(cards, CardDB.card(&"fireball")), "full deck: can't add")
	return true


func test_save_load_and_play() -> bool:
	var old: String = _use_test_store()
	var id: StringName = DeckStore.new_id()
	assert_true(DeckStore.is_custom(id), "custom id")
	DeckStore.put(DeckStore.make(id, "Test deck", _thirty()))
	DeckStore.refresh()
	var d: DeckData = DeckStore.find(id)
	assert_true(d != null and d.cards.size() == 30 and d.display_name == "Test deck", "saved and read back")
	assert_eq(CardDB.deck(id), d, "CardDB finds it")
	var s: GameState = Rules.setup(d, CardDB.deck(&"blaze_rush"), 3)
	assert_eq(s.players[0].deck.size() + s.players[0].hand.size(), 30 + (1 if s.first_player == 1 else 0), "a match deals from it")
	DeckStore.remove(id)
	assert_true(DeckStore.find(id) == null, "deleted")
	_restore(old)
	return true


func test_builder_edits_and_saves() -> bool:
	var old: String = _use_test_store()
	var b := DeckBuilder.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(not b.editable, "opens on a starter deck, view only")
	assert_eq(b.cards.size(), 30, "starter deck shown")
	assert_true(not b.add_card(&"fireball"), "can't change a starter deck")
	b.copy_deck()
	assert_true(b.editable and b.cards.size() == 30, "copied into your own deck")
	var id: StringName = b.deck_id
	assert_true(b.remove_card(b.cards[0].id), "took one out")
	assert_eq(DeckStore.find(id).cards.size(), 29, "saved on change")
	b.new_deck()
	assert_eq(b.cards.size(), 0, "new deck is empty")
	assert_true(b.add_card(&"fireball") and b.add_card(&"fireball"), "two fireballs")
	assert_true(not b.add_card(&"fireball"), "not a third")
	assert_true(not b.add_card(&"star_shard"), "no star shard")
	b.set_filter(2)
	assert_true(b.visible_cards() > 0 and b.visible_cards() < 46, "land filter narrows the collection")
	b.set_filter(DeckBuilder.FILTERS.find("NEUTRAL"))
	assert_eq(b.visible_cards(), CardDB.collectible_cards().filter(func(c: CardData) -> bool:
		return c.land == CardData.Land.NEUTRAL and c.deck_legal).size(), "NEUTRAL shows the neutral cards (no Star Shard)")
	assert_true(b.add_card(&"dark_moon"), "a legendary")
	assert_true(not b.add_card(&"dark_moon"), "only one")
	assert_true(b.add_card(&"shiba_shepherd"), "neutral cards can go in")
	b.open_deck(id)
	assert_eq(b.cards.size(), 29, "reopening your deck shows its saved cards")
	b.close()
	_restore(old)
	return true


func test_menu_has_decks_button() -> bool:
	var old: String = _use_test_store()
	var tree := Engine.get_main_loop() as SceneTree
	var cards: Array[CardData] = _thirty()
	DeckStore.put(DeckStore.make(DeckStore.new_id(), "Mine", cards))
	var menu: Node = (load("res://menus/main_menu.tscn") as PackedScene).instantiate()
	tree.root.add_child(menu)
	await tree.process_frame
	assert_true(menu.find_child("DecksButton", true, false) != null, "DECKS button")
	var row: Node = menu.find_child("CustomDecks", true, false)
	assert_true(row != null and row.find_child("Deck_custom_1", true, false) != null, "your legal deck is offered")
	var builder: DeckBuilder = menu.call(&"open_deck_builder")
	await tree.process_frame
	assert_true(is_instance_valid(builder), "builder opens")
	builder.open_deck(&"custom_1")
	builder.deck_chosen.emit(&"custom_1")
	assert_eq(Session.player_deck, &"custom_1", "choosing it selects it for the match")
	builder.close()
	menu.queue_free()
	Session.player_deck = &"grove_guard"
	await tree.process_frame
	_restore(old)
	return true


func test_hover_preview_is_big() -> bool:
	var old: String = _use_test_store()
	var b := DeckBuilder.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	await (Engine.get_main_loop() as SceneTree).process_frame
	b._show_preview(CardDB.card(&"dark_moon"))
	var p: CardWidget = b.preview()
	assert_true(p.visible, "shown")
	assert_true(p.scale.x >= 2.0, "at least twice the card size (was 1.2)")
	var r := Rect2(p.global_position, CardWidget.SIZE * p.scale)
	var vp: Vector2 = b.get_viewport_rect().size
	assert_true(Rect2(Vector2.ZERO, vp).encloses(r), "fully on screen")
	b.close()
	_restore(old)
	return true
