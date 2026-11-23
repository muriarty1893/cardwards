extends TestCase
## Hearthstone-style combat (Rules 2.0 spec 3.4): choose a target, the defender hits back.

const N := Action.Hit.NORMAL
const C := Action.Hit.CRIT
const G := Action.Hit.GLANCE
const CR := CardData.Kind.CREATURE


func _mk(atk: int, hp: int, kws: Array[StringName] = [], effs: Array[EffectData] = []) -> CardData:
	return Fx.card(&"c%d_%d" % [atk, hp], CR, 1, atk, hp, kws, effs)


func _hit(s: GameState, lane: int, target_lane: int, hit: Action.Hit = N, blocked: bool = false) -> Array[GameEvent]:
	return Rules.apply(s, Action.attack(s.active, lane, target_lane, hit, blocked))


func test_damage_table() -> bool:
	assert_eq(Combat.attack_damage(4, N, false, 0), 4, "4 normal")
	assert_eq(Combat.attack_damage(4, C, false, 0), 6, "4 crit")
	assert_eq(Combat.attack_damage(5, C, false, 0), 8, "5 crit rounds up")
	assert_eq(Combat.attack_damage(5, G, false, 0), 2, "5 glance rounds down")
	assert_eq(Combat.attack_damage(1, G, false, 0), 1, "glance min 1")
	assert_eq(Combat.attack_damage(6, N, true, 0), 3, "block halves")
	assert_eq(Combat.attack_damage(6, C, true, 0), 4, "crit then block: 9/2")
	assert_eq(Combat.attack_damage(3, N, false, 1), 2, "ice wall -1")
	assert_eq(Combat.attack_damage(1, N, false, 1), 1, "ice wall min 1")
	assert_eq(Combat.attack_damage(0, C, false, 1), 0, "0 stays 0")
	assert_eq(Combat.hero_damage(5, C), 8, "hero crit")
	assert_eq(Combat.hit_back_damage(3, 0), 3, "hit-back")
	assert_eq(Combat.hit_back_damage(3, 1), 2, "ice wall on hit-back")
	assert_eq(Combat.hit_back_damage(1, 1), 1, "min 1")
	assert_eq(Combat.hit_back_damage(0, 1), 0, "0 stays 0")
	return true


func test_attack_creature_hit_back() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(3, 5))
	var d: GameState.CreatureState = Fx.put(s, 1, 2, _mk(2, 4))
	var ev: Array[GameEvent] = _hit(s, 0, 2)
	assert_eq([d.damage, a.damage, a.attacks_used], [3, 2, 1], "3 dealt, 2 back, one attack used")
	var atk: GameEvent = ev[Fx.types(ev).find(&"attack")]
	assert_eq([atk.data["lane"], atk.data["target_lane"]], [0, 2], "attack event lanes")
	return true


func test_attack_hero_no_hit_back() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 1, _mk(4, 4))
	Fx.put(s, 1, 1, _mk(5, 5))
	_hit(s, 1, -1)
	assert_eq(s.players[1].hero_hp, GameState.START_HP - 4, "hero start - 4")
	assert_eq(a.damage, 0, "no hit-back from heroes")
	return true


func test_mutual_kill_simultaneous() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(3, 3))
	Fx.put(s, 1, 3, _mk(3, 3))
	var t: Array[StringName] = Fx.types(_hit(s, 0, 3))
	assert_true(s.players[0].lanes[0].creature == null and s.players[1].lanes[3].creature == null, "both destroyed")
	assert_true(t.rfind(&"creature_damaged") < t.find(&"creature_destroyed"), "both damaged before either dies")
	return true


func test_bars_change_attack_not_hit_back() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(4, 9))
	var d: GameState.CreatureState = Fx.put(s, 1, 0, _mk(2, 20))
	_hit(s, 0, 0, C, true)
	assert_eq(d.damage, 3, "crit 6, blocked 3")
	assert_eq(a.damage, 2, "hit-back unchanged")
	Fx.put_building(s, 1, 0, &"ice_wall")
	a.attacks_used = 0
	_hit(s, 0, 0, N, false)
	assert_eq(d.damage, 6, "ice wall: 4 - 1")
	return true


func test_ice_wall_reduces_hit_back() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 2, _mk(2, 9))
	Fx.put_building(s, 0, 2, &"ice_wall")
	Fx.put(s, 1, 0, _mk(3, 9))
	Fx.put(s, 1, 1, _mk(0, 9))
	_hit(s, 2, 0)
	assert_eq(a.damage, 2, "hit-back 3 - 1")
	a.attacks_used = 0
	a.xp = 0  # no level-up heal in between
	_hit(s, 2, 1)
	assert_eq(a.damage, 2, "0-attack defender: no hit-back even with min 1")
	return true


func test_frost_spire_lowers_hit_back() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(1, 9))
	Fx.put_building(s, 0, 2, &"frost_spire")
	Fx.put(s, 1, 2, _mk(3, 9))
	_hit(s, 0, 2)
	assert_eq(a.damage, 2, "defender across the spire hits back for 3 - 1")
	return true


