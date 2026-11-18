class_name Effects
extends RefCounted
## Runs a card's EffectData steps (spec section 5). `lane` is the source lane (creature or
## building), or -1 for spells.


static func run(s: GameState, p: int, lane: int, card: CardData, when: StringName, targets: Array[Dictionary], ev: Array[GameEvent], ctx: Dictionary = {}) -> void:
	var effs: Array[EffectData] = card.effects_for(when)
	if effs.is_empty():
		return
	if lane >= 0 and card.kind == CardData.Kind.CREATURE:
		var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
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
				var b: CardData = s.players[t["player"]].lanes[t["lane"]].building
				if b:
					s.players[t["player"]].lanes[t["lane"]].building = null
					ev.append(GameEvent.make(&"building_returned", {"player": t["player"], "lane": t["lane"], "card": b.id}))
					Rules.return_to_hand(s, t["player"], b, ev)
		&"move":
			if chosen.size() == 1 and chosen[0].has("lane") and ps.lanes[chosen[0]["lane"]].creature == null and ps.lanes[lane].creature:
				var to: int = chosen[0]["lane"]
				ps.lanes[to].creature = ps.lanes[lane].creature
				ps.lanes[lane].creature = null
				ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": lane, "to": to}))
			else:
				push_warning("Effects: move target gone")
		&"swap":
			if ts.size() == 2 and _creature(s, ts[0]) and _creature(s, ts[1]):
				var a: int = ts[0]["lane"]
				var b: int = ts[1]["lane"]
				var tmp: GameState.CreatureState = ps.lanes[a].creature
				ps.lanes[a].creature = ps.lanes[b].creature
				ps.lanes[b].creature = tmp
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
			Rules.offer_dream_up(s, p, e.filter_kind, e.filter_land, ev)
		&"armour":
			for t: Dictionary in ts:
				if t.has("hero"):
					Rules.gain_armour(s, t["hero"], e.amount, ev)
		&"sprout_meadow":
			# Spore Bloom: the player's first Meadow lane grows into the field's land.
			for l: int in GameState.LANES:
				if ps.lanes[l].land == Lands.MEADOW:
					Lands.set_land(s, p, l, card.land, &"field", ev)
					break
		&"land_draw":
			# Sugar Rain: draw if the player has a creature on that land.
			for l: int in GameState.LANES:
				if ps.lanes[l].creature and ps.lanes[l].land == e.filter_land:
					for i: int in e.amount:
						Rules.draw(s, p, ev)
					break
		&"lane_atk", &"lane_hp", &"lane_keyword", &"lane_damage_taken", &"opposing_atk", \
				&"on_land_atk", &"off_land_atk", &"on_land_hp", &"no_quirk":
			pass  # auras: read by Rules.effective_* / keywords_of / damage_reduction / Fields
		_:
			push_warning("Effects: unknown op '%s'" % e.op)


static func _creature(s: GameState, t: Dictionary) -> bool:
	return t.has("lane") and t.has("player") and s.players[t["player"]].lanes[t["lane"]].creature != null
