extends TestCase
## Legends & Grudges (2026-11-25): Drain, Scaling counts, "whenever a creature dies".


func _state(land: int) -> GameState:
	var s: GameState = Fx.blank([land, land, land, land], [land, land, land, land])
	s.players[0].magic = 10
	s.players[0].max_magic = 10
	return s


func _play(s: GameState, id: StringName, lane: int, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	var i: int = Fx.give(s, 0, id)
	var a: Action = Action.play(0, i, lane, targets)
	assert_eq(Rules.validate(s, a), "", "%s can be played" % id)
	return Rules.apply(s, a)


func test_drain_takes_hp_from_the_opposing_creature() -> bool:
	var s: GameState = _state(CardData.Land.MUSHROOM)
	Fx.put_creature(s, 1, 0, &"magmaw")
	var ev: Array[GameEvent] = _play(s, &"bog_biter", 0)
	assert_eq(s.players[1].at(0).damage, 1, "the opposing creature took 1")
	assert_eq(Rules.effective_max_hp(s, 0, 0), 3, "Bog Biter grew to 3 HP")
	assert_true(&"drained" in Fx.types(ev), "a drained event for the view")
	return true


func test_drain_from_an_empty_lane_hits_the_hero() -> bool:
	var s: GameState = _state(CardData.Land.MUSHROOM)
	var hp: int = s.players[1].hero_hp
	_play(s, &"bog_biter", 1)
	assert_eq(s.players[1].hero_hp, hp - 1, "the enemy hero lost 1")
	assert_eq(Rules.effective_max_hp(s, 0, 1), 3, "Bog Biter grew to 3 HP")
	return true


func test_hero_hits_are_counted_and_scale_damage() -> bool:
	var s: GameState = _state(CardData.Land.EMBER)
	var ev: Array[GameEvent] = []
	for i: int in 2:
		Rules.damage_hero(s, 0, 2, ev)
	Rules.damage_hero(s, 0, 0, ev)
	assert_eq(int(s.players[0].history["hero_hits"]), 2, "two hits (a 0 hit doesn't count)")
	Fx.put_creature(s, 1, 0, &"magmaw")
	_play(s, &"grudge_bolt", -1, [{"player": 1, "lane": 0}])
	assert_eq(s.players[1].at(0).damage, 3, "1 + 2 hits")
	return true


func test_vexa_hits_the_enemy_hero_with_every_grudge() -> bool:
	var s: GameState = _state(CardData.Land.EMBER)
	var ev: Array[GameEvent] = []
	Rules.damage_hero(s, 0, 1, ev)
	Rules.damage_hero(s, 0, 1, ev)
	var hp: int = s.players[1].hero_hp
	_play(s, &"vexa_grudgekeeper", 0)
	assert_eq(s.players[1].hero_hp, hp - 3, "1 + 2 hits")
	return true


func test_shield_bash_deals_your_armour() -> bool:
	var s: GameState = _state(CardData.Land.DUNES)
	var ev: Array[GameEvent] = []
	Rules.gain_armour(s, 0, 5, ev)
	Fx.put_creature(s, 1, 0, &"magmaw")
	_play(s, &"shield_bash", -1, [{"player": 1, "lane": 0}])
	assert_eq(s.players[1].at(0), null, "5 armour, 5 damage kills a 4 HP Magmaw")
	return true


func test_mawra_doubles_whenever_a_creature_dies() -> bool:
	var s: GameState = _state(CardData.Land.NEUTRAL)
	Fx.put_creature(s, 0, 0, &"mawra_grave_glutton")
	Fx.put_creature(s, 1, 1, &"gumdrop")
	Fx.put_creature(s, 1, 2, &"gumdrop")
	var ev: Array[GameEvent] = []
	Rules.destroy_creature(s, 1, 1, ev)
	Rules.resolve_deaths(s, ev)
	assert_eq([Rules.effective_attack(s, 0, 0), Rules.effective_max_hp(s, 0, 0)], [2, 4], "doubled once")
	Rules.destroy_creature(s, 1, 2, ev)
	Rules.resolve_deaths(s, ev)
	assert_eq([Rules.effective_attack(s, 0, 0), Rules.effective_max_hp(s, 0, 0)], [4, 8], "doubled twice")
	return true


func test_carrion_hound_grows_on_any_death_but_not_its_own() -> bool:
	var s: GameState = _state(CardData.Land.MUSHROOM)
	Fx.put_creature(s, 0, 0, &"carrion_hound")
	Fx.put_creature(s, 0, 1, &"gumdrop")
	var ev: Array[GameEvent] = []
	Rules.destroy_creature(s, 0, 1, ev)
	Rules.resolve_deaths(s, ev)
	assert_eq(Rules.effective_attack(s, 0, 0), 3, "+1 ATK from its friend's death")
	Rules.destroy_creature(s, 0, 0, ev)
	Rules.resolve_deaths(s, ev)
	assert_eq(s.players[0].at(0), null, "it died without errors")
	return true


func test_sugar_hoarder_counts_the_hand() -> bool:
	var s: GameState = _state(CardData.Land.CANDY)
	for i: int in 3:
		Fx.give(s, 0, &"gumdrop")
	_play(s, &"sugar_hoarder", 0)
	assert_eq(s.players[0].at(0).atk_bonus, 3, "+3: three cards left in hand")
	return true


func test_hailmother_splits_her_attack_each_turn() -> bool:
	var s: GameState = _state(CardData.Land.FROST)
	Fx.put_creature(s, 0, 0, &"hailmother_ysra")
	var hp: int = s.players[1].hero_hp
	var ev: Array[GameEvent] = []
	Effects.run(s, 0, 0, CardDB.card(&"hailmother_ysra"), &"start_of_turn", [], ev)
	assert_eq(hp - s.players[1].hero_hp, 5, "5 ATK split over the only enemy, the hero")
	return true


func test_scaling_text_and_counts_exist() -> bool:
	for k: StringName in Scaling.ALL:
		assert_true(Scaling.each_text(k) != "for each " + String(k) and Scaling.total_text(k) != String(k), "%s has words" % k)
	return true


func test_preview_shows_the_number_now() -> bool:
	var s: GameState = _state(CardData.Land.CANDY)
	var ev: Array[GameEvent] = []
	Rules.damage_hero(s, 0, 1, ev)
	Rules.damage_hero(s, 0, 1, ev)
	assert_eq(Scaling.preview(s, 0, CardDB.card(&"grudge_bolt")), 3, "1 + 2 hits")
	assert_eq(Scaling.preview(s, 0, CardDB.card(&"gumdrop")), -1, "plain cards don't grow")
	s.players[0].hand.append(CardDB.card(&"duchess_bonbonpaw"))
	s.players[0].hand.append(CardDB.card(&"gumdrop"))
	assert_eq(Scaling.preview(s, 0, CardDB.card(&"duchess_bonbonpaw")), 3, "gumdrop + two Sweet Treats")
	return true


func test_hand_card_shows_the_now_badge() -> bool:
	var w := CardWidget.new()
	w.setup(CardDB.card(&"grudge_bolt"), 0)
	w.set_now(4)
	assert_eq(w.now_value(), 4, "badge shows 4")
	w.set_now(-1)
	assert_eq(w.now_value(), -1, "hidden")
	w.free()
	return true
