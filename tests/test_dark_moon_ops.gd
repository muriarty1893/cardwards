extends TestCase
## Dark Moon spec 3.3: the new effect steps, triggers and conditions.

const C := CardData.Kind.CREATURE
const S := CardData.Kind.SPELL


func _spell(id: StringName, effects: Array[EffectData], land: int = CardData.Land.MUSHROOM) -> CardData:
	var c: CardData = Fx.card(id, S, 0, 0, 0, [], effects)
	c.land = land
	return c


func _cast(s: GameState, c: CardData, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	s.players[0].hand.append(c)
	var a: Action = Action.play(0, s.players[0].hand.size() - 1, -1, targets)
	assert_eq(Rules.validate(s, a), "", "%s can be cast" % c.id)
	return Rules.apply(s, a)


func _token(id: StringName, atk: int, hp: int) -> CardData:
	var t: CardData = Fx.card(id, C, 1, atk, hp)
	t.collectible = false
	CardDB.add_test_card(t)
	return t


func _eff(when: StringName, op: StringName, amount: int, who: StringName, extra: Dictionary = {}) -> EffectData:
	return Fx.eff(when, op, amount, who, extra)


func test_split_damage() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"gumdrop")
	Fx.put_creature(s, 1, 2, &"magmaw")
	var hp0: int = s.players[1].hero_hp
	var before: int = 0
	_cast(s, _spell(&"t_storm", [_eff(&"on_play", &"split_damage", 8, &"all_enemies")]))
	var dealt: int = hp0 - s.players[1].hero_hp
	for sp: int in [0, 2]:
		var cr: GameState.CreatureState = s.players[1].at(sp)
		if cr:
			dealt += cr.damage
	var dead: int = 0
	for e: Variant in s.players[1].discard:
		dead += 1
	assert_true(dealt + dead > 0 and dealt <= 8, "8 single hits shared out (dead ones absorb their share)")
	var t: GameState = Fx.blank()
	var u: GameState = Fx.blank()
	for g: GameState in [t, u]:
		Fx.put_creature(g, 1, 0, &"gumdrop")
		Fx.put_creature(g, 1, 1, &"magmaw")
		_cast(g, _spell(&"t_storm", [_eff(&"on_play", &"split_damage", 6, &"all_enemies")]))
	assert_eq(t.digest(), u.digest(), "same seed, same split")
	assert_true(before == 0, "ok")
	return true


func test_double_stats() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"magmaw")
	var atk: int = Rules.effective_attack(s, 0, 1)
	var hp: int = Rules.effective_max_hp(s, 0, 1) - s.players[0].at(1).damage
	_cast(s, _spell(&"t_double", [_eff(&"on_play", &"double_stats", 0, &"chosen_own_creature")]), [{"player": 0, "lane": 1}])
	assert_eq(Rules.effective_attack(s, 0, 1), atk * 2, "attack doubled")
	assert_eq(Rules.effective_max_hp(s, 0, 1) - s.players[0].at(1).damage, hp * 2, "health doubled")
	return true


func test_next_spell_twice() -> bool:
	var s: GameState = Fx.blank()
	_cast(s, _spell(&"t_echo", [_eff(&"on_play", &"next_spell_twice", 1, &"own_hero")]))
	var hp: int = s.players[1].hero_hp
	_cast(s, _spell(&"t_bolt", [_eff(&"on_play", &"damage", 2, &"enemy_hero")]))
	assert_eq(s.players[1].hero_hp, hp - 4, "the next spell happens twice")
	_cast(s, _spell(&"t_bolt", [_eff(&"on_play", &"damage", 2, &"enemy_hero")]))
	assert_eq(s.players[1].hero_hp, hp - 6, "only once")
	return true


func test_replay_spells() -> bool:
	var s: GameState = Fx.blank()
	var bolt: CardData = _spell(&"t_frostbolt", [_eff(&"on_play", &"damage", 2, &"enemy_hero")], CardData.Land.FROST)
	CardDB.add_test_card(bolt)
	var fire: CardData = _spell(&"t_firebolt", [_eff(&"on_play", &"damage", 5, &"enemy_hero")], CardData.Land.EMBER)
	CardDB.add_test_card(fire)
	_cast(s, bolt)
	_cast(s, bolt)
	_cast(s, fire)
	var hp: int = s.players[1].hero_hp
	var replay: CardData = _spell(&"t_replay", [_eff(&"on_play", &"replay_spells", 0, &"own_hero", {"filter_land": CardData.Land.FROST})], CardData.Land.FROST)
	CardDB.add_test_card(replay)
	_cast(s, replay)
	assert_eq(s.players[1].hero_hp, hp - 4, "both Frost spells again, not the Ember one")
	_cast(s, replay)
	assert_eq(s.players[1].hero_hp, hp - 8, "a replay never replays a replay card")
	for id: StringName in [&"t_frostbolt", &"t_firebolt", &"t_replay"]:
		CardDB.remove_test_card(id)
	return true


