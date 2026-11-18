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
			# Every lane starts bare; cards claim them (living board spec 2).
			lane.land = Lands.MEADOW
			ps.lanes.append(lane)
		ps.deck = deck.cards.duplicate()
		_shuffle(s, ps.deck)
		s.players.append(ps)
	for p: int in 2:
		for i: int in GameState.START_HAND:
			s.players[p].hand.append(s.players[p].deck.pop_back())
	s.first_player = s.rng.randi_range(0, 1)
	# Going second: a Star Shard to make up for it (spec 3.1).
	s.players[1 - s.first_player].hand.append(CardDB.card(&"star_shard"))
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
	ps.max_magic = maxi(ps.max_magic, mini(ps.max_magic + 1, ps.magic_cap))
	ps.magic = ps.max_magic
	ps.cards_played = 0
	for lane: GameState.LaneState in ps.lanes:
		if lane.creature:
			lane.creature.ready = true
			lane.creature.attacks_used = 0
			lane.creature.booped = false
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


# --- Validation --------------------------------------------------------------

static func validate(s: GameState, a: Action) -> String:
	if s.phase == GameState.Phase.OVER:
		return "Game is over"
	if s.phase == GameState.Phase.CHOOSING:
		if a.type != Action.Type.CHOOSE:
			return "Choose a card first"
		if a.player != s.pending_player:
			return "Not your choice"
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


static func _validate_attack(s: GameState, a: Action) -> String:
	if a.lane < 0 or a.lane >= GameState.LANES or not can_attack(s, a.player, a.lane):
		return "Can't attack"
	var targets: Array[int] = attack_targets(s, a.player, a.lane)
	if a.target_lane in targets:
		return ""
	if a.target_lane >= -1 and a.target_lane < GameState.LANES and _guarded(s, s.opponent(a.player)):
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
		var lane: GameState.LaneState = ps.lanes[a.lane]
		if c.kind == CardData.Kind.CREATURE and lane.creature != null:
			return "Lane already has a creature"
		if c.kind == CardData.Kind.BUILDING and lane.building != null:
			return "Lane already has a building"
	if c.kind == CardData.Kind.CREATURE and Lands.count_after_play(s, a.player, a.lane, c.land) < c.level:
		return "Needs %d %s lane%s" % [c.level, CardData.LAND_NAMES[c.land], "" if c.level == 1 else "s"]
	return _validate_targets(s, a.player, c, &"on_play", a.lane if c.kind != CardData.Kind.SPELL else -1, a.targets)


static func _validate_boop(s: GameState, a: Action) -> String:
	if s.phase != GameState.Phase.MAIN:
		return "Can't do that now"
	if a.lane < 0 or a.lane >= GameState.LANES or s.players[a.player].lanes[a.lane].creature == null:
		return "No such creature"
	var cr: GameState.CreatureState = s.players[a.player].lanes[a.lane].creature
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
			var cr: GameState.CreatureState = s.players[a.player].lanes[a.lane].creature
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
	var c: CardData = s.pending_choice[a.choice]
	s.pending_choice = []
	s.pending_player = -1
	s.phase = GameState.Phase.MAIN
	ev.append(GameEvent.make(&"dream_up_chosen", {"player": a.player, "card": c.id}))
	var ps: GameState.PlayerState = s.players[a.player]
	if ps.hand.size() >= GameState.HAND_LIMIT:
		ps.discard.append(c)
		ev.append(GameEvent.make(&"card_burned", {"player": a.player, "card": c.id}))
	else:
		ps.hand.append(c)


## Every legal action for the active player. Used by the AI and tests.
static func legal_actions(s: GameState) -> Array[Action]:
	var out: Array[Action] = []
	var p: int = s.active
	match s.phase:
		GameState.Phase.CHOOSING:
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
					for t: Array[Dictionary] in _target_options(s, p, c, &"on_play", lane):
						var a: Action = Action.play(p, i, lane, t)
						if validate(s, a) == "":
							out.append(a)
			for lane: int in GameState.LANES:
				var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
				if cr == null or not cr.card.has_effect(&"on_boop"):
					continue
				for t: Array[Dictionary] in _target_options(s, p, cr.card, &"on_boop", lane):
					var a: Action = Action.boop(p, lane, t)
					if validate(s, a) == "":
						out.append(a)
			for lane: int in GameState.LANES:
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[foe].lanes[l].creature
		if cr == null or cr.hidden:
			continue
		if guarded and not has_keyword(s, foe, l, &"guard"):
			continue
		out.append(l)
	var mine: GameState.CreatureState = s.players[p].lanes[lane].creature
	if not guarded and mine and mine.ready:
		out.append(-1)
	return out


