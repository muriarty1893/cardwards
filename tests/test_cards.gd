extends TestCase
## Every real card's ability with its Rules 2.0 numbers (spec section 6).


func _boop(s: GameState, p: int, lane: int, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	return Rules.apply(s, Action.boop(p, lane, targets))


func _cast(s: GameState, p: int, id: StringName, lane: int = -1, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	s.players[p].magic = 9
	return Rules.apply(s, Action.play(p, Fx.give(s, p, id), lane, targets))


# --- Mushroom ---

func test_sporeling() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"sporeling", 1)
	var ev: Array[GameEvent] = _boop(s, 0, 0)
	assert_eq(s.players[0].lanes[0].creature.damage, 0, "boop heals itself")
	assert_true(&"booped" in Fx.types(ev) and &"creature_healed" in Fx.types(ev), "events")
	assert_true(Rules.has_keyword(s, 0, 0, &"venom"), "venom")
	return true


func test_puffcap_and_rootstalker_heal_hero() -> bool:
	var s: GameState = Fx.blank([0, 0, 2, 3])
	s.players[0].hero_hp = 20
	Fx.put_creature(s, 0, 0, &"puffcap")
	_boop(s, 0, 0)
	assert_eq(s.players[0].hero_hp, 22, "puffcap boop")
	assert_true(Rules.has_keyword(s, 0, 0, &"second_wind"), "puffcap second wind")
	s.players[0].hero_hp = 24
	_cast(s, 0, &"rootstalker", 1)
	assert_eq(s.players[0].hero_hp, 25, "rootstalker on play, capped at 25")
	assert_true(Rules.has_keyword(s, 0, 1, &"leech"), "rootstalker leech")
	return true


func test_glimmer_morel_heals_all_own_2() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"glimmer_morel", 3)
	Fx.put_creature(s, 0, 2, &"mossback", 3)
	Fx.put_creature(s, 1, 2, &"mossback", 3)
	_boop(s, 0, 0)
	assert_eq([s.players[0].lanes[0].creature.damage, s.players[0].lanes[2].creature.damage, s.players[1].lanes[2].creature.damage], [1, 1, 3], "own only")
	return true


func test_elder_shroomhulk() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"elder_shroomhulk", 5)
	Fx.put_creature(s, 0, 1, &"mossback", 1)
	_boop(s, 0, 0)
	assert_eq([s.players[0].lanes[0].creature.damage, s.players[0].lanes[1].creature.damage], [2, 0], "healed 3, floor 0")
	assert_true(Rules.has_keyword(s, 0, 0, &"guard") and Rules.has_keyword(s, 0, 0, &"second_wind"), "guard, second wind")
	return true


func test_spore_hut_heals_2() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_building(s, 0, 1, &"spore_hut")
	Fx.put_creature(s, 0, 1, &"mossback", 3)
	Fx.fill_deck(s, 0, &"mossback", 3)
	Rules.start_turn(s)
	assert_eq(s.players[0].lanes[1].creature.damage, 1, "spore hut heals 2 at start of turn")
	return true


func test_glowcap_lantern() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"sporeling")
	Fx.put_building(s, 0, 0, &"glowcap_lantern")
	assert_eq(Rules.effective_max_hp(s, 0, 0), 4, "2 + 2")
	assert_true(Rules.has_keyword(s, 0, 0, &"guard"), "guard from the lantern")
	return true


func test_rain_of_spores() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 3, &"mossback", 4)
	_cast(s, 0, &"rain_of_spores", -1, [{"player": 0, "lane": 3}])
	assert_eq(s.players[0].lanes[3].creature.damage, 0, "healed 4")
	return true


func test_regrowth() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].discard.append(CardDB.card(&"fireball"))
	s.players[0].discard.append(CardDB.card(&"blazehorn"))
	var ev: Array[GameEvent] = _cast(s, 0, &"regrowth", -1, [{"discard": 1}])
	assert_eq(s.players[0].hand.size(), 1, "one card back in hand")
	assert_eq(s.players[0].hand[0].id, &"blazehorn", "the creature")
	assert_true(&"card_returned" in Fx.types(ev), "card_returned")
	return true


