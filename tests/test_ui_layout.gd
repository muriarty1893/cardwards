extends TestCase
## Headless layout check: HUD and hand fit on screen and don't overlap the END TURN button; the
## board stays clear of the HUD and the resting hand.


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
	var names: Array[String] = []
	for panel: Control in hud.panels():
		names.append(String(panel.name))
	assert_true("YouBar" in names and "RivalBar" in names, "hero bars are HUD panels")
	var you_bar: Control = hud.find_child("YouBar", true, false)
	var rival_bar: Control = hud.find_child("RivalBar", true, false)
	if you_bar and rival_bar:
		assert_true(not you_bar.get_global_rect().intersects(rival_bar.get_global_rect()), "hero bars apart at %s" % size)
	var cards: Rect2 = hand.cards_rect()
	assert_true(cards.size.x > 0, "hand has cards")
	assert_true(not hud.end_turn_button.get_global_rect().intersects(cards), "END TURN clear of hand at %s" % size)
	assert_true(cards.position.x >= 0 and cards.end.x <= size.x, "hand fits horizontally at %s" % size)
	for i: int in [0, 6]:
		hand.hover(i)
		await tree.process_frame
		var hr: Rect2 = hand.hovered_rect()
		assert_true(screen.encloses(hr), "hovered card %d on screen at %s (%s)" % [i, size, hr])
		assert_true(not hud.end_turn_button.get_global_rect().intersects(hr), "hovered card %d clear of BATTLE! at %s" % [i, size])
	holder.queue_free()
	await tree.process_frame


func test_hud_fits() -> bool:
	await _check(Vector2(1280, 720))
	await _check(Vector2(1366, 768))
	await _check(Vector2(1920, 1080))
	return true


func test_card_faces() -> bool:
	for c: CardData in CardDB.all_cards():
		var w := CardWidget.new()
		w.setup(c, 0)
		assert_true(w.art_texture() != null, "art for %s" % c.id)
		if CardText.render(c) != "":
			assert_eq(w.text_label().text, CardText.render(c), "rules text on %s" % c.id)
		w.free()
	return true


func test_settings_panel_writes_settings() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var settings: GameSettings = tree.root.get_node("Settings")
	var old_path: String = settings.path
	var old: float = settings.music_volume
	settings.path = "user://t_settings_panel.cfg"
	var p: SettingsPanel = SettingsPanel.make()
	tree.root.add_child(p)
	# Godot 4.7.2 no longer emits value_changed for values set from code; a drag does both.
	p.music_slider.value = 0.25
	p.music_slider.value_changed.emit(0.25)
	assert_eq(settings.music_volume, 0.25, "slider wrote music volume")
	p.quality_option.select(1)
	p.quality_option.item_selected.emit(1)
	assert_eq(settings.quality, GameSettings.Quality.LOW, "option wrote quality")
	settings.set_value(&"music_volume", old)
	settings.path = old_path
	settings.load_settings()
	p.queue_free()
	await tree.process_frame
	return true


func test_main_menu_loads() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var menu: Node = (load("res://menus/main_menu.tscn") as PackedScene).instantiate()
	tree.root.add_child(menu)
	await tree.process_frame
	var decks: Array[Node] = menu.find_children("Deck_*", "Button", true, false)
	assert_eq(decks.size(), 4, "four deck buttons")
	for b: Node in decks:
		assert_true((b as Button).icon != null, "%s shows champion art" % b.name)
	menu.queue_free()
	await tree.process_frame
	return true


func test_panels_have_thick_ink_border() -> bool:
	var sb: StyleBoxFlat = UiStyle.panel()
	assert_eq(sb.border_width_left, 5, "5 px ink border")
	return true


func test_bold_font_is_shared() -> bool:
	var a: Label = UiStyle.bold(UiStyle.label("a"))
	var b: Label = UiStyle.bold(UiStyle.label("b"))
	assert_true(a.get_theme_font("font") == b.get_theme_font("font"), "one shared font, not one per label")
	a.free()
	b.free()
	return true