## True while player p has a Guard that is not Hidden.
static func _guarded(s: GameState, p: int) -> bool:
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[p].lanes[l].creature
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
	match c.kind:
		CardData.Kind.CREATURE:
			enter_creature(s, p, a.lane, c, ev)
			ev.append(GameEvent.make(&"creature_played", {"player": p, "lane": a.lane, "card": c.id}))
			Lands.claim(s, p, a.lane, c, ev)
			Effects.run(s, p, a.lane, c, &"on_play", a.targets, ev)
		CardData.Kind.BUILDING:
			ps.lanes[a.lane].building = c
			ev.append(GameEvent.make(&"building_played", {"player": p, "lane": a.lane, "card": c.id}))
			Lands.claim(s, p, a.lane, c, ev)
			Effects.run(s, p, a.lane, c, &"on_play", a.targets, ev)
		CardData.Kind.SPELL:
			ev.append(GameEvent.make(&"spell_cast", {"player": p, "card": c.id}))
			if c.field:
				Fields.set_field(s, p, c, ev)
			Effects.run(s, p, -1, c, &"on_play", a.targets, ev)
			if not c.field:
				ps.discard.append(c)
	ps.cards_played += 1
	if ps.cards_played == 1:
		ev.append(GameEvent.make(&"combo_active", {"player": p}))
	resolve_deaths(s, ev)


static func _end_turn(s: GameState, ev: Array[GameEvent]) -> void:
	var p: int = s.active
	_run_lane_triggers(s, p, &"end_of_turn", ev)
	Fields.run(s, p, &"field_end", ev)
	for l: int in GameState.LANES:
		var mine: GameState.CreatureState = s.players[p].lanes[l].creature
		if mine and mine.doomed:
			destroy_creature(s, p, l, ev)
	resolve_deaths(s, ev)
	s.players[p].spell_discount = 0
	for q: int in 2:
		for lane: GameState.LaneState in s.players[q].lanes:
			if lane.creature:
				lane.creature.temp_atk = 0
	if s.phase == GameState.Phase.OVER:
		return
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[p].lanes[l].creature
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
	for l: int in GameState.LANES:
		var cr: GameState.CreatureState = s.players[p].lanes[l].creature
		if cr and cr.damage > 0 and Lands.home(s, p, l) == CardData.Land.MUSHROOM:
			heal_creature(s, p, l, 2, ev)
	var grove: int = Tribes.grove_heal(s, p)
	if grove > 0 and s.players[p].hero_hp < GameState.MAX_HP:
		ev.append(GameEvent.make(&"tribe_bonus", {"player": p, "tribe": &"sprout"}))
		heal_hero(s, p, grove, ev)


static func _run_lane_triggers(s: GameState, p: int, trigger: StringName, ev: Array[GameEvent]) -> void:
	for l: int in GameState.LANES:
		var b: CardData = s.players[p].lanes[l].building
		if b:
			Effects.run(s, p, l, b, trigger, [], ev)


## Printed ATK plus buffs, building auras, home (Fired up, Plump), tribe (Pack), level and field.
static func effective_attack(s: GameState, p: int, lane: int) -> int:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return 0
	var hp: int = cr.card.health + cr.hp_bonus + _aura(s, p, lane, &"lane_hp")
	if Lands.home(s, p, lane) == CardData.Land.CANDY:
		hp += 1
	return hp + Tribes.hp_bonus(s, p, lane) + Levels.bonus(cr) + Fields.hp_bonus(s, p, lane)


## Sum of a building aura's amounts in player p's lane.
static func _aura(s: GameState, p: int, lane: int, op: StringName) -> int:
	var b: CardData = s.players[p].lanes[lane].building
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return out
	if not cr.hushed:
		for k: StringName in cr.card.keywords:
			if not (k == &"second_wind" and cr.second_wind_used):
				out.append(k)
	for k: StringName in cr.gained:
		if not k in out:
			out.append(k)
	var b: CardData = s.players[p].lanes[lane].building
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
	for lane: GameState.LaneState in s.players[p].lanes:
		if lane.creature and not lane.creature.hushed:
			n += lane.creature.card.spell_power
	return n + Tribes.spell_power(s, p)


## Puts a fresh creature into a lane (played, or back from Second Wind). Not ready yet.
static func enter_creature(s: GameState, p: int, lane: int, c: CardData, _ev: Array[GameEvent]) -> GameState.CreatureState:
	var cr := GameState.CreatureState.new()
	cr.card = c
	cr.played_turn = s.turn
	cr.ready = false
	cr.bubble = &"bubble" in c.keywords
	cr.hidden = &"hidden" in c.keywords
	s.players[p].lanes[lane].creature = cr
	return cr


## Damage to a creature from `src` = {"player", "lane" (-1: not a creature), "kind":
## attack | hit_back | ability | spell}. Applies Bubble, Venom, Leech and the source's
## after_damage effects. Returns the damage dealt.
static func damage_creature(s: GameState, p: int, lane: int, amount: int, src: Dictionary, ev: Array[GameEvent], hit: Action.Hit = Action.Hit.NORMAL, blocked: bool = false) -> int:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return 0
	var dealt: int = maxi(amount, 0)
	if dealt > 0 and cr.bubble:
		cr.bubble = false
		ev.append(GameEvent.make(&"bubble_popped", {"player": p, "lane": lane}))
		dealt = 0
	var sp: int = int(src.get("player", -1))
	var sl: int = int(src.get("lane", -1))
	var sc: GameState.CreatureState = s.players[sp].lanes[sl].creature if sp >= 0 and sl >= 0 else null
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
	return dealt


