extends TestCase
## Card expansion 2, spec 5.4: the rules behind the Hearthstone-style spells.

const C := CardData.Kind.CREATURE
const S := CardData.Kind.SPELL


func _spell(id: StringName, cost: int, effects: Array[EffectData]) -> CardData:
	return Fx.card(id, S, cost, 0, 0, [], effects)


func _cast(s: GameState, c: CardData, targets: Array[Dictionary] = []) -> Array[GameEvent]:
	s.players[0].hand.append(c)
	var a: Action = Action.play(0, s.players[0].hand.size() - 1, -1, targets)
	var err: String = Rules.validate(s, a)
	assert_eq(err, "", "%s can be cast" % c.id)
	return Rules.apply(s, a)


func test_temp_atk_lasts_this_turn() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"magmaw")
	var base: int = Rules.effective_attack(s, 0, 1)
	_cast(s, _spell(&"roar", 0, [Fx.eff(&"on_play", &"temp_atk", 2, &"all_own_creatures")]))
	assert_eq(Rules.effective_attack(s, 0, 1), base + 2, "+2 attack this turn")
	Rules.apply(s, Action.end_turn(0))
	assert_eq(Rules.effective_attack(s, 0, 1), base, "gone at the end of the turn")
	return true


func test_doom_destroys_at_owners_end_of_turn() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"magmaw")
	Fx.put_creature(s, 1, 0, &"mossback")
	var t: Array[Dictionary] = [{"player": 0, "lane": 0}]
	_cast(s, _spell(&"overheat", 0, [Fx.eff(&"on_play", &"buff", 4, &"chosen_own_creature", {"amount2": 4}), Fx.eff(&"on_play", &"doom", 0, &"same_target")]), t)
	assert_true(s.players[0].lanes[0].creature != null, "still there this turn")
	assert_true(s.players[0].lanes[0].creature.doomed, "doomed")
	var ev: Array[GameEvent] = Rules.apply(s, Action.end_turn(0))
	assert_true(s.players[0].lanes[0].creature == null, "destroyed at the end of your turn")
	assert_true(&"creature_destroyed" in Fx.types(ev), "destroy event")
	assert_true(s.players[1].lanes[0].creature != null, "the rival's creature is untouched")
	return true


func test_doom_and_second_wind() -> bool:
	var s: GameState = Fx.blank()
	var c: CardData = Fx.card(&"phoenix", C, 1, 2, 2, [&"second_wind"])
	Fx.put(s, 0, 2, c)
	_cast(s, _spell(&"overheat", 0, [Fx.eff(&"on_play", &"doom", 0, &"chosen_own_creature")]), [{"player": 0, "lane": 2}])
	Rules.apply(s, Action.end_turn(0))
	var back: GameState.CreatureState = s.players[0].lanes[2].creature
	assert_true(back != null and back.second_wind_used, "came back with Second Wind")
	assert_true(not back.doomed, "and is not doomed again")
	Rules.apply(s, Action.end_turn(1))
	Rules.apply(s, Action.end_turn(0))
	assert_true(s.players[0].lanes[2].creature != null, "survives later turns")
	return true


func test_grow_magic() -> bool:
	var s: GameState = Fx.blank()
	var ps: GameState.PlayerState = s.players[0]
	_cast(s, _spell(&"roots", 0, [Fx.eff(&"on_play", &"grow_magic", 1, &"own_hero")]))
	assert_eq(ps.max_magic, 3, "+1 max magic")
	assert_eq(ps.magic_cap, GameState.MAGIC_CAP + 1, "the cap rises too")
	ps.max_magic = 10
	ps.magic_cap = 10
	_cast(s, _spell(&"roots", 0, [Fx.eff(&"on_play", &"grow_magic", 1, &"own_hero")]))
	assert_eq(ps.max_magic, 10, "max magic stays at 10")
	assert_eq(ps.magic_cap, 10, "the cap stays at 10")
	ps.max_magic = 8
	ps.magic_cap = 9
	Rules.apply(s, Action.end_turn(0))
	Rules.apply(s, Action.end_turn(1))
	assert_eq(ps.max_magic, 9, "turn growth goes up to the raised cap")
	return true


