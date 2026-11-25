extends TestCase
## Every card's rules text fits inside its paper box (Dark Moon spec 1).


func test_every_card_text_fits() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var ws: Array[CardWidget] = []
	for c: CardData in CardDB.all_cards():
		if CardText.render(c) == "":
			continue
		var w := CardWidget.new()
		w.setup(c, 0)
		tree.root.add_child(w)
		ws.append(w)
	await tree.process_frame
	await tree.process_frame
	var bad: Array[String] = []
	for w: CardWidget in ws:
		var t: RichTextLabel = w.text_label()
		if t.get_content_height() > t.size.y + 0.5:
			bad.append("%s (%d > %d)" % [w.card.id, t.get_content_height(), int(t.size.y)])
		w.free()
	assert_eq(bad, [] as Array[String], "cards whose text overflows")
	return true


func test_dark_gift_copies_still_fit() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var ws: Array[CardWidget] = []
	for c: CardData in CardDB.dream_up_pool(CardData.Kind.CREATURE, -1):
		var w := CardWidget.new()
		w.setup(CardDB.variant(c, Gifts.delta(&"haunt")), 0)
		tree.root.add_child(w)
		ws.append(w)
	await tree.process_frame
	await tree.process_frame
	var bad: Array[String] = []
	for w: CardWidget in ws:
		var t: RichTextLabel = w.text_label()
		if t.get_content_height() > t.size.y + 0.5:
			bad.append(String(w.card.id))
		w.free()
	assert_eq(bad, [] as Array[String], "Dark Gift (Last Breath) copies whose text overflows")
	return true


func test_every_card_name_fits_its_ribbon() -> bool:
	var bad: Array[String] = []
	for c: CardData in CardDB.all_cards():
		var w := CardWidget.new()
		w.setup(c, 0)
		var l: Label = w.name_label()
		var need: float = l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
		if need > CardWidget.NAME_WIDTH or l.size.x > CardWidget.SIZE.x - 8.0 + 0.5:
			bad.append("%s (%d > %d, label %d)" % [c.id, int(need), int(CardWidget.NAME_WIDTH), int(l.size.x)])
		w.free()
	assert_eq(bad, [] as Array[String], "names wider than the ribbon")
	return true
