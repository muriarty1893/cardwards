extends TestCase
## Keyword and mechanic rules (Rules 2.0 spec section 4) on built cards.

const C := CardData.Kind.CREATURE
const S := CardData.Kind.SPELL


func _src(p: int, lane: int, kind: StringName = &"attack") -> Dictionary:
	return {"player": p, "lane": lane, "kind": kind}


func _types(ev: Array[GameEvent]) -> Array[StringName]:
	return Fx.types(ev)


func test_bubble_blocks_once_and_stops_venom() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, Fx.card(&"snake", C, 1, 2, 2, [&"venom"]))
	var t: GameState.CreatureState = Fx.put(s, 1, 0, Fx.card(&"bub", C, 1, 1, 5, [&"bubble"]))
	t.bubble = true
	var ev: Array[GameEvent] = []
	var dealt: int = Rules.damage_creature(s, 1, 0, 2, _src(0, 0), ev)
	assert_eq(dealt, 0, "bubble absorbs")
	assert_true(not t.bubble and t.damage == 0 and &"bubble_popped" in _types(ev), "popped, no damage")
	Rules.resolve_deaths(s, ev)
	assert_true(s.players[1].lanes[0].creature != null, "alive after bubble")
	Rules.damage_creature(s, 1, 0, 2, _src(0, 0), ev)
	Rules.resolve_deaths(s, ev)
	assert_true(s.players[1].lanes[0].creature == null, "venom kills on the second hit")
	return true


func test_bubble_ignores_zero() -> bool:
	var s: GameState = Fx.blank()
	var t: GameState.CreatureState = Fx.put(s, 1, 0, Fx.card(&"bub", C, 1, 1, 5, [&"bubble"]))
	t.bubble = true
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 1, 0, 0, _src(0, -1, &"spell"), ev)
	assert_true(t.bubble and not &"bubble_popped" in _types(ev), "zero damage keeps the bubble")
	return true


func test_leech_heals_owner() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].hero_hp = 20
	Fx.put(s, 0, 2, Fx.card(&"leech", C, 1, 3, 5, [&"leech"]))
	Fx.put(s, 1, 2, Fx.card(&"foe", C, 1, 1, 9))
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 1, 2, 3, _src(0, 2), ev)
	assert_eq(s.players[0].hero_hp, 23, "healed by damage dealt")
	var t: Array[StringName] = _types(ev)
	assert_true(t.find(&"leeched") >= 0 and t.find(&"leeched") < t.find(&"hero_healed"), "leeched before hero_healed")
	Rules.damage_hero(s, 1, 2, ev, _src(0, 2))
	assert_eq(s.players[0].hero_hp, 25, "leech on hero damage too")
	return true


func test_leech_no_heal_on_bubble() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].hero_hp = 20
	Fx.put(s, 0, 2, Fx.card(&"leech", C, 1, 3, 5, [&"leech"]))
	Fx.put(s, 1, 2, Fx.card(&"bub", C, 1, 1, 9, [&"bubble"])).bubble = true
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 1, 2, 3, _src(0, 2), ev)
	assert_eq(s.players[0].hero_hp, 20, "no heal when the bubble took it")
	return true


func test_second_wind_returns_once() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = Fx.card(&"puff", C, 1, 2, 3, [&"second_wind"])
	Fx.put(s, 1, 1, c)
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 1, 1, 5, _src(0, -1, &"spell"), ev)
	Rules.resolve_deaths(s, ev)
	var back: GameState.CreatureState = s.players[1].lanes[1].creature
	assert_true(back != null and back.card == c, "came back")
	assert_eq(Rules.effective_max_hp(s, 1, 1) - back.damage, 1, "with 1 HP")
	assert_true(back.second_wind_used and not back.ready, "used, not ready")
	assert_true(not Rules.has_keyword(s, 1, 1, &"second_wind"), "no second wind keyword any more")
	Rules.damage_creature(s, 1, 1, 1, _src(0, -1, &"spell"), ev)
	Rules.resolve_deaths(s, ev)
	assert_true(s.players[1].lanes[1].creature == null, "gone the second time")
	return true


func test_second_wind_runs_on_destroyed_first() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 1, &"mossback", 3)
	Fx.put(s, 1, 0, Fx.card(&"jelly", C, 1, 1, 1, [&"second_wind"], [Fx.eff(&"on_destroyed", &"draw", 1, &"own_hero")]))
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 1, 0, 3, _src(0, -1, &"spell"), ev)
	Rules.resolve_deaths(s, ev)
	var t: Array[StringName] = _types(ev)
	assert_true(t.find(&"creature_destroyed") < t.find(&"card_drawn") and t.find(&"card_drawn") < t.find(&"second_wind"), "destroyed, draw, second wind")
	return true


