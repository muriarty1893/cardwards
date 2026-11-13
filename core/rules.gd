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
		Action.Type.PLAY_CARD:
			return _validate_play(s, a)
		Action.Type.BEGIN_ATTACKS:
			if s.phase != GameState.Phase.MAIN:
				return "Can't do that now"
		Action.Type.END_TURN:
			pass
		_:
			return "Can't do that now"
	return ""


static func _validate_play(s: GameState, a: Action) -> String:
	if s.phase != GameState.Phase.MAIN:
		return "Can't do that now"
	var ps: GameState.PlayerState = s.players[a.player]
	if a.hand_index < 0 or a.hand_index >= ps.hand.size():
		return "No such card"
	var c: CardData = ps.hand[a.hand_index]
	if c.cost > ps.magic:
		return "Not enough magic"
	if c.kind == CardData.Kind.CREATURE and matching_lands(s, a.player, c.land) < c.level:
		return "Needs %d %s lands" % [c.level, CardData.LAND_NAMES[c.land]]
	if c.kind != CardData.Kind.SPELL:
		if a.lane < 0 or a.lane >= GameState.LANES:
			return "Invalid target"
		var lane: GameState.LaneState = ps.lanes[a.lane]
		if c.kind == CardData.Kind.CREATURE and lane.creature != null:
			return "Lane already has a creature"
		if c.kind == CardData.Kind.BUILDING and lane.building != null:
			return "Lane already has a building"
	if c.kind == CardData.Kind.SPELL:
		return _validate_targets(s, a.player, c, -1, a.targets)
	return ""


## Spells need targets when played; creature boops need them when booped.
static func _validate_targets(s: GameState, p: int, c: CardData, source_lane: int, targets: Array[Dictionary]) -> String:
	if c.target == &"none":
		return ""
	var valid: Array[Dictionary] = valid_targets(s, p, c, source_lane)
	var needed: int = 2 if c.target == &"own_two_creatures" else 1
	if valid.size() < needed:
		return "No valid target"
	if targets.size() != needed:
		return "Invalid target"
	for t: Dictionary in targets:
		if not t in valid:
			return "Invalid target"
	if needed == 2 and targets[0] == targets[1]:
		return "Invalid target"
	return ""


static func matching_lands(s: GameState, p: int, land: int) -> int:
	var n: int = 0
	for lane: GameState.LaneState in s.players[p].lanes:
		if lane.land == land:
			n += 1
	return n


static func valid_targets(s: GameState, p: int, c: CardData, source_lane: int = -1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match c.target:
		&"any_creature":
			for q: int in 2:
				for i: int in GameState.LANES:
					if s.players[q].lanes[i].creature:
						out.append({"player": q, "lane": i})
		&"own_creature", &"own_two_creatures":
			for i: int in GameState.LANES:
				if s.players[p].lanes[i].creature:
					out.append({"player": p, "lane": i})
		&"own_empty_lane":
			for i: int in GameState.LANES:
				if i != source_lane and s.players[p].lanes[i].creature == null:
					out.append({"player": p, "lane": i})
		&"discard_creature":
			var d: Array[CardData] = s.players[p].discard
			for i: int in d.size():
				if d[i].kind == CardData.Kind.CREATURE:
					out.append({"discard": i})
	return out


# --- Apply -------------------------------------------------------------------

static func apply(s: GameState, a: Action) -> Array[GameEvent]:
	var err: String = validate(s, a)
	if err != "":
		push_warning("Rules.apply rejected %s: %s" % [a, err])
		return []
	var ev: Array[GameEvent] = []
	match a.type:
		Action.Type.PLAY_CARD:
			_play(s, a, ev)
		Action.Type.BEGIN_ATTACKS:
			s.phase = GameState.Phase.ATTACK
			ev.append(GameEvent.make(&"phase_changed", {"phase": int(s.phase)}))
		Action.Type.END_TURN:
			_end_turn(s, ev)
	return ev


static func _play(s: GameState, a: Action, ev: Array[GameEvent]) -> void:
	var p: int = a.player
	var ps: GameState.PlayerState = s.players[p]
	var c: CardData = ps.hand[a.hand_index]
	ps.hand.remove_at(a.hand_index)
	if c.cost > 0:
		ps.magic -= c.cost
		ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": ps.magic}))
	match c.kind:
		CardData.Kind.CREATURE:
			var cr := GameState.CreatureState.new()
			cr.card = c
			cr.played_turn = s.turn
			ps.lanes[a.lane].creature = cr
			ev.append(GameEvent.make(&"creature_played", {"player": p, "lane": a.lane, "card": c.id}))
			if c.trigger == &"on_play":
				Abilities.run(s, p, a.lane, c, a.targets, ev)
		CardData.Kind.BUILDING:
			ps.lanes[a.lane].building = c
			ev.append(GameEvent.make(&"building_played", {"player": p, "lane": a.lane, "card": c.id}))
		CardData.Kind.SPELL:
			ev.append(GameEvent.make(&"spell_cast", {"player": p, "card": c.id}))
			Abilities.run(s, p, -1, c, a.targets, ev)
			ps.discard.append(c)
	resolve_deaths(s, ev)


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
