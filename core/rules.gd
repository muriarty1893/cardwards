class_name Rules
extends RefCounted
## The rules engine: validate and apply actions on a GameState, returning events.


# --- Setup and turn flow -----------------------------------------------------

## `first` >= 0 forces who goes first (online: the room decides). The coin flip is still rolled so the
## random stream, and so every later shuffle, is the same either way.
## `mulligan`: each player may redraw starting cards at the start of their first turn.
static func setup(deck_a: DeckData, deck_b: DeckData, seed: int, first: int = -1, mulligan: bool = false) -> GameState:
	var s := GameState.new()
	s.rng.seed = seed
	for deck: DeckData in [deck_a, deck_b]:
		var ps := GameState.PlayerState.new()
		for i: int in GameState.LANES:
			var lane := GameState.LaneState.new()
			# Every lane starts bare; cards claim them (living board spec 2).
			lane.land = Lands.MEADOW
			ps.lanes.append(lane)
		ps.deck = deck.cards.duplicate()
		GameHistory.record_start(ps, ps.deck)
		_shuffle(s, ps.deck)
		s.players.append(ps)
	for p: int in 2:
		for i: int in GameState.START_HAND:
			s.players[p].hand.append(s.players[p].deck.pop_back())
	var flip: int = s.rng.randi_range(0, 1)
	s.first_player = first if first >= 0 else flip
	# Going second: a Star Shard to make up for it (spec 3.1).
	s.players[1 - s.first_player].hand.append(CardDB.card(&"star_shard"))
	s.active = s.first_player
	for ps: GameState.PlayerState in s.players:
		ps.mulligan_pending = mulligan
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
	if ps.mulligan_pending:
		# The turn waits for the redraw choice; CHOOSE then starts it for real.
		s.phase = GameState.Phase.CHOOSING
		s.pending_kind = &"mulligan"
		s.pending_player = p
		s.pending_gift = false
		s.pending_choice = ps.hand.duplicate()
		ev.append(GameEvent.make(&"mulligan_offered", {"player": p}))
		return ev
	s.phase = GameState.Phase.MAIN
	ev.append(GameEvent.make(&"turn_started", {"player": p, "turn": s.turn}))
	ps.max_magic = maxi(ps.max_magic, mini(ps.max_magic + 1, ps.magic_cap))
	ps.magic = ps.max_magic
	ps.cards_played = 0
	for sp: int in ps.creature_spots():
		var mine: GameState.CreatureState = ps.at(sp)
		mine.ready = true
		mine.attacks_used = 0
		mine.booped = false
	_run_lane_triggers(s, p, &"start_of_turn", ev)
	_start_of_turn_lands(s, p, ev)
	Fields.run(s, p, &"field_start", ev)
	ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": ps.magic, "max": ps.max_magic}))
	if s.turn != 1:
		draw(s, p, ev)
	resolve_deaths(s, ev)
	return ev


