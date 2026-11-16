class_name AIPlanner
extends RefCounted
## Hard AI turn planner (Rules 2.0 spec section 7): a beam search over sequences of this turn's
## actions. Each step keeps the `beam_width` best positions; the search stops after `max_states`
## simulated actions. A sequence that wins is returned at once. Attacks are simulated as normal,
## unblocked hits; the plan is redone before every action, so real bar results are accounted for.

## States simulated by the last plan() call (for tests and the bench).
static var last_states: int = 0


## The best action sequence found for ai.player this turn (empty: just end the turn).
static func plan(s: GameState, ai: AIPlayer, beam_width: int, max_states: int) -> Array[Action]:
	last_states = 0
	var best_seq: Array[Action] = []
	var best_score: float = ai.evaluate(s)
	var beam: Array[Dictionary] = [{"state": s, "seq": [] as Array[Action]}]
	while not beam.is_empty() and last_states < max_states:
		var next: Array[Dictionary] = []
		for node: Dictionary in beam:
			var st: GameState = node["state"]
			for a: Action in Rules.legal_actions(st):
				if a.type == Action.Type.END_TURN:
					continue
				if last_states >= max_states:
					break
				var sim: GameState = st.clone()
				Rules.apply(sim, a)
				last_states += 1
				var seq: Array[Action] = (node["seq"] as Array[Action]).duplicate()
				seq.append(a)
				if sim.phase == GameState.Phase.OVER and sim.winner == ai.player:
					return seq
				var score: float = ai.evaluate(sim)
				if score > best_score + 0.001:
					best_score = score
					best_seq = seq
				if sim.phase != GameState.Phase.OVER and sim.active == ai.player:
					next.append({"state": sim, "seq": seq, "score": score})
		next.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["score"] > y["score"])
		beam = next.slice(0, beam_width)
	return best_seq
