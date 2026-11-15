extends TestCase


func _boop(s: GameState, p: int, lane: int, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	return Rules.apply(s, Action.boop(p, lane, targets))


func _cast(s: GameState, p: int, id: StringName, lane: int = -1, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	s.players[p].magic = 9
	return Rules.apply(s, Action.play(p, Fx.give(s, p, id), lane, targets))


# --- Mushroom ---

func test_heal_self_2() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"sporeling", 3)
	var ev: Array[GameEvent] = _boop(s, 0, 0)
	assert_eq(s.players[0].lanes[0].creature.damage, 1, "healed 2")
	assert_true(s.players[0].lanes[0].creature.acted, "acted")
	assert_true(&"booped" in Fx.types(ev) and &"creature_healed" in Fx.types(ev), "events")
	return true


func test_heal_hero_2() -> bool:
	var s: GameState = Fx.blank([0, 0, 2, 3])
	s.players[0].hero_hp = 20
	Fx.put_creature(s, 0, 0, &"puffcap")
	_boop(s, 0, 0)
	assert_eq(s.players[0].hero_hp, 22, "puffcap boop")
	s.players[0].hero_hp = 24
	_cast(s, 0, &"rootstalker", 1)
	assert_eq(s.players[0].hero_hp, 25, "rootstalker on play, capped at 25")
	return true


func test_heal_all_own_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"glimmer_morel", 2)
	Fx.put_creature(s, 0, 2, &"mossback", 3)
	Fx.put_creature(s, 1, 2, &"mossback", 3)
	_boop(s, 0, 0)
	assert_eq([s.players[0].lanes[0].creature.damage, s.players[0].lanes[2].creature.damage, s.players[1].lanes[2].creature.damage], [1, 2, 3], "own only")
	return true


func test_heal_all_own_3() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"elder_shroomhulk", 5)
	Fx.put_creature(s, 0, 1, &"mossback", 1)
	_boop(s, 0, 0)
	assert_eq([s.players[0].lanes[0].creature.damage, s.players[0].lanes[1].creature.damage], [2, 0], "healed 3, floor 0")
	return true


func test_heal_lane_creature_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_building(s, 0, 1, &"spore_hut")
	Fx.put_creature(s, 0, 1, &"mossback", 2)
	Fx.fill_deck(s, 0, &"mossback", 3)
	Rules.start_turn(s)
	assert_eq(s.players[0].lanes[1].creature.damage, 1, "spore hut heals at start of turn")
	return true


func test_lane_max_hp_3() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"mossback")
	Fx.put_building(s, 0, 0, &"glowcap_lantern")
	assert_eq(Rules.effective_max_hp(s, 0, 0), 9, "6 + 3")
	return true


func test_heal_target_4() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 3, &"mossback", 5)
	_cast(s, 0, &"rain_of_spores", -1, [{"player": 0, "lane": 3}])
	assert_eq(s.players[0].lanes[3].creature.damage, 1, "healed 4")
	return true


func test_return_from_discard() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].discard.append(CardDB.card(&"fireball"))
	s.players[0].discard.append(CardDB.card(&"blazehorn"))
	var ev: Array[GameEvent] = _cast(s, 0, &"regrowth", -1, [{"discard": 1}])
	assert_eq(s.players[0].hand.size(), 1, "one card back in hand")
	assert_eq(s.players[0].hand[0].id, &"blazehorn", "the creature")
	assert_true(&"card_returned" in Fx.types(ev), "card_returned")
	return true


# --- Ember ---

func test_dmg_opposing_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"ashmite")
	Fx.put_creature(s, 1, 2, &"mossback")
	_boop(s, 0, 2)
	assert_eq(s.players[1].lanes[2].creature.damage, 1, "1 damage opposing")
	return true


func test_dmg_enemy_hero_2() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"magmaw")
	_boop(s, 0, 0)
	assert_eq(s.players[1].hero_hp, 23, "2 to enemy hero")
	return true


