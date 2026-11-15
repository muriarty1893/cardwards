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
		if c.text != "":
			assert_eq(w.text_label().text, c.text, "rules text on %s" % c.id)
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
	p.music_slider.value = 0.25
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