func test_bounce() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 3, &"gumdrop", 2)
	var hand_before: int = s.players[1].hand.size()
	var ev: Array[GameEvent] = _cast(s, _spell(&"pull", 0, [Fx.eff(&"on_play", &"bounce", 0, &"chosen_enemy_creature")]), [{"player": 1, "lane": 3}])
	assert_true(s.players[1].lanes[3].creature == null, "the lane is empty")
	assert_eq(s.players[1].hand.size(), hand_before + 1, "back in its owner's hand")
	assert_eq(s.players[1].hand.back().id, &"gumdrop", "the same card")
	assert_true(not &"creature_destroyed" in Fx.types(ev), "not a death")
	assert_true(&"creature_bounced" in Fx.types(ev), "bounce event")
	# Full hand: the card is discarded.
	Fx.put_creature(s, 1, 2, &"mossback")
	while s.players[1].hand.size() < GameState.HAND_LIMIT:
		s.players[1].hand.append(CardDB.card(&"star_shard"))
	_cast(s, _spell(&"pull", 0, [Fx.eff(&"on_play", &"bounce", 0, &"chosen_enemy_creature")]), [{"player": 1, "lane": 2}])
	assert_eq(s.players[1].discard.back().id, &"mossback", "a full hand discards it")
	return true


func test_spell_discount() -> bool:
	var s: GameState = Fx.blank()
	var ps: GameState.PlayerState = s.players[0]
	ps.magic = 2
	_cast(s, _spell(&"prep", 0, [Fx.eff(&"on_play", &"spell_discount", 2, &"own_hero")]))
	assert_eq(ps.spell_discount, 2, "next spell 2 cheaper")
	var creature: CardData = Fx.card(&"bigguy", C, 3, 3, 3)
	assert_eq(Rules.card_cost(s, 0, creature), 3, "creatures keep their cost")
	var four: CardData = _spell(&"boom", 4, [Fx.eff(&"on_play", &"draw", 1, &"own_hero")])
	assert_eq(Rules.card_cost(s, 0, four), 2, "a 4-cost spell costs 2")
	_cast(s, four)
	assert_eq(ps.magic, 0, "paid 2")
	assert_eq(ps.spell_discount, 0, "used up")
	ps.spell_discount = 5
	assert_eq(Rules.card_cost(s, 0, four), 0, "never below 0")
	Rules.apply(s, Action.end_turn(0))
	assert_eq(ps.spell_discount, 0, "cleared at the end of the turn")
	return true


func test_transform() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 1, &"blizzard_titan", 3)
	var cr: GameState.CreatureState = s.players[1].lanes[1].creature
	cr.atk_bonus = 2
	cr.gained.append(&"guard")
	cr.level = 2
	_cast(s, _spell(&"poly", 0, [Fx.eff(&"on_play", &"transform", 0, &"chosen_creature", {"card_id": &"sporeling"})]), [{"player": 1, "lane": 1}])
	var now: GameState.CreatureState = s.players[1].lanes[1].creature
	assert_eq(now.card.id, &"sporeling", "turned into the token")
	assert_eq(now.damage, 0, "fresh health")
	assert_eq(now.atk_bonus, 0, "buffs gone")
	assert_eq(now.gained.size(), 0, "gained keywords gone")
	assert_eq(now.level, 1, "back to level 1")
	assert_eq(Rules.effective_attack(s, 1, 1), now.card.attack, "token attack")
	return true


