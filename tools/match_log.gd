extends SceneTree
## Prints one AI-vs-AI match, one line per action, to check the rules by eye.
##   godot --headless --path . --script res://tools/match_log.gd -- --seed=N [--easy|--hard]

const HITS: Array[String] = ["", " (crit)", " (glancing)"]


func _initialize() -> void:
	var seed: int = 1
	var diff: AIPlayer.Difficulty = AIPlayer.Difficulty.MEDIUM
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed = int(arg.substr(7))
		elif arg == "--easy":
			diff = AIPlayer.Difficulty.EASY
		elif arg == "--hard":
			diff = AIPlayer.Difficulty.HARD
	var decks: Array[DeckData] = CardDB.all_decks()
	var s: GameState = Rules.setup(decks[seed % 4], decks[(seed + 1) % 4], seed)
	var ais: Array[AIPlayer] = [AIPlayer.new(0, diff, seed * 2), AIPlayer.new(1, diff, seed * 2 + 1)]
	print("P0 %s vs P1 %s, seed %d, %s AI. P%d goes first." % [decks[seed % 4].display_name, decks[(seed + 1) % 4].display_name, seed, AIPlayer.Difficulty.keys()[diff].to_lower(), s.first_player])
	Rules.start_turn(s)
	var steps: int = 0
	while s.phase != GameState.Phase.OVER and steps < 3000:
		steps += 1
		var who: int = s.pending_player if s.phase == GameState.Phase.CHOOSING else s.active
		var ai: AIPlayer = ais[who]
		var a: Action = ai.choose_action(s)
		if a.type == Action.Type.ATTACK:
			a.hit = ai.roll_hit()
			a.blocked = ais[1 - who].roll_block() if a.target_lane >= 0 else false
		var line: String = _describe(s, a)
		var ev: Array[GameEvent] = Rules.apply(s, a)
		print(line + _effects(ev))
	print("Winner: P%d on turn %d (HP %d / %d)" % [s.winner, s.turn, s.players[0].hero_hp, s.players[1].hero_hp])
	quit()


func _name(s: GameState, p: int, lane: int) -> String:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	return cr.card.display_name if cr else "lane %d" % lane


func _describe(s: GameState, a: Action) -> String:
	var head: String = "T%d P%d " % [s.turn, a.player]
	match a.type:
		Action.Type.PLAY_CARD:
			var c: CardData = s.players[a.player].hand[a.hand_index]
			return head + "plays %s%s" % [c.display_name, "" if c.kind == CardData.Kind.SPELL else " in lane %d" % a.lane]
		Action.Type.BOOP:
			return head + "boops %s" % _name(s, a.player, a.lane)
		Action.Type.ATTACK:
			var target: String = "the hero" if a.target_lane < 0 else _name(s, 1 - a.player, a.target_lane)
			return head + "%s attacks %s%s%s" % [_name(s, a.player, a.lane), target, HITS[a.hit], " (blocked)" if a.blocked else ""]
		Action.Type.CHOOSE:
			return head + "dreams up %s" % s.pending_choice[a.choice].display_name
	return head + "ends turn. HP %d / %d" % [s.players[0].hero_hp, s.players[1].hero_hp]


func _effects(ev: Array[GameEvent]) -> String:
	var bits: Array[String] = []
	for e: GameEvent in ev:
		var d: Dictionary = e.data
		match e.type:
			&"creature_damaged":
				bits.append("P%d L%d -%d%s%s" % [d["player"], d["lane"], d["amount"], " back" if d.get("kind") == &"hit_back" else "", " venom" if d.get("venom", false) else ""])
			&"hero_damaged":
				bits.append("P%d hero -%d" % [d["player"], d["amount"]])
			&"hero_healed":
				bits.append("P%d hero +%d" % [d["player"], d["amount"]])
			&"creature_destroyed":
				bits.append("%s dies" % CardDB.card(d["card"]).display_name)
			&"bubble_popped", &"revealed", &"hushed", &"second_wind", &"frozen":
				bits.append("%s P%d L%d" % [e.type, d["player"], d["lane"]])
			&"dream_up_offered":
				bits.append("offers %s" % ", ".join(d["cards"]))
	return "" if bits.is_empty() else "  [" + "; ".join(bits) + "]"