func test_guard_forces_target() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(2, 9))
	var g: GameState.CreatureState = Fx.put(s, 1, 1, _mk(1, 5, [&"guard"]))
	Fx.put(s, 1, 3, _mk(2, 2))
	assert_eq(Rules.attack_targets(s, 0, 0), [1] as Array[int], "only the guard")
	assert_eq(Rules.validate(s, Action.attack(0, 0, 3)), "Must attack a Guard", "message")
	assert_eq(Rules.validate(s, Action.attack(0, 0, -1)), "Must attack a Guard", "hero blocked too")
	g.hidden = true
	assert_eq(Rules.attack_targets(s, 0, 0), [3, -1] as Array[int], "a hidden guard forces nothing and can't be chosen")
	return true


func test_hidden_untargetable_and_revealed() -> bool:
	var s: GameState = Fx.blank()
	var me: GameState.CreatureState = Fx.put(s, 0, 0, _mk(2, 9))
	me.hidden = true
	Fx.put(s, 1, 0, _mk(1, 9)).hidden = true
	assert_true(not 0 in Rules.attack_targets(s, 0, 0), "enemy hidden not attackable")
	var ev: Array[GameEvent] = _hit(s, 0, -1)
	assert_true(&"revealed" in Fx.types(ev) and not me.hidden, "attacking reveals")
	return true


func test_dash_creatures_only() -> bool:
	var s: GameState = Fx.blank([1, 1, 1, 1])
	s.players[0].magic = 9
	Fx.put(s, 1, 2, _mk(1, 9))
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cinderpup"), 0))
	assert_true(Rules.can_attack(s, 0, 0), "dash attacks on the turn played")
	assert_eq(Rules.attack_targets(s, 0, 0), [2] as Array[int], "creatures only, no hero")
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"magmaw"), 1))
	assert_true(not Rules.can_attack(s, 0, 1), "no dash: waits a turn")
	assert_eq(Rules.validate(s, Action.attack(0, 1, 2)), "Can't attack", "message")
	return true


func test_flurry_twice_then_done() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 1, _mk(2, 9, [&"flurry"]))
	_hit(s, 1, -1)
	assert_true(Rules.can_attack(s, 0, 1), "second attack allowed")
	_hit(s, 1, -1)
	assert_eq(s.players[1].hero_hp, GameState.START_HP - 4, "two hits")
	assert_true(not Rules.can_attack(s, 0, 1), "done")
	return true


func test_flurry_frozen_by_hit_back() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(2, 9, [&"flurry"]))
	Fx.put_creature(s, 1, 0, &"frostfang")
	_hit(s, 0, 0)
	assert_true(a.is_frozen(), "frostfang's hit-back froze it")
	assert_eq(Rules.validate(s, Action.attack(0, 0, -1)), "Can't attack", "no second attack")
	return true


func test_boop_and_attack_exclusive() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 4)
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.put_creature(s, 0, 1, &"gumdrop")
	Rules.apply(s, Action.boop(0, 0))
	assert_true(not Rules.can_attack(s, 0, 0), "booped: no attack")
	_hit(s, 1, -1)
	assert_eq(Rules.validate(s, Action.boop(0, 1)), "Creature already acted", "attacked: no boop")
	return true


func test_zero_attack_cannot_attack() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"snowmite")
	Fx.put_building(s, 1, 2, &"frost_spire")
	assert_true(not Rules.can_attack(s, 0, 2), "1 - 1 = 0 attack")
	return true


func test_venom_leech_bubble_in_combat() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(1, 1, [&"venom"]))
	Fx.put(s, 1, 0, _mk(9, 9))
	_hit(s, 0, 0)
	assert_true(s.players[1].lanes[0].creature == null, "venom kills the 9/9")
	s.players[0].hero_hp = 20
	Fx.put(s, 0, 1, _mk(3, 9, [&"leech"]))
	_hit(s, 1, -1)
	assert_eq(s.players[0].hero_hp, 23, "leech on a hero hit")
	var a: GameState.CreatureState = Fx.put(s, 0, 2, _mk(3, 9))
	var b: GameState.CreatureState = Fx.put(s, 1, 2, _mk(2, 5, [&"bubble"]))
	_hit(s, 2, 2)
	assert_true(not b.bubble and b.damage == 0, "bubble took the attack")
	assert_eq(a.damage, 2, "hit-back still lands")
	return true


func test_frozen_cannot_attack_until_thawed() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	Fx.put_creature(s, 1, 0, &"cinderpup")
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cold_snap"), -1, [{"player": 1, "lane": 0}]))
	Rules.apply(s, Action.end_turn(0))
	assert_true(s.players[1].lanes[0].creature.is_frozen(), "still frozen on its turn")
	assert_true(not Rules.can_attack(s, 1, 0), "can't attack")
	var ev: Array[GameEvent] = Rules.apply(s, Action.end_turn(1))
	assert_true(&"unfrozen" in Fx.types(ev), "cleared after its turn")
	return true


func test_end_turn_in_main() -> bool:
	var s: GameState = Fx.blank()
	assert_eq(Rules.validate(s, Action.end_turn(0)), "", "end turn any time in the main phase")
	return true


func test_win() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].hero_hp = 3
	Fx.put_creature(s, 0, 0, &"flarebeak")
	var ev: Array[GameEvent] = _hit(s, 0, -1)
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
	for a: Action in [Action.play(0, i, 0), Action.boop(0, 0), Action.attack(0, 0, -1), Action.end_turn(0), Action.choose(0, 0)]:
		assert_eq(Rules.validate(s, a), "Game is over", "rejected %d" % a.type)
	return true
