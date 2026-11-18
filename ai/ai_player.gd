class_name AIPlayer
extends RefCounted
## The computer opponent (Rules 2.0 spec section 7). It only produces Actions; it never touches
## the view. Easy: greedy with random slips. Medium: greedy one action ahead. Hard: plans the
## whole turn (AIPlanner).

enum Difficulty { EASY, MEDIUM, HARD }

## [crit, normal, glance] percentages per difficulty (spec 4.4).
const HIT_RATES: Array[Array] = [[15, 50, 35], [30, 50, 20], [50, 40, 10]]
const BLOCK_RATES: Array[int] = [15, 30, 50]
const WIN_SCORE := 1000.0
## Chance that Easy plays a random legal action instead of its best one.
const EASY_RANDOM := 0.25
const HAND_CARD := 0.6
const ENEMY_LETHAL_PENALTY := 4.0
## Armour is worth a little less than HP (fatigue goes around it).
const ARMOUR_VALUE := 0.9
## A claimed lane of a land the AI still has creatures of (they need those lanes to be played).
const LAND_VALUE := 0.35
const XP_VALUE := 0.25
## Hard's turn planner: states kept per step, and the most states simulated per decision.
const BEAM := 6
const MAX_STATES := 1500
## Flat keyword worth; bubble and flurry also scale with ATK (see _creature_value).
const KEYWORD_VALUE: Dictionary = {
	&"guard": 1.5, &"bubble": 1.5, &"venom": 2.5, &"leech": 1.0, &"flurry": 0.0,
	&"second_wind": 1.5, &"hidden": 1.0, &"dash": 0.3,
}

var player: int
var difficulty: Difficulty
var rng := RandomNumberGenerator.new()


func _init(p: int, d: Difficulty, seed: int) -> void:
	player = p
	difficulty = d
	rng.seed = seed


## The next action. While a Dream Up is pending, the best pick; otherwise END_TURN when nothing
## improves the position. Attacks come back as normal, unblocked hits: the caller rolls the bars.
func choose_action(s: GameState) -> Action:
	if s.phase == GameState.Phase.CHOOSING:
		return _best_choice(s)
	if difficulty == Difficulty.HARD:
		var plan: Array[Action] = AIPlanner.plan(s, self, BEAM, MAX_STATES)
		return plan[0] if not plan.is_empty() else Action.end_turn(player)
	if difficulty == Difficulty.EASY and rng.randf() < EASY_RANDOM:
		var options: Array[Action] = Rules.legal_actions(s).filter(func(a: Action) -> bool: return a.type != Action.Type.END_TURN)
		if not options.is_empty():
			return options[rng.randi_range(0, options.size() - 1)]
	return _greedy(s)


func _greedy(s: GameState) -> Action:
	var best: Action = Action.end_turn(player)
	var best_score: float = evaluate(s)
	for a: Action in Rules.legal_actions(s):
		if a.type == Action.Type.END_TURN:
			continue
		var score: float = evaluate(_after(s, a))
		if score > best_score + 0.001:
			best_score = score
			best = a
	return best


func _after(s: GameState, a: Action) -> GameState:
	var sim: GameState = s.clone()
	Rules.apply(sim, a)
	return sim


## Dream Up: the pick that leaves the best position; equal positions go to the stronger card.
func _best_choice(s: GameState) -> Action:
	var best: Action = null
	var best_score: float = -INF
	for a: Action in Rules.legal_actions(s):
		var score: float = evaluate(_after(s, a)) + 0.01 * card_value(s.pending_choice[a.choice])
		if best == null or score > best_score:
			best = a
			best_score = score
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


## Position score from this AI's point of view (spec 7).
func evaluate(s: GameState) -> float:
	if s.phase == GameState.Phase.OVER:
		return WIN_SCORE if s.winner == player else -WIN_SCORE
	var me: int = player
	var foe: int = s.opponent(me)
	var score: float = float(s.players[me].hero_hp - s.players[foe].hero_hp)
	score += ARMOUR_VALUE * float(s.players[me].armour - s.players[foe].armour)
	score += LAND_VALUE * float(_useful_lanes(s, me))
	for q: int in 2:
		var sign: float = 0.5 if q == me else -0.5
		for l: int in GameState.LANES:
			if s.players[q].lanes[l].creature:
				score += sign * _creature_value(s, q, l)
	score += HAND_CARD * s.players[me].hand.size()
	if enemy_has_lethal(s):
		score -= ENEMY_LETHAL_PENALTY
	return score


func _creature_value(s: GameState, p: int, lane: int) -> float:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	var atk: float = float(Rules.effective_attack(s, p, lane))
	var v: float = atk + float(Rules.effective_max_hp(s, p, lane) - cr.damage)
	for k: StringName in Rules.keywords_of(s, p, lane):
		v += KEYWORD_VALUE.get(k, 0.0)
		if k == &"flurry":
			v += 0.8 * atk
	if cr.bubble:
		v += 0.5 * atk
	elif &"bubble" in Rules.keywords_of(s, p, lane):
		v -= KEYWORD_VALUE[&"bubble"]  # bubble already popped
	if not cr.hidden and &"hidden" in Rules.keywords_of(s, p, lane):
		v -= KEYWORD_VALUE[&"hidden"]  # already revealed
	if not cr.hushed:
		v += 0.8 * cr.card.spell_power
	return v + XP_VALUE * float(cr.xp)


## My claimed lanes whose land matches a creature I still hold (hand or deck).
func _useful_lanes(s: GameState, p: int) -> int:
	var want: Dictionary = {}
	for c: CardData in s.players[p].hand:
		if c.is_creature():
			want[c.land] = true
	for c: CardData in s.players[p].deck:
		if c.is_creature():
			want[c.land] = true
	var n: int = 0
	for l: GameState.LaneState in s.players[p].lanes:
		if l.land != Lands.MEADOW and want.has(l.land):
			n += 1
	return n


## A card's rough worth in hand (Dream Up tie-break).
static func card_value(c: CardData) -> float:
	if not c.is_creature():
		return 2.0 * c.cost + 1.0
	var v: float = c.attack + c.health
	for k: StringName in c.keywords:
		v += KEYWORD_VALUE.get(k, 0.0)
	return v + 0.8 * c.spell_power


## True when the enemy's creatures could kill my hero next turn on the current board:
## their total attack (Flurry twice; frozen ones can't), minus what my un-hidden Guards soak.
func enemy_has_lethal(s: GameState) -> bool:
	var me: int = player
	var foe: int = s.opponent(me)
	var total: int = 0
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[foe].lanes[l].creature
		if cr == null or cr.is_frozen():
			continue
		var atk: int = Rules.effective_attack(s, foe, l)
		total += atk * (2 if Rules.has_keyword(s, foe, l, &"flurry") else 1)
	var soak: int = 0
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[me].lanes[l].creature
		if cr and not cr.hidden and Rules.has_keyword(s, me, l, &"guard"):
			soak += Rules.effective_max_hp(s, me, l) - cr.damage
	return total > 0 and total - soak >= s.players[me].hero_hp
