extends TestCase

const N := Action.Hit.NORMAL
const C := Action.Hit.CRIT
const G := Action.Hit.GLANCE


func _attack_phase(s: GameState) -> void:
	Rules.apply(s, Action.begin_attacks(s.active))


func test_damage_table() -> bool:
	assert_eq(Combat.attack_damage(4, N, false, false), 4, "4 normal")
	assert_eq(Combat.attack_damage(4, C, false, false), 6, "4 crit")
	assert_eq(Combat.attack_damage(5, C, false, false), 8, "5 crit rounds up")
	assert_eq(Combat.attack_damage(5, G, false, false), 2, "5 glance rounds down")
	assert_eq(Combat.attack_damage(1, G, false, false), 1, "glance min 1")
	assert_eq(Combat.attack_damage(6, N, true, false), 3, "block halves")
	assert_eq(Combat.attack_damage(6, C, true, false), 4, "crit then block: 9/2")
	assert_eq(Combat.attack_damage(3, N, false, true), 2, "ice wall -1")
	assert_eq(Combat.attack_damage(1, N, false, true), 1, "ice wall min 1")
	assert_eq(Combat.hero_damage(5, C), 8, "hero crit")
	return true


func test_zero_attack() -> bool:
	assert_eq(Combat.attack_damage(0, G, false, false), 0, "0 glance")
	assert_eq(Combat.attack_damage(0, C, false, false), 0, "0 crit")
	assert_eq(Combat.attack_damage(0, N, false, true), 0, "0 ice wall")
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"snowmite")
	Fx.put_creature(s, 1, 2, &"mossback")
	Fx.put_building(s, 1, 2, &"frost_spire")
	_attack_phase(s)
	Rules.apply(s, Action.attack(0, 2, G, false))
	assert_eq(s.players[1].lanes[2].creature.damage, 0, "defender unharmed")
	return true


func test_empty_lane_hits_hero() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"cinderpup")
	_attack_phase(s)
	var ev: Array[GameEvent] = Rules.apply(s, Action.attack(0, 0, C, true))
	assert_eq(s.players[1].hero_hp, 20, "25 - ceil(4.5)")
	assert_true(&"attack" in Fx.types(ev) and &"hero_damaged" in Fx.types(ev), "events")
	return true


func test_creature_hit() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"flarebeak")
	Fx.put_creature(s, 1, 1, &"mossback")
	Fx.put_building(s, 1, 1, &"ice_wall")
	_attack_phase(s)
	Rules.apply(s, Action.attack(0, 1, N, true))
	assert_eq(s.players[1].lanes[1].creature.damage, 1, "4 -1 wall = 3, block -> 1")
	assert_eq(s.players[0].lanes[1].creature.damage, 0, "no counter damage")
	assert_eq(Rules.validate(s, Action.attack(0, 1, N, false)), "Can't attack", "only once")
	return true


func test_first_turn_no_attack() -> bool:
	var s: GameState = Fx.blank()
	s.turn = 1
	Fx.put_creature(s, 0, 0, &"cinderpup")
	_attack_phase(s)
	assert_eq(Rules.attackers(s), [] as Array[int], "no attackers turn 1")
	return true


func test_played_this_turn_can_attack() -> bool:
	var s: GameState = Fx.blank()
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cinderpup"), 3))
	_attack_phase(s)
	assert_eq(Rules.attackers(s), [3] as Array[int], "fresh creature attacks")
	return true


func test_booped_cannot_attack() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.put_creature(s, 0, 1, &"cinderpup")
	Fx.fill_deck(s, 0, &"mossback", 2)
	Rules.apply(s, Action.boop(0, 0))
	_attack_phase(s)
	assert_eq(Rules.attackers(s), [1] as Array[int], "booped creature skipped")
	return true


func test_frostfang_freezes() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"frostfang")
	Fx.put_creature(s, 1, 0, &"sporeling")
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	_attack_phase(s)
	var ev: Array[GameEvent] = Rules.apply(s, Action.attack(0, 0, N, false))
	assert_true(&"frozen" in Fx.types(ev), "frozen event")
	Rules.apply(s, Action.end_turn(0))
	assert_eq(s.active, 1, "enemy turn")
	assert_eq(Rules.validate(s, Action.boop(1, 0)), "Creature is frozen", "can't boop while frozen")
	_attack_phase(s)
	assert_eq(Rules.attackers(s), [] as Array[int], "can't attack while frozen")
	var ev2: Array[GameEvent] = Rules.apply(s, Action.end_turn(1))
	assert_true(&"unfrozen" in Fx.types(ev2), "unfrozen at end of its turn")
	assert_true(not s.players[1].lanes[0].creature.is_frozen(), "thawed")
	return true


func test_cold_snap_own_turn() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"cinderpup")
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cold_snap"), -1, [{"player": 1, "lane": 0}]))
	_attack_phase(s)
	Rules.apply(s, Action.end_turn(0))
	assert_true(s.players[1].lanes[0].creature.is_frozen(), "still frozen on enemy turn")
	_attack_phase(s)
	assert_eq(Rules.attackers(s), [] as Array[int], "can't attack")
	Rules.apply(s, Action.end_turn(1))
	assert_true(not s.players[1].lanes[0].creature.is_frozen(), "cleared after its turn")
	return true


func test_end_turn_needs_attack_phase() -> bool:
	var s: GameState = Fx.blank()
	assert_eq(Rules.validate(s, Action.end_turn(0)), "Can't do that now", "must begin attacks first")
	return true


func test_win() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].hero_hp = 3
	Fx.put_creature(s, 0, 0, &"flarebeak")
	_attack_phase(s)
	var ev: Array[GameEvent] = Rules.apply(s, Action.attack(0, 0, N, false))
	assert_eq(s.phase, GameState.Phase.OVER, "over")
	assert_eq(s.winner, 0, "p0 wins")
	assert_eq(ev[ev.size() - 1].type, &"game_over", "game_over event last")
	return true


func test_simultaneous_death() -> bool:
	var s: GameState = Fx.blank()
	s.active = 1
	s.players[0].hero_hp = 0
	s.players[1].hero_hp = 0
	var ev: Array[GameEvent] = []
	Rules.resolve_deaths(s, ev)
	assert_eq(s.winner, 1, "active player wins")
	return true


func test_after_game_over() -> bool:
	var s: GameState = Fx.blank()
	s.phase = GameState.Phase.OVER
	var i: int = Fx.give(s, 0, &"mossback")
	for a: Action in [Action.play(0, i, 0), Action.boop(0, 0), Action.begin_attacks(0), Action.attack(0, 0, N, false), Action.end_turn(0)]:
		assert_eq(Rules.validate(s, a), "Game is over", "rejected %d" % a.type)
	return true
