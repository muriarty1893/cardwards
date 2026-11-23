extends TestCase
## Effect runner ops and target resolution on built cards (Rules 2.0 spec section 5).

const C := CardData.Kind.CREATURE
const S := CardData.Kind.SPELL
const B := CardData.Kind.BUILDING


func _spell(effs: Array[EffectData]) -> CardData:
	return Fx.card(&"spell", S, 1, 0, 0, [], effs)


func test_damage_chosen_and_spell_power() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 1, 2, Fx.card(&"foe", C, 1, 1, 9))
	var sp: CardData = Fx.card(&"sp", C, 1, 1, 9); sp.spell_power = 1
	Fx.put(s, 0, 0, sp)
	var bolt: CardData = _spell([Fx.eff(&"on_play", &"damage", 3, &"chosen_creature")])
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, bolt, &"on_play", [{"player": 1, "lane": 2}], ev)
	assert_eq(s.players[1].lanes[2].creature.damage, 4, "3 + spell power 1")
	assert_eq(ev[0].type, &"ability_triggered", "announced first")
	return true


func test_same_target_freeze() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 1, 1, Fx.card(&"foe", C, 1, 1, 9))
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"damage", 3, &"chosen_creature"), Fx.eff(&"on_play", &"freeze", 0, &"same_target")]), &"on_play", [{"player": 1, "lane": 1}], ev)
	var cr: GameState.CreatureState = s.players[1].lanes[1].creature
	assert_eq(cr.damage, 3, "damaged")
	assert_true(cr.is_frozen(), "frozen too")
	return true


func test_all_enemy_hits_hidden() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 1, 0, Fx.card(&"a", C, 1, 1, 9)).hidden = true
	Fx.put(s, 1, 3, Fx.card(&"b", C, 1, 1, 9))
	Fx.put(s, 0, 0, Fx.card(&"mine", C, 1, 1, 9))
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"damage", 2, &"all_enemy_creatures")]), &"on_play", [], ev)
	assert_eq([s.players[1].lanes[0].creature.damage, s.players[1].lanes[3].creature.damage], [2, 2], "both enemies, hidden too")
	assert_eq(s.players[0].lanes[0].creature.damage, 0, "own untouched")
	return true


func test_hidden_not_choosable() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 1, 0, Fx.card(&"a", C, 1, 1, 9)).hidden = true
	Fx.put(s, 1, 2, Fx.card(&"b", C, 1, 1, 9))
	Fx.put(s, 0, 1, Fx.card(&"mine", C, 1, 1, 9)).hidden = true
	var v: Array[Dictionary] = Targeting.valid(s, 0, &"chosen_creature")
	assert_true(not {"player": 1, "lane": 0} in v, "enemy hidden excluded")
	assert_true({"player": 1, "lane": 2} in v and {"player": 0, "lane": 1} in v, "others included, own hidden too")
	return true


func test_chosen_who_and_needed() -> bool:
	var c: CardData = _spell([Fx.eff(&"on_play", &"swap", 0, &"chosen_two_own_creatures"), Fx.eff(&"on_play", &"draw", 1, &"own_hero")])
	assert_eq(Targeting.chosen_who(c, &"on_play"), &"chosen_two_own_creatures", "chosen who")
	assert_eq(Targeting.chosen_who(c, &"on_boop"), &"", "none for boop")
	assert_eq(Targeting.needed(&"chosen_two_own_creatures"), 2, "two")
	assert_eq(Targeting.needed(&"chosen_creature"), 1, "one")
	return true


func test_empty_lane_and_discard_targets() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, Fx.card(&"a", C, 1, 1, 1))
	Fx.put(s, 0, 2, Fx.card(&"b", C, 1, 1, 1))
	assert_eq(Targeting.valid(s, 0, &"chosen_own_empty_lane", 0), [{"player": 0, "lane": 1}, {"player": 0, "lane": 3}], "empty lanes")
	s.players[0].discard = [Fx.card(&"sp", S, 1, 0, 0), Fx.card(&"cr", C, 1, 1, 1)]
	assert_eq(Targeting.valid(s, 0, &"chosen_discard_creature"), [{"discard": 1}], "discard creatures only")
	return true


