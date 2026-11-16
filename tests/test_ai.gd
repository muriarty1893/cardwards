extends TestCase


func test_ai_takes_lethal() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].hero_hp = 2
	Fx.put_creature(s, 0, 1, &"cinderpup")
	Fx.put_creature(s, 0, 2, &"mossback")  # two attackers: lethal even through glancing hits
	Fx.give(s, 0, &"mossback")
	Fx.fill_deck(s, 1, &"mossback", 3)
	var me := AIPlayer.new(0, AIPlayer.Difficulty.EASY, 1)
	var foe := AIPlayer.new(1, AIPlayer.Difficulty.EASY, 2)
	var ev: Array[GameEvent] = []
	AIRunner.play_turn(s, me, foe, ev)
	assert_eq(s.phase, GameState.Phase.OVER, "game over this turn")
	assert_eq(s.winner, 0, "AI wins")
	return true


func test_ai_prefers_kill() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 2
	Fx.put_creature(s, 1, 2, &"flarebeak")
	Fx.give(s, 0, &"sugar_rush")
	Fx.give(s, 0, &"fireball")
	Fx.fill_deck(s, 0, &"mossback", 5)
	var me := AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1)
	var a: Action = me.choose_action(s)
	assert_eq(a.type, Action.Type.PLAY_CARD, "plays a card")
	assert_eq(s.players[0].hand[a.hand_index].id, &"fireball", "picks fireball")
	assert_eq(a.targets, [{"player": 1, "lane": 2}] as Array[Dictionary], "targets the flarebeak")
	return true


func test_hit_rates() -> bool:
	var me := AIPlayer.new(0, AIPlayer.Difficulty.HARD, 5)
	var crits: int = 0
	var blocks: int = 0
	for i: int in 10000:
		if me.roll_hit() == Action.Hit.CRIT:
			crits += 1
		if me.roll_block():
			blocks += 1
	assert_true(crits >= 4700 and crits <= 5300, "hard crit share ~50%% (%d)" % crits)
	assert_true(blocks >= 4700 and blocks <= 5300, "hard block share ~50%% (%d)" % blocks)
	return true


func test_ai_vs_ai_100() -> bool:
	var decks: Array[DeckData] = CardDB.all_decks()
	var wins: Dictionary = {}
	var games: Dictionary = {}
	for d: DeckData in decks:
		wins[d.id] = 0
		games[d.id] = 0
	var total_turns: int = 0
	for seed: int in range(1, 101):
		var a: int = seed % 4
		var b: int = (a + 1 + (seed / 4) % 3) % 4
		var s: GameState = Rules.setup(decks[a], decks[b], seed)
		var diff: int = seed % 3
		var ais: Array[AIPlayer] = [AIPlayer.new(0, diff, seed * 2), AIPlayer.new(1, diff, seed * 2 + 1)]
		var w: int = AIRunner.play_match(s, ais)
		assert_true(w == 0 or w == 1, "seed %d finished (winner %d, turn %d)" % [seed, w, s.turn])
		total_turns += s.turn
		games[decks[a].id] += 1
		games[decks[b].id] += 1
		if w == 0:
			wins[decks[a].id] += 1
		elif w == 1:
			wins[decks[b].id] += 1
	print("AI-vs-AI deck results (wins/games): ", wins, " / ", games, "  avg turns: ", total_turns / 100.0)
	return true


func test_ai_resolves_dream_up() -> bool:
	var s: GameState = Fx.blank([0, 1, 2, 3], [2, 2, 2, 3])
	s.active = 1
	s.players[1].magic = 9
	Fx.give(s, 1, &"bonbon_behemoth")
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	var me := AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, 3)
	var foe := AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 4)
	var ev: Array[GameEvent] = []
	AIRunner.play_turn(s, me, foe, ev)
	assert_true(&"dream_up_chosen" in Fx.types(ev), "picked a Dream Up card")
	assert_eq(s.active, 0, "turn passed")
	return true