func test_dmg_opposing_2() -> bool:
	var s: GameState = Fx.blank([1, 1, 1, 1])
	Fx.put_creature(s, 1, 1, &"cinderpup")
	var ev: Array[GameEvent] = _cast(s, 0, &"blazehorn", 1)
	assert_eq(s.players[1].lanes[1].creature, null, "cinderpup (2 hp) destroyed")
	assert_true(&"creature_destroyed" in Fx.types(ev), "destroyed event")
	assert_eq(s.players[1].discard[0].id, &"cinderpup", "to owner's discard")
	return true


func test_dmg_all_enemy_2() -> bool:
	var s: GameState = Fx.blank([1, 1, 1, 1])
	Fx.put_creature(s, 0, 0, &"inferno_drake")
	Fx.put_creature(s, 1, 0, &"cinderpup")
	Fx.put_creature(s, 1, 3, &"flarebeak")
	_boop(s, 0, 0)
	assert_eq(s.players[1].lanes[0].creature, null, "2-hp destroyed")
	assert_eq(s.players[1].lanes[3].creature.damage, 2, "other damaged 2")
	var s2: GameState = Fx.blank()
	Fx.put_creature(s2, 1, 1, &"mossback")
	Fx.put_creature(s2, 0, 1, &"mossback")
	_cast(s2, 0, &"ember_rain")
	assert_eq([s2.players[1].lanes[1].creature.damage, s2.players[0].lanes[1].creature.damage], [2, 0], "ember rain enemy only")
	return true


func test_lane_atk_2() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"cinderpup")
	Fx.put_building(s, 0, 0, &"kiln_tower")
	assert_eq(Rules.effective_attack(s, 0, 0), 5, "3 + 2")
	return true


func test_dmg_enemy_hero_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_building(s, 0, 2, &"smokestack")
	Fx.fill_deck(s, 1, &"mossback", 3)
	Rules.apply(s, Action.begin_attacks(0))
	Rules.apply(s, Action.end_turn(0))
	assert_eq(s.players[1].hero_hp, 24, "smokestack end of turn")
	return true


func test_dmg_target_3() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 2, &"mossback")
	_cast(s, 0, &"fireball", -1, [{"player": 1, "lane": 2}])
	assert_eq(s.players[1].lanes[2].creature.damage, 3, "fireball 3")
	return true


# --- Candy ---

func test_draw_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.fill_deck(s, 0, &"mossback", 3)
	_boop(s, 0, 0)
	assert_eq(s.players[0].hand.size(), 1, "drew 1")
	return true


func test_gain_magic_1() -> bool:
	var s: GameState = Fx.blank()
	_cast(s, 0, &"taffy_snail", 0)
	assert_eq(s.players[0].magic, 9, "taffy: paid 1, gained 1")
	var s2: GameState = Fx.blank()
	Fx.put_building(s2, 0, 0, &"candy_mill")
	Fx.fill_deck(s2, 0, &"mossback", 3)
	Rules.start_turn(s2)
	assert_eq([s2.players[0].magic, s2.players[0].magic_cap], [3, 3], "candy mill")
	return true


func test_move_self() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"lollibat", 1)
	Fx.put_building(s, 0, 0, &"kiln_tower")
	var ev: Array[GameEvent] = _boop(s, 0, 0, [{"player": 0, "lane": 3}])
	assert_eq(s.players[0].lanes[0].creature, null, "left lane 0")
	assert_eq(s.players[0].lanes[3].creature.card.id, &"lollibat", "now lane 3")
	assert_eq(s.players[0].lanes[3].creature.damage, 1, "keeps damage")
	assert_eq(s.players[0].lanes[0].building.id, &"kiln_tower", "building stays")
	assert_true(&"creature_moved" in Fx.types(ev), "moved event")
	return true


func test_bounce_opposing_building() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"sugar_sprite")
	Fx.put_building(s, 1, 1, &"kiln_tower")
	var ev: Array[GameEvent] = _boop(s, 0, 1)
	assert_eq(s.players[1].lanes[1].building, null, "building removed")
	assert_eq(s.players[1].hand[0].id, &"kiln_tower", "back to owner's hand")
	assert_true(&"building_returned" in Fx.types(ev), "event")
	return true


