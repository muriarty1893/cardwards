class_name Abilities
extends RefCounted
## Card ability implementations, keyed by CardData.ability_id.
## `lane` is the source lane (creature or building), or -1 for spells.


static func run(s: GameState, p: int, lane: int, card: CardData, targets: Array[Dictionary], ev: Array[GameEvent]) -> void:
	# Informational only (no state change): tells the view what caused the events that follow.
	ev.append(GameEvent.make(&"ability_triggered", {"player": p, "lane": lane, "card": card.id}))
	var foe: int = s.opponent(p)
	match card.ability_id:
		&"heal_self_2":
			Rules.heal_creature(s, p, lane, 2, ev)
		&"heal_hero_2":
			Rules.heal_hero(s, p, 2, ev)
		&"heal_all_own_1":
			_each_creature(s, p, func(l: int) -> void: Rules.heal_creature(s, p, l, 1, ev))
		&"heal_all_own_3":
			_each_creature(s, p, func(l: int) -> void: Rules.heal_creature(s, p, l, 3, ev))
		&"heal_lane_creature_1":
			if s.players[p].lanes[lane].creature:
				Rules.heal_creature(s, p, lane, 1, ev)
		&"heal_target_4":
			if _target_ok(s, targets, 0):
				Rules.heal_creature(s, targets[0]["player"], targets[0]["lane"], 4, ev)
		&"return_from_discard":
			var d: Array[CardData] = s.players[p].discard
			if targets.size() == 1 and targets[0].has("discard") and int(targets[0]["discard"]) < d.size():
				var c: CardData = d[targets[0]["discard"]]
				d.remove_at(targets[0]["discard"])
				Rules.return_to_hand(s, p, c, ev)
			else:
				push_warning("return_from_discard: target gone")
		&"dmg_opposing_1":
			if s.players[foe].lanes[lane].creature:
				Rules.deal_creature_damage(s, foe, lane, 1, ev)
		&"dmg_opposing_2":
			if s.players[foe].lanes[lane].creature:
				Rules.deal_creature_damage(s, foe, lane, 2, ev)
		&"dmg_enemy_hero_2":
			Rules.damage_hero(s, foe, 2, ev)
		&"dmg_enemy_hero_1":
			Rules.damage_hero(s, foe, 1, ev)
		&"dmg_all_enemy_2":
			_each_creature(s, foe, func(l: int) -> void: Rules.deal_creature_damage(s, foe, l, 2, ev))
		&"dmg_target_3":
			if _target_ok(s, targets, 0):
				Rules.deal_creature_damage(s, targets[0]["player"], targets[0]["lane"], 3, ev)
		&"dmg_target_3_freeze":
			if _target_ok(s, targets, 0):
				Rules.deal_creature_damage(s, targets[0]["player"], targets[0]["lane"], 3, ev)
				Rules.freeze(s, targets[0]["player"], targets[0]["lane"], ev)
		&"draw_1":
			Rules.draw(s, p, ev)
		&"draw_2":
			Rules.draw(s, p, ev)
			Rules.draw(s, p, ev)
		&"gain_magic_1":
			s.players[p].magic += 1
			ev.append(GameEvent.make(&"magic_changed", {"player": p, "value": s.players[p].magic}))
		&"move_self":
			if targets.size() == 1 and targets[0].has("lane") and s.players[p].lanes[targets[0]["lane"]].creature == null:
				var to: int = targets[0]["lane"]
				s.players[p].lanes[to].creature = s.players[p].lanes[lane].creature
				s.players[p].lanes[lane].creature = null
				ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": lane, "to": to}))
			else:
				push_warning("move_self: target gone")
		&"bounce_opposing_building":
			var b: CardData = s.players[foe].lanes[lane].building
			if b:
				s.players[foe].lanes[lane].building = null
				ev.append(GameEvent.make(&"building_returned", {"player": foe, "lane": lane, "card": b.id}))
				Rules.return_to_hand(s, foe, b, ev)
		&"swap_two":
			if _target_ok(s, targets, 0) and _target_ok(s, targets, 1):
				var a: int = targets[0]["lane"]
				var c: int = targets[1]["lane"]
				var lanes: Array[GameState.LaneState] = s.players[p].lanes
				var tmp: GameState.CreatureState = lanes[a].creature
				lanes[a].creature = lanes[c].creature
				lanes[c].creature = tmp
				ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": a, "to": c}))
				ev.append(GameEvent.make(&"creature_moved", {"player": p, "from": c, "to": a}))
		&"freeze_opposing":
			if s.players[foe].lanes[lane].creature:
				Rules.freeze(s, foe, lane, ev)
		&"freeze_all_enemy":
			_each_creature(s, foe, func(l: int) -> void: Rules.freeze(s, foe, l, ev))
		&"freeze_target":
			if _target_ok(s, targets, 0):
				Rules.freeze(s, targets[0]["player"], targets[0]["lane"], ev)
		&"freeze_damaged":
			# Handled by combat: lane here is the damaged creature's lane on `p`'s opponent side.
			if s.players[foe].lanes[lane].creature:
				Rules.freeze(s, foe, lane, ev)
		&"lane_max_hp_3", &"lane_atk_2", &"lane_atk_1_hp_1", &"lane_damage_minus_1", &"opposing_atk_minus_1":
			pass  # passive modifiers, read by Rules.effective_* and Combat
		_:
			push_warning("Abilities: unknown ability '%s'" % card.ability_id)


static func _each_creature(s: GameState, p: int, f: Callable) -> void:
	for l: int in GameState.LANES:
		if s.players[p].lanes[l].creature:
			f.call(l)


static func _target_ok(s: GameState, targets: Array[Dictionary], i: int) -> bool:
	if i >= targets.size() or not targets[i].has("lane"):
		push_warning("Abilities: missing target")
		return false
	var t: Dictionary = targets[i]
	if s.players[t["player"]].lanes[t["lane"]].creature == null:
		push_warning("Abilities: target creature gone")
		return false
	return true