func test_hush_rules() -> bool:
	var s: GameState = Fx.blank()
	var cr: GameState.CreatureState = Fx.put(s, 1, 2, Fx.card(&"wall", C, 1, 1, 5, [&"guard", &"bubble"]))
	cr.bubble = true
	cr.atk_bonus = 2
	cr.damage = 1
	s.players[1].lanes[2].building = Fx.card(&"lantern", CardData.Kind.BUILDING, 1, 0, 0, [], [Fx.eff(&"aura", &"lane_keyword", 0, &"lane_creature", {"keyword": &"guard"})])
	var ev: Array[GameEvent] = []
	Rules.freeze(s, 1, 2, ev)
	Rules.hush(s, 1, 2, ev)
	assert_eq(Rules.keywords_of(s, 1, 2), [&"guard"] as Array[StringName], "only the building's guard")
	assert_true(not cr.bubble and cr.atk_bonus == 0 and not cr.is_frozen(), "bubble, buffs and freeze gone")
	assert_eq(cr.damage, 1, "damage kept")
	assert_true(&"hushed" in _types(ev), "event")
	Rules.give_keyword(s, 1, 2, &"venom", ev)
	assert_true(Rules.has_keyword(s, 1, 2, &"venom"), "can gain keywords after hush")
	return true


func test_spell_power_stacks_and_ignores_abilities() -> bool:
	var s: GameState = Fx.blank()
	for l: int in 2:
		var c: CardData = Fx.card(&"sp", C, 1, 1, 9)
		c.spell_power = 1
		Fx.put(s, 0, l, c)
	Fx.put(s, 1, 3, Fx.card(&"foe", C, 1, 1, 20))
	assert_eq(Rules.spell_power(s, 0), 2, "stacks")
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, Fx.card(&"bolt", S, 1, 0, 0, [], [Fx.eff(&"on_play", &"damage", 3, &"chosen_creature")]), &"on_play", [{"player": 1, "lane": 3}], ev)
	assert_eq(s.players[1].lanes[3].creature.damage, 5, "spell 3+2")
	var pinger: CardData = Fx.card(&"ping", C, 1, 1, 9, [], [Fx.eff(&"on_boop", &"damage", 1, &"opposing")])
	Fx.put(s, 0, 3, pinger)
	Effects.run(s, 0, 3, pinger, &"on_boop", [], ev)
	assert_eq(s.players[1].lanes[3].creature.damage, 6, "ability not boosted")
	s.players[0].lanes[0].creature.hushed = true
	assert_eq(Rules.spell_power(s, 0), 1, "hushed creature gives none")
	return true


func test_dream_up_offer_and_choose() -> bool:
	var s: GameState = Fx.blank()
	var ev: Array[GameEvent] = []
	Rules.offer_dream_up(s, 0, -1, CardData.Land.CANDY, ev)
	assert_eq(s.phase, GameState.Phase.CHOOSING, "choosing")
	var ids: Array = ev[ev.size() - 1].data["cards"]
	assert_eq(ids.size(), 3, "three offered")
	var seen: Dictionary = {}
	for id: StringName in ids:
		assert_eq(CardDB.card(id).land, CardData.Land.CANDY, "candy")
		seen[id] = true
	assert_eq(seen.size(), 3, "distinct")
	assert_true(Rules.validate(s, Action.end_turn(0)) == "Choose a card first", "other actions blocked")
	assert_true(Rules.validate(s, Action.choose(0, 3)) != "", "index checked")
	var picked: CardData = s.pending_choice[1]
	ev = Rules.apply(s, Action.choose(0, 1))
	assert_true(picked in s.players[0].hand and s.phase == GameState.Phase.MAIN, "card in hand, back to main")
	assert_true(&"dream_up_chosen" in _types(ev), "event")
	return true


func test_dream_up_small_pool_and_full_hand() -> bool:
	var s: GameState = Fx.blank()
	var ev: Array[GameEvent] = []
	Rules.offer_dream_up(s, 0, CardData.Kind.BUILDING, CardData.Land.CANDY, ev)
	var pool: int = CardDB.dream_up_pool(CardData.Kind.BUILDING, CardData.Land.CANDY).size()
	assert_eq(s.pending_choice.size(), mini(3, pool), "offers the whole small pool (%d candy buildings)" % pool)
	for i: int in GameState.HAND_LIMIT:
		s.players[0].hand.append(CardDB.card(&"mossback"))
	var picked: CardData = s.pending_choice[0]
	ev = Rules.apply(s, Action.choose(0, 0))
	assert_true(picked in s.players[0].discard and &"card_burned" in _types(ev), "burned when the hand is full")
	return true


func test_dream_up_is_seeded() -> bool:
	var a: GameState = Fx.blank()
	var b: GameState = Fx.blank()
	var ev: Array[GameEvent] = []
	Rules.offer_dream_up(a, 0, -1, -1, ev)
	Rules.offer_dream_up(b, 0, -1, -1, ev)
	assert_eq(a.pending_choice, b.pending_choice, "same seed, same offer")
	return true


func test_deaths_active_player_first() -> bool:
	var s: GameState = Fx.blank()
	s.active = 1
	Fx.put(s, 0, 0, Fx.card(&"mine", C, 1, 1, 1)).damage = 1
	Fx.put(s, 1, 3, Fx.card(&"theirs", C, 1, 1, 1)).damage = 1
	var ev: Array[GameEvent] = []
	Rules.resolve_deaths(s, ev)
	var dead: Array = ev.filter(func(e: GameEvent) -> bool: return e.type == &"creature_destroyed").map(func(e: GameEvent) -> int: return e.data["player"])
	assert_eq(dead, [1, 0], "active player's creatures die first")
	return true