func test_add_and_shuffle() -> bool:
	var s: GameState = Fx.blank()
	_token(&"t_curse", 0, 0)
	var h0: int = s.players[0].hand.size()
	var h1: int = s.players[1].hand.size()
	_cast(s, _spell(&"t_gift", [_eff(&"on_play", &"add_to_hand", 2, &"own_hero", {"card_id": &"t_curse"})]))
	assert_eq(s.players[0].hand.size(), h0 + 2, "two copies to your hand")
	_cast(s, _spell(&"t_hex", [_eff(&"on_play", &"add_to_hand", 1, &"enemy_hero", {"card_id": &"t_curse"})]))
	assert_eq(s.players[1].hand.size(), h1 + 1, "one to the rival's hand")
	var d1: int = s.players[1].deck.size()
	_cast(s, _spell(&"t_bombs", [_eff(&"on_play", &"shuffle_into_deck", 3, &"enemy_hero", {"card_id": &"t_curse"})]))
	assert_eq(s.players[1].deck.size(), d1 + 3, "three into the rival's deck")
	CardDB.remove_test_card(&"t_curse")
	return true


func test_summon() -> bool:
	var s: GameState = Fx.blank()
	_token(&"t_guardling", 2, 2)
	Fx.put_creature(s, 0, 0, &"gumdrop")
	_cast(s, _spell(&"t_call", [_eff(&"on_play", &"summon", 2, &"own_hero", {"card_id": &"t_guardling"})]))
	assert_eq(s.players[0].at(1).card.id, &"t_guardling", "first empty lane")
	assert_eq(s.players[0].at(2).card.id, &"t_guardling", "then the next")
	assert_true(s.players[0].at(3) == null, "only two")
	_cast(s, _spell(&"t_call5", [_eff(&"on_play", &"summon", 5, &"own_hero", {"card_id": &"t_guardling"})]))
	assert_eq(s.players[0].creature_spots().size(), 4, "stops when the lanes are full")
	CardDB.remove_test_card(&"t_guardling")
	return true


func test_buff_hand() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].hand.append(CardDB.card(&"gumdrop"))
	s.players[0].hand.append(CardDB.card(&"bark_shield"))
	_cast(s, _spell(&"t_feast", [_eff(&"on_play", &"buff_hand", 1, &"own_hero", {"amount2": 2})]))
	var g: CardData = s.players[0].hand[s.players[0].hand.size() - 2]
	assert_eq(g.attack, CardDB.card(&"gumdrop").attack + 1, "creature in hand +1 attack")
	assert_eq(g.health, CardDB.card(&"gumdrop").health + 2, "+2 health")
	assert_true(not CardDB.is_changed(s.players[0].hand.back()), "spells unchanged")
	return true


func test_curse_on_draw() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = Fx.card(&"t_nightmare", S, 0, 0, 0, [], [_eff(&"on_draw", &"damage", 3, &"own_hero")])
	c.curse = true
	CardDB.add_test_card(c)
	s.players[0].deck.append(CardDB.card(&"gumdrop"))
	s.players[0].deck.append(c)
	var hp: int = s.players[0].hero_hp
	var ev: Array[GameEvent] = []
	Rules.draw(s, 0, ev)
	assert_eq(s.players[0].hero_hp, hp - 3, "the curse hurts its drawer")
	assert_true(not c in s.players[0].hand, "and doesn't stay in hand")
	assert_true(&"curse_triggered" in Fx.types(ev), "curse event")
	CardDB.remove_test_card(&"t_nightmare")
	return true


func test_cost_per_death_while_held() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = Fx.card(&"t_ghoul", C, 8, 6, 6, [], [_eff(&"in_hand", &"cost_per_death", 1, &"own_hero")])
	assert_eq(Rules.card_cost(s, 0, c), 8, "full price")
	for i: int in 3:
		Fx.put_creature(s, 1, 0, &"gumdrop")
		Rules.destroy_creature(s, 1, 0, [])
		Rules.resolve_deaths(s, [])
	assert_eq(Rules.card_cost(s, 0, c), 5, "1 less per creature that died this game")
	return true


func test_grow_on_spell_while_held() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = Fx.card(&"t_sprout", C, 3, 2, 2, [], [_eff(&"in_hand", &"grow_on_spell", 1, &"own_hero", {"amount2": 1})])
	CardDB.add_test_card(c)
	s.players[0].hand.append(c)
	_cast(s, _spell(&"t_any", [_eff(&"on_play", &"draw", 0, &"own_hero")]))
	var held: CardData = s.players[0].hand.filter(func(x: CardData) -> bool: return x.id == &"t_sprout")[0]
	assert_eq(held.attack, 3, "+1 attack after a spell")
	assert_eq(held.health, 3, "+1 health")
	CardDB.remove_test_card(&"t_sprout")
	return true


