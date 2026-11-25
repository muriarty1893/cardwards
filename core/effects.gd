class_name Effects
extends RefCounted
## Runs a card's EffectData steps (spec section 5). `lane` is the source lane (creature or
## building), or -1 for spells.


static func run(s: GameState, p: int, lane: int, card: CardData, when: StringName, targets: Array[Dictionary], ev: Array[GameEvent], ctx: Dictionary = {}) -> void:
	var effs: Array[EffectData] = card.effects_for(when)
	if effs.is_empty():
		return
	if lane >= 0 and card.kind == CardData.Kind.CREATURE:
		var cr: GameState.CreatureState = s.players[p].at(lane)
		if cr and cr.card == card and cr.hushed:
			return
	var c: Dictionary = ctx.duplicate()
	var announced: bool = false
	for e: EffectData in effs:
		if s.phase == GameState.Phase.OVER:
			return
		if e.combo and s.players[p].cards_played < 1:
			continue
		if e.need > 0 and Tribes.count_other(s, p, e.tribe, lane if card.kind == CardData.Kind.CREATURE else -1) < e.need:
			continue
		if e.need_cond != &"" and not Conditions.ok(s, p, e.need_cond):
			continue
		if not announced:
			# Informational only: tells the view what caused the events that follow.
			ev.append(GameEvent.make(&"ability_triggered", {"player": p, "lane": lane, "card": card.id}))
			announced = true
		var ts: Array[Dictionary] = Targeting.resolve(s, p, lane, e.who, targets, c, e.filter_land)
		_apply(s, p, lane, card, e, ts, targets, ev)
		if e.who != &"same_target":
			c["last"] = ts


