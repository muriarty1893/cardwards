extends SceneTree
## Deck balance: Medium AI vs Medium AI for every deck pairing, both seats.
##   godot --headless --path . --script res://tools/deck_balance.gd [-- --n=<matches per pairing>]


func _initialize() -> void:
	var n: int = 10
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.substr(4))
	var decks: Array[DeckData] = CardDB.all_decks()
	var wins: Dictionary = {}
	var games: Dictionary = {}
	var turns: Array[int] = []
	for d: DeckData in decks:
		wins[d.id] = 0
		games[d.id] = 0
	var row: String = ""
	for i: int in decks.size():
		row = "%-12s" % decks[i].id
		for j: int in decks.size():
			var w: int = 0
			for k: int in n:
				var seed: int = 5000 + i * 100 + j * 10 + k
				var pair: Array[DeckData] = [decks[i], decks[j]]
				var s: GameState = Rules.setup(pair[0], pair[1], seed)
				var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, seed), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, seed + 7)]
				var winner: int = AIRunner.play_match(s, ais, 120)
				turns.append(s.turn)
				if winner == 0:
					w += 1
				if i != j:
					games[decks[i].id] += 1
					games[decks[j].id] += 1
					if winner == 0:
						wins[decks[i].id] += 1
					elif winner == 1:
						wins[decks[j].id] += 1
			row += " %3d%%" % int(100.0 * w / n)
		print(row)
	for d: DeckData in decks:
		print("%-12s wins %d / %d (%.0f%%)" % [d.id, wins[d.id], games[d.id], 100.0 * wins[d.id] / maxi(1, games[d.id])])
	turns.sort()
	print("turns: median %d, max %d" % [turns[turns.size() / 2], turns[turns.size() - 1]])
	quit()
