class_name AIRunner
extends RefCounted
## Drives whole AI turns and matches without any view. Used by tests and demos.

## Safety cap on actions in one AI turn; the turn always ends after it.
const MAX_ACTIONS := 40


static func play_turn(s: GameState, ai: AIPlayer, defender_ai: AIPlayer, ev: Array[GameEvent]) -> void:
	for i: int in MAX_ACTIONS:
		if s.phase == GameState.Phase.OVER or s.active != ai.player:
			return
		var a: Action = ai.choose_action(s)
		if a.type == Action.Type.ATTACK:
			a.hit = ai.roll_hit()
			a.blocked = defender_ai.roll_block() if a.target_lane >= 0 else false
		ev.append_array(Rules.apply(s, a))
		if a.type == Action.Type.END_TURN:
			return
	if s.phase == GameState.Phase.CHOOSING:
		ev.append_array(Rules.apply(s, Action.choose(s.pending_player, 0)))
	if s.phase != GameState.Phase.OVER and s.active == ai.player:
		ev.append_array(Rules.apply(s, Action.end_turn(ai.player)))


## Plays from the current state. Returns the winner, or -1 if max_turns is reached.
static func play_match(s: GameState, ais: Array[AIPlayer], max_turns: int = 200) -> int:
	var ev: Array[GameEvent] = []
	if s.turn == 1 and s.phase == GameState.Phase.MAIN and s.players[s.active].max_magic == 0:
		ev.append_array(Rules.start_turn(s))
	var start: int = s.turn
	while s.phase != GameState.Phase.OVER and s.turn - start < max_turns:
		play_turn(s, ais[s.active], ais[s.opponent(s.active)], ev)
	return s.winner if s.phase == GameState.Phase.OVER else -1