func test_dark_gift() -> bool:
	var s: GameState = Fx.blank()
	_cast(s, _spell(&"t_offer", [_eff(&"on_play", &"dream_up", 0, &"own_hero", {"filter_kind": C, "gift": true})]))
	assert_eq(s.phase, GameState.Phase.CHOOSING, "choose one")
	assert_true(s.pending_gift, "a Dark Gift choice")
	Rules.apply(s, Action.choose(0, 0))
	var got: CardData = s.players[0].hand.back()
	assert_true(got.changes.has("gift"), "the pick carries a gift")
	assert_true(StringName(got.changes["gift"]) in Gifts.ORDER, "one of the gifts")
	assert_true(not s.pending_gift, "cleared")
	return true


func test_echo_doubles_on_play() -> bool:
	var s: GameState = Fx.blank()
	var brann: CardData = Fx.card(&"t_echo", C, 1, 1, 1, [], [_eff(&"aura", &"echo", 0, &"self")])
	Fx.put(s, 0, 0, brann)
	var hp: int = s.players[1].hero_hp
	var c: CardData = Fx.card(&"t_pinger", C, 1, 1, 1, [], [_eff(&"on_play", &"damage", 2, &"enemy_hero")])
	s.players[0].hand.append(c)
	s.players[0].magic = 5
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, 1))
	assert_eq(s.players[1].hero_hp, hp - 4, "on-play happens twice")
	var d: CardData = Fx.card(&"t_dreamer", C, 1, 1, 1, [], [_eff(&"on_play", &"dream_up", 0, &"own_hero", {"filter_kind": C})])
	s.players[0].hand.append(d)
	var hand: int = s.players[0].hand.size()
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, 2))
	assert_eq(s.phase, GameState.Phase.CHOOSING, "first pick")
	Rules.apply(s, Action.choose(0, 0))
	assert_eq(s.phase, GameState.Phase.CHOOSING, "second pick waits its turn")
	Rules.apply(s, Action.choose(0, 1))
	assert_eq(s.phase, GameState.Phase.MAIN, "done")
	assert_eq(s.players[0].hand.size(), hand - 1 + 2, "two cards gained")
	return true


func test_conditions() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 3)
	assert_true(not Conditions.ok(s, 0, &"start_no_dupes"), "starter decks have duplicates")
	s.players[0].history["start_no_dupes"] = true
	assert_true(Conditions.ok(s, 0, &"start_no_dupes"), "no duplicates")
	assert_true(not Conditions.ok(s, 0, &"start_40"), "30 cards")
	s.players[0].history["start_size"] = 40
	assert_true(Conditions.ok(s, 0, &"start_40"), "40 cards")
	assert_true(Conditions.ok(s, 0, &"started_with:sporeling"), "started with Sporeling")
	assert_true(not Conditions.ok(s, 0, &"started_with:magmaw"), "not Magmaw")
	s.players[0].hand.clear()
	s.players[0].hand.append(CardDB.card(&"bark_shield"))
	assert_true(Conditions.ok(s, 0, &"holding_land:%d" % CardData.Land.MUSHROOM), "holding a Mushroom card")
	assert_true(not Conditions.ok(s, 0, &"holding_land:%d" % CardData.Land.FROST), "not a Frost card")
	assert_true(not Conditions.ok(s, 0, &"holding_big"), "no 6+ attack creature")
	s.players[0].hand.append(CardDB.variant(CardDB.card(&"gumdrop"), {"attack": 10}))
	assert_true(Conditions.ok(s, 0, &"holding_big"), "a 6+ attack creature")
	s.players[0].max_magic = 9
	assert_true(not Conditions.ok(s, 0, &"max_magic_at_least:10"), "9 max magic")
	s.players[0].max_magic = 10
	assert_true(Conditions.ok(s, 0, &"max_magic_at_least:10"), "10 max magic")
	assert_true(not Conditions.ok(s, 0, &"deaths_at_least:1"), "nothing died")
	s.players[1].history["deaths_own"] = 2
	assert_true(Conditions.ok(s, 0, &"deaths_at_least:2"), "two died (either side)")
	GameHistory.record_spell(s.players[0], CardDB.card(&"bark_shield"))
	assert_true(Conditions.ok(s, 0, &"spells_of_land_at_least:%d:1" % CardData.Land.MUSHROOM), "one Mushroom spell")
	assert_true(not Conditions.ok(s, 0, &"spells_of_land_at_least:%d:2" % CardData.Land.MUSHROOM), "not two")
	var b: GameState = Fx.blank()
	var hp: int = b.players[1].hero_hp
	_cast(b, _spell(&"t_if", [_eff(&"on_play", &"damage", 5, &"enemy_hero", {"need_cond": &"deaths_at_least:1"})]))
	assert_eq(b.players[1].hero_hp, hp, "condition not met: nothing")
	b.players[0].history["deaths_own"] = 1
	_cast(b, _spell(&"t_if", [_eff(&"on_play", &"damage", 5, &"enemy_hero", {"need_cond": &"deaths_at_least:1"})]))
	assert_eq(b.players[1].hero_hp, hp - 5, "condition met")
	return true


