extends TestCase
## The main menu's PLAY ONLINE panel and the "Rejoin your match?" banner.

const TEST_DECKS := "user://t_online_decks.json"
const TEST_REJOIN := "user://t_online_rejoin.json"


class DeadLink:
	extends RefCounted
	signal opened
	signal received(msg: Dictionary)
	signal closed(code: int, reason: String)
	func send(_m: Dictionary) -> void:
		pass
	func close() -> void:
		pass
	func is_open() -> bool:
		return false
	func was_open() -> bool:
		return false
	func poll() -> void:
		pass


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _online() -> Node:
	return _tree().root.get_node("Online")


## Points Online at test files and the given link factory; returns what to restore.
func _setup(factory: Callable) -> Dictionary:
	var o: Node = _online()
	var saved: Dictionary = {"factory": o.get("link_factory"), "rejoin": o.get("rejoin_path"), "deck": Session.player_deck, "decks": DeckStore.path}
	o.set("link_factory", factory)
	o.set("rejoin_path", TEST_REJOIN)
	DeckStore.path = TEST_DECKS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DECKS))
	DeckStore.refresh()
	return saved


func _restore(saved: Dictionary) -> void:
	var o: Node = _online()
	o.call("cancel")
	o.set("link_factory", saved["factory"])
	o.set("rejoin_path", saved["rejoin"])
	Session.player_deck = saved["deck"]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DECKS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_REJOIN))
	DeckStore.path = saved["decks"]
	DeckStore.refresh()


func _menu() -> Node:
	var menu: Node = (load("res://menus/main_menu.tscn") as PackedScene).instantiate()
	_tree().root.add_child(menu)
	await _tree().process_frame
	return menu


func test_menu_has_both_play_buttons() -> bool:
	var saved: Dictionary = _setup(func(_p: String) -> Object: return DeadLink.new())
	Session.player_deck = &"grove_guard"
	var menu: Node = await _menu()
	var ai: Button = menu.find_child("PlayAI", true, false)
	var online: Button = menu.find_child("PlayOnline", true, false)
	assert_true(ai != null and ai.text == "PLAY vs AI", "PLAY vs AI")
	assert_true(online != null and online.text == "PLAY ONLINE", "PLAY ONLINE")
	var panel: OnlinePanel = menu.call("open_online")
	assert_true(is_instance_valid(panel), "panel opens")
	assert_eq(panel.deck_text(), "Deck: Grove Guard", "shows the selected deck")
	menu.queue_free()
	_restore(saved)
	return true


func test_illegal_custom_deck_blocked() -> bool:
	var made: Array = []
	var saved: Dictionary = _setup(func(_p: String) -> Object:
		made.append(1)
		return DeadLink.new())
	var cards: Array[CardData] = []
	for c: CardData in CardDB.collectible_cards():
		for i: int in 2:
			if cards.size() < 29:
				cards.append(c)
	var id: StringName = DeckStore.new_id()
	DeckStore.put(DeckStore.make(id, "Short", cards))
	Session.player_deck = id
	var menu: Node = await _menu()
	Session.player_deck = id
	var panel: OnlinePanel = menu.call("open_online")
	for press: Callable in [panel.press_quick, panel.press_host, func() -> void: panel.press_join("FROG-42")]:
		press.call()
		assert_eq(panel.message_text(), "That deck can't be used online: A deck needs 30 cards (29 now)", "refused before connecting")
		assert_eq(_online().get("state"), &"idle", "no request made")
	assert_eq(made.size(), 0, "no connection attempt")
	menu.queue_free()
	_restore(saved)
	return true


func test_join_with_bad_code_shows_message() -> bool:
	var made: Array = []
	var saved: Dictionary = _setup(func(_p: String) -> Object:
		made.append(1)
		return DeadLink.new())
	var menu: Node = await _menu()
	var panel: OnlinePanel = menu.call("open_online")
	panel.press_join("xyz")
	assert_eq(panel.message_text(), "That isn't a room code", "says so")
	assert_eq(made.size(), 0, "no connection attempt")
	menu.queue_free()
	_restore(saved)
	return true


func test_hosting_shows_code() -> bool:
	var relay := FakeRelay.new(3)
	var saved: Dictionary = _setup(func(p: String) -> Object: return relay.transport(&"host" if p == "/host" else &"join"))
	var menu: Node = await _menu()
	var panel: OnlinePanel = menu.call("open_online")
	panel.set_player_name("  Ann  ")
	panel.press_host()
	relay.pump()
	assert_eq(panel.code_text(), "FAKE-01", "the code is shown")
	assert_true(panel.copy_visible(), "COPY offered")
	assert_eq(Settings.player_name, "Ann", "the name is saved")
	assert_eq(String(relay.seats[0]["name"]), "Ann", "and sent")
	menu.queue_free()
	_restore(saved)
	return true


func test_unreachable_server_shows_retry() -> bool:
	var made: Array = []
	var saved: Dictionary = _setup(func(_p: String) -> Object:
		var l := DeadLink.new()
		made.append(l)
		return l)
	var menu: Node = await _menu()
	var panel: OnlinePanel = menu.call("open_online")
	panel.press_host()
	(made[0] as DeadLink).closed.emit(1006, "")
	assert_eq(panel.message_text(), "Can't reach the Dream Isles server", "says so")
	assert_true(panel.retry_visible(), "RETRY offered")
	panel.press_retry()
	assert_eq(made.size(), 2, "RETRY tries again")
	menu.queue_free()
	_restore(saved)
	return true


func test_rejoin_banner_when_file_exists() -> bool:
	var saved: Dictionary = _setup(func(_p: String) -> Object: return DeadLink.new())
	var f := FileAccess.open(TEST_REJOIN, FileAccess.WRITE)
	f.store_string(JSON.stringify({"code": "FROG-42", "token": "t", "version": NetVersion.current()}))
	f.close()
	var menu: Node = await _menu()
	var banner: Control = menu.find_child("RejoinBanner", true, false)
	assert_true(banner != null and banner.visible, "banner shown")
	var forget: Button = banner.find_child("Forget", true, false)
	forget.pressed.emit()
	assert_true(not banner.visible, "FORGET hides it")
	assert_true(not FileAccess.file_exists(TEST_REJOIN), "and forgets the match")
	menu.queue_free()
	_restore(saved)
	return true
