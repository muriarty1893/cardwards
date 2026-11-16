extends SceneTree
## Times Hard AI decisions over seeded turns.
##   godot --headless --path . --script res://tools/ai_bench.gd


func _initialize() -> void:
	var decks: Array[DeckData] = CardDB.all_decks()
	var times: Array[int] = []
	var states: Array[int] = []
	for seed: int in range(1, 6):
		var s: GameState = Rules.setup(decks[seed % 4], decks[(seed + 2) % 4], seed)
		var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.HARD, seed), AIPlayer.new(1, AIPlayer.Difficulty.HARD, seed + 50)]
		Rules.start_turn(s)
		var turns: int = 0
		while s.phase != GameState.Phase.OVER and turns < 8:
			var who: int = s.pending_player if s.phase == GameState.Phase.CHOOSING else s.active
			var t0: int = Time.get_ticks_usec()
			var a: Action = ais[who].choose_action(s)
			times.append(Time.get_ticks_usec() - t0)
			states.append(AIPlanner.last_states)
			if a.type == Action.Type.END_TURN:
				turns += 1
			Rules.apply(s, a)
	times.sort()
	var total: int = 0
	for t: int in times:
		total += t
	print("Hard decisions: %d, mean %.0f ms, median %.0f ms, max %.0f ms, max states %d" % [times.size(), total / 1000.0 / times.size(), times[times.size() / 2] / 1000.0, times[times.size() - 1] / 1000.0, states.max()])
	quit()