static func _leech(s: GameState, sp: int, sl: int, dealt: int, ev: Array[GameEvent]) -> void:
	if has_keyword(s, sp, sl, &"leech"):
		ev.append(GameEvent.make(&"leeched", {"player": sp, "lane": sl, "amount": dealt}))
		heal_hero(s, sp, dealt, ev)


## Removes keywords, effects, stat changes and freeze (spec 4.2). Damage stays.
static func hush(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return
	cr.atk_bonus += atk
	cr.hp_bonus += hp
	ev.append(GameEvent.make(&"buffed", {"player": p, "lane": lane, "atk": atk, "hp": hp}))


## Marks a creature to die; resolve_deaths removes it.
static func destroy_creature(s: GameState, p: int, lane: int, _ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr:
		cr.damage = maxi(cr.damage, effective_max_hp(s, p, lane))


static func reveal(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr and cr.hidden:
		cr.hidden = false
		ev.append(GameEvent.make(&"revealed", {"player": p, "lane": lane}))


## Offers up to 3 different random cards matching the filter; play waits for CHOOSE.
static func offer_dream_up(s: GameState, p: int, filter_kind: int, filter_land: int, ev: Array[GameEvent]) -> void:
	var pool: Array[CardData] = CardDB.dream_up_pool(filter_kind, filter_land)
	if pool.is_empty():
		return
	_shuffle(s, pool)
	s.pending_choice = pool.slice(0, mini(3, pool.size()))
	s.pending_player = p
	s.phase = GameState.Phase.CHOOSING
	var ids: Array[StringName] = []
	for c: CardData in s.pending_choice:
		ids.append(c.id)
	ev.append(GameEvent.make(&"dream_up_offered", {"player": p, "cards": ids}))


static func heal_creature(s: GameState, p: int, lane: int, amount: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
	ev.append(GameEvent.make(&"hero_damaged", {"player": p, "amount": amount - soaked, "armour": soaked}))
	var sp: int = int(src.get("player", -1))
	var sl: int = int(src.get("lane", -1))
	if amount > 0 and sp >= 0 and sl >= 0 and s.players[sp].lanes[sl].creature:
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


## What `c` costs player p right now: spells get the pending spell discount (never below 0).
static func card_cost(s: GameState, p: int, c: CardData) -> int:
	if c.kind == CardData.Kind.SPELL:
		return maxi(c.cost - s.players[p].spell_discount, 0)
	return c.cost


## Takes a creature off the board back to its owner's hand (discarded if the hand is full). Not a death.
static func bounce_creature(s: GameState, p: int, lane: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return
	s.players[p].lanes[lane].creature = null
	ev.append(GameEvent.make(&"creature_bounced", {"player": p, "lane": lane, "card": cr.card.id}))
	return_to_hand(s, p, cr.card, ev)


## Turns a creature into `into` where it stands: a fresh creature (no damage, buffs, keywords or level) that keeps
## its readiness for this turn.
static func transform_creature(s: GameState, p: int, lane: int, into: CardData, ev: Array[GameEvent]) -> void:
	var old: GameState.CreatureState = s.players[p].lanes[lane].creature
	if old == null:
		return
	var cr: GameState.CreatureState = enter_creature(s, p, lane, into, ev)
	cr.played_turn = old.played_turn
	cr.ready = old.ready
	cr.attacks_used = old.attacks_used
	cr.booped = old.booped
	ev.append(GameEvent.make(&"creature_transformed", {"player": p, "lane": lane, "from": old.card.id, "card": into.id}))


static func _hero_down(s: GameState) -> bool:
	return s.players[0].hero_hp <= 0 or s.players[1].hero_hp <= 0


static func resolve_deaths(s: GameState, ev: Array[GameEvent]) -> void:
	if s.phase == GameState.Phase.OVER:
		return
	var any: bool = true
	while any and not _hero_down(s):
		any = false
		for p: int in [s.active, s.opponent(s.active)]:
			for l: int in GameState.LANES:
				if _hero_down(s):
					break
				var cr: GameState.CreatureState = s.players[p].lanes[l].creature
				if cr and cr.damage >= effective_max_hp(s, p, l):
					any = true
					var second_wind: bool = has_keyword(s, p, l, &"second_wind") and not cr.second_wind_used
					s.players[p].lanes[l].creature = null
					s.players[p].discard.append(cr.card)
					ev.append(GameEvent.make(&"creature_destroyed", {"player": p, "lane": l, "card": cr.card.id}))
					if not cr.hushed:
						Effects.run(s, p, l, cr.card, &"on_destroyed", [], ev)
					if second_wind and not _hero_down(s) and s.players[p].lanes[l].creature == null:
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
