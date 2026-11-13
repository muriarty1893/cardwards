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
		Action.Type.BOOP:
			return _validate_boop(s, a)
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


static func _validate_boop(s: GameState, a: Action) -> String:
	if s.phase != GameState.Phase.MAIN:
		return "Can't do that now"
	if a.lane < 0 or a.lane >= GameState.LANES or s.players[a.player].lanes[a.lane].creature == null:
		return "No such creature"
	var cr: GameState.CreatureState = s.players[a.player].lanes[a.lane].creature
	if cr.card.trigger != &"on_boop":
		return "No boop ability"
	if cr.is_frozen():
		return "Creature is frozen"
	if cr.acted:
		return "Creature already acted"
	return _validate_targets(s, a.player, cr.card, a.lane, a.targets)


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
		Action.Type.BOOP:
			var cr: GameState.CreatureState = s.players[a.player].lanes[a.lane].creature
			cr.acted = true
			ev.append(GameEvent.make(&"booped", {"player": a.player, "lane": a.lane}))
			Abilities.run(s, a.player, a.lane, cr.card, a.targets, ev)
			resolve_deaths(s, ev)
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


# --- Triggers, stats, damage and deaths --------------------------------------

static func _run_lane_triggers(s: GameState, p: int, trigger: StringName, ev: Array[GameEvent]) -> void:
	for l: int in GameState.LANES:
		var b: CardData = s.players[p].lanes[l].building
		if b and b.trigger == trigger:
			Abilities.run(s, p, l, b, [], ev)


static func _building_ability(s: GameState, p: int, lane: int) -> StringName:
	var b: CardData = s.players[p].lanes[lane].building
	return b.ability_id if b else &""


static func effective_attack(s: GameState, p: int, lane: int) -> int:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return 0
	var atk: int = cr.card.attack
	match _building_ability(s, p, lane):
		&"lane_atk_2":
			atk += 2
		&"lane_atk_1_hp_1":
			atk += 1
	if _building_ability(s, s.opponent(p), lane) == &"opposing_atk_minus_1":
		atk -= 1
	return maxi(atk, 0)


static func effective_max_hp(s: GameState, p: int, lane: int) -> int:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return 0
	var hp: int = cr.card.health
	match _building_ability(s, p, lane):
		&"lane_max_hp_3":
			hp += 3
		&"lane_atk_1_hp_1":
			hp += 1
	return hp


static func has_ice_wall(s: GameState, p: int, lane: int) -> bool:
	return _building_ability(s, p, lane) == &"lane_damage_minus_1"


static func deal_creature_damage(s: GameState, p: int, lane: int, amount: int, ev: Array[GameEvent], hit: Action.Hit = Action.Hit.NORMAL, blocked: bool = false) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return
	cr.damage += amount
	ev.append(GameEvent.make(&"creature_damaged", {"player": p, "lane": lane, "amount": amount, "hit": int(hit), "blocked": blocked}))


static func heal_creature(s: GameState, p: int, lane: int, amount: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return
	var healed: int = mini(amount, cr.damage)
	cr.damage -= healed
	ev.append(GameEvent.make(&"creature_healed", {"player": p, "lane": lane, "amount": healed}))


static func damage_hero(s: GameState, p: int, amount: int, ev: Array[GameEvent]) -> void:
	s.players[p].hero_hp -= amount
	ev.append(GameEvent.make(&"hero_damaged", {"player": p, "amount": amount}))


static func heal_hero(s: GameState, p: int, amount: int, ev: Array[GameEvent]) -> void:
	var before: int = s.players[p].hero_hp
	s.players[p].hero_hp = mini(GameState.MAX_HP, before + amount)
	ev.append(GameEvent.make(&"hero_healed", {"player": p, "amount": s.players[p].hero_hp - before}))


static func freeze(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return
	cr.freeze_turn = s.turn
	ev.append(GameEvent.make(&"frozen", {"player": p, "lane": lane}))


static func return_to_hand(s: GameState, p: int, c: CardData, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	if ps.hand.size() >= GameState.HAND_LIMIT:
		ps.discard.append(c)
		ev.append(GameEvent.make(&"card_burned", {"player": p, "card": c.id}))
	else:
		ps.hand.append(c)
		ev.append(GameEvent.make(&"card_returned", {"player": p, "card": c.id}))


static func resolve_deaths(s: GameState, ev: Array[GameEvent]) -> void:
	if s.phase == GameState.Phase.OVER:
		return
	var any: bool = true
	while any:
		any = false
		for p: int in 2:
			for l: int in GameState.LANES:
				var cr: GameState.CreatureState = s.players[p].lanes[l].creature
				if cr and cr.damage >= effective_max_hp(s, p, l):
					any = true
					s.players[p].lanes[l].creature = null
					s.players[p].discard.append(cr.card)
					ev.append(GameEvent.make(&"creature_destroyed", {"player": p, "lane": l, "card": cr.card.id}))
					if cr.card.trigger == &"on_destroyed":
						Abilities.run(s, p, l, cr.card, [], ev)
	var dead: Array[bool] = [s.players[0].hero_hp <= 0, s.players[1].hero_hp <= 0]
	if dead[0] or dead[1]:
		s.phase = GameState.Phase.OVER
		s.winner = s.active if (dead[0] and dead[1]) else (1 if dead[0] else 0)
		ev.append(GameEvent.make(&"game_over", {"winner": s.winner}))
