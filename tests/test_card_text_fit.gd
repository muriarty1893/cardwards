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
