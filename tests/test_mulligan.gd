extends TestCase
## Mulligan (user request): at the start of their first turn each player may redraw any of their
## starting cards once. CHOOSE carries a bitmask of hand indices (bit i = redraw card i).


func _game() -> GameState:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 11, 0, true)
	Rules.start_turn(s)
	return s


func test_first_turn_starts_with_a_mulligan() -> bool:
	var s: GameState = _game()
	assert_eq(s.phase, GameState.Phase.CHOOSING, "a choice first")
	assert_eq(s.pending_kind, &"mulligan", "the mulligan")
	assert_eq(s.pending_player, 0, "for the first player")
	assert_eq(s.players[0].magic, 0, "the turn hasn't started yet")
	return true


func test_redraw_replaces_marked_cards() -> bool:
	var s: GameState = _game()
	var ps: GameState.PlayerState = s.players[0]
	var before: Array[CardData] = ps.hand.duplicate()
	var deck: int = ps.deck.size()
	var top: CardData = ps.deck.back()
	Rules.apply(s, Action.choose(0, 0b101))
	assert_eq(ps.hand.size(), before.size(), "same hand size (the first player has no draw on turn 1)")
	assert_eq(ps.hand[1], before[1], "unmarked cards stay")
	assert_eq(ps.hand[0], top, "a marked card is replaced from the top of the deck")
	assert_eq(s.phase, GameState.Phase.MAIN, "then the turn starts")
	assert_true(ps.magic >= 1, "with its magic")
	return true


func test_deck_count_after_mulligan() -> bool:
	var s: GameState = _game()
	var ps: GameState.PlayerState = s.players[0]
	var deck: int = ps.deck.size()
	Rules.apply(s, Action.choose(0, 0b11))
	assert_eq(ps.deck.size(), deck, "two out, two back (the first player doesn't draw on turn 1)")
	return true


func test_keep_all() -> bool:
	var s: GameState = _game()
	var before: Array[CardData] = s.players[0].hand.duplicate()
	Rules.apply(s, Action.choose(0, 0))
	assert_eq(s.players[0].hand, before, "keep everything")
	return true


func test_second_player_mulligans_on_their_first_turn() -> bool:
	var s: GameState = _game()
	Rules.apply(s, Action.choose(0, 0))
	Rules.apply(s, Action.end_turn(0))
	assert_eq(s.phase, GameState.Phase.CHOOSING, "player 2's turn opens with their mulligan")
	assert_eq(s.pending_player, 1, "theirs")
	var hand: int = s.players[1].hand.size()
	Rules.apply(s, Action.choose(1, 1))
	assert_eq(s.players[1].hand.size(), hand + 1, "then their turn's draw")
	Rules.apply(s, Action.end_turn(1))
	assert_eq(s.phase, GameState.Phase.MAIN, "only once each")
	return true


func test_star_shard_cannot_be_redrawn_and_masks_are_checked() -> bool:
	var s: GameState = _game()
	Rules.apply(s, Action.choose(0, 0))
	Rules.apply(s, Action.end_turn(0))
	var shard: int = s.players[1].hand.find(CardDB.card(&"star_shard"))
	assert_true(shard >= 0, "player 2 holds the Star Shard")
	assert_true(Rules.validate(s, Action.choose(1, 1 << shard)) != "", "no redrawing the Star Shard")
	assert_true(Rules.validate(s, Action.choose(1, 1 << 10)) != "", "no cards past the hand")
	return true


func test_off_by_default_and_ai_mulligans() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 11, 0)
	Rules.start_turn(s)
	assert_eq(s.phase, GameState.Phase.MAIN, "no mulligan unless asked for")
	var t: GameState = _game()
	t.players[0].hand[0] = CardDB.card(&"elder_shroomhulk")
	var ai := AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1)
	var a: Action = ai.choose_action(t)
	assert_eq(a.type, Action.Type.CHOOSE, "the AI answers the mulligan")
	assert_true(a.choice & 1, "and throws back the 7-cost card")
	return true


func test_panel_marks_and_returns_a_mask() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var p := MulliganPanel.new()
	tree.root.add_child(p)
	await tree.process_frame
	var cards: Array[CardData] = [CardDB.card(&"gumdrop"), CardDB.card(&"star_shard"), CardDB.card(&"fireball")]
	var result: Array[int] = [-1]
	var run := func() -> void:
		result[0] = await p.open(cards)
	run.call()
	assert_true(p.is_open(), "open")
	p.toggle(0)
	p.toggle(1)
	p.toggle(2)
	p.toggle(2)
	assert_eq(p.marked(), 0b001, "toggling marks; the Star Shard can't be marked")
	p.confirm()
	await tree.process_frame
	assert_eq(result[0], 0b001, "returns the mask")
	assert_true(not p.is_open(), "closed")
	p.free()
	return true