# --- Ember ---

func test_ashmite() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"ashmite")
	Fx.put_creature(s, 1, 2, &"mossback")
	_boop(s, 0, 2)
	assert_eq(s.players[1].lanes[2].creature.damage, 1, "1 damage opposing")
	assert_eq(Rules.spell_power(s, 0), 1, "spell power +1")
	return true


func test_magmaw() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"magmaw")
	_boop(s, 0, 0)
	assert_eq(s.players[1].hero_hp, 23, "2 to enemy hero")
	return true


func test_blazehorn() -> bool:
	var s: GameState = Fx.blank([1, 1, 1, 1])
	Fx.put_creature(s, 1, 1, &"cinderpup")
	var ev: Array[GameEvent] = _cast(s, 0, &"blazehorn", 1)
	assert_eq(s.players[1].lanes[1].creature, null, "cinderpup (1 hp) destroyed")
	assert_true(&"creature_destroyed" in Fx.types(ev), "destroyed event")
	assert_eq(s.players[1].discard[0].id, &"cinderpup", "to owner's discard")
	assert_true(Rules.has_keyword(s, 0, 1, &"dash"), "dash")
	return true


func test_inferno_drake_and_ember_rain() -> bool:
	var s: GameState = Fx.blank([1, 1, 1, 1])
	Fx.put_creature(s, 0, 0, &"inferno_drake")
	Fx.put_creature(s, 1, 0, &"cinderpup")
	Fx.put_creature(s, 1, 3, &"flarebeak")
	_boop(s, 0, 0)
	assert_eq(s.players[1].lanes[0].creature, null, "1-hp destroyed")
	assert_eq(s.players[1].lanes[3].creature.damage, 2, "other damaged 2 (abilities ignore spell power)")
	var s2: GameState = Fx.blank()
	Fx.put_creature(s2, 1, 1, &"mossback")
	Fx.put_creature(s2, 0, 1, &"mossback")
	_cast(s2, 0, &"ember_rain")
	assert_eq([s2.players[1].lanes[1].creature.damage, s2.players[0].lanes[1].creature.damage], [2, 0], "ember rain enemy only")
	return true


func test_kiln_tower() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"cinderpup")
	Fx.put_building(s, 0, 0, &"kiln_tower")
	assert_eq(Rules.effective_attack(s, 0, 0), 4, "2 + 2")
	return true


func test_smokestack() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_building(s, 0, 2, &"smokestack")
	Fx.fill_deck(s, 1, &"mossback", 3)
	Rules.apply(s, Action.begin_attacks(0))
	var ev: Array[GameEvent] = Rules.apply(s, Action.end_turn(0))
	assert_eq(s.players[1].hero_hp, 24, "smokestack end of turn")
	assert_true(&"ability_triggered" in Fx.types(ev), "announced")
	return true


func test_fireball() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 2, &"mossback")
	_cast(s, 0, &"fireball", -1, [{"player": 1, "lane": 2}])
	assert_eq(s.players[1].lanes[2].creature.damage, 3, "fireball 3")
	return true


# --- Candy ---

func test_gumdrop() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.fill_deck(s, 0, &"mossback", 3)
	_boop(s, 0, 0)
	assert_eq(s.players[0].hand.size(), 1, "drew 1")
	return true


func test_taffy_snail_and_candy_mill() -> bool:
	var s: GameState = Fx.blank()
	_cast(s, 0, &"taffy_snail", 0)
	assert_eq(s.players[0].magic, 8, "taffy: paid 2, gained 1")
	var plain: GameState = Fx.blank()
	Fx.fill_deck(plain, 0, &"mossback", 3)
	Rules.start_turn(plain)
	var s2: GameState = Fx.blank()
	Fx.put_building(s2, 0, 0, &"candy_mill")
	Fx.fill_deck(s2, 0, &"mossback", 3)
	Rules.start_turn(s2)
	assert_eq(s2.players[0].magic, plain.players[0].magic + 1, "candy mill adds 1 on top")
	return true