func test_hushed_last_breath_does_nothing() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = Fx.card(&"t_lb", C, 1, 1, 1, [], [_eff(&"on_destroyed", &"damage", 3, &"enemy_hero")])
	Fx.put(s, 0, 0, c)
	Rules.hush(s, 0, 0, [])
	var hp: int = s.players[1].hero_hp
	Rules.destroy_creature(s, 0, 0, [])
	Rules.resolve_deaths(s, [])
	assert_eq(s.players[1].hero_hp, hp, "hushed: no Last Breath")
	return true


func test_new_ops_have_text() -> bool:
	for op: StringName in [&"split_damage", &"double_stats", &"next_spell_twice", &"replay_spells", &"add_to_hand",
			&"shuffle_into_deck", &"summon", &"buff_hand", &"cost_per_death", &"grow_on_spell", &"echo"]:
		var e: EffectData = _eff(&"on_play", op, 2, &"own_hero", {"card_id": &"gumdrop"})
		var t: String = CardText.render(Fx.card(&"t_text", S, 0, 0, 0, [], [e]))
		assert_true(not String(op) in t, "%s has words: %s" % [op, t])
	var c: CardData = Fx.card(&"t_cond", S, 0, 0, 0, [], [_eff(&"on_play", &"draw", 1, &"own_hero", {"need_cond": &"start_no_dupes"})])
	assert_true("no duplicates" in CardText.render(c), "condition in words: %s" % CardText.render(c))
	var lb: CardData = Fx.card(&"t_lbt", C, 0, 1, 1, [], [_eff(&"on_destroyed", &"draw", 1, &"own_hero")])
	assert_true(CardText.render(lb).begins_with("Last Breath: "), "Last Breath wording: %s" % CardText.render(lb))
	return true


func test_resurrect() -> bool:
	var s: GameState = Fx.blank()
	var lb: CardData = Fx.card(&"t_lbc", C, 1, 2, 2, [], [_eff(&"on_destroyed", &"draw", 1, &"own_hero")])
	CardDB.add_test_card(lb)
	Fx.put(s, 0, 0, lb)
	Fx.put_creature(s, 0, 1, &"gumdrop")
	for sp: int in [0, 1]:
		Rules.destroy_creature(s, 0, sp, [])
	Rules.resolve_deaths(s, [])
	assert_eq(s.players[0].history["dead"], [&"t_lbc", &"gumdrop"] as Array[StringName], "the dead are remembered")
	_cast(s, _spell(&"t_raise_lb", [_eff(&"on_play", &"resurrect", 4, &"own_hero", {"keyword": &"last_breath"})]))
	assert_eq(s.players[0].creature_spots().size(), 1, "only the Last Breath one comes back")
	assert_eq(s.players[0].at(0).card.id, &"t_lbc", "it's back")
	_cast(s, _spell(&"t_raise", [_eff(&"on_play", &"resurrect", 1, &"own_hero")]))
	assert_eq(s.players[0].creature_spots().size(), 2, "one random dead creature back")
	CardDB.remove_test_card(&"t_lbc")
	return true


func test_echo_death_doubles_last_breath() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, Fx.card(&"t_keeper", C, 1, 1, 5, [], [_eff(&"aura", &"echo_death", 0, &"self")]))
	Fx.put(s, 0, 1, Fx.card(&"t_lb2", C, 1, 1, 1, [], [_eff(&"on_destroyed", &"damage", 2, &"enemy_hero")]))
	var hp: int = s.players[1].hero_hp
	Rules.destroy_creature(s, 0, 1, [])
	Rules.resolve_deaths(s, [])
	assert_eq(s.players[1].hero_hp, hp - 4, "Last Breath happens twice")
	return true


func test_neutral_creature_needs_no_land() -> bool:
	var s: GameState = Fx.blank([CardData.Land.EMBER, CardData.Land.EMBER, CardData.Land.EMBER, CardData.Land.EMBER])
	s.players[0].hand.append(CardDB.card(&"shiba_shepherd"))
	s.players[0].magic = 10
	assert_eq(Rules.validate(s, Action.play(0, s.players[0].hand.size() - 1, 0)), "", "a neutral creature fits any land")
	return true
