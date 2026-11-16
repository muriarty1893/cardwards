extends TestCase


const CR := CardData.Kind.CREATURE


func _mk(atk: int, hp: int, kws: Array[StringName] = []) -> CardData:
	return Fx.card(&"ai%d_%d" % [atk, hp], CR, 1, atk, hp, kws)


func test_ai_takes_lethal() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].hero_hp = 3
	Fx.put(s, 0, 0, _mk(3, 1))
	Fx.put(s, 1, 2, _mk(5, 5))
	Fx.give(s, 0, &"mossback")
	var a: Action = AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1).choose_action(s)
	assert_eq([a.type, a.lane, a.target_lane], [Action.Type.ATTACK, 0, -1], "goes for the hero first")
	return true


func test_ai_respects_guard() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(3, 9))
	Fx.put(s, 1, 1, _mk(1, 5, [&"guard"]))
	Fx.put(s, 1, 3, _mk(2, 2))
	var a: Action = AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1).choose_action(s)
	assert_eq([a.type, a.target_lane], [Action.Type.ATTACK, 1], "attacks the guard")
	return true


func test_ai_pops_bubble_with_small_creature() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(1, 1))
	Fx.put(s, 0, 1, _mk(5, 5))
	Fx.put(s, 1, 0, _mk(6, 6, [&"guard", &"bubble"]))
	var a: Action = AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1).choose_action(s)
	assert_eq([a.type, a.lane, a.target_lane], [Action.Type.ATTACK, 0, 0], "the 1/1 pops the bubble")
	return true


func test_ai_trades_venom_into_big() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(1, 1, [&"venom"]))
	Fx.put(s, 1, 2, _mk(8, 8))
	var a: Action = AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1).choose_action(s)
	assert_eq([a.type, a.lane, a.target_lane], [Action.Type.ATTACK, 0, 2], "venom into the 8/8")
	return true


func test_ai_picks_best_dream_up() -> bool:
	var s: GameState = Fx.blank()
	s.phase = GameState.Phase.CHOOSING
	s.pending_player = 0
	s.pending_choice = [CardDB.card(&"cinderpup"), CardDB.card(&"blizzard_titan"), CardDB.card(&"gumdrop")]
	var a: Action = AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1).choose_action(s)
	assert_eq([a.type, a.choice], [Action.Type.CHOOSE, 1], "the titan")
	return true


func test_ai_values_keywords() -> bool:
	var s: GameState = Fx.blank()
	var me := AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1)
	var plain: float = me.evaluate(s)
	Fx.put(s, 0, 0, _mk(2, 2))
	var vanilla: float = me.evaluate(s) - plain
	s.players[0].lanes[0].creature = null
	Fx.put(s, 0, 0, _mk(2, 2, [&"venom", &"guard"]))
	assert_true(me.evaluate(s) - plain > vanilla + 1.5, "venom + guard worth more than a vanilla 2/2")
	return true


func test_ai_fears_enemy_lethal() -> bool:
	var s: GameState = Fx.blank()
	var me := AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1)
	s.players[0].hero_hp = 5
	Fx.put(s, 1, 0, _mk(3, 9))
	var safe: float = me.evaluate(s)
	Fx.put(s, 1, 1, _mk(3, 9))
	var after: float = me.evaluate(s)
	assert_true(safe - after > 4.0 + 5.0, "second 3/9 costs its value plus the lethal penalty")
	Fx.put(s, 0, 2, _mk(1, 9, [&"guard"]))
	assert_true(not me.enemy_has_lethal(s), "a 9-HP guard soaks it")
	return true


func test_easy_sometimes_random() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 9
	for id: StringName in [&"mossback", &"fireball", &"cinderpup", &"sugar_rush", &"iceling"]:
		Fx.give(s, 0, id)
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.put(s, 1, 1, _mk(2, 6))
	Fx.put(s, 0, 3, _mk(2, 9))
	var best: Dictionary = AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 1).choose_action(s).to_dict()
	var easy := AIPlayer.new(0, AIPlayer.Difficulty.EASY, 77)
	var differ: int = 0
	for i: int in 200:
		if easy.choose_action(s).to_dict() != best:
			differ += 1
	assert_true(differ >= 30 and differ <= 70, "easy strays 15-35%% of the time (%d/200)" % differ)
	return true


func test_ai_turn_always_ends() -> bool:
	var s: GameState = Fx.blank()
	for i: int in 8:
		Fx.give(s, 0, &"star_shard")
	Fx.put(s, 0, 0, _mk(1, 9, [&"flurry"]))
	Fx.put(s, 0, 1, _mk(1, 9, [&"flurry"]))
	Fx.put_creature(s, 0, 2, &"gumdrop")
	Fx.fill_deck(s, 0, &"star_shard", 20)
	Fx.fill_deck(s, 1, &"mossback", 5)
	Fx.put(s, 1, 3, _mk(0, 30))
	for d: AIPlayer.Difficulty in [AIPlayer.Difficulty.EASY, AIPlayer.Difficulty.MEDIUM]:
		var t: GameState = s.clone()
		var ev: Array[GameEvent] = []
		AIRunner.play_turn(t, AIPlayer.new(0, d, 5), AIPlayer.new(1, d, 6), ev)
		assert_eq(t.active, 1, "turn ended (difficulty %d)" % d)
		assert_eq(ev[ev.size() - 1].type in [&"magic_changed", &"card_drawn", &"card_burned", &"fatigue", &"turn_started"], true, "ended with the next turn starting")
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
