class_name AIRunner
extends RefCounted
## Drives whole AI turns and matches without any view. Used by tests and demos.

const MAX_MAIN_ACTIONS := 30


static func play_turn(s: GameState, ai: AIPlayer, defender_ai: AIPlayer, ev: Array[GameEvent]) -> void:
	for i: int in MAX_MAIN_ACTIONS:
		if s.phase != GameState.Phase.MAIN and s.phase != GameState.Phase.CHOOSING:
			break
		var a: Action = ai.choose_main_action(s)
		ev.append_array(Rules.apply(s, a))
		if a.type == Action.Type.BEGIN_ATTACKS:
			break
	if s.phase == GameState.Phase.MAIN:
		ev.append_array(Rules.apply(s, Action.begin_attacks(ai.player)))
	for lane: int in Rules.attackers(s):
		if s.phase == GameState.Phase.OVER:
			return
		var blocked: bool = defender_ai.roll_block() if Rules.has_defender(s, lane) else false
		ev.append_array(Rules.apply(s, Action.attack(ai.player, lane, ai.roll_hit(), blocked)))
	if s.phase != GameState.Phase.OVER:
		ev.append_array(Rules.apply(s, Action.end_turn(ai.player)))


## Plays from the current state. Returns the winner, or -1 if max_turns is reached.
static func play_match(s: GameState, ais: Array[AIPlayer], max_turns: int = 200) -> int:
	var ev: Array[GameEvent] = []
	if s.turn == 1 and s.phase == GameState.Phase.MAIN and s.players[s.active].magic == 0:
		ev.append_array(Rules.start_turn(s))
	var start: int = s.turn
	while s.phase != GameState.Phase.OVER and s.turn - start < max_turns:
		play_turn(s, ais[s.active], ais[s.opponent(s.active)], ev)
	return s.winner if s.phase == GameState.Phase.OVER else -1
