extends TestCase
## Drawn cards fly from the deck pile into their place in the hand (user request, Dark Moon batch).


func test_drawn_card_flies_from_the_deck() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var h := Hand.new()
	h.size = Vector2(1280, 720)
	tree.root.add_child(h)
	var cards: Array[CardData] = [CardDB.card(&"gumdrop"), CardDB.card(&"fireball")]
	h.show_hand(cards, [true, true])
	var settled: Vector2 = h.card_widget(1).position
	var deck := Vector2(1100, 560)
	h.expect_draw(deck)
	var more: Array[CardData] = cards.duplicate()
	more.append(CardDB.card(&"iceling"))
	h.show_hand(more, [true, true, true])
	var w: CardWidget = h.card_widget(2)
	assert_true(w.position.distance_to(deck - h.global_position - CardWidget.SIZE / 2.0) < 80.0, "the new card starts at the deck")
	assert_true(w.scale.x < Hand.REST_SCALE, "small while it flies")
	assert_true(h.card_widget(1).position.distance_to(settled) < 1.0, "the others start where they were")
	await tree.create_timer(Hand.DRAW_TIME + 0.2).timeout
	assert_true(w.position.distance_to(h.rest_position(2)) < 2.0, "and lands in its slot")
	h.free()
	return true
