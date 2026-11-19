class_name AiRival
extends RivalDriver
## The computer rival: local moves apply at once, then the AI plays its turn step by step.

var ai: AIPlayer


func _init(rival_ai: AIPlayer) -> void:
	ai = rival_ai


func begin() -> void:
	if m.state.phase != GameState.Phase.OVER and m.state.active == MatchController.AI:
		await rival_turn()


func submit(a: Action) -> void:
	await m.perform(a)
	if a.type == Action.Type.END_TURN and m.state.phase != GameState.Phase.OVER and m.state.active == MatchController.AI:
		await rival_turn()


## The AI may block an attack on one of its creatures.
func attack(lane: int, target_lane: int, hit: Action.Hit) -> void:
	var blocked: bool = false
	if target_lane >= 0:
		blocked = ai.roll_block()
		await m.timing_bar.simulate_block(blocked)
	await m.perform(Action.attack(MatchController.HUMAN, lane, target_lane, hit, blocked))


## The AI's whole turn, shown step by step. Ends after the AI's END_TURN (human's turn started).
func rival_turn() -> void:
	var s: GameState = m.state
	for i: int in AIRunner.MAX_ACTIONS:
		if s.phase == GameState.Phase.OVER or s.active != MatchController.AI:
			return
		await m.get_tree().create_timer(MatchController.AI_PAUSE / m.pace).timeout
		var a: Action = ai.choose_action(s)
		if a.type == Action.Type.ATTACK:
			await m.show_attack_arrow(MatchController.AI, a.lane, a.target_lane)
			a.hit = ai.roll_hit()
			await m.timing_bar.simulate_attack(a.hit)
			if a.target_lane >= 0:
				a.blocked = await m.timing_bar.run_block()
		await m.perform(a)
		if a.type == Action.Type.END_TURN:
			return
	if s.phase == GameState.Phase.CHOOSING:
		await m.perform(Action.choose(s.pending_player, 0))
	if s.phase != GameState.Phase.OVER and s.active == MatchController.AI:
		await m.perform(Action.end_turn(MatchController.AI))