func test_combo_needs_card_played() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	var c: CardData = _spell([Fx.eff(&"on_play", &"draw", 1, &"own_hero", {"combo": true})])
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, c, &"on_play", [], ev)
	assert_eq(s.players[0].hand.size(), 0, "no combo without an earlier card")
	assert_true(ev.is_empty(), "nothing announced")
	s.players[0].cards_played = 1
	Effects.run(s, 0, -1, c, &"on_play", [], ev)
	assert_eq(s.players[0].hand.size(), 1, "combo draws")
	return true


func test_hushed_source_runs_nothing() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].hero_hp = 20
	var c: CardData = Fx.card(&"puff", C, 1, 1, 3, [], [Fx.eff(&"on_boop", &"heal", 2, &"own_hero")])
	Fx.put(s, 0, 1, c).hushed = true
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, 1, c, &"on_boop", [], ev)
	assert_eq(s.players[0].hero_hp, 20, "no heal")
	assert_true(ev.is_empty(), "no events")
	return true


func test_heal_variants() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].hero_hp = GameState.MAX_HP - 1
	var me: CardData = Fx.card(&"me", C, 1, 1, 9, [], [
		Fx.eff(&"on_boop", &"heal", 2, &"self"), Fx.eff(&"on_boop", &"heal", 2, &"own_hero"), Fx.eff(&"on_boop", &"heal", 1, &"all_own_creatures")])
	Fx.put(s, 0, 0, me).damage = 5
	Fx.put(s, 0, 3, Fx.card(&"pal", C, 1, 1, 9)).damage = 4
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, 0, me, &"on_boop", [], ev)
	assert_eq(s.players[0].lanes[0].creature.damage, 2, "self 2 then all 1")
	assert_eq(s.players[0].lanes[3].creature.damage, 3, "all own 1")
	assert_eq(s.players[0].hero_hp, GameState.MAX_HP, "hero capped at max")
	var hut: CardData = Fx.card(&"hut", B, 1, 0, 0, [], [Fx.eff(&"start_of_turn", &"heal", 2, &"lane_creature")])
	Effects.run(s, 0, 3, hut, &"start_of_turn", [], ev)
	assert_eq(s.players[0].lanes[3].creature.damage, 1, "lane creature")
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"heal", 4, &"chosen_own_creature")]), &"on_play", [{"player": 0, "lane": 3}], ev)
	assert_eq(s.players[0].lanes[3].creature.damage, 0, "chosen own")
	return true


func test_damage_opposing_and_enemy_hero() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 1, 2, Fx.card(&"foe", C, 1, 1, 9))
	var c: CardData = Fx.card(&"me", C, 1, 1, 9, [], [Fx.eff(&"on_boop", &"damage", 2, &"opposing"), Fx.eff(&"on_boop", &"damage", 3, &"enemy_hero")])
	Fx.put(s, 0, 2, c)
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, 2, c, &"on_boop", [], ev)
	assert_eq(s.players[1].lanes[2].creature.damage, 2, "opposing")
	assert_eq(s.players[1].hero_hp, GameState.START_HP - 3, "enemy hero")
	return true


func test_draw_and_gain_magic() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"draw", 2, &"own_hero"), Fx.eff(&"on_play", &"gain_magic", 1, &"own_hero")]), &"on_play", [], ev)
	assert_eq(s.players[0].hand.size(), 2, "drew 2")
	assert_eq(s.players[0].magic, 3, "gained 1 (from 2)")
	var mc: GameEvent = ev.filter(func(e: GameEvent) -> bool: return e.type == &"magic_changed")[0]
	assert_eq([mc.data["value"], mc.data["max"]], [3, 2], "magic event carries max")
	return true