func test_icicle_conditions() -> bool:
	var effects: Array[EffectData] = [
		Fx.eff(&"on_play", &"damage", 4, &"chosen_creature", {"cond": &"target_frozen"}),
		Fx.eff(&"on_play", &"freeze", 0, &"same_target", {"cond": &"target_not_frozen"}),
	]
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 0, &"mossback")   # 1/5, no Bubble
	_cast(s, _spell(&"icicle", 0, effects), [{"player": 1, "lane": 0}])
	var cr: GameState.CreatureState = s.players[1].lanes[0].creature
	assert_true(cr.is_frozen(), "not frozen: freezes it")
	assert_eq(cr.damage, 0, "and deals no damage")
	_cast(s, _spell(&"icicle", 0, effects), [{"player": 1, "lane": 0}])
	assert_eq(cr.damage, 4, "already frozen: 4 damage instead")
	return true


func test_new_target_lists() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"magmaw", 1)
	Fx.put_creature(s, 1, 0, &"gumdrop", 1)
	Fx.put_creature(s, 1, 1, &"mossback")
	Fx.put_creature(s, 1, 2, &"iceling")
	s.players[1].lanes[2].creature.freeze_turn = s.turn
	Fx.put_creature(s, 1, 3, &"sugar_sprite")   # Hidden
	assert_eq(Targeting.valid(s, 0, &"chosen_enemy_creature"), [{"player": 1, "lane": 0}, {"player": 1, "lane": 1}, {"player": 1, "lane": 2}], "enemy creatures, not hidden ones")
	assert_eq(Targeting.valid(s, 0, &"chosen_damaged_enemy"), [{"player": 1, "lane": 0}], "damaged enemies")
	assert_eq(Targeting.valid(s, 0, &"chosen_undamaged_creature"), [{"player": 1, "lane": 1}, {"player": 1, "lane": 2}], "undamaged creatures, either side")
	assert_eq(Targeting.valid(s, 0, &"chosen_frozen_enemy"), [{"player": 1, "lane": 2}], "frozen enemies")
	var others: Array[Dictionary] = Targeting.resolve(s, 0, -1, &"other_enemies", [], {"last": [{"player": 1, "lane": 1}]}, -1)
	assert_true({"player": 1, "lane": 1} not in others, "not the last target")
	assert_true({"player": 1, "lane": 0} in others and {"player": 1, "lane": 3} in others, "every other enemy creature")
	assert_true({"hero": 1} in others, "and the enemy hero")
	return true


