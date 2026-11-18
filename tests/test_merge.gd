extends TestCase
## Card expansion 2, spec 4: two partner creatures merge into one named form when one is played onto the other.

const C := CardData.Kind.CREATURE


## Partners "mpa" (on the board) and "mpb" (in hand) merge into "mpm" (Bubble, When merged: draw 1).
func _cards() -> Array[CardData]:
	var a: CardData = Fx.card(&"mpa", C, 2, 2, 3)
	var b: CardData = Fx.card(&"mpb", C, 3, 2, 2, [], [Fx.eff(&"on_play", &"armour", 3, &"own_hero")])
	var m: CardData = Fx.card(&"mpm", C, 5, 4, 5, [&"bubble"], [Fx.eff(&"on_play", &"draw", 1, &"own_hero")])
	for pair: Array in [[a, b], [b, a]]:
		(pair[0] as CardData).merge_with = (pair[1] as CardData).id
		(pair[0] as CardData).merges_into = &"mpm"
	m.collectible = false
	for c: CardData in [a, b, m]:
		CardDB.add_test_card(c)
	return [a, b, m]


func _cleanup() -> void:
	for id: StringName in [&"mpa", &"mpb", &"mpm"]:
		CardDB.remove_test_card(id)


func _setup() -> GameState:
	var cs: Array[CardData] = _cards()
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"star_shard", 5)
	Fx.put(s, 0, 1, cs[0])
	s.players[0].hand.append(cs[1])
	s.players[0].magic = 5
	return s


func test_merge_is_legal_only_onto_own_partner() -> bool:
	var s: GameState = _setup()
	var hb: int = s.players[0].hand.size() - 1
	assert_eq(Rules.validate(s, Action.play(0, hb, 1, [])), "", "onto your partner: legal")
	Fx.put_creature(s, 0, 2, &"magmaw")
	assert_eq(Rules.validate(s, Action.play(0, hb, 2, [])), "Lane already has a creature", "onto another creature: not legal")
	assert_eq(Rules.validate(s, Action.play(0, hb, 0, [])), "", "into an empty lane: plays normally")
	assert_true(Rules.can_merge(s, 0, 1, s.players[0].hand[hb]), "can_merge onto own partner")
	# The rival's copy of the partner in their lane 3 never merges with your card: your lane 3 is empty.
	s.players[1].lanes[3].creature = s.players[0].lanes[1].creature.clone()
	assert_true(not Rules.can_merge(s, 0, 3, s.players[0].hand[hb]), "not onto the rival's partner")
	var merges: int = 0
	for a: Action in Rules.legal_actions(s):
		if a.type == Action.Type.PLAY_CARD and a.hand_index == hb and a.lane == 1:
			merges += 1
	assert_eq(merges, 1, "legal_actions offers the merge")
	_cleanup()
	return true


func test_merge_carries_state_over() -> bool:
	var s: GameState = _setup()
	var cr: GameState.CreatureState = s.players[0].lanes[1].creature
	cr.damage = 2
	cr.level = 2
	cr.xp = 3
	cr.atk_bonus = 1
	cr.hp_bonus = 2
	cr.gained.append(&"guard")
	cr.freeze_turn = s.turn
	cr.attacks_used = 1
	cr.ready = true
	var played: int = cr.played_turn
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, 1, []))
	var now: GameState.CreatureState = s.players[0].lanes[1].creature
	assert_eq(now.card.id, &"mpm", "the lane holds the merged form")
	assert_eq(now.damage, 2, "damage carries over")
	assert_eq(now.level, 2, "level carries over")
	assert_eq(now.xp, 3, "xp carries over")
	assert_eq(now.atk_bonus, 1, "atk buff carries over")
	assert_eq(now.hp_bonus, 2, "hp buff carries over")
	assert_true(&"guard" in now.gained, "gained keywords carry over")
	assert_true(now.is_frozen(), "freeze carries over")
	assert_eq(now.attacks_used, 1, "attacks used carry over")
	assert_true(now.ready, "still ready")
	assert_eq(now.played_turn, played, "no fresh Dash from merging")
	assert_true(now.bubble, "printed Bubble switches on")
	assert_true(&"creature_merged" in Fx.types(ev), "merge event")
	assert_true(not &"creature_played" in Fx.types(ev), "not a normal play")
	_cleanup()
	return true


func test_merge_runs_when_merged_and_counts_as_a_play() -> bool:
	var s: GameState = _setup()
	var hand: int = s.players[0].hand.size()
	Rules.apply(s, Action.play(0, hand - 1, 1, []))
	assert_eq(s.players[0].hand.size(), hand - 1 + 1, "When merged: draw 1 (the hand card is absorbed)")
	assert_eq(s.players[0].cards_played, 1, "counts as playing a card")
	assert_eq(s.players[0].magic, 2, "paid the hand card's cost (3)")
	assert_eq(s.players[0].armour, 0, "the hand card's own on-play does not run")
	assert_true(s.players[0].discard.is_empty(), "nothing goes to the discard")
	_cleanup()
	return true


func test_merged_death_discards_only_the_form() -> bool:
	var s: GameState = _setup()
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, 1, []))
	var ev: Array[GameEvent] = []
	s.players[0].lanes[1].creature.bubble = false
	Rules.destroy_creature(s, 0, 1, ev)
	Rules.resolve_deaths(s, ev)
	assert_eq(s.players[0].discard.size(), 1, "one card in the discard")
	assert_eq(s.players[0].discard[0].id, &"mpm", "the merged form")
	_cleanup()
	return true


func test_collectible_cards_skip_merged_forms() -> bool:
	_cards()
	var ids: Array[StringName] = []
	for c: CardData in CardDB.collectible_cards():
		ids.append(c.id)
	assert_true(not &"mpm" in ids, "merged forms are not collectible")
	for c: CardData in CardDB.dream_up_pool(-1, -1):
		assert_true(c.collectible, "Dream Up offers only collectible cards (%s)" % c.id)
	_cleanup()
	return true


func test_merge_text() -> bool:
	var cs: Array[CardData] = _cards()
	assert_true(CardText.render(cs[0]).contains("Merges with mpb."), "partner text (%s)" % CardText.render(cs[0]))
	assert_true(CardText.render(cs[1]).ends_with("Merges with mpa."), "partner text (%s)" % CardText.render(cs[1]))
	var t: String = CardText.render(cs[2])
	assert_true(t.contains("When merged: Draw a card."), "merged form's on-play reads When merged (%s)" % t)
	assert_true(t.contains("Merged form of mpb + mpa."), "names its partners (%s)" % t)
	_cleanup()
	return true


func test_ai_merges_when_good() -> bool:
	var s: GameState = _setup()
	s.active = 0
	var ai := AIPlayer.new(0, AIPlayer.Difficulty.HARD, 5)
	var a: Action = ai.choose_action(s)
	assert_true(a.type == Action.Type.PLAY_CARD and a.lane == 1, "the AI merges a clearly good pair (%s lane %d)" % [Action.Type.keys()[a.type], a.lane])
	_cleanup()
	return true
