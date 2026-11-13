extends TestCase
## End to end: an AI plays the human side through the real match scene, input layer and playback.


func test_full_match_through_view() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var m := (load("res://view/match.tscn") as PackedScene).instantiate() as MatchController
	tree.root.add_child(m)
	await tree.process_frame
	m.player.speed = 20.0
	m.pace = 20.0
	m.timing_bar.auto_stop = true
	m.timing_bar.force_needle = 0.5
	var me := AIPlayer.new(MatchController.HUMAN, AIPlayer.Difficulty.MEDIUM, 77)
	var frames: int = 0
	var actions: int = 0
	while m.state.phase != GameState.Phase.OVER and frames < 60000:
		await tree.process_frame
		frames += 1
		if m.busy or m.state.active != MatchController.HUMAN:
			continue
		var a: Action = me.choose_main_action(m.state)
		actions += 1
		if a.type == Action.Type.BEGIN_ATTACKS:
			m.hud.end_turn_pressed.emit()
		else:
			m.input.action_requested.emit(a)
	assert_eq(m.state.phase, GameState.Phase.OVER, "match finished (turn %d, %d human actions)" % [m.state.turn, actions])
	var views: int = 0
	for p: int in 2:
		for l: int in 4:
			var has_c: bool = m.state.players[p].lanes[l].creature != null
			assert_eq(m.creature_views[p][l] != null, has_c, "view matches state p%d l%d" % [p, l])
	print("full match through view: winner %d on turn %d after %d frames" % [m.state.winner, m.state.turn, frames])
	m.queue_free()
	return true
