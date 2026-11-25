extends TestCase
## Packs: a creature that enters with a follower in the same lane (Dark Moon spec 2.1).


func _pack() -> CardData:
	var tok: CardData = Fx.card(&"t_thornling", CardData.Kind.CREATURE, 0, 2, 2)
	tok.collectible = false
	CardDB.add_test_card(tok)
	var c: CardData = Fx.card(&"t_matriarch", CardData.Kind.CREATURE, 5, 5, 5)
	c.follower_id = &"t_thornling"
	CardDB.add_test_card(c)
	return c


func _clean() -> void:
	CardDB.remove_test_card(&"t_thornling")
	CardDB.remove_test_card(&"t_matriarch")


func _play(s: GameState, p: int, c: CardData, lane: int) -> Array[GameEvent]:
	s.players[p].hand.append(c)
	s.players[p].magic = 10
	return Rules.apply(s, Action.play(p, s.players[p].hand.size() - 1, lane))


func test_pack_enters_with_follower() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	var ev: Array[GameEvent] = _play(s, 0, c, 1)
	var ps: GameState.PlayerState = s.players[0]
	assert_eq(ps.at(1).card.id, &"t_matriarch", "leader in its lane")
	assert_eq(ps.at(5).card.id, &"t_thornling", "follower in spot 5 (lane 1)")
	assert_eq(ps.creature_spots(), [1, 5] as Array[int], "two creatures")
	assert_true(&"follower_entered" in Fx.types(ev), "follower event")
	assert_eq(GameState.lane_of(5), 1, "spot 5 is in lane 1")
	_clean()
	return true


func test_follower_is_independent() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	s.active = 1
	_play(s, 1, c, 2)
	for sp: int in [2, 6]:
		s.players[1].at(sp).ready = true
	s.active = 0
	Fx.put_creature(s, 0, 0, &"gumdrop")
	var targets: Array[int] = Rules.attack_targets(s, 0, 0)
	assert_true(6 in targets, "the follower can be attacked on its own")
	assert_true(2 in targets, "and the leader")
	var opts: Array[Dictionary] = Targeting.valid(s, 0, &"chosen_enemy_creature")
	assert_true({"player": 1, "lane": 6} in opts, "and targeted")
	s.active = 1
	assert_true(Rules.can_attack(s, 1, 6), "the follower attacks on its own")
	Rules.apply(s, Action.attack(1, 6, -1))
	assert_eq(s.players[0].hero_hp, GameState.START_HP - 2, "follower hits the hero for 2")
	assert_true(Rules.can_attack(s, 1, 2), "the leader still can")
	_clean()
	return true


func test_follower_moves_up_when_leader_dies() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	_play(s, 0, c, 1)
	Rules.destroy_creature(s, 0, 1, [])
	var ev: Array[GameEvent] = []
	Rules.resolve_deaths(s, ev)
	assert_eq(s.players[0].at(1).card.id, &"t_thornling", "the follower is the lane's creature now")
	assert_true(s.players[0].at(5) == null, "follower spot empty")
	assert_true(&"follower_promoted" in Fx.types(ev), "promotion event")
	_clean()
	return true


func test_no_normal_creature_while_lane_full() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	_play(s, 0, c, 1)
	Rules.destroy_creature(s, 0, 1, [])
	Rules.resolve_deaths(s, [])
	s.players[0].hand.append(CardDB.card(&"gumdrop"))
	s.players[0].magic = 10
	assert_eq(Rules.validate(s, Action.play(0, s.players[0].hand.size() - 1, 1)), "Lane already has a creature", "lane is taken by the follower")
	assert_true(Rules.validate(s, Action.play(0, s.players[0].hand.size() - 1, 5)) != "", "spot 5 can't be played into")
	_clean()
	return true


func test_follower_gets_lane_bonus() -> bool:
	var s: GameState = Fx.blank([CardData.Land.EMBER, 4, 4, 4])
	var tok: CardData = Fx.card(&"t_ember_tok", CardData.Kind.CREATURE, 0, 2, 2)
	tok.land = CardData.Land.EMBER
	var cr: GameState.CreatureState = Fx.put(s, 0, 4, tok)
	assert_eq(Lands.home(s, 0, 4), CardData.Land.EMBER, "follower is at home in its lane's land")
	assert_eq(Rules.effective_attack(s, 0, 4), 3, "Fired up: +1 ATK")
	assert_true(cr != null, "placed")
	return true


func test_bounce_takes_the_pack() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	_play(s, 0, c, 1)
	var hand: int = s.players[0].hand.size()
	Rules.bounce_creature(s, 0, 1, [])
	assert_true(s.players[0].at(1) == null and s.players[0].at(5) == null, "both gone")
	assert_eq(s.players[0].hand.size(), hand + 1, "only the leader card returns")
	_clean()
	return true


func test_move_carries_follower() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	_play(s, 0, c, 1)
	Rules.move_unit(s, 0, 1, 3, [])
	assert_eq(s.players[0].at(3).card.id, &"t_matriarch", "leader moved")
	assert_eq(s.players[0].at(7).card.id, &"t_thornling", "follower moved with it")
	assert_true(s.players[0].at(1) == null and s.players[0].at(5) == null, "old lane empty")
	_clean()
	return true


func test_digest_covers_followers() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = _pack()
	_play(s, 0, c, 1)
	var a: String = s.digest()
	s.players[0].at(5).damage = 1
	assert_true(a != s.digest(), "follower state is in the digest")
	assert_eq(s.clone().digest(), s.digest(), "clone keeps the follower")
	_clean()
	return true


func test_changed_copy_on_board_keeps_views_in_sync() -> bool:
	var m: MatchController = await Fx.load_match()
	var s: GameState = m.state
	var c: CardData = CardDB.variant(CardDB.card(&"gumdrop"), {"attack": 2})
	var cr := GameState.CreatureState.new()
	cr.card = c
	s.players[0].put(2, cr)
	m.place_creature(0, 2, CardDB.card(&"gumdrop"))
	var before: int = m.view_resyncs
	m.verify_views()
	assert_eq(m.view_resyncs, before, "a buffed copy and its printed card's view agree")
	m.queue_free()
	return true