func test_move_and_swap() -> bool:
	var s: GameState = Fx.blank()
	var bat: CardData = Fx.card(&"bat", C, 1, 1, 3, [], [Fx.eff(&"on_boop", &"move", 0, &"chosen_own_empty_lane")])
	Fx.put(s, 0, 0, bat)
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, 0, bat, &"on_boop", [{"player": 0, "lane": 2}], ev)
	assert_true(s.players[0].lanes[0].creature == null and s.players[0].lanes[2].creature.card == bat, "moved")
	var other: CardData = Fx.card(&"other", C, 1, 1, 3)
	Fx.put(s, 0, 3, other)
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"swap", 0, &"chosen_two_own_creatures")]), &"on_play", [{"player": 0, "lane": 2}, {"player": 0, "lane": 3}], ev)
	assert_true(s.players[0].lanes[2].creature.card == other and s.players[0].lanes[3].creature.card == bat, "swapped")
	return true


func test_return_building_and_from_discard() -> bool:
	var s: GameState = Fx.blank()
	var hut: CardData = Fx.card(&"hut", B, 1, 0, 0)
	s.players[1].lanes[1].building = hut
	var sprite: CardData = Fx.card(&"sprite", C, 1, 1, 3, [], [Fx.eff(&"on_play", &"return_building", 0, &"opposing")])
	Fx.put(s, 0, 1, sprite)
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, 1, sprite, &"on_play", [], ev)
	assert_true(s.players[1].lanes[1].building == null and hut in s.players[1].hand, "building back to its owner's hand")
	var dead: CardData = Fx.card(&"dead", C, 1, 1, 1)
	s.players[0].discard = [dead]
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"return_from_discard", 0, &"chosen_discard_creature")]), &"on_play", [{"discard": 0}], ev)
	assert_true(dead in s.players[0].hand and s.players[0].discard.is_empty(), "returned from discard")
	return true


func test_buff_give_keyword_destroy() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 1, 0, Fx.card(&"foe", C, 1, 2, 5))
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"buff", 2, &"chosen_creature", {"amount2": 3}), Fx.eff(&"on_play", &"give_keyword", 0, &"same_target", {"keyword": &"bubble"})]), &"on_play", [{"player": 1, "lane": 0}], ev)
	assert_eq([Rules.effective_attack(s, 1, 0), Rules.effective_max_hp(s, 1, 0)], [4, 8], "buffed +2/+3")
	assert_true(Rules.has_keyword(s, 1, 0, &"bubble") and s.players[1].lanes[0].creature.bubble, "gained bubble, bubble up")
	Effects.run(s, 0, -1, _spell([Fx.eff(&"on_play", &"destroy", 0, &"chosen_creature")]), &"on_play", [{"player": 1, "lane": 0}], ev)
	Rules.resolve_deaths(s, ev)
	assert_true(s.players[1].lanes[0].creature == null, "destroyed")
	return true


func test_auras_feed_effective_stats() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 1, Fx.card(&"me", C, 1, 3, 4))
	Fx.put(s, 1, 1, Fx.card(&"foe", C, 1, 3, 4))
	s.players[0].lanes[1].building = Fx.card(&"shack", B, 1, 0, 0, [], [Fx.eff(&"aura", &"lane_atk", 1, &"lane_creature"), Fx.eff(&"aura", &"lane_hp", 2, &"lane_creature"), Fx.eff(&"aura", &"lane_damage_taken", 1, &"lane_creature")])
	s.players[1].lanes[1].building = Fx.card(&"spire", B, 1, 0, 0, [], [Fx.eff(&"aura", &"opposing_atk", 1, &"opposing")])
	assert_eq([Rules.effective_attack(s, 0, 1), Rules.effective_max_hp(s, 0, 1)], [3, 6], "+1 ATK -1 spire, +2 HP")
	assert_eq(Rules.damage_reduction(s, 0, 1), 1, "damage reduction")
	return true