func test_draw_2() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 9)
	_cast(s, 0, &"sugar_rush")
	assert_eq(s.players[0].hand.size(), 2, "sugar rush")
	Fx.put_creature(s, 0, 0, &"bonbon_behemoth")
	_boop(s, 0, 0)
	assert_eq(s.players[0].hand.size(), 4, "behemoth")
	return true


func test_draw_2_on_destroyed() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"jellywobble", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	_cast(s, 0, &"fireball", -1, [{"player": 1, "lane": 0}])
	assert_eq(s.players[1].lanes[0].creature, null, "destroyed")
	assert_eq(s.players[1].hand.size(), 2, "owner drew 2")
	return true


func test_lane_atk_1_hp_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.put_building(s, 0, 0, &"sugar_shack")
	assert_eq([Rules.effective_attack(s, 0, 0), Rules.effective_max_hp(s, 0, 0)], [3, 4], "+1/+1")
	return true


func test_swap_two() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"mossback", 2)
	Fx.put_creature(s, 0, 3, &"cinderpup")
	_cast(s, 0, &"swap_trick", -1, [{"player": 0, "lane": 0}, {"player": 0, "lane": 3}])
	assert_eq(s.players[0].lanes[0].creature.card.id, &"cinderpup", "lane 0")
	assert_eq(s.players[0].lanes[3].creature.card.id, &"mossback", "lane 3")
	assert_eq(s.players[0].lanes[3].creature.damage, 2, "damage travels")
	return true


# --- Frost ---

func test_freeze_opposing() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"snowmite")
	Fx.put_creature(s, 1, 1, &"mossback")
	var ev: Array[GameEvent] = _boop(s, 0, 1)
	assert_true(s.players[1].lanes[1].creature.is_frozen(), "snowmite freezes")
	assert_true(&"frozen" in Fx.types(ev), "frozen event")
	var s2: GameState = Fx.blank([3, 3, 3, 3])
	Fx.put_creature(s2, 1, 2, &"mossback")
	_cast(s2, 0, &"rimewing", 2)
	assert_true(s2.players[1].lanes[2].creature.is_frozen(), "rimewing on play")
	return true


func test_freeze_all_enemy() -> bool:
	var s: GameState = Fx.blank([3, 3, 3, 3])
	Fx.put_creature(s, 0, 0, &"blizzard_titan")
	Fx.put_creature(s, 1, 0, &"mossback")
	Fx.put_creature(s, 1, 3, &"mossback")
	_boop(s, 0, 0)
	assert_true(s.players[1].lanes[0].creature.is_frozen() and s.players[1].lanes[3].creature.is_frozen(), "all frozen")
	assert_true(not s.players[0].lanes[0].creature.is_frozen(), "own not frozen")
	return true


func test_opposing_atk_minus_1() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"snowmite")
	Fx.put_building(s, 1, 2, &"frost_spire")
	assert_eq(Rules.effective_attack(s, 0, 2), 0, "1 - 1")
	return true


func test_freeze_target() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"mossback")
	_cast(s, 0, &"cold_snap", -1, [{"player": 1, "lane": 0}])
	assert_true(s.players[1].lanes[0].creature.is_frozen(), "cold snap")
	return true


func test_dmg_target_3_freeze() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"mossback")
	_cast(s, 0, &"avalanche", -1, [{"player": 1, "lane": 0}])
	assert_eq(s.players[1].lanes[0].creature.damage, 3, "3 damage")
	assert_true(s.players[1].lanes[0].creature.is_frozen(), "frozen")
	return true


# --- Boop rules ---

func test_boop_blocks() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"sporeling", 2)
	_boop(s, 0, 0)
	assert_eq(Rules.validate(s, Action.boop(0, 0)), "Creature already acted", "second boop")
	Fx.put_creature(s, 0, 1, &"sporeling")
	s.players[0].lanes[1].creature.freeze_turn = s.turn
	assert_eq(Rules.validate(s, Action.boop(0, 1)), "Creature is frozen", "frozen")
	Fx.put_creature(s, 0, 2, &"mossback")
	assert_eq(Rules.validate(s, Action.boop(0, 2)), "No boop ability", "no ability")
	return true


