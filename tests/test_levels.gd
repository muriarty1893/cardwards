extends TestCase
## Living board spec 6: XP from surviving attacks, +1/+1 per level, on_level_up steps.


func _mk(atk: int, hp: int) -> CardData:
	return Fx.card(&"t", CardData.Kind.CREATURE, 1, atk, hp)


func _again(cr: GameState.CreatureState) -> void:
	cr.attacks_used = 0


func test_xp_and_levels() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(2, 20))
	Fx.put(s, 1, 0, _mk(0, 30))
	Rules.apply(s, Action.attack(0, 0, 0))
	assert_eq([a.level, a.xp], [1, 1], "survived one attack: 1 XP")
	_again(a)
	var ev: Array[GameEvent] = Rules.apply(s, Action.attack(0, 0, 0))
	assert_eq([a.level, a.xp], [2, 2], "2 XP: level 2")
	assert_true(&"level_up" in Fx.types(ev), "level_up event")
	assert_eq([Rules.effective_attack(s, 0, 0), Rules.effective_max_hp(s, 0, 0)], [3, 21], "+1/+1")
	for i: int in 4:
		_again(a)
		Rules.apply(s, Action.attack(0, 0, 0))
	assert_eq(a.level, Levels.MAX, "capped at level 3")
	return true


func test_kill_gives_extra_xp() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(5, 9))
	Fx.put(s, 1, 0, _mk(1, 2))
	Rules.apply(s, Action.attack(0, 0, 0))
	assert_eq(a.level, 2, "survive + kill = 2 XP = level 2")
	return true


func test_dying_attacker_gets_nothing() -> bool:
	var s: GameState = Fx.blank()
	Fx.put(s, 0, 0, _mk(1, 1))
	Fx.put(s, 1, 0, _mk(5, 9))
	var ev: Array[GameEvent] = Rules.apply(s, Action.attack(0, 0, 0))
	assert_true(not &"xp_gained" in Fx.types(ev), "no XP for a dead attacker")
	return true


func test_level_up_ability() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"flarebeak")  # level up: 1 damage to the enemy hero
	var cr: GameState.CreatureState = s.players[0].lanes[0].creature
	cr.xp = 1
	Fx.put(s, 1, 2, _mk(0, 30))
	Rules.apply(s, Action.attack(0, 0, 2))
	assert_eq(cr.level, 2, "levelled")
	assert_eq(s.players[1].hero_hp, GameState.START_HP - 1, "flarebeak's level-up ping")
	return true


func test_hush_keeps_level() -> bool:
	var s: GameState = Fx.blank()
	var a: GameState.CreatureState = Fx.put(s, 0, 0, _mk(2, 5))
	a.level = 3
	var ev: Array[GameEvent] = []
	Rules.hush(s, 0, 0, ev)
	assert_eq(Rules.effective_attack(s, 0, 0), 4, "levels stay through Hush")
	return true