func test_hand_reuses_cards_when_unchanged() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var hand := Hand.new()
	tree.root.add_child(hand)
	hand.size = Vector2(1280, 720)
	var cards: Array[CardData] = [CardDB.card(&"mossback"), CardDB.card(&"fireball")]
	var playable: Array[bool] = [true, true]
	hand.show_hand(cards, playable)
	var before: Array[Node] = hand.get_children()
	hand.show_hand(cards.duplicate(), [true, false] as Array[bool])
	var after: Array[Node] = hand.get_children()
	assert_eq(after.size(), before.size(), "same number of cards")
	assert_true(after[0] == before[0] and after[1] == before[1], "same card widgets reused")
	assert_true((after[1] as CardWidget).modulate != Color.WHITE, "playable change applied in place")
	var more: Array[CardData] = [CardDB.card(&"mossback"), CardDB.card(&"fireball"), CardDB.card(&"gumdrop")]
	hand.show_hand(more, [true, true, true] as Array[bool])
	await tree.process_frame
	assert_eq(hand.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).size(), 3, "rebuilt when the cards change")
	hand.queue_free()
	await tree.process_frame
	return true


func test_eight_cards_fit() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var hand := Hand.new()
	tree.root.add_child(hand)
	var cards: Array[CardData] = []
	var playable: Array[bool] = []
	for id: StringName in [&"mossback", &"fireball", &"gumdrop", &"iceling", &"magmaw", &"sugar_rush", &"cold_snap", &"star_shard"]:
		cards.append(CardDB.card(id))
		playable.append(true)
	for sz: Vector2 in [Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080)]:
		hand.size = sz
		hand.show_hand(cards, playable)
		hand.show_hand(cards.duplicate(), playable)
		var ws: Array = hand.get_children().filter(func(n: Node) -> bool: return n is CardWidget and not n.is_queued_for_deletion())
		assert_eq(ws.size(), 8, "8 cards at %s" % sz)
		for i: int in ws.size():
			var r: Rect2 = hand.card_rect(i)
			assert_true(r.position.x >= Hand.REGION_LEFT - 1 and r.end.x <= sz.x - Hand.REGION_RIGHT + 1, "card %d inside the hand region at %s" % [i, sz])
			# Slim hand: only the top of each card peeks into the strip along the bottom edge.
			assert_true(r.position.y >= sz.y - Hud.HAND_STRIP_H and r.position.y <= sz.y - 60.0, "card %d peeks into the hand strip at %s (%s)" % [i, sz, r])
			if i > 0:
				assert_true(r.position.x - hand.card_rect(i - 1).position.x >= 60.0, "cards %d/%d far enough apart at %s" % [i - 1, i, sz])
	hand.queue_free()
	return true


func test_magic_gems() -> bool:
	var g := MagicGems.new()
	g.set_magic(3, 5)
	assert_eq(g.gem_states(), [2, 2, 2, 1, 1, 0, 0, 0] as Array[int], "3 filled, 2 empty, 3 hidden")
	assert_eq(g.extra(), 0, "no overflow")
	g.set_magic(9, 8)
	assert_eq(g.gem_states(), [2, 2, 2, 2, 2, 2, 2, 2] as Array[int], "all filled")
	assert_eq(g.extra(), 1, "+1 beyond the cap")
	g.free()
	return true


func test_end_turn_label_and_pulse() -> bool:
	var m: MatchController = await Fx.load_match()
	var s: GameState = m.state
	assert_eq(m.hud.end_turn_button.text, "END TURN", "label")
	s.players[0].hand.clear()
	for l: int in 4:
		s.players[0].lanes[l].creature = null
	m.sync_all()
	m.refresh_ui()
	assert_true(m.hud.end_turn_pulsing, "nothing left to do: pulse")
	s.players[0].hand.append(CardDB.card(&"star_shard"))
	m.refresh_ui()
	assert_true(not m.hud.end_turn_pulsing, "a card to play: no pulse")
	m.queue_free()
	return true


## Every board tile corner is above the hand strip and outside the HUD panels (the old purple
## tray covered the near row).
func test_board_clear_of_hud() -> bool:
	var m: MatchController = await Fx.load_match()
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var rects: Array[Rect2] = []
	for p: Control in m.hud.panels():
		rects.append(p.get_global_rect())
	var hand: Rect2 = m.hand.cards_rect()
	for p: int in 2:
		for l: int in 4:
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					var c := Vector3(m.board.lane_x(l) + sx * Island.WIDTH / 2.0, Island.TOP_Y, Board.STRIP_Z[p] + sz * Island.LENGTH / 2.0)
					var s: Vector2 = m.rig.camera.unproject_position(c)
					assert_true(s.y < vp.y - Hud.HAND_STRIP_H, "tile p%d l%d corner above the hand strip (%s)" % [p, l, s])
					assert_true(not hand.has_point(s), "tile p%d l%d corner clear of the hand (%s)" % [p, l, s])
					for r: Rect2 in rects:
						assert_true(not r.has_point(s), "tile p%d l%d corner clear of HUD panel %s (%s)" % [p, l, r, s])
	m.queue_free()
	return true
