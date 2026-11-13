class_name EventPlayer
extends Node
## Plays GameEvents back as animations, one after another. Reads views from the MatchController.

signal finished

var m: MatchController
var speed: float = 1.0
var _skip_move: Dictionary = {}


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds / speed).timeout


func play(events: Array[GameEvent]) -> void:
	for e: GameEvent in events:
		await _play_one(e)
	m.refresh_pieces()
	m.refresh_ui()
	m.verify_views()
	finished.emit()


func _play_one(e: GameEvent) -> void:
	var d: Dictionary = e.data
	match e.type:
		&"creature_played":
			var v: CreatureView = m.place_creature(d["player"], d["lane"], CardDB.card(d["card"]))
			var target: Vector3 = v.position
			v.position = target + Vector3(0, 3, 0)
			v.busy = true
			var tw := v.create_tween()
			tw.tween_property(v, "position", target, 0.45 / speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			await tw.finished
			v.busy = false
			m.refresh_pieces()
			Poof.spawn(m, target - Vector3(0, 0.4, 0), Color.WHITE, 12)
		&"building_played":
			var b: BuildingView = m.place_building(d["player"], d["lane"], CardDB.card(d["card"]))
			b.scale = Vector3.ZERO
			var tw := b.create_tween()
			tw.tween_property(b, "scale", Vector3.ONE * 0.75, 0.35 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await tw.finished
		&"spell_cast":
			var c: CardData = CardDB.card(d["card"])
			m.toast.show_message("%s casts %s" % ["You" if d["player"] == MatchController.HUMAN else "Rival", c.display_name], 1.0)
			Poof.spawn(m, Vector3(0, 0.8, -0.6), Palette.LAND_CARD[c.land], 40)
			await _wait(0.5)
		&"booped":
			var v: CreatureView = m.creature_views[d["player"]][d["lane"]]
			if v:
				v.busy = true
				var base: Vector3 = v.body.scale
				var tw := v.create_tween()
				tw.tween_property(v.body, "scale", base * Vector3(1.3, 0.7, 1.3), 0.1 / speed)
				tw.tween_property(v.body, "scale", base, 0.2 / speed).set_trans(Tween.TRANS_ELASTIC)
				Poof.spawn(m, v.global_position + Vector3(0, 0.6, 0), Palette.GOLD, 16)
				await tw.finished
				v.busy = false
		&"attack":
			await _attack(d)
		&"creature_damaged":
			var v: CreatureView = m.creature_views[d["player"]][d["lane"]]
			var hit: int = d["hit"]
			var amt: int = d["amount"]
			var txt: String = "-%d" % amt
			var col: Color = Color.WHITE
			if hit == Action.Hit.CRIT:
				txt = "CRIT! -%d" % amt
				col = Palette.GOLD
			elif hit == Action.Hit.GLANCE:
				col = Color("#c8c8c8")
			if d.get("blocked", false):
				txt += "  BLOCK"
			var pos: Vector3 = m.board.anchor(d["player"], d["lane"]) + Vector3(0, 1.2, 0)
			DamageNumber.spawn(m, pos, txt, col)
			m.rig.kick(0.3 if hit == Action.Hit.CRIT else 0.15)
			if v:
				await _shake(v)
			m.refresh_pieces()
		&"hero_damaged", &"fatigue":
			var human: bool = d["player"] == MatchController.HUMAN
			var pos := Vector3(0, 1.5, 3.6) if human else Vector3(0, 1.5, -4.6)
			DamageNumber.spawn(m, pos, "-%d" % d["amount"], Palette.HP, 96)
			m.hud.shake_hero(human)
			m.rig.kick(0.25)
			m.hud.refresh(m.state, MatchController.HUMAN)
			await _wait(0.4)
		&"creature_healed":
			if int(d["amount"]) > 0:
				DamageNumber.spawn(m, m.board.anchor(d["player"], d["lane"]) + Vector3(0, 1.2, 0), "+%d" % d["amount"], Color("#6aff7a"))
				m.refresh_pieces()
				await _wait(0.3)
		&"hero_healed":
			var human: bool = d["player"] == MatchController.HUMAN
			DamageNumber.spawn(m, Vector3(0, 1.5, 3.6) if human else Vector3(0, 1.5, -4.6), "+%d" % d["amount"], Color("#6aff7a"), 80)
			await _wait(0.3)
		&"creature_destroyed":
			var v: CreatureView = m.creature_views[d["player"]][d["lane"]]
			if v:
				m.creature_views[d["player"]][d["lane"]] = null
				var col: Color = Color.WHITE
				if v.card and CreatureView.LOOKS.has(v.card.id):
					col = Color(CreatureView.LOOKS[v.card.id][0] as String)
				Poof.spawn(m, v.global_position + Vector3(0, 0.3, 0), col, 30)
				var tw := v.create_tween()
				tw.tween_property(v, "scale", Vector3.ZERO, 0.25 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				await tw.finished
				v.queue_free()
				await _wait(0.15)
		&"frozen", &"unfrozen":
			var v: CreatureView = m.creature_views[d["player"]][d["lane"]]
			if v:
				v.set_frozen(e.type == &"frozen")
				if e.type == &"frozen":
					Poof.spawn(m, v.global_position + Vector3(0, 0.4, 0), Color("#bfe8ff"), 16)
			await _wait(0.25)
		&"creature_moved":
			await _move(d)
		&"building_returned":
			var b: BuildingView = m.building_views[d["player"]][d["lane"]]
			if b:
				m.building_views[d["player"]][d["lane"]] = null
				var tw := b.create_tween()
				tw.tween_property(b, "scale", Vector3.ZERO, 0.3 / speed)
				await tw.finished
				b.queue_free()
		&"card_drawn", &"card_returned", &"card_burned":
			m.refresh_ui()
			if e.type == &"card_burned":
				m.toast.show_message("Hand full: %s burned" % CardDB.card(d["card"]).display_name, 1.0)
			await _wait(0.2)
		&"turn_started":
			m.hud.refresh(m.state, MatchController.HUMAN)
			m.toast.show_message("Your turn!" if d["player"] == MatchController.HUMAN else "Rival's turn", 1.0)
			await _wait(0.5)
		&"game_over":
			m.refresh_ui()
		_:
			m.hud.refresh(m.state, MatchController.HUMAN)


func _attack(d: Dictionary) -> void:
	var p: int = d["player"]
	var lane: int = d["lane"]
	var v: CreatureView = m.creature_views[p][lane]
	if v == null:
		return
	var foe: int = 1 - p
	var home: Vector3 = v.position
	var target: Vector3 = m.board.anchor(foe, lane) if d["target"] == "creature" else m.board.hero_point(foe, lane)
	target = home.lerp(target, 0.78)
	v.busy = true
	var out := v.create_tween()
	out.tween_method(func(k: float) -> void:
		v.position = home.lerp(target, k * k) + Vector3(0, sin(k * PI) * 0.9, 0), 0.0, 1.0, 0.35 / speed)
	await out.finished
	var back := v.create_tween()
	back.tween_interval(0.15 / speed)
	back.tween_method(func(k: float) -> void:
		v.position = target.lerp(home, k) + Vector3(0, sin(k * PI) * 0.4, 0), 0.0, 1.0, 0.4 / speed)
	back.tween_callback(func() -> void: v.busy = false)


func _shake(v: Node3D) -> void:
	var base: Vector3 = v.position
	var tw := v.create_tween()
	for i: int in 5:
		tw.tween_property(v, "position", base + Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.06, 0.06)), 0.05 / speed)
	tw.tween_property(v, "position", base, 0.05 / speed)
	await tw.finished


func _move(d: Dictionary) -> void:
	var p: int = d["player"]
	var from: int = d["from"]
	var to: int = d["to"]
	var key: String = "%d:%d:%d" % [p, to, from]
	if _skip_move.has(key):
		_skip_move.erase(key)
		return
	var a: CreatureView = m.creature_views[p][from]
	var b: CreatureView = m.creature_views[p][to]
	m.creature_views[p][to] = a
	m.creature_views[p][from] = b
	if b:
		_skip_move["%d:%d:%d" % [p, from, to]] = true  # Swap Trick emits the reverse move too
	var tw := create_tween().set_parallel(true)
	if a:
		tw.tween_property(a, "position", m.board.anchor(p, to), 0.35 / speed).set_trans(Tween.TRANS_BACK)
	if b:
		tw.tween_property(b, "position", m.board.anchor(p, from), 0.35 / speed).set_trans(Tween.TRANS_BACK)
	await tw.finished