static func draw(s: GameState, p: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	if ps.deck.is_empty():
		# 2, then 3, 4, ...: Grove and Rooted heals can't hold off an empty deck forever.
		var dmg: int = GameState.FATIGUE_DAMAGE + ps.fatigue
		ps.fatigue += 1
		ps.hero_hp -= dmg
		ev.append(GameEvent.make(&"fatigue", {"player": p, "amount": dmg}))
		return
	var c: CardData = ps.deck.pop_back()
	if ps.hand.size() >= GameState.HAND_LIMIT:
		ps.discard.append(c)
		ev.append(GameEvent.make(&"card_burned", {"player": p, "card": c.id}))
	else:
		ps.hand.append(c)
		ev.append(GameEvent.make(&"card_drawn", {"player": p, "card": c.id}))
		if c.has_effect(&"on_draw"):
			# Cards cast when drawn (curses and boons): they act on their drawer, are gone, and the
			# drawer draws another card in their place.
			ps.hand.erase(c)
			ev.append(GameEvent.make(&"curse_triggered" if c.curse else &"drawn_cast", {"player": p, "card": c.id}))
			Effects.run(s, p, -1, c, &"on_draw", [], ev)
			ps.discard.append(c)
			if s.phase != GameState.Phase.OVER and not ps.deck.is_empty():
				draw(s, p, ev)


# --- Validation --------------------------------------------------------------

static func validate(s: GameState, a: Action) -> String:
	if s.phase == GameState.Phase.OVER:
		return "Game is over"
	if s.phase == GameState.Phase.CHOOSING:
		if a.type != Action.Type.CHOOSE:
			return "Choose a card first"
		if a.player != s.pending_player:
			return "Not your choice"
		if s.pending_kind == &"mulligan":
			return _validate_mulligan(s, a.player, a.choice)
		if a.choice < 0 or a.choice >= s.pending_choice.size():
			return "No such card"
		return ""
	if a.player != s.active:
		return "Not your turn"
	match a.type:
		Action.Type.CHOOSE:
			return "Can't do that now"
		Action.Type.PLAY_CARD:
			return _validate_play(s, a)
		Action.Type.BOOP:
			return _validate_boop(s, a)
		Action.Type.ATTACK:
			return _validate_attack(s, a)
	return ""


static func _validate_mulligan(s: GameState, p: int, mask: int) -> String:
	var hand: Array[CardData] = s.players[p].hand
	if mask < 0 or mask >= (1 << hand.size()):
		return "No such card"
	for i: int in hand.size():
		if mask & (1 << i) and hand[i].id == &"star_shard":
			return "The Star Shard stays"
	return ""


static func _validate_attack(s: GameState, a: Action) -> String:
	if a.lane < 0 or a.lane >= GameState.SPOTS or not can_attack(s, a.player, a.lane):
		return "Can't attack"
	var targets: Array[int] = attack_targets(s, a.player, a.lane)
	if a.target_lane in targets:
		return ""
	if a.target_lane >= -1 and a.target_lane < GameState.SPOTS and _guarded(s, s.opponent(a.player)):
		return "Must attack a Guard"
	return "Invalid target"


static func _validate_play(s: GameState, a: Action) -> String:
	if s.phase != GameState.Phase.MAIN:
		return "Can't do that now"
	var ps: GameState.PlayerState = s.players[a.player]
	if a.hand_index < 0 or a.hand_index >= ps.hand.size():
		return "No such card"
	var c: CardData = ps.hand[a.hand_index]
	if card_cost(s, a.player, c) > ps.magic:
		return "Not enough magic"
	if c.kind != CardData.Kind.SPELL:
		if a.lane < 0 or a.lane >= GameState.LANES:
			return "Invalid target"
		var lane: GameState.LaneState = ps.lane(a.lane)
		if c.kind == CardData.Kind.CREATURE and lane.creature != null and not can_merge(s, a.player, a.lane, c):
			return "Lane already has a creature"
		if c.kind == CardData.Kind.BUILDING and lane.building != null:
			return "Lane already has a building"
	# Neutral creatures belong to no land, so they need no lanes of one.
	if c.kind == CardData.Kind.CREATURE and c.land != CardData.Land.NEUTRAL and Lands.count_after_play(s, a.player, a.lane, c.land) < c.level:
		return "Needs %d %s lane%s" % [c.level, CardData.LAND_NAMES[c.land], "" if c.level == 1 else "s"]
	return _validate_targets(s, a.player, _played_form(s, a.player, a.lane, c), &"on_play", a.lane if c.kind != CardData.Kind.SPELL else -1, a.targets)


## True if creature card `c` from player p's hand would merge with p's creature in `lane`.
static func can_merge(s: GameState, p: int, lane: int, c: CardData) -> bool:
	if c == null or c.kind != CardData.Kind.CREATURE or c.merge_with == &"" or lane < 0 or lane >= GameState.LANES:
		return false
	var cr: GameState.CreatureState = s.players[p].at(lane)
	return cr != null and cr.card.id == c.merge_with and CardDB.has_card(c.merges_into)


## The card whose on-play runs when `c` is played into `lane`: its merged form when it merges, else itself.
static func played_form(s: GameState, p: int, lane: int, c: CardData) -> CardData:
	return _played_form(s, p, lane, c)


static func _played_form(s: GameState, p: int, lane: int, c: CardData) -> CardData:
	return CardDB.card(c.merges_into) if can_merge(s, p, lane, c) else c


static func _validate_boop(s: GameState, a: Action) -> String:
	if s.phase != GameState.Phase.MAIN:
		return "Can't do that now"
	if a.lane < 0 or a.lane >= GameState.SPOTS or s.players[a.player].at(a.lane) == null:
		return "No such creature"
	var cr: GameState.CreatureState = s.players[a.player].at(a.lane)
	if not cr.card.has_effect(&"on_boop") or cr.hushed:
		return "No boop ability"
	if cr.is_frozen():
		return "Creature is frozen"
	if cr.booped or cr.attacks_used > 0:
		return "Creature already acted"
	if not cr.ready:
		return "Not ready yet"
	return _validate_targets(s, a.player, cr.card, &"on_boop", a.lane, a.targets)


## Chosen targets for the card's `when` effects (on_play when played, on_boop when booped).
static func _validate_targets(s: GameState, p: int, c: CardData, when: StringName, source_lane: int, targets: Array[Dictionary]) -> String:
	var who: StringName = Targeting.chosen_who(c, when)
	if who == &"":
		return ""
	var valid: Array[Dictionary] = Targeting.valid(s, p, who, source_lane)
	var needed: int = Targeting.needed(who)
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


## Ready, not frozen, hasn't attacked or booped this turn, and has an un-hushed boop.
static func can_boop(s: GameState, p: int, lane: int) -> bool:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	return cr != null and cr.ready and not cr.is_frozen() and not cr.booped \
		and cr.attacks_used == 0 and cr.card.has_effect(&"on_boop") and not cr.hushed


static func matching_lands(s: GameState, p: int, land: int) -> int:
	var n: int = 0
	for lane: GameState.LaneState in s.players[p].lanes:
		if lane.land == land:
			n += 1
	return n


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
			var cr: GameState.CreatureState = s.players[a.player].at(a.lane)
			cr.booped = true
			ev.append(GameEvent.make(&"booped", {"player": a.player, "lane": a.lane}))
			reveal(s, a.player, a.lane, ev)
			Effects.run(s, a.player, a.lane, cr.card, &"on_boop", a.targets, ev)
			resolve_deaths(s, ev)
		Action.Type.ATTACK:
			Combat.resolve(s, a, ev)
		Action.Type.END_TURN:
			_end_turn(s, ev)
		Action.Type.CHOOSE:
			_choose(s, a, ev)
	return ev


static func _choose(s: GameState, a: Action, ev: Array[GameEvent]) -> void:
	if s.pending_kind == &"mulligan":
		_mulligan(s, a.player, a.choice, ev)
		return
	if s.pending_kind == &"direction":
		s.pending_choice = []
		s.pending_player = -1
		s.pending_kind = &""
		s.phase = GameState.Phase.MAIN
		dark_moon(s, a.player, -1 if a.choice == 0 else 1, ev)
		resolve_deaths(s, ev)
		_next_choice(s, ev)
		return
	var c: CardData = s.pending_choice[a.choice]
	var gift: bool = s.pending_gift
	s.pending_choice = []
	s.pending_player = -1
	s.pending_gift = false
	s.phase = GameState.Phase.MAIN
	if gift:
		# The offered cards already carry their gifts (see offer_dream_up).
		var g: StringName = StringName(c.changes.get("gift", &""))
		ev.append(GameEvent.make(&"dark_gift", {"player": a.player, "card": c.id, "gift": g}))
	ev.append(GameEvent.make(&"dream_up_chosen", {"player": a.player, "card": c.id}))
	var ps: GameState.PlayerState = s.players[a.player]
	if ps.hand.size() >= GameState.HAND_LIMIT:
		ps.discard.append(c)
		ev.append(GameEvent.make(&"card_burned", {"player": a.player, "card": c.id}))
	else:
		ps.hand.append(c)
	_next_choice(s, ev)


## Redraws the starting cards marked in `mask` (new cards first, then the old ones shuffle back),
## then starts the turn.
static func _mulligan(s: GameState, p: int, mask: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	s.pending_choice = []
	s.pending_player = -1
	s.pending_kind = &""
	s.phase = GameState.Phase.MAIN
	ps.mulligan_pending = false
	var back: Array[CardData] = []
	for i: int in ps.hand.size():
		if mask & (1 << i) and not ps.deck.is_empty():
			back.append(ps.hand[i])
			ps.hand[i] = ps.deck.pop_back()
	for c: CardData in back:
		ps.deck.insert(s.rng.randi_range(0, ps.deck.size()), c)
	ev.append(GameEvent.make(&"mulligan_done", {"player": p, "count": back.size()}))
	ev.append_array(start_turn(s))


## Opens the next queued choice, if any.
static func _next_choice(s: GameState, ev: Array[GameEvent]) -> void:
	if s.pending_queue.is_empty() or s.phase != GameState.Phase.MAIN:
		return
	var q: Dictionary = s.pending_queue.pop_front()
	if q.get("type", "") == "direction":
		offer_direction(s, int(q["player"]), ev)
	else:
		offer_dream_up(s, int(q["player"]), int(q["kind"]), int(q["land"]), ev, bool(q["gift"]))


## Every legal action for the active player. Used by the AI and tests.
static func legal_actions(s: GameState) -> Array[Action]:
	var out: Array[Action] = []
	var p: int = s.active
	match s.phase:
		GameState.Phase.CHOOSING:
			if s.pending_kind == &"mulligan":
				for mask: int in (1 << s.players[s.pending_player].hand.size()):
					if _validate_mulligan(s, s.pending_player, mask) == "":
						out.append(Action.choose(s.pending_player, mask))
			else:
				for i: int in s.pending_choice.size():
					out.append(Action.choose(s.pending_player, i))
		GameState.Phase.MAIN:
			var hand: Array[CardData] = s.players[p].hand
			for i: int in hand.size():
				var c: CardData = hand[i]
				var lanes: Array[int] = [-1]
				if c.kind != CardData.Kind.SPELL:
					lanes = [0, 1, 2, 3]
				for lane: int in lanes:
					for t: Array[Dictionary] in _target_options(s, p, _played_form(s, p, lane, c), &"on_play", lane):
						var a: Action = Action.play(p, i, lane, t)
						if validate(s, a) == "":
							out.append(a)
			for lane: int in GameState.SPOTS:
				var cr: GameState.CreatureState = s.players[p].at(lane)
				if cr == null or not cr.card.has_effect(&"on_boop"):
					continue
				for t: Array[Dictionary] in _target_options(s, p, cr.card, &"on_boop", lane):
					var a: Action = Action.boop(p, lane, t)
					if validate(s, a) == "":
						out.append(a)
			for lane: int in GameState.SPOTS:
				if can_attack(s, p, lane):
					for t: int in attack_targets(s, p, lane):
						out.append(Action.attack(p, lane, t))
			out.append(Action.end_turn(p))
	return out


static func _target_options(s: GameState, p: int, c: CardData, when: StringName, source_lane: int) -> Array[Array]:
	var out: Array[Array] = []
	var who: StringName = Targeting.chosen_who(c, when)
	if who == &"":
		var empty: Array[Dictionary] = []
		out.append(empty)
		return out
	var valid: Array[Dictionary] = Targeting.valid(s, p, who, source_lane)
	if who == &"chosen_two_own_creatures":
		for i: int in valid.size():
			for j: int in range(i + 1, valid.size()):
				var pair: Array[Dictionary] = [valid[i], valid[j]]
				out.append(pair)
	else:
		for t: Dictionary in valid:
			var one: Array[Dictionary] = [t]
			out.append(one)
	return out


## Ready (or just played with Dash), not frozen or booped, attacks left, and ATK above 0.
static func can_attack(s: GameState, p: int, lane: int) -> bool:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null or cr.is_frozen() or cr.booped:
		return false
	if not cr.ready and not (cr.played_turn == s.turn and has_keyword(s, p, lane, &"dash")):
		return false
	var allowed: int = 2 if has_keyword(s, p, lane, &"flurry") else 1
	return cr.attacks_used < allowed and effective_attack(s, p, lane) > 0


## Enemy lanes this creature may attack, then -1 for the enemy hero (spec 3.4).
static func attack_targets(s: GameState, p: int, lane: int) -> Array[int]:
	var foe: int = s.opponent(p)
	var out: Array[int] = []
	var guarded: bool = _guarded(s, foe)
	for l: int in GameState.SPOTS:
		var cr: GameState.CreatureState = s.players[foe].at(l)
		if cr == null or cr.hidden:
			continue
		if guarded and not has_keyword(s, foe, l, &"guard"):
			continue
		out.append(l)
	var mine: GameState.CreatureState = s.players[p].at(lane)
	if not guarded and mine and mine.ready:
		out.append(-1)
	return out


## True while player p has a Guard that is not Hidden.
static func _guarded(s: GameState, p: int) -> bool:
	for l: int in GameState.SPOTS:
		var cr: GameState.CreatureState = s.players[p].at(l)
		if cr and not cr.hidden and has_keyword(s, p, l, &"guard"):
			return true
	return false


static func _play(s: GameState, a: Action, ev: Array[GameEvent]) -> void:
	var p: int = a.player
	var ps: GameState.PlayerState = s.players[p]
	var c: CardData = ps.hand[a.hand_index]
	var cost: int = card_cost(s, p, c)
	ps.hand.remove_at(a.hand_index)
	if c.kind == CardData.Kind.SPELL:
		ps.spell_discount = 0
	if cost > 0:
		ps.magic -= cost
		ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": ps.magic}))
	var merging: bool = can_merge(s, p, a.lane, c)
	match c.kind:
		CardData.Kind.CREATURE when merging:
			_merge(s, p, a.lane, c, a.targets, ev)
		CardData.Kind.CREATURE:
			enter_creature(s, p, a.lane, c, ev)
			ev.append(GameEvent.make(&"creature_played", {"player": p, "lane": a.lane, "card": c.id}))
			_enter_follower(s, p, a.lane, c, ev)
			Lands.claim(s, p, a.lane, c, ev)
			for i: int in _on_play_times(s, p, c):
				Effects.run(s, p, a.lane, c, &"on_play", a.targets, ev)
		CardData.Kind.BUILDING:
			ps.lane(a.lane).building = c
			ev.append(GameEvent.make(&"building_played", {"player": p, "lane": a.lane, "card": c.id}))
			Lands.claim(s, p, a.lane, c, ev)
			for i: int in _on_play_times(s, p, c):
				Effects.run(s, p, a.lane, c, &"on_play", a.targets, ev)
		CardData.Kind.SPELL:
			ev.append(GameEvent.make(&"spell_cast", {"player": p, "card": c.id}))
			GameHistory.record_spell(ps, c)
			if c.field:
				Fields.set_field(s, p, c, ev)
			var times: int = 1
			if ps.spell_twice > 0:
				ps.spell_twice -= 1
				times = 2
			for i: int in times:
				if i > 0:
					ev.append(GameEvent.make(&"spell_echoed", {"player": p, "card": c.id}))
				Effects.run(s, p, -1, c, &"on_play", a.targets, ev)
			if not c.field:
				ps.discard.append(c)
			_grow_held(s, p, ev)
	ps.cards_played += 1
	if ps.cards_played == 1:
		ev.append(GameEvent.make(&"combo_active", {"player": p}))
	resolve_deaths(s, ev)


## Merges hand card `c` into p's partner in `lane`: the creature becomes the merged form, keeping its damage, level,
## buffs, gained keywords, freeze, hush and readiness; the form's printed Bubble / Hidden switch on and its on-play
## ("When merged") runs. The hand card is absorbed.
## How many times a creature's or building's on-play runs: twice while p has an Echo creature.
static func _on_play_times(s: GameState, p: int, c: CardData) -> int:
	return 2 if c.has_effect(&"on_play") and echoes(s, p) else 1


## True while player p controls an un-hushed creature with the Echo aura.
static func echoes(s: GameState, p: int) -> bool:
	for sp: int in s.players[p].creature_spots():
		var cr: GameState.CreatureState = s.players[p].at(sp)
		if cr.hushed:
			continue
		for e: EffectData in cr.card.effects_for(&"aura"):
			if e.op == &"echo":
				return true
	return false


## True while player p controls an un-hushed creature whose aura doubles Last Breaths.
static func _echoes_death(s: GameState, p: int) -> bool:
	for sp: int in s.players[p].creature_spots():
		var cr: GameState.CreatureState = s.players[p].at(sp)
		if cr.hushed:
			continue
		for e: EffectData in cr.card.effects_for(&"aura"):
			if e.op == &"echo_death":
				return true
	return false


## Brings back up to `n` of p's creatures that died this game (each card once, newest first when
## `last_breath_only`, else random), into empty lanes.
static func resurrect(s: GameState, p: int, n: int, last_breath_only: bool, except: StringName, ev: Array[GameEvent]) -> void:
	var pool: Array[StringName] = []
	for id: Variant in s.players[p].history["dead"]:
		var sid := StringName(id)
		if sid == except or sid in pool or not CardDB.has_card(sid):
			continue
		if last_breath_only and not CardDB.card(sid).has_effect(&"on_destroyed"):
			continue
		pool.append(sid)
	if not last_breath_only:
		for i: int in range(pool.size() - 1, 0, -1):
			var j: int = s.rng.randi_range(0, i)
			var tmp: StringName = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp
	for i: int in mini(n, pool.size()):
		summon(s, p, CardDB.card(pool[i]), -1, ev)


## After p casts a spell: held creatures that grow on spells get their bonus (as changed copies).
static func _grow_held(s: GameState, p: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	for i: int in ps.hand.size():
		for e: EffectData in ps.hand[i].effects_for(&"in_hand"):
			if e.op == &"grow_on_spell":
				ps.hand[i] = CardDB.variant(ps.hand[i], {"attack": e.amount, "health": e.amount2})
				ev.append(GameEvent.make(&"hand_card_grew", {"player": p, "index": i, "card": ps.hand[i].id}))


static func _merge(s: GameState, p: int, lane: int, c: CardData, targets: Array[Dictionary], ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	var into: CardData = CardDB.card(c.merges_into)
	var from: CardData = cr.card
	cr.card = into
	if &"bubble" in into.keywords:
		cr.bubble = true
	if &"hidden" in into.keywords:
		cr.hidden = true
	ev.append(GameEvent.make(&"creature_merged", {"player": p, "lane": lane, "from": from.id, "card": c.id, "into": into.id}))
	for i: int in _on_play_times(s, p, into):
		Effects.run(s, p, lane, into, &"on_play", targets, ev)


static func _end_turn(s: GameState, ev: Array[GameEvent]) -> void:
	var p: int = s.active
	_run_lane_triggers(s, p, &"end_of_turn", ev)
	# Bask: creatures that didn't attack this turn grow +1/+1.
	for l: int in GameState.SPOTS:
		var bk: GameState.CreatureState = s.players[p].at(l)
		if bk and bk.attacks_used == 0 and has_keyword(s, p, l, &"bask"):
			buff(s, p, l, 1, 1, ev)
	Fields.run(s, p, &"field_end", ev)
	for l: int in GameState.SPOTS:
		var mine: GameState.CreatureState = s.players[p].at(l)
		if mine and mine.doomed:
			destroy_creature(s, p, l, ev)
	resolve_deaths(s, ev)
	s.players[p].spell_discount = 0
	for q: int in 2:
		for sp: int in s.players[q].creature_spots():
			s.players[q].at(sp).temp_atk = 0
	if s.phase == GameState.Phase.OVER:
		return
	for l: int in GameState.SPOTS:
		var cr: GameState.CreatureState = s.players[p].at(l)
		if cr == null:
			continue
		if cr.freeze_turn >= 0 and cr.freeze_turn < s.turn:
			cr.freeze_turn = -1
			ev.append(GameEvent.make(&"unfrozen", {"player": p, "lane": l}))
	s.active = s.opponent(p)
	s.turn += 1
	ev.append_array(start_turn(s))


# --- Triggers, stats, damage and deaths --------------------------------------

## Start of p's turn: creatures at home on Mushroom Forest heal 2 (Rooted); Grove heals the hero.
static func _start_of_turn_lands(s: GameState, p: int, ev: Array[GameEvent]) -> void:
	for l: int in GameState.SPOTS:
		var cr: GameState.CreatureState = s.players[p].at(l)
		if cr and cr.damage > 0 and Lands.home(s, p, l) == CardData.Land.MUSHROOM:
			heal_creature(s, p, l, 2, ev)
	# Sun-baked: 1 armour per creature at home on Sunny Dunes.
	var baked: int = 0
	for l: int in GameState.SPOTS:
		if Lands.home(s, p, l) == CardData.Land.DUNES:
			baked += 1
	if baked > 0:
		gain_armour(s, p, baked, ev)
	var grove: int = Tribes.grove_heal(s, p)
	if grove > 0 and s.players[p].hero_hp < GameState.MAX_HP:
		ev.append(GameEvent.make(&"tribe_bonus", {"player": p, "tribe": &"sprout"}))
		heal_hero(s, p, grove, ev)


static func _run_lane_triggers(s: GameState, p: int, trigger: StringName, ev: Array[GameEvent]) -> void:
	for l: int in GameState.LANES:
		var b: CardData = s.players[p].lane(l).building
		if b:
			Effects.run(s, p, l, b, trigger, [], ev)


## Printed ATK plus buffs, building auras, home (Fired up, Plump), tribe (Pack), level and field.
static func effective_attack(s: GameState, p: int, lane: int) -> int:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return 0
	var atk: int = cr.card.attack + cr.atk_bonus + cr.temp_atk + _aura(s, p, lane, &"lane_atk") - _aura(s, s.opponent(p), lane, &"opposing_atk")
	var home: int = Lands.home(s, p, lane)
	if home == CardData.Land.EMBER or home == CardData.Land.CANDY:
		atk += 1
	atk += Tribes.atk_bonus(s, p, lane) + Levels.bonus(cr) + Fields.atk_bonus(s, p, lane)
	return maxi(atk, 0)


## Printed HP plus buffs, building auras, home (Plump), tribe (Squish), level and field.
static func effective_max_hp(s: GameState, p: int, lane: int) -> int:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return 0
	var hp: int = cr.card.health + cr.hp_bonus + _aura(s, p, lane, &"lane_hp")
	if Lands.home(s, p, lane) == CardData.Land.CANDY:
		hp += 1
	return hp + Tribes.hp_bonus(s, p, lane) + Levels.bonus(cr) + Fields.hp_bonus(s, p, lane)


## Sum of a building aura's amounts in player p's lane.
static func _aura(s: GameState, p: int, lane: int, op: StringName) -> int:
	var b: CardData = s.players[p].lane(lane).building
	var n: int = 0
	if b:
		for e: EffectData in b.effects:
			if e.when == &"aura" and e.op == op:
				n += e.amount
	return n


## Damage taken from attacks and hit-back is reduced by this (Ice Wall), to a minimum of 1.
## Ice Wall's aura plus the Ice skin home quirk.
static func damage_reduction(s: GameState, p: int, lane: int) -> int:
	var n: int = _aura(s, p, lane, &"lane_damage_taken")
	if Lands.home(s, p, lane) == CardData.Land.FROST:
		n += 1
	return n


static func keywords_of(s: GameState, p: int, lane: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return out
	if not cr.hushed:
		for k: StringName in cr.card.keywords:
			if not (k == &"second_wind" and cr.second_wind_used):
				out.append(k)
	for k: StringName in cr.gained:
		if not k in out:
			out.append(k)
	var b: CardData = s.players[p].lane(lane).building
	if b:
		for e: EffectData in b.effects:
			if e.when == &"aura" and e.op == &"lane_keyword" and not e.keyword in out:
				out.append(e.keyword)
	return out


static func has_keyword(s: GameState, p: int, lane: int, kw: StringName) -> bool:
	return kw in keywords_of(s, p, lane)


## Bonus damage for player p's spells: the sum over their un-hushed creatures.
static func spell_power(s: GameState, p: int) -> int:
	var n: int = 0
	for sp: int in s.players[p].creature_spots():
		var cr: GameState.CreatureState = s.players[p].at(sp)
		if not cr.hushed:
			n += cr.card.spell_power
	return n + Tribes.spell_power(s, p)


## Puts a fresh creature into a lane (played, or back from Second Wind). Not ready yet.
static func enter_creature(s: GameState, p: int, lane: int, c: CardData, _ev: Array[GameEvent]) -> GameState.CreatureState:
	var cr := GameState.CreatureState.new()
	cr.card = c
	cr.played_turn = s.turn
	cr.ready = false
	cr.bubble = &"bubble" in c.keywords
	cr.hidden = &"hidden" in c.keywords
	s.players[p].put(lane, cr)
	return cr


## Damage to a creature from `src` = {"player", "lane" (-1: not a creature), "kind":
## attack | hit_back | ability | spell}. Applies Bubble, Venom, Leech and the source's
## after_damage effects. Returns the damage dealt.
static func damage_creature(s: GameState, p: int, lane: int, amount: int, src: Dictionary, ev: Array[GameEvent], hit: Action.Hit = Action.Hit.NORMAL, blocked: bool = false) -> int:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return 0
	var dealt: int = maxi(amount, 0)
	# Sturdy: every hit is 1 smaller (it can be blocked completely).
	if dealt > 0 and has_keyword(s, p, lane, &"sturdy"):
		dealt -= 1
	if dealt > 0 and cr.bubble:
		cr.bubble = false
		ev.append(GameEvent.make(&"bubble_popped", {"player": p, "lane": lane}))
		dealt = 0
	var sp: int = int(src.get("player", -1))
	var sl: int = int(src.get("lane", -1))
	var sc: GameState.CreatureState = s.players[sp].at(sl) if sp >= 0 and sl >= 0 else null
	var venom: bool = false
	if dealt > 0:
		cr.damage += dealt
		if sc and has_keyword(s, sp, sl, &"venom"):
			venom = true
			cr.damage = maxi(cr.damage, effective_max_hp(s, p, lane))
	ev.append(GameEvent.make(&"creature_damaged", {"player": p, "lane": lane, "amount": dealt, "hit": int(hit), "blocked": blocked, "kind": src.get("kind", &"ability"), "venom": venom}))
	if dealt > 0 and sc:
		_leech(s, sp, sl, dealt, ev)
		Effects.run(s, sp, sl, sc.card, &"after_damage", [], ev, {"damaged": {"player": p, "lane": lane}})
	# "After this takes damage" (Pain Shroom, Emberkit): the damaged creature's own trigger.
	if dealt > 0 and s.players[p].at(lane) == cr:
		Effects.run(s, p, lane, cr.card, &"on_hurt", [], ev)
	return dealt


static func _leech(s: GameState, sp: int, sl: int, dealt: int, ev: Array[GameEvent]) -> void:
	if has_keyword(s, sp, sl, &"leech"):
		ev.append(GameEvent.make(&"leeched", {"player": sp, "lane": sl, "amount": dealt}))
		heal_hero(s, sp, dealt, ev)


## Removes keywords, effects, stat changes and freeze (spec 4.2). Damage stays.
static func hush(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return
	cr.hushed = true
	cr.gained.clear()
	cr.atk_bonus = 0
	cr.hp_bonus = 0
	cr.bubble = false
	cr.hidden = false
	cr.freeze_turn = -1
	ev.append(GameEvent.make(&"hushed", {"player": p, "lane": lane}))


static func give_keyword(s: GameState, p: int, lane: int, kw: StringName, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return
	if not kw in cr.gained:
		cr.gained.append(kw)
	if kw == &"bubble":
		cr.bubble = true
	elif kw == &"hidden":
		cr.hidden = true
	ev.append(GameEvent.make(&"keyword_gained", {"player": p, "lane": lane, "keyword": kw}))


static func buff(s: GameState, p: int, lane: int, atk: int, hp: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return
	cr.atk_bonus += atk
	cr.hp_bonus += hp
	ev.append(GameEvent.make(&"buffed", {"player": p, "lane": lane, "atk": atk, "hp": hp}))


## Marks a creature to die; resolve_deaths removes it.
static func destroy_creature(s: GameState, p: int, lane: int, _ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr:
		cr.damage = maxi(cr.damage, effective_max_hp(s, p, lane))


static func reveal(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr and cr.hidden:
		cr.hidden = false
		ev.append(GameEvent.make(&"revealed", {"player": p, "lane": lane}))


## Offers up to 3 different random cards matching the filter; play waits for CHOOSE.
## A Dark Gift (`gift`) offers creatures, each already carrying a different Gifts bonus that the
## chooser can see. While another choice is open, the offer waits in the queue.
static func offer_dream_up(s: GameState, p: int, filter_kind: int, filter_land: int, ev: Array[GameEvent], gift: bool = false) -> void:
	if s.phase == GameState.Phase.CHOOSING:
		s.pending_queue.append({"player": p, "kind": filter_kind, "land": filter_land, "gift": gift})
		return
	var pool: Array[CardData] = CardDB.dream_up_pool(CardData.Kind.CREATURE if gift else filter_kind, filter_land)
	if pool.is_empty():
		return
	_shuffle(s, pool)
	s.pending_choice = pool.slice(0, mini(3, pool.size()))
	if gift:
		var gifts: Array[StringName] = Gifts.ORDER.duplicate()
		for i: int in range(gifts.size() - 1, 0, -1):
			var j: int = s.rng.randi_range(0, i)
			var t: StringName = gifts[i]
			gifts[i] = gifts[j]
			gifts[j] = t
		for i: int in s.pending_choice.size():
			s.pending_choice[i] = CardDB.variant(s.pending_choice[i], Gifts.delta(gifts[i]))
	s.pending_player = p
	s.pending_gift = gift
	s.phase = GameState.Phase.CHOOSING
	var ids: Array[StringName] = []
	for c: CardData in s.pending_choice:
		ids.append(c.id)
	ev.append(GameEvent.make(&"dream_up_offered", {"player": p, "cards": ids}))


static func heal_creature(s: GameState, p: int, lane: int, amount: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return
	var healed: int = mini(amount, cr.damage)
	cr.damage -= healed
	ev.append(GameEvent.make(&"creature_healed", {"player": p, "lane": lane, "amount": healed}))


## Armour soaks the damage first; "amount" in the event is the HP lost, "armour" what armour took.
static func damage_hero(s: GameState, p: int, amount: int, ev: Array[GameEvent], src: Dictionary = {}) -> void:
	var ps: GameState.PlayerState = s.players[p]
	var soaked: int = mini(ps.armour, maxi(amount, 0))
	ps.armour -= soaked
	ps.hero_hp -= amount - soaked
	if amount > 0:
		ps.history["hero_hits"] = int(ps.history.get("hero_hits", 0)) + 1
	ev.append(GameEvent.make(&"hero_damaged", {"player": p, "amount": amount - soaked, "armour": soaked}))
	var sp: int = int(src.get("player", -1))
	var sl: int = int(src.get("lane", -1))
	if amount > 0 and sp >= 0 and sl >= 0 and s.players[sp].at(sl):
		_leech(s, sp, sl, amount, ev)


static func gain_armour(s: GameState, p: int, amount: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	var before: int = ps.armour
	ps.armour = mini(GameState.MAX_ARMOUR, ps.armour + maxi(amount, 0))
	ev.append(GameEvent.make(&"armour_gained", {"player": p, "amount": ps.armour - before, "total": ps.armour}))


static func heal_hero(s: GameState, p: int, amount: int, ev: Array[GameEvent]) -> void:
	var before: int = s.players[p].hero_hp
	s.players[p].hero_hp = mini(GameState.MAX_HP, before + amount)
	ev.append(GameEvent.make(&"hero_healed", {"player": p, "amount": s.players[p].hero_hp - before}))


static func freeze(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
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


## What `c` costs player p right now: spells get the pending spell discount (never below 0).
static func card_cost(s: GameState, p: int, c: CardData) -> int:
	var cost: int = c.cost
	for e: EffectData in c.effects_for(&"in_hand"):
		if e.op == &"cost_per_death":
			cost -= e.amount * GameHistory.deaths_all(s)
	if c.kind == CardData.Kind.SPELL:
		cost -= s.players[p].spell_discount
	return maxi(cost, 0)


## Takes a creature off the board back to its owner's hand (discarded if the hand is full). Not a death.
static func bounce_creature(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	if cr == null:
		return
	s.players[p].put(lane, null)
	ev.append(GameEvent.make(&"creature_bounced", {"player": p, "lane": lane, "card": cr.card.id}))
	# A pack goes back as one card: its follower token leaves too. A follower alone just leaves.
	var fol: GameState.CreatureState = s.players[p].at(lane + GameState.LANES) if lane < GameState.LANES else null
	if fol:
		s.players[p].put(lane + GameState.LANES, null)
		ev.append(GameEvent.make(&"creature_bounced", {"player": p, "lane": lane + GameState.LANES, "card": fol.card.id}))
	if not GameState.is_follower(lane):
		return_to_hand(s, p, cr.card, ev)


## Turns a creature into `into` where it stands: a fresh creature (no damage, buffs, keywords or level) that keeps
## its readiness for this turn.
static func transform_creature(s: GameState, p: int, lane: int, into: CardData, ev: Array[GameEvent]) -> void:
	var old: GameState.CreatureState = s.players[p].at(lane)
	if old == null:
		return
	var cr: GameState.CreatureState = enter_creature(s, p, lane, into, ev)
	cr.played_turn = old.played_turn
	cr.ready = old.ready
	cr.attacks_used = old.attacks_used
	cr.booped = old.booped
	ev.append(GameEvent.make(&"creature_transformed", {"player": p, "lane": lane, "from": old.card.id, "card": into.id}))


## A pack card's follower token enters the lane's follower spot.
static func _enter_follower(s: GameState, p: int, lane: int, c: CardData, ev: Array[GameEvent]) -> void:
	if c.follower_id == &"" or not CardDB.has_card(c.follower_id) or s.players[p].at(lane + GameState.LANES) != null:
		return
	var tok: CardData = CardDB.card(c.follower_id)
	enter_creature(s, p, lane + GameState.LANES, tok, ev)
	ev.append(GameEvent.make(&"follower_entered", {"player": p, "lane": lane + GameState.LANES, "card": tok.id, "leader": c.id}))


## After a lane's main creature left: its follower (if any) becomes the main creature.
static func _promote_follower(s: GameState, p: int, spot: int, ev: Array[GameEvent]) -> void:
	if GameState.is_follower(spot) or s.players[p].at(spot) != null:
		return
	var fol: GameState.CreatureState = s.players[p].at(spot + GameState.LANES)
	if fol == null:
		return
	s.players[p].put(spot + GameState.LANES, null)
	s.players[p].put(spot, fol)
	ev.append(GameEvent.make(&"follower_promoted", {"player": p, "from": spot + GameState.LANES, "to": spot}))


## Moves the creatures at `from` to the empty lane `to`: a main creature brings its follower; a
## follower alone becomes the main creature there.
static func move_unit(s: GameState, p: int, from: int, to: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	if ps.at(from) == null or to < 0 or to >= GameState.LANES or ps.at(to) != null:
		return
	ps.put(to, ps.at(from))
	ps.put(from, null)
	ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": from, "to": to}))
	if not GameState.is_follower(from):
		var fol: GameState.CreatureState = ps.at(from + GameState.LANES)
		if fol:
			ps.put(to + GameState.LANES, fol)
			ps.put(from + GameState.LANES, null)
			ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": from + GameState.LANES, "to": to + GameState.LANES}))


## `total` single hits, each on a random living enemy (creature or hero) of p.
static func split_damage(s: GameState, p: int, total: int, src: Dictionary, ev: Array[GameEvent]) -> void:
	var foe: int = s.opponent(p)
	for i: int in total:
		if s.phase == GameState.Phase.OVER or _hero_down(s):
			return
		var pool: Array[int] = [-1]
		for sp: int in s.players[foe].creature_spots():
			if s.players[foe].at(sp).damage < effective_max_hp(s, foe, sp):
				pool.append(sp)
		var pick: int = pool[s.rng.randi_range(0, pool.size() - 1)]
		if pick < 0:
			damage_hero(s, foe, 1, ev, src)
		else:
			damage_creature(s, foe, pick, 1, src, ev)


## Casts again every spell p cast this game (of `land`, -1 any) on random legal targets. Cards that
## replay spells are skipped, and replays don't count as new casts.
static func replay_spells(s: GameState, p: int, land: int, ev: Array[GameEvent]) -> void:
	var ids: Array = (s.players[p].history["spells"] as Array).duplicate()
	for id: Variant in ids:
		if s.phase == GameState.Phase.OVER or _hero_down(s):
			return
		if not CardDB.has_card(StringName(id)):
			continue
		var c: CardData = CardDB.card(StringName(id))
		if c.field or (land >= 0 and c.land != land) or _replays(c):
			continue
		var targets: Array[Dictionary] = []
		var who: StringName = Targeting.chosen_who(c, &"on_play")
		if who != &"":
			var valid: Array[Dictionary] = Targeting.valid(s, p, who, -1)
			var needed: int = Targeting.needed(who)
			if valid.size() < needed:
				continue
			_shuffle_dicts(s, valid)
			targets.assign(valid.slice(0, needed))
		ev.append(GameEvent.make(&"spell_replayed", {"player": p, "card": c.id}))
		Effects.run(s, p, -1, c, &"on_play", targets, ev)
		resolve_deaths(s, ev)


static func _replays(c: CardData) -> bool:
	for e: EffectData in c.effects:
		if e.op == &"replay_spells":
			return true
	return false


static func _shuffle_dicts(s: GameState, arr: Array[Dictionary]) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = s.rng.randi_range(0, i)
		var tmp: Dictionary = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## A made card goes to p's hand (burned if the hand is full).
static func add_to_hand(s: GameState, p: int, c: CardData, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	if ps.hand.size() >= GameState.HAND_LIMIT:
		ps.discard.append(c)
		ev.append(GameEvent.make(&"card_burned", {"player": p, "card": c.id}))
	else:
		ps.hand.append(c)
		ev.append(GameEvent.make(&"card_added", {"player": p, "card": c.id}))


## `n` copies of `c` into p's deck at random places.
static func shuffle_into_deck(s: GameState, p: int, c: CardData, n: int, ev: Array[GameEvent]) -> void:
	var deck: Array[CardData] = s.players[p].deck
	for i: int in n:
		deck.insert(s.rng.randi_range(0, deck.size()), c)
	ev.append(GameEvent.make(&"shuffled_in", {"player": p, "card": c.id, "count": n}))


## Puts `c` on p's board without playing it (no on-play): into lane `prefer` if empty, else the
## first empty lane from the left. Nothing happens when every lane is full.
static func summon(s: GameState, p: int, c: CardData, prefer: int, ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	var lane: int = -1
	if prefer >= 0 and ps.at(GameState.lane_of(prefer)) == null:
		lane = GameState.lane_of(prefer)
	else:
		for l: int in GameState.LANES:
			if ps.at(l) == null:
				lane = l
				break
	if lane < 0:
		return
	enter_creature(s, p, lane, c, ev)
	ev.append(GameEvent.make(&"creature_summoned", {"player": p, "lane": lane, "card": c.id}))
	_enter_follower(s, p, lane, c, ev)


# --- Dark Moon and stealing (Dark Moon spec 2.2, 2.3) ------------------------

## The ring of the 8 lands as seen by player p: p's lanes left to right, then the rival's right to
## left. Each entry is [player, lane].
static func ring(p: int) -> Array:
	var q: int = 1 - p
	return [[p, 0], [p, 1], [p, 2], [p, 3], [q, 3], [q, 2], [q, 1], [q, 0]]


## Dark Moon asks p for a direction: choice 0 = left, 1 = right.
static func offer_direction(s: GameState, p: int, ev: Array[GameEvent]) -> void:
	if s.phase == GameState.Phase.CHOOSING:
		s.pending_queue.append({"type": "direction", "player": p})
		return
	s.pending_choice = [CardDB.card(&"moon_left"), CardDB.card(&"moon_right")]
	s.pending_player = p
	s.pending_kind = &"direction"
	s.pending_gift = false
	s.phase = GameState.Phase.CHOOSING
	ev.append(GameEvent.make(&"direction_offered", {"player": p}))


## Every lane's creatures (main + follower as one) move to the next occupied land along p's ring
## (dir 1 = right, -1 = left), once. Crossing sides changes owner; such creatures can't attack this
## turn. Buildings stay.
static func dark_moon(s: GameState, p: int, dir: int, ev: Array[GameEvent]) -> void:
	var places: Array = []
	for at: Array in ring(p):
		if s.players[at[0]].at(at[1]) != null:
			places.append(at)
	var moves: Array[Dictionary] = []
	if places.size() >= 2:
		var units: Array = []
		for at: Array in places:
			var l: GameState.LaneState = s.players[at[0]].lanes[at[1]]
			units.append([l.creature, l.follower])
			l.creature = null
			l.follower = null
		var n: int = places.size()
		for i: int in n:
			var to: Array = places[posmod(i + dir, n)]
			var from: Array = places[i]
			var u: Array = units[i]
			var l: GameState.LaneState = s.players[to[0]].lanes[to[1]]
			l.creature = u[0]
			l.follower = u[1]
			if to[0] != from[0]:
				for cr: Variant in u:
					if cr:
						(cr as GameState.CreatureState).ready = false
			moves.append({"from_player": from[0], "from_lane": from[1], "to_player": to[0], "to_lane": to[1]})
	ev.append(GameEvent.make(&"dark_moon", {"player": p, "dir": dir, "moves": moves}))


## p takes `n` cards from the rival's hand: random ones, or the most expensive (`priciest`).
static func steal_from_hand(s: GameState, p: int, n: int, priciest: bool, ev: Array[GameEvent]) -> void:
	var foe: GameState.PlayerState = s.players[s.opponent(p)]
	for i: int in n:
		if foe.hand.is_empty():
			return
		var k: int = 0
		if priciest:
			for j: int in foe.hand.size():
				if foe.hand[j].cost > foe.hand[k].cost:
					k = j
		else:
			k = s.rng.randi_range(0, foe.hand.size() - 1)
		var c: CardData = foe.hand[k]
		foe.hand.remove_at(k)
		ev.append(GameEvent.make(&"card_stolen", {"player": p, "from": s.opponent(p), "card": c.id}))
		GameHistory.record_steal(s.players[p])
		add_to_hand(s, p, c, ev)


## p gets copies of `n` random cards from the rival's hand or deck (they keep theirs).
static func copy_rival_card(s: GameState, p: int, n: int, ev: Array[GameEvent]) -> void:
	var foe: GameState.PlayerState = s.players[s.opponent(p)]
	var pool: Array[CardData] = foe.hand + foe.deck
	for i: int in n:
		if pool.is_empty():
			return
		var c: CardData = pool[s.rng.randi_range(0, pool.size() - 1)]
		ev.append(GameEvent.make(&"card_copied", {"player": p, "from": s.opponent(p), "card": c.id}))
		add_to_hand(s, p, c, ev)


## p takes control of the rival's creature at `spot` (with its follower if it is a main creature)
## into p's first empty lane. Nothing happens without an empty lane.
static func steal_creature(s: GameState, p: int, q: int, spot: int, ev: Array[GameEvent]) -> void:
	var to: int = -1
	for l: int in GameState.LANES:
		if s.players[p].at(l) == null:
			to = l
			break
	if to < 0 or s.players[q].at(spot) == null:
		return
	var cr: GameState.CreatureState = s.players[q].at(spot)
	var fol: GameState.CreatureState = s.players[q].at(spot + GameState.LANES) if not GameState.is_follower(spot) else null
	s.players[q].put(spot, null)
	cr.ready = false
	s.players[p].put(to, cr)
	if fol:
		s.players[q].put(spot + GameState.LANES, null)
		fol.ready = false
		s.players[p].put(to + GameState.LANES, fol)
	ev.append(GameEvent.make(&"creature_stolen", {"player": p, "from_player": q, "from_lane": spot, "to_lane": to, "card": cr.card.id}))
	GameHistory.record_steal(s.players[p])
	_promote_follower(s, q, spot, ev)


## "Whenever a creature dies": every creature still on the board with an on_any_death step.
static func _any_death(s: GameState, ev: Array[GameEvent]) -> void:
	for q: int in [s.active, s.opponent(s.active)]:
		for l: int in GameState.SPOTS:
			var cr: GameState.CreatureState = s.players[q].at(l)
			if cr and not cr.hushed and cr.damage < effective_max_hp(s, q, l) and cr.card.has_effect(&"on_any_death"):
				Effects.run(s, q, l, cr.card, &"on_any_death", [], ev)


static func _hero_down(s: GameState) -> bool:
	return s.players[0].hero_hp <= 0 or s.players[1].hero_hp <= 0


static func resolve_deaths(s: GameState, ev: Array[GameEvent]) -> void:
	if s.phase == GameState.Phase.OVER:
		return
	var any: bool = true
	while any and not _hero_down(s):
		any = false
		for p: int in [s.active, s.opponent(s.active)]:
			for l: int in GameState.SPOTS:
				if _hero_down(s):
					break
				var cr: GameState.CreatureState = s.players[p].at(l)
				if cr and cr.damage >= effective_max_hp(s, p, l):
					any = true
					var second_wind: bool = has_keyword(s, p, l, &"second_wind") and not cr.second_wind_used
					s.players[p].put(l, null)
					s.players[p].discard.append(cr.card)
					ev.append(GameEvent.make(&"creature_destroyed", {"player": p, "lane": l, "card": cr.card.id}))
					GameHistory.record_death(s.players[p], cr.card)
					_promote_follower(s, p, l, ev)
					if not cr.hushed and cr.card.has_effect(&"on_destroyed"):
						ev.append(GameEvent.make(&"last_breath", {"player": p, "lane": l, "card": cr.card.id}))
					if not cr.hushed:
						for i: int in (2 if _echoes_death(s, p) else 1):
							Effects.run(s, p, l, cr.card, &"on_destroyed", [], ev)
					if not _hero_down(s):
						_any_death(s, ev)
					if second_wind and not _hero_down(s) and s.players[p].at(l) == null:
						s.players[p].discard.erase(cr.card)
						var back: GameState.CreatureState = enter_creature(s, p, l, cr.card, ev)
						back.second_wind_used = true
						back.damage = effective_max_hp(s, p, l) - 1
						ev.append(GameEvent.make(&"second_wind", {"player": p, "lane": l, "card": cr.card.id}))
	var dead: Array[bool] = [s.players[0].hero_hp <= 0, s.players[1].hero_hp <= 0]
	if dead[0] or dead[1]:
		s.phase = GameState.Phase.OVER
		s.winner = s.active if (dead[0] and dead[1]) else (1 if dead[0] else 0)
		ev.append(GameEvent.make(&"game_over", {"winner": s.winner}))
