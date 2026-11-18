extends TestCase
## Board look 2, spec 3.3: a Hearthstone-style log — one small card tile per action, details on hover.


func _log() -> ActionLog:
	var l := ActionLog.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(l)
	return l


func test_one_tile_per_action() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 2, &"gumdrop", 1)   # 4 HP, 1 damage: Fireball (3) kills it
	var i: int = Fx.give(s, 0, &"fireball")
	s.players[0].magic = 5
	var events: Array[GameEvent] = Rules.apply(s, Action.play(0, i, -1, [{"player": 1, "lane": 2}]))
	var log: ActionLog = _log()
	log.add_action(events, s)
	var entries: Array[Dictionary] = log.entries()
	assert_eq(entries.size(), 1, "one tile for the whole spell")
	var e: Dictionary = entries[0]
	assert_eq(e["card"], &"fireball", "the tile shows the spell")
	assert_eq(e["side"], 0, "your tile")
	assert_eq(e["badge"], &"destroyed", "its main result was a kill")
	var text: String = "\n".join(e["lines"])
	assert_true(text.contains("You cast Fireball"), "first line says what happened (%s)" % text)
	assert_true(text.contains("Gumdrop") and text.contains("3 damage") and text.contains("destroyed"), "a target line with the result (%s)" % text)
	log.free()
	return true


func test_badges() -> bool:
	var s: GameState = Fx.blank()
	var log: ActionLog = _log()
	var i: int = Fx.give(s, 0, &"mossback")
	s.players[0].magic = 9
	log.add_action(Rules.apply(s, Action.play(0, i, 0, [])), s)
	assert_eq(log.entries()[0]["badge"], &"play", "creature played")
	i = Fx.give(s, 0, &"kiln_tower")
	log.add_action(Rules.apply(s, Action.play(0, i, 1, [])), s)
	assert_eq(log.entries()[0]["badge"], &"built", "building (newest first)")
	assert_eq(log.entries()[1]["badge"], &"play", "older tile below")
	log.free()
	return true


func test_no_tile_without_an_actor() -> bool:
	var s: GameState = Fx.blank()
	var log: ActionLog = _log()
	var events: Array[GameEvent] = [GameEvent.make(&"turn_started", {"player": 0, "turn": 2}), GameEvent.make(&"card_drawn", {"player": 0, "card": &"fireball"})]
	log.add_action(events, s)
	assert_eq(log.entries().size(), 0, "turn start and draws make no tile")
	log.free()
	return true


func test_max_eight_tiles() -> bool:
	var s: GameState = Fx.blank()
	var log: ActionLog = _log()
	for n: int in 11:
		log.add_action([GameEvent.make(&"spell_cast", {"player": n % 2, "card": &"sugar_rush"})], s)
	assert_eq(log.entries().size(), ActionLog.MAX_TILES, "at most %d tiles" % ActionLog.MAX_TILES)
	assert_eq(log.entries()[0]["side"], 0, "newest on top (the 11th, yours)")
	log.free()
	return true


func test_compact_and_hover_detail() -> bool:
	var s: GameState = Fx.blank()
	var log: ActionLog = _log()
	log.add_action([GameEvent.make(&"spell_cast", {"player": 1, "card": &"fireball"})], s)
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(log.size.x <= ActionLog.TILE + 8.0, "the column is one slim tile wide (%.0f)" % log.size.x)
	assert_true(not log.detail_visible(), "no detail until hovered")
	log.hover_tile(0)
	assert_true(log.detail_visible(), "hovering a tile shows the full card and lines")
	log.hover_tile(-1)
	assert_true(not log.detail_visible(), "leaving hides it")
	log.free()
	return true