func test_lollibat() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"lollibat", 1)
	Fx.put_building(s, 0, 0, &"kiln_tower")
	var ev: Array[GameEvent] = _boop(s, 0, 0, [{"player": 0, "lane": 3}])
	assert_eq(s.players[0].lanes[0].creature, null, "left lane 0")
	assert_eq(s.players[0].lanes[3].creature.card.id, &"lollibat", "now lane 3")
	assert_eq(s.players[0].lanes[3].creature.damage, 1, "keeps damage")
	assert_eq(s.players[0].lanes[0].building.id, &"kiln_tower", "building stays")
	assert_true(&"creature_moved" in Fx.types(ev), "moved event")
	assert_true(Rules.has_keyword(s, 0, 3, &"flurry"), "flurry")
	return true


func test_sugar_sprite_combo_only() -> bool:
	var s: GameState = Fx.blank([2, 2, 2, 3])
	Fx.put_building(s, 1, 1, &"kiln_tower")
	Fx.put_building(s, 1, 2, &"ice_wall")
	_cast(s, 0, &"sugar_sprite", 1)
	assert_true(s.players[1].lanes[1].building != null, "first card of the turn: no combo")
	assert_true(s.players[0].lanes[1].creature.hidden, "enters hidden")
	var ev: Array[GameEvent] = _cast(s, 0, &"sugar_sprite", 2)
	assert_eq(s.players[1].lanes[2].building, null, "combo returns the opposing building")
	assert_eq(s.players[1].hand[0].id, &"ice_wall", "to its owner's hand")
	assert_true(&"building_returned" in Fx.types(ev), "event")
	return true


func test_sugar_rush_and_bonbon_draw() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 9)
	_cast(s, 0, &"sugar_rush")
	assert_eq(s.players[0].hand.size(), 2, "sugar rush")
	Fx.put_creature(s, 0, 0, &"bonbon_behemoth")
	_boop(s, 0, 0)
	assert_eq(s.players[0].hand.size(), 4, "behemoth boop")
	return true


func test_bonbon_dreams_up_candy() -> bool:
	var s: GameState = Fx.blank([2, 2, 2, 3])
	var ev: Array[GameEvent] = _cast(s, 0, &"bonbon_behemoth", 0)
	assert_eq(s.phase, GameState.Phase.CHOOSING, "choosing")
	assert_eq(s.pending_choice.size(), 3, "three offered")
	for c: CardData in s.pending_choice:
		assert_eq(c.land, CardData.Land.CANDY, "candy card")
	assert_true(&"dream_up_offered" in Fx.types(ev), "event")
	return true


func test_jellywobble() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"jellywobble", 3)
	Fx.fill_deck(s, 1, &"mossback", 5)
	_cast(s, 0, &"fireball", -1, [{"player": 1, "lane": 0}])
	assert_eq(s.players[1].lanes[0].creature, null, "destroyed")
	assert_eq(s.players[1].hand.size(), 2, "owner drew 2")
	return true


func test_sugar_shack() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.put_building(s, 0, 0, &"sugar_shack")
	assert_eq([Rules.effective_attack(s, 0, 0), Rules.effective_max_hp(s, 0, 0)], [2, 4], "+1/+1")
	return true