static func _apply(s: GameState, p: int, lane: int, card: CardData, e: EffectData, ts: Array[Dictionary], chosen: Array[Dictionary], ev: Array[GameEvent]) -> void:
	var ps: GameState.PlayerState = s.players[p]
	if e.scale != &"":
		# Scaling (Scaling.value): the step grows by scale_per for each point of the count.
		var bonus: int = e.scale_per * Scaling.value(s, p, lane if card.kind == CardData.Kind.CREATURE else -1, e.scale)
		e = e.duplicate() as EffectData
		e.amount += bonus
		if e.op == &"buff":
			e.amount2 += bonus
	if e.cond != &"":
		ts = ts.filter(func(t: Dictionary) -> bool: return _cond_ok(s, e.cond, t))
	match e.op:
		&"damage":
			var amount: int = e.amount
			if card.kind == CardData.Kind.SPELL and not card.field:
				amount += Rules.spell_power(s, p)
			# Only creatures can venom/leech; buildings and spells are plain sources.
			var src: Dictionary = {"player": p, "lane": lane if card.kind == CardData.Kind.CREATURE else -1,
				"kind": &"spell" if card.kind == CardData.Kind.SPELL else &"ability"}
			for t: Dictionary in ts:
				if t.has("hero"):
					Rules.damage_hero(s, t["hero"], amount, ev, src)
				elif _creature(s, t):
					var r: Dictionary = Lands.react_before(s, card, e.op, t, ev)
					Rules.damage_creature(s, t["player"], t["lane"], amount + int(r.get("extra", 0)), src, ev)
					Lands.react_after(s, p, r, t, ev)
		&"drain":
			# Leech on play: the target loses HP and this creature gains it (+0/+N).
			# An empty lane drains the enemy hero instead.
			var dsrc: Dictionary = {"player": p, "lane": -1, "kind": &"ability"}
			for t: Dictionary in ts:
				var got: int = 0
				if _creature(s, t):
					got = Rules.damage_creature(s, t["player"], t["lane"], e.amount, dsrc, ev)
				elif t.has("player"):
					var before: int = s.players[t["player"]].hero_hp + s.players[t["player"]].armour
					Rules.damage_hero(s, t["player"], e.amount, ev, dsrc)
					got = before - s.players[t["player"]].hero_hp - s.players[t["player"]].armour
				if got > 0 and lane >= 0 and card.kind == CardData.Kind.CREATURE and ps.at(lane) and ps.at(lane).card == card:
					ev.append(GameEvent.make(&"drained", {"player": p, "lane": lane, "from": t, "amount": got}))
					Rules.buff(s, p, lane, 0, got, ev)
				elif got > 0:
					ev.append(GameEvent.make(&"drained", {"player": p, "lane": -1, "from": t, "amount": got}))
					Rules.heal_hero(s, p, got, ev)
		&"heal":
			for t: Dictionary in ts:
				if t.has("hero"):
					Rules.heal_hero(s, t["hero"], e.amount, ev)
				elif _creature(s, t):
					var r: Dictionary = Lands.react_before(s, card, e.op, t, ev)
					Rules.heal_creature(s, t["player"], t["lane"], e.amount + int(r.get("extra", 0)), ev)
					Lands.react_after(s, p, r, t, ev)
		&"draw":
			for i: int in e.amount:
				Rules.draw(s, p, ev)
		&"gain_magic":
			ps.magic += e.amount
			ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": ps.magic, "max": ps.max_magic}))
		&"freeze":
			for t: Dictionary in ts:
				if _creature(s, t):
					var r: Dictionary = Lands.react_before(s, card, e.op, t, ev)
					Rules.freeze(s, t["player"], t["lane"], ev)
					Lands.react_after(s, p, r, t, ev)
		&"hush":
			for t: Dictionary in ts:
				if _creature(s, t):
					Rules.hush(s, t["player"], t["lane"], ev)
		&"buff":
			for t: Dictionary in ts:
				if _creature(s, t):
					Rules.buff(s, t["player"], t["lane"], e.amount, e.amount2, ev)
		&"give_keyword":
			for t: Dictionary in ts:
				if _creature(s, t):
					Rules.give_keyword(s, t["player"], t["lane"], e.keyword, ev)
		&"destroy":
			for t: Dictionary in ts:
				if _creature(s, t):
					Rules.destroy_creature(s, t["player"], t["lane"], ev)
		&"return_building":
			for t: Dictionary in ts:
				var b: CardData = s.players[t["player"]].lane(t["lane"]).building
				if b:
					s.players[t["player"]].lane(t["lane"]).building = null
					ev.append(GameEvent.make(&"building_returned", {"player": t["player"], "lane": t["lane"], "card": b.id}))
					Rules.return_to_hand(s, t["player"], b, ev)
		&"move":
			if chosen.size() == 1 and chosen[0].has("lane") and ps.at(chosen[0]["lane"]) == null and ps.at(lane):
				Rules.move_unit(s, p, lane, chosen[0]["lane"], ev)
			else:
				push_warning("Effects: move target gone")
		&"swap":
			if ts.size() == 2 and _creature(s, ts[0]) and _creature(s, ts[1]):
				var a: int = ts[0]["lane"]
				var b: int = ts[1]["lane"]
				if not GameState.is_follower(a) and not GameState.is_follower(b):
					# Whole lanes trade places: each main creature keeps its follower.
					var la: GameState.LaneState = ps.lanes[a]
					var lb: GameState.LaneState = ps.lanes[b]
					var tmp_c: GameState.CreatureState = la.creature
					var tmp_f: GameState.CreatureState = la.follower
					la.creature = lb.creature
					la.follower = lb.follower
					lb.creature = tmp_c
					lb.follower = tmp_f
				else:
					var tmp: GameState.CreatureState = ps.at(a)
					ps.put(a, ps.at(b))
					ps.put(b, tmp)
				ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": a, "to": b}))
				ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": b, "to": a}))
		&"return_from_discard":
			if ts.size() == 1 and ts[0].has("discard") and int(ts[0]["discard"]) < ps.discard.size():
				var c: CardData = ps.discard[ts[0]["discard"]]
				ps.discard.remove_at(ts[0]["discard"])
				Rules.return_to_hand(s, p, c, ev)
			else:
				push_warning("Effects: discard target gone")
		&"dream_up":
			Rules.offer_dream_up(s, p, e.filter_kind, e.filter_land, ev, e.gift)
		&"dark_moon":
			Rules.offer_direction(s, p, ev)
		&"steal_hand":
			Rules.steal_from_hand(s, p, maxi(e.amount, 1), e.amount2 > 0, ev)
		&"copy_rival":
			Rules.copy_rival_card(s, p, maxi(e.amount, 1), ev)
		&"steal_creature":
			for t: Dictionary in ts:
				if _creature(s, t) and int(t["player"]) != p and (e.amount <= 0 or Rules.effective_attack(s, t["player"], t["lane"]) <= e.amount):
					Rules.steal_creature(s, p, t["player"], t["lane"], ev)
		&"split_damage":
			var total: int = e.amount
			if card.kind == CardData.Kind.SPELL and not card.field:
				total += Rules.spell_power(s, p)
			Rules.split_damage(s, p, total, {"player": p, "lane": -1, "kind": &"spell" if card.kind == CardData.Kind.SPELL else &"ability"}, ev)
		&"double_stats":
			for t: Dictionary in ts:
				if _creature(s, t):
					var cr: GameState.CreatureState = s.players[t["player"]].at(t["lane"])
					var hp_now: int = Rules.effective_max_hp(s, t["player"], t["lane"]) - cr.damage
					var atk_now: int = Rules.effective_attack(s, t["player"], t["lane"])
					ev.append(GameEvent.make(&"doubled", {"player": t["player"], "lane": t["lane"]}))
					# Capped at 99/99 so the numbers stay readable (Mawra doubles on every death).
					Rules.buff(s, t["player"], t["lane"], clampi(99 - atk_now, 0, atk_now), clampi(99 - hp_now, 0, hp_now), ev)
		&"next_spell_twice":
			ps.spell_twice += maxi(e.amount, 1)
		&"replay_spells":
			Rules.replay_spells(s, p, e.filter_land, ev)
		&"add_to_hand":
			if CardDB.has_card(e.card_id):
				for i: int in maxi(e.amount, 1):
					Rules.add_to_hand(s, _owner(s, p, e.who), CardDB.card(e.card_id), ev)
		&"shuffle_into_deck":
			if CardDB.has_card(e.card_id):
				Rules.shuffle_into_deck(s, _owner(s, p, e.who), CardDB.card(e.card_id), maxi(e.amount, 1), ev)
		&"summon":
			if CardDB.has_card(e.card_id):
				var q: int = _owner(s, p, e.who)
				for i: int in maxi(e.amount, 1):
					Rules.summon(s, q, CardDB.card(e.card_id), lane if (e.who == &"self" and q == p) else -1, ev)
		&"resurrect":
			Rules.resurrect(s, p, maxi(e.amount, 1), e.keyword == &"last_breath", card.id if card.kind == CardData.Kind.CREATURE else &"", ev)
		&"buff_hand":
			for i: int in ps.hand.size():
				if ps.hand[i].is_creature():
					ps.hand[i] = CardDB.variant(ps.hand[i], {"attack": e.amount, "health": e.amount2})
			ev.append(GameEvent.make(&"hand_buffed", {"player": p, "atk": e.amount, "hp": e.amount2}))
		&"armour":
			for t: Dictionary in ts:
				if t.has("hero"):
					Rules.gain_armour(s, t["hero"], e.amount, ev)
		&"sprout_meadow":
			# Spore Bloom: the player's first Meadow lane grows into the field's land.
			for l: int in GameState.LANES:
				if ps.lane(l).land == Lands.MEADOW:
					Lands.set_land(s, p, l, card.land, &"field", ev)
					break
		&"land_draw":
			# Sugar Rain: draw if the player has a creature on that land.
			for l: int in GameState.LANES:
				if ps.at(l) and ps.lane(l).land == e.filter_land:
					for i: int in e.amount:
						Rules.draw(s, p, ev)
					break
		&"temp_atk":
			for t: Dictionary in ts:
				if _creature(s, t):
					s.players[t["player"]].at(t["lane"]).temp_atk += e.amount
					ev.append(GameEvent.make(&"buffed", {"player": t["player"], "lane": t["lane"], "atk": e.amount, "hp": 0, "temp": true}))
		&"doom":
			for t: Dictionary in ts:
				if _creature(s, t):
					s.players[t["player"]].at(t["lane"]).doomed = true
					ev.append(GameEvent.make(&"doomed", {"player": t["player"], "lane": t["lane"]}))
		&"grow_magic":
			ps.magic_cap = mini(ps.magic_cap + e.amount, GameState.MAGIC_CAP_MAX)
			ps.max_magic = mini(ps.max_magic + e.amount, ps.magic_cap)
			ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": ps.magic, "max": ps.max_magic}))
		&"bounce":
			for t: Dictionary in ts:
				if _creature(s, t):
					Rules.bounce_creature(s, t["player"], t["lane"], ev)
		&"spell_discount":
			ps.spell_discount += e.amount
		&"transform":
			var into: CardData = CardDB.card(e.card_id) if CardDB.has_card(e.card_id) else null
			for t: Dictionary in ts:
				if into and _creature(s, t):
					Rules.transform_creature(s, t["player"], t["lane"], into, ev)
		&"lane_atk", &"lane_hp", &"lane_keyword", &"lane_damage_taken", &"opposing_atk", \
				&"on_land_atk", &"off_land_atk", &"on_land_hp", &"no_quirk":
			pass  # auras: read by Rules.effective_* / keywords_of / damage_reduction / Fields
		&"echo", &"echo_death", &"cost_per_death", &"grow_on_spell":
			pass  # passives: Rules.echoes / card_cost / _grow_held
		_:
			push_warning("Effects: unknown op '%s'" % e.op)


static func _cond_ok(s: GameState, cond: StringName, t: Dictionary) -> bool:
	if not _creature(s, t):
		return false
	var frozen: bool = s.players[t["player"]].at(t["lane"]).is_frozen()
	match cond:
		&"target_frozen":
			return frozen
		&"target_not_frozen":
			return not frozen
	return true


## Whose hand/deck/board a step aimed at `who` reaches: the rival for enemy_hero, else the owner.
static func _owner(s: GameState, p: int, who: StringName) -> int:
	return s.opponent(p) if who == &"enemy_hero" else p


static func _creature(s: GameState, t: Dictionary) -> bool:
	return t.has("lane") and t.has("player") and s.players[t["player"]].at(t["lane"]) != null
