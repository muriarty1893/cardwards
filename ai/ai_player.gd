class_name AIPlayer
extends RefCounted
## Greedy one-step AI. It only produces Actions; it never touches the view.

enum Difficulty { EASY, MEDIUM, HARD }

## [crit, normal, glance] percentages per difficulty (spec 4.4).
const HIT_RATES: Array[Array] = [[15, 50, 35], [30, 50, 20], [50, 40, 10]]
const BLOCK_RATES: Array[int] = [15, 30, 50]
const WIN_SCORE := 1000.0

var player: int
var difficulty: Difficulty
var rng := RandomNumberGenerator.new()


func _init(p: int, d: Difficulty, seed: int) -> void:
	player = p
	difficulty = d
	rng.seed = seed


## Best main-phase action that improves the position, otherwise BEGIN_ATTACKS.
func choose_main_action(s: GameState) -> Action:
	var best: Action = Action.begin_attacks(player)
	var best_score: float = evaluate(s)
	for a: Action in Rules.legal_actions(s):
		if a.type == Action.Type.BEGIN_ATTACKS:
			continue
		var sim: GameState = s.clone()
		Rules.apply(sim, a)
		var score: float = evaluate(sim)
		if score > best_score + 0.001:
			best_score = score
			best = a
	return best


func roll_hit() -> Action.Hit:
	var r: int = rng.randi_range(1, 100)
	var rates: Array = HIT_RATES[difficulty]
	if r <= int(rates[0]):
		return Action.Hit.CRIT
	if r <= int(rates[0]) + int(rates[1]):
		return Action.Hit.NORMAL
	return Action.Hit.GLANCE


func roll_block() -> bool:
	return rng.randi_range(1, 100) <= BLOCK_RATES[difficulty]


## Position score from this AI's point of view.
func evaluate(s: GameState) -> float:
	if s.phase == GameState.Phase.OVER:
		return WIN_SCORE if s.winner == player else -WIN_SCORE
	var me: int = player
	var foe: int = s.opponent(me)
	var score: float = float(s.players[me].hero_hp - s.players[foe].hero_hp)
	for q: int in 2:
		var sign: float = 0.5 if q == me else -0.5
		for l: int in GameState.LANES:
			var cr: GameState.CreatureState = s.players[q].lanes[l].creature
			if cr:
				var remaining: int = Rules.effective_max_hp(s, q, l) - cr.damage
				score += sign * float(Rules.effective_attack(s, q, l) + remaining)
	score += 0.3 * s.players[me].hand.size()
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[me].lanes[l].creature
		if cr == null or cr.acted or cr.is_frozen():
			continue
		var atk: float = float(Rules.effective_attack(s, me, l))
		if s.players[foe].lanes[l].creature == null:
			atk *= 1.2
		score += 0.8 * atk
	return score