func test_new_ops_card_text() -> bool:
	var c: CardData = _spell(&"t", 0, [Fx.eff(&"on_play", &"buff", 4, &"chosen_own_creature", {"amount2": 4}), Fx.eff(&"on_play", &"doom", 0, &"same_target")])
	assert_eq(CardText.render(c), "Give one of your creatures +4/+4 and destroy it at the end of your turn.", "overheat text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"temp_atk", 2, &"all_own_creatures")])
	assert_eq(CardText.render(c), "Give all your creatures +2 ATK this turn.", "rally text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"grow_magic", 1, &"own_hero")])
	assert_eq(CardText.render(c), "Gain 1 max magic.", "grow text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"bounce", 0, &"chosen_enemy_creature")])
	assert_eq(CardText.render(c), "Return an enemy creature to its owner's hand.", "bounce text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"spell_discount", 2, &"own_hero")])
	assert_eq(CardText.render(c), "Your next spell this turn costs 2 less.", "discount text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"transform", 0, &"chosen_creature", {"card_id": &"sporeling"})])
	assert_eq(CardText.render(c), "Turn a creature into a 1/2 Sporeling with no abilities.", "transform text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"damage", 4, &"chosen_creature", {"cond": &"target_frozen"}), Fx.eff(&"on_play", &"freeze", 0, &"same_target", {"cond": &"target_not_frozen"})])
	assert_eq(CardText.render(c), "Freeze a creature. If it was already frozen, deal 4 damage to it instead.", "icicle text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"damage", 4, &"chosen_enemy_creature"), Fx.eff(&"on_play", &"damage", 1, &"other_enemies")])
	assert_eq(CardText.render(c), "Deal 4 damage to an enemy creature. Deal 1 damage to every other enemy.", "thorn lash text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"damage", 2, &"chosen_creature"), Fx.eff(&"on_play", &"damage", 2, &"same_target", {"combo": true})])
	assert_eq(CardText.render(c), "Deal 2 damage to a creature. Combo: deal 2 more damage to it.", "jawbreaker text")
	c = _spell(&"t", 0, [Fx.eff(&"on_play", &"destroy", 0, &"chosen_damaged_enemy")])
	assert_eq(CardText.render(c), "Destroy a damaged enemy creature.", "finish off text")
	return true


func test_discounted_spell_shows_playable() -> bool:
	var m: MatchController = await Fx.load_match()
	var ps: GameState.PlayerState = m.state.players[0]
	ps.hand.clear()
	ps.hand.append(CardDB.card(&"thorn_lash"))   # 4 cost
	Fx.put_creature(m.state, 1, 0, &"gumdrop")
	ps.magic = 2
	assert_true(not m.hand_playable()[0], "4-cost spell with 2 magic: not playable")
	ps.spell_discount = 2
	assert_true(m.hand_playable()[0], "with a 2 discount it is playable")
	m.queue_free()
	return true


func test_card_widget_shows_given_cost() -> bool:
	var w := CardWidget.new()
	w.setup(CardDB.card(&"thorn_lash"), 0)
	assert_eq(w.cost_label().text, "4", "printed cost by default")
	assert_true(not w.is_discounted(), "not discounted by default")
	w.set_cost(1)
	assert_eq(w.cost_label().text, "1", "shows the lowered cost")
	assert_true(w.is_discounted(), "marked as discounted")
	assert_true(w.cost_label().get_theme_color("font_color") != Color.WHITE, "lowered cost is coloured")
	w.set_cost(4)
	assert_eq(w.cost_label().text, "4", "back to the printed cost")
	assert_true(not w.is_discounted(), "no longer discounted")
	assert_eq(w.cost_label().get_theme_color("font_color"), Color.WHITE, "printed cost is white")
	w.free()
	return true


func test_hand_shows_discounted_spell_cost() -> bool:
	var m: MatchController = await Fx.load_match()
	var ps: GameState.PlayerState = m.state.players[0]
	ps.hand.clear()
	ps.hand.append(CardDB.card(&"thorn_lash"))   # 4-cost spell
	ps.hand.append(CardDB.card(&"gumdrop"))      # creature: discounts never apply
	ps.spell_discount = 3
	m.refresh_ui()
	assert_eq(m.hand_costs(), [1, CardDB.card(&"gumdrop").cost] as Array[int], "current costs")
	var ws: Array = m.hand.get_children().filter(func(n: Node) -> bool: return n is CardWidget and not n.is_queued_for_deletion())
	assert_eq((ws[0] as CardWidget).cost_label().text, "1", "spell gem shows the discounted cost")
	assert_eq((ws[1] as CardWidget).cost_label().text, str(CardDB.card(&"gumdrop").cost), "creature gem unchanged")
	# Same hand, discount used up: the gem goes back without rebuilding the hand.
	ps.spell_discount = 0
	m.refresh_ui()
	ws = m.hand.get_children().filter(func(n: Node) -> bool: return n is CardWidget and not n.is_queued_for_deletion())
	assert_eq((ws[0] as CardWidget).cost_label().text, "4", "printed cost again")
	m.queue_free()
	return true


func test_drag_card_shows_discounted_cost() -> bool:
	var dc := DragCard3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(dc)
	var c: CardData = CardDB.card(&"thorn_lash")
	dc.show_card(c, 2)
	assert_eq(dc.face_widget().cost_label().text, "2", "3D card shows the given cost")
	dc.show_card(c, 4)
	assert_eq(dc.face_widget().cost_label().text, "4", "re-rendered when the cost changes")
	dc.queue_free()
	return true
