extends TestCase
## Sunny Dunes rules (Sunny Dunes spec 1-2): the land, Sun-baked, Scorch and Thaw, Sturdy, Bask,
## and the Heatwave field's targets.

const C := CardData.Kind.CREATURE
const D := CardData.Land.DUNES


func _dune_card(id: StringName, atk: int, hp: int, kws: Array[StringName] = []) -> CardData:
	var c: CardData = Fx.card(id, C, 1, atk, hp, kws)
	c.land = D
	return c


func test_dunes_is_a_real_land_after_neutral() -> bool:
	assert_eq(int(CardData.Land.DUNES), 5, "appended after NEUTRAL")
	assert_eq(CardData.LAND_NAMES[D], "Sunny Dunes", "name")
	assert_true(D in CardData.REAL_LANDS and not CardData.Land.NEUTRAL in CardData.REAL_LANDS, "real lands")
	assert_eq(Lands.QUIRKS[D], "Sun-baked", "quirk name")
	return true


func test_sun_baked_gives_armour_per_creature_at_home() -> bool:
	var s: GameState = Fx.blank([5, 5, 4, 4])
	Fx.put(s, 0, 0, _dune_card(&"a", 1, 3))
	Fx.put(s, 0, 1, _dune_card(&"b", 1, 3))
	Fx.put(s, 0, 2, _dune_card(&"c", 1, 3))  # on Meadow: not at home
	var ev: Array[GameEvent] = []
	Rules._start_of_turn_lands(s, 0, ev)
	assert_eq(s.players[0].armour, 2, "two at home: 2 armour")
	return true


func test_scorch_adds_one_fire_damage_on_dunes() -> bool:
	var s: GameState = Fx.blank([4, 4, 4, 4], [5, 4, 4, 4])
	Fx.put(s, 1, 0, Fx.card(&"foe", C, 1, 1, 9))
	s.players[0].magic = 9
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, Fx.give(s, 0, &"fireball"), -1, [{"player": 1, "lane": 0}]))
	assert_eq(s.players[1].lanes[0].creature.damage, 4, "3 + scorch 1")
	assert_true(&"land_reaction" in Fx.types(ev), "reaction event")
	assert_eq(Lands.reaction(CardData.Land.EMBER, D), &"scorch", "ember on dunes")
	return true


func test_thaw_unfreezes_and_heals() -> bool:
	var s: GameState = Fx.blank([3, 4, 4, 4])
	var cr: GameState.CreatureState = Fx.put(s, 0, 0, Fx.card(&"me", C, 1, 1, 9))
	cr.damage = 5
	cr.freeze_turn = s.turn
	var spell: CardData = Fx.card(&"sunbeam", CardData.Kind.SPELL, 1, 0, 0, [], [Fx.eff(&"on_play", &"heal", 1, &"chosen_own_creature")])
	spell.land = D
	var ev: Array[GameEvent] = []
	var info: Dictionary = Lands.react_before(s, spell, &"heal", {"player": 0, "lane": 0}, ev)
	assert_eq(info.get("reaction", &""), &"thaw", "dunes spell on frost: thaw")
	Lands.react_after(s, 0, info, {"player": 0, "lane": 0}, ev)
	assert_eq(cr.freeze_turn, -1, "unfrozen")
	assert_eq(cr.damage, 3, "healed 2")
	return true


func test_sturdy_takes_one_less() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, Fx.card(&"rock", C, 1, 1, 5, [&"sturdy"]))
	var ev: Array[GameEvent] = []
	assert_eq(Rules.damage_creature(s, 0, 0, 3, {"player": 1, "lane": -1, "kind": &"spell"}, ev), 2, "3 → 2")
	assert_eq(Rules.damage_creature(s, 0, 0, 1, {"player": 1, "lane": -1, "kind": &"spell"}, ev), 0, "1 → 0")
	assert_eq(s.players[0].lanes[0].creature.damage, 2, "total 2")
	return true


func test_sturdy_bubble_not_popped_by_zero() -> bool:
	var s: GameState = Fx.blank()
	var cr: GameState.CreatureState = Fx.put(s, 0, 0, Fx.card(&"rock", C, 1, 1, 5, [&"sturdy", &"bubble"]))
	cr.bubble = true
	var ev: Array[GameEvent] = []
	Rules.damage_creature(s, 0, 0, 1, {"player": 1, "lane": -1, "kind": &"spell"}, ev)
	assert_true(cr.bubble, "a hit Sturdy shrugs off doesn't pop the bubble")
	return true


func test_bask_grows_only_without_attacking() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, Fx.card(&"lizard", C, 1, 1, 2, [&"bask"]))
	var busy: GameState.CreatureState = Fx.put(s, 0, 1, Fx.card(&"lizard2", C, 1, 1, 2, [&"bask"]))
	busy.attacks_used = 1
	s.active = 0
	var ev: Array[GameEvent] = []
	Rules._end_turn(s, ev)
	assert_eq([Rules.effective_attack(s, 0, 0), Rules.effective_max_hp(s, 0, 0)], [2, 3], "rested: +1/+1")
	assert_eq([Rules.effective_attack(s, 0, 1), Rules.effective_max_hp(s, 0, 1)], [1, 2], "attacked: no growth")
	return true


func test_heatwave_targets_creatures_away_from_home() -> bool:
	var s: GameState = Fx.blank([5, 4, 4, 4], [4, 4, 4, 4])
	Fx.put(s, 0, 0, _dune_card(&"home", 1, 3))
	Fx.put(s, 0, 1, _dune_card(&"away", 1, 3))
	Fx.put(s, 1, 0, Fx.card(&"foe", C, 1, 1, 3))
	var ts: Array[Dictionary] = Targeting.resolve(s, 0, -1, &"all_away_creatures", [], {})
	assert_eq(ts, [{"player": 0, "lane": 1}, {"player": 1, "lane": 0}] as Array[Dictionary], "away creatures on both sides")
	return true