func test_swap_trick() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 3)
	Fx.put_creature(s, 0, 0, &"mossback", 2)
	Fx.put_creature(s, 0, 3, &"cinderpup")
	_cast(s, 0, &"swap_trick", -1, [{"player": 0, "lane": 0}, {"player": 0, "lane": 3}])
	assert_eq(s.players[0].lanes[0].creature.card.id, &"cinderpup", "lane 0")
	assert_eq(s.players[0].lanes[3].creature.card.id, &"mossback", "lane 3")
	assert_eq(s.players[0].lanes[3].creature.damage, 2, "damage travels")
	assert_eq(s.players[0].hand.size(), 0, "no combo on the first card")
	_cast(s, 0, &"swap_trick", -1, [{"player": 0, "lane": 0}, {"player": 0, "lane": 3}])
	assert_eq(s.players[0].hand.size(), 1, "combo draws a card")
	return true


# --- Frost ---

func test_snowmite() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"snowmite")
	Fx.put_creature(s, 1, 1, &"mossback")
	var ev: Array[GameEvent] = _boop(s, 0, 1)
	assert_true(s.players[1].lanes[1].creature.is_frozen(), "snowmite freezes")
	assert_true(&"frozen" in Fx.types(ev), "frozen event")
	return true


func test_rimewing_hushes() -> bool:
	var s: GameState = Fx.blank([3, 3, 3, 3])
	Fx.put_creature(s, 1, 2, &"mossback")
	var ev: Array[GameEvent] = _cast(s, 0, &"rimewing", 2)
	assert_true(s.players[1].lanes[2].creature.hushed, "hushed")
	assert_true(not Rules.has_keyword(s, 1, 2, &"guard"), "lost guard")
	assert_true(&"hushed" in Fx.types(ev), "event")
	return true


func test_blizzard_titan() -> bool:
	var s: GameState = Fx.blank([3, 3, 3, 3])
	_cast(s, 0, &"blizzard_titan", 0)
	assert_true(s.players[0].lanes[0].creature.bubble, "enters with its bubble up")
	Fx.put_creature(s, 1, 0, &"mossback")
	Fx.put_creature(s, 1, 3, &"mossback")
	_boop(s, 0, 0)
	assert_true(s.players[1].lanes[0].creature.is_frozen() and s.players[1].lanes[3].creature.is_frozen(), "all frozen")
	assert_true(not s.players[0].lanes[0].creature.is_frozen(), "own not frozen")
	return true


func test_frostfang_freezes_what_it_damages() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"frostfang")
	Fx.put_creature(s, 1, 1, &"mossback")
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 1, 1, 3, {"player": 0, "lane": 1, "kind": &"attack"}, ev)
	assert_true(s.players[1].lanes[1].creature.is_frozen(), "frozen after damage")
	return true


func test_frost_spire_and_ice_wall() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"iceling")
	Fx.put_building(s, 1, 2, &"frost_spire")
	assert_eq(Rules.effective_attack(s, 0, 2), 1, "2 - 1")
	Fx.put_building(s, 0, 2, &"ice_wall")
	assert_eq(Rules.damage_reduction(s, 0, 2), 1, "ice wall")
	return true


func test_cold_snap() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 2)
	Fx.put_creature(s, 1, 0, &"mossback")
	_cast(s, 0, &"cold_snap", -1, [{"player": 1, "lane": 0}])
	assert_true(s.players[1].lanes[0].creature.is_frozen(), "frozen")
	assert_eq(s.players[0].hand.size(), 1, "drew a card")
	return true


func test_avalanche() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"mossback")
	_cast(s, 0, &"avalanche", -1, [{"player": 1, "lane": 0}])
	assert_eq(s.players[1].lanes[0].creature.damage, 3, "3 damage")
	assert_true(s.players[1].lanes[0].creature.is_frozen(), "frozen")
	return true


func test_star_shard() -> bool:
	var s: GameState = Fx.blank()
	var i: int = Fx.give(s, 0, &"star_shard")
	Rules.apply(s, Action.play(0, i, -1, []))
	assert_eq(s.players[0].magic, 3, "free, +1 magic")
	return true


# --- Boop rules ---