# --- Review Focus ---

func test_building_removed_kills() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"mossback", 7)
	Fx.put_building(s, 0, 1, &"glowcap_lantern")
	Fx.put_creature(s, 1, 1, &"sugar_sprite")
	s.active = 1
	var ev: Array[GameEvent] = _boop(s, 1, 1)
	assert_eq(s.players[0].lanes[1].building, null, "lantern returned")
	assert_eq(s.players[0].lanes[1].creature, null, "mossback destroyed")
	assert_true(&"creature_destroyed" in Fx.types(ev), "destroyed event")
	return true


func test_no_valid_target() -> bool:
	var s: GameState = Fx.blank()
	var i: int = Fx.give(s, 0, &"fireball")
	assert_eq(Rules.validate(s, Action.play(0, i, -1, [])), "No valid target", "fireball, no creatures")
	s.players[0].hand.clear()
	s.players[0].discard.append(CardDB.card(&"fireball"))
	i = Fx.give(s, 0, &"regrowth")
	assert_eq(Rules.validate(s, Action.play(0, i, -1, [])), "No valid target", "regrowth, no creature in discard")
	s.players[0].hand.clear()
	for l: int in 4:
		Fx.put_creature(s, 0, l, &"lollibat")
	assert_eq(Rules.validate(s, Action.boop(0, 0, [])), "No valid target", "lollibat, no empty lane")
	var s2: GameState = Fx.blank()
	Fx.put_creature(s2, 0, 0, &"mossback")
	i = Fx.give(s2, 0, &"swap_trick")
	assert_eq(Rules.validate(s2, Action.play(0, i, -1, [{"player": 0, "lane": 0}])), "No valid target", "swap trick, 1 creature")
	assert_eq(Rules.apply(s2, Action.play(0, i, -1, [{"player": 0, "lane": 0}])).size(), 0, "nothing applied")
	assert_eq([s2.players[0].magic, s2.players[0].hand.size()], [2, 1], "magic unchanged, card in hand")
	return true


func test_return_to_full_hand() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].discard.append(CardDB.card(&"blazehorn"))
	var i: int = Fx.give(s, 0, &"regrowth")
	for n: int in 7:
		Fx.give(s, 0, &"mossback")
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, i, -1, [{"discard": 0}]))
	assert_eq(s.players[0].hand.size(), 7, "hand stays 7")
	assert_true(&"card_burned" in Fx.types(ev), "burned")
	var ids: Array[StringName] = []
	for c: CardData in s.players[0].discard:
		ids.append(c.id)
	assert_true(&"blazehorn" in ids, "blazehorn back in discard")
	return true


func _count(ev: Array[GameEvent], t: StringName) -> int:
	return Fx.types(ev).count(t)

func test_ability_triggered_on_boop() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"sporeling", 2)
	var ev: Array[GameEvent] = Rules.apply(s, Action.boop(0, 1, []))
	var i: int = Fx.types(ev).find(&"ability_triggered")
	assert_true(i >= 0 and i < Fx.types(ev).find(&"creature_healed"), "before the heal")
	assert_eq(ev[i].data, {"player": 0, "lane": 1, "card": &"sporeling"}, "data")
	return true

func test_ability_triggered_once_per_spell() -> bool:
	var s: GameState = Fx.blank()
	for l: int in 3:
		Fx.put_creature(s, 1, l, &"mossback")
	var i: int = Fx.give(s, 0, &"ember_rain")
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, i, -1, []))
	assert_eq(_count(ev, &"ability_triggered"), 1, "once for 3 targets")
	assert_eq(ev[Fx.types(ev).find(&"ability_triggered")].data["lane"], -1, "spell lane -1")
	return true

func test_ability_triggered_for_building() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_building(s, 0, 2, &"smokestack")
	Fx.fill_deck(s, 1, &"mossback", 3)
	Rules.apply(s, Action.begin_attacks(0))
	var ev: Array[GameEvent] = Rules.apply(s, Action.end_turn(0))
	assert_true(&"ability_triggered" in Fx.types(ev), "smokestack trigger")
	return true
