extends TestCase
## Headless layout check: HUD and hand fit on screen and don't overlap the END TURN button.


func _check(size: Vector2) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var holder := Control.new()
	holder.size = size
	tree.root.add_child(holder)
	var hud := Hud.new()
	holder.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hand := Hand.new()
	holder.add_child(hand)
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s: GameState = Fx.blank()
	for id: StringName in [&"mossback", &"fireball", &"kiln_tower", &"inferno_drake", &"gumdrop", &"swap_trick", &"iceling"]:
		Fx.give(s, 0, id)
	hud.refresh(s, 0)
	var playable: Array[bool] = []
	playable.resize(7)
	playable.fill(true)
	hand.show_hand(s.players[0].hand, playable)
	await tree.process_frame
	await tree.process_frame
	var screen := Rect2(Vector2.ZERO, size)
	for panel: Control in hud.panels():
		assert_true(screen.encloses(panel.get_global_rect()), "%s inside %s (%s)" % [panel.name, size, panel.get_global_rect()])
	var cards: Rect2 = hand.cards_rect()
	assert_true(cards.size.x > 0, "hand has cards")
	assert_true(not hud.end_turn_button.get_global_rect().intersects(cards), "END TURN clear of hand at %s" % size)
	assert_true(cards.position.x >= 0 and cards.end.x <= size.x, "hand fits horizontally at %s" % size)
	holder.queue_free()
	await tree.process_frame


func test_hud_fits() -> bool:
	await _check(Vector2(1280, 720))
	await _check(Vector2(1920, 1080))
	return true