func test_boop_blocks() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"sporeling", 1)
	_boop(s, 0, 0)
	assert_eq(Rules.validate(s, Action.boop(0, 0)), "Creature already acted", "second boop")
	Fx.put_creature(s, 0, 1, &"sporeling")
	s.players[0].lanes[1].creature.freeze_turn = s.turn
	assert_eq(Rules.validate(s, Action.boop(0, 1)), "Creature is frozen", "frozen")
	Fx.put_creature(s, 0, 2, &"mossback")
	assert_eq(Rules.validate(s, Action.boop(0, 2)), "No boop ability", "no ability")
	Fx.put_creature(s, 0, 3, &"gumdrop")
	s.players[0].lanes[3].creature.hushed = true
	assert_eq(Rules.validate(s, Action.boop(0, 3)), "No boop ability", "hushed")
	return true


# --- Review Focus ---

func test_building_removed_kills() -> bool:
	var s: GameState = Fx.blank([0, 1, 2, 3], [2, 2, 2, 3])
	Fx.put_creature(s, 0, 1, &"sporeling", 3)
	Fx.put_building(s, 0, 1, &"glowcap_lantern")
	s.active = 1
	s.players[1].cards_played = 1
	var ev: Array[GameEvent] = _cast(s, 1, &"sugar_sprite", 1)
	assert_eq(s.players[0].lanes[1].building, null, "lantern returned")
	assert_eq(s.players[0].lanes[1].creature, null, "sporeling destroyed without its +2 HP")
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


func test_hidden_enemy_not_a_spell_target() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"sugar_sprite")
	s.players[1].lanes[0].creature.hidden = true
	var i: int = Fx.give(s, 0, &"fireball")
	assert_eq(Rules.validate(s, Action.play(0, i, -1, [{"player": 1, "lane": 0}])), "No valid target", "hidden")
	return true


func test_return_to_full_hand() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].discard.append(CardDB.card(&"blazehorn"))
	var i: int = Fx.give(s, 0, &"regrowth")
	for n: int in GameState.HAND_LIMIT:
		Fx.give(s, 0, &"mossback")
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, i, -1, [{"discard": 0}]))
	assert_eq(s.players[0].hand.size(), GameState.HAND_LIMIT, "hand stays full")
	assert_true(&"card_burned" in Fx.types(ev), "burned")
	var ids: Array[StringName] = []
	for c: CardData in s.players[0].discard:
		ids.append(c.id)
	assert_true(&"blazehorn" in ids, "blazehorn back in discard")
	return true


func test_ability_triggered_on_boop() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"sporeling", 1)
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
	s.players[0].magic = 9
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, i, -1, []))
	assert_eq(Fx.types(ev).count(&"ability_triggered"), 1, "once for 3 targets")
	assert_eq(ev[Fx.types(ev).find(&"ability_triggered")].data["lane"], -1, "spell lane -1")
	return true


func test_combo_active_event() -> bool:
	var s: GameState = Fx.blank()
	var ev: Array[GameEvent] = _cast(s, 0, &"star_shard")
	assert_true(&"combo_active" in Fx.types(ev), "after the first card")
	assert_eq(s.players[0].cards_played, 1, "counted")
	ev = _cast(s, 0, &"star_shard")
	assert_true(not &"combo_active" in Fx.types(ev), "only once")
	return true


func test_game_over_mid_cascade() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].hero_hp = 2
	Fx.put_creature(s, 0, 0, &"jellywobble", 3)
	var ev: Array[GameEvent] = []
	Rules.give_keyword(s, 0, 0, &"second_wind", ev)
	s.active = 1
	ev = _cast(s, 1, &"ember_rain")
	var t: Array[StringName] = Fx.types(ev)
	assert_eq(t.count(&"game_over"), 1, "one game over")
	assert_true(not &"second_wind" in t, "no second wind once a hero is down")
	assert_eq(s.winner, 1, "p1 wins")
	assert_eq(t[t.size() - 1], &"game_over", "nothing after game over")
	return true
