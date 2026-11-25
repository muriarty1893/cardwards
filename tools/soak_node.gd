extends Node

func _ready() -> void:
	# The root is still setting up its children during _ready: start a frame later.
	await get_tree().process_frame
	var n: int = 8
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--matches="):
			n = int(a.substr(10))
	var decks: Array[DeckData] = CardDB.all_decks()
	var session: Node = get_tree().root.get_node("Session")
	for i: int in n:
		var nd: int = decks.size()
		session.set("player_deck", decks[i % nd].id)
		session.set("ai_deck", decks[(i / nd + i + 1) % nd].id)
		session.set("seed", 100 + i)
		var m := (load("res://view/match.tscn") as PackedScene).instantiate() as MatchController
		get_tree().root.add_child(m)
		await get_tree().process_frame
		m.player.speed = 20.0
		m.pace = 20.0
		m.timing_bar.auto_stop = true
		m.timing_bar.force_needle = randf()
		var me := AIPlayer.new(MatchController.HUMAN, AIPlayer.Difficulty.MEDIUM, 500 + i)
		var frames: int = 0
		while m.state.phase != GameState.Phase.OVER and frames < 60000:
			await get_tree().process_frame
			frames += 1
			# Dream Up: the picker waits for a click; pick the first card.
			if m.mulligan.is_open() and m.human_choosing():
				m.mulligan.toggle(0)
				m.mulligan.confirm()
				continue
			if m.picker.is_open() and m.human_choosing():
				m.picker.choose(0)
				continue
			if m.busy or m.state.active != MatchController.HUMAN:
				continue
			var a: Action = me.choose_action(m.state)
			match a.type:
				Action.Type.END_TURN:
					m.hud.end_turn_pressed.emit()
				Action.Type.ATTACK:
					m.request_attack(a.lane, a.target_lane)
				Action.Type.CHOOSE:
					m.perform(a)
				_:
					m.input.action_requested.emit(a)
		var lands: Array = []
		for p: int in 2:
			for l: int in 4:
				lands.append(m.state.players[p].lanes[l].land)
		print("SOAK match %d %s vs %s: phase %d winner %d turn %d frames %d field %s lands %s" % [i, session.get("player_deck"), session.get("ai_deck"), m.state.phase, m.state.winner, m.state.turn, frames, m.state.field.id if m.state.field else &"-", lands])
		m.queue_free()
		await get_tree().process_frame
	get_tree().quit()
