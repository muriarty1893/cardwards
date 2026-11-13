class_name Rules
extends RefCounted
## The rules engine: validate and apply actions on a GameState, returning events.


# --- Setup and turn flow -----------------------------------------------------

static func setup(deck_a: DeckData, deck_b: DeckData, seed: int) -> GameState:
	var s := GameState.new()
	s.rng.seed = seed
	for deck: DeckData in [deck_a, deck_b]:
		var ps := GameState.PlayerState.new()
		for i: int in GameState.LANES:
			var lane := GameState.LaneState.new()
			lane.land = deck.lands[i]
			ps.lanes.append(lane)
		ps.deck = deck.cards.duplicate()
		_shuffle(s, ps.deck)
		s.players.append(ps)
	for p: int in 2:
		for i: int in GameState.START_HAND:
			s.players[p].hand.append(s.players[p].deck.pop_back())
	s.first_player = s.rng.randi_range(0, 1)
	s.active = s.first_player
	s.turn = 1
	s.phase = GameState.Phase.MAIN
	return s


static func _shuffle(s: GameState, arr: Array[CardData]) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = s.rng.randi_range(0, i)
		var tmp: CardData = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func start_turn(s: GameState) -> Array[GameEvent]:
	var ev: Array[GameEvent] = []
	var p: int = s.active
	var ps: GameState.PlayerState = s.players[p]
	s.phase = GameState.Phase.MAIN
	ev.append(GameEvent.make(&"turn_started", {"player": p, "turn": s.turn}))
	ps.magic = GameState.MAGIC_PER_TURN
	_run_lane_triggers(s, p, &"start_of_turn", ev)
	ps.magic_cap = ps.magic
	ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": ps.magic}))
	if s.turn != 1:
		draw(s, p, ev)
	resolve_deaths(s, ev)
	return ev


static func draw(s: GameState, p: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	if ps.deck.is_empty():
		ps.hero_hp -= GameState.FATIGUE_DAMAGE
		ev.append(GameEvent.make(&"fatigue", {"player": p, "amount": GameState.FATIGUE_DAMAGE}))
		return
	var c: CardData = ps.deck.pop_back()
	if ps.hand.size() >= GameState.HAND_LIMIT:
		ps.discard.append(c)
		ev.append(GameEvent.make(&"card_burned", {"player": p, "card": c.id}))
	else:
		ps.hand.append(c)
		ev.append(GameEvent.make(&"card_drawn", {"player": p, "card": c.id}))


# --- Validation --------------------------------------------------------------

static func validate(s: GameState, a: Action) -> String:
	if s.phase == GameState.Phase.OVER:
		return "Game is over"
	if a.player != s.active:
		return "Not your turn"
	match a.type:
		Action.Type.BEGIN_ATTACKS:
			if s.phase != GameState.Phase.MAIN:
				return "Can't do that now"
		Action.Type.END_TURN:
			pass
		_:
			return "Can't do that now"
	return ""


# --- Apply -------------------------------------------------------------------

static func apply(s: GameState, a: Action) -> Array[GameEvent]:
	var err: String = validate(s, a)
	if err != "":
		push_warning("Rules.apply rejected %s: %s" % [a, err])
		return []
	var ev: Array[GameEvent] = []
	match a.type:
		Action.Type.BEGIN_ATTACKS:
			s.phase = GameState.Phase.ATTACK
			ev.append(GameEvent.make(&"phase_changed", {"phase": int(s.phase)}))
		Action.Type.END_TURN:
			_end_turn(s, ev)
	return ev


static func _end_turn(s: GameState, ev: Array[GameEvent]) -> void:
	var p: int = s.active
	_run_lane_triggers(s, p, &"end_of_turn", ev)
	resolve_deaths(s, ev)
	if s.phase == GameState.Phase.OVER:
		return
	for lane: GameState.LaneState in s.players[p].lanes:
		if lane.creature:
			lane.creature.acted = false
	s.active = s.opponent(p)
	s.turn += 1
	ev.append_array(start_turn(s))


# --- Triggers and deaths (filled in by later tasks) --------------------------

static func _run_lane_triggers(_s: GameState, _p: int, _trigger: StringName, _ev: Array[GameEvent]) -> void:
	pass


static func resolve_deaths(s: GameState, ev: Array[GameEvent]) -> void:
	if s.phase == GameState.Phase.OVER:
		return
	var dead: Array[bool] = [s.players[0].hero_hp <= 0, s.players[1].hero_hp <= 0]
	if dead[0] or dead[1]:
		s.phase = GameState.Phase.OVER
		s.winner = s.active if (dead[0] and dead[1]) else (1 if dead[0] else 0)
		ev.append(GameEvent.make(&"game_over", {"winner": s.winner}))
