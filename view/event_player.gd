class_name EventPlayer
extends Node
## Plays GameEvents back one after another. Tracks what caused the current effects
## (ability_triggered / attack) and hands effect events to FxDirector; plays the piece
## sequences itself (play, attack, death, move, building rise, turn banner).

signal finished

## Effect events FxDirector draws (spec 6.3).
const EFFECT_EVENTS: Array[StringName] = [
	&"creature_damaged", &"creature_healed", &"hero_damaged", &"hero_healed", &"frozen",
	&"card_drawn", &"card_returned", &"creature_moved", &"building_returned", &"magic_changed",
]
const HIT_STOP := 0.07
## Landing / death burst preset per CardData.Land (NEUTRAL last).
const LAND_BURSTS: Array[StringName] = [&"leaves", &"embers", &"sprinkles", &"snow", &"stars"]
const HIT_STOP_SCALE := 0.05

var m: MatchController
var speed: float = 1.0
var _skip_move: Dictionary = {}
## {} | {"kind": &"ability", "player", "lane", "card"} | {"kind": &"attack", "player", "lane", "hit"}
var _source: Dictionary = {}


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds / speed).timeout


func play(events: Array[GameEvent]) -> void:
	_source = {}
	for e: GameEvent in events:
		await _play_one(e)
	_source = {}
	m.refresh_pieces()
	m.refresh_ui()
	m.verify_views()
	finished.emit()


func _play_one(e: GameEvent) -> void:
	var d: Dictionary = e.data
	if e.type in EFFECT_EVENTS:
		var kind: StringName = FxDirector.choose(_source, e)
		await FxDirector.play(kind, _source, e, m)
		# A gem pop / magic gain draws once; later magic updates in the batch are plain.
		if e.type == &"magic_changed" and kind in [&"gem_pop", &"magic"]:
			_source = {}
		return
	match e.type:
		&"ability_triggered":
			_source = {"kind": &"ability", "player": d["player"], "lane": d["lane"], "card": d["card"]}
		&"attack":
			_source = {"kind": &"attack", "player": d["player"], "lane": d["lane"], "hit": d["hit"]}
			Audio.sfx(&"attack_whoosh")
			await _attack(d)
		&"creature_played":
			await _play_creature(d)
		&"building_played":
			await _play_building(d)
		&"spell_cast":
			var c: CardData = CardDB.card(d["card"])
			Audio.sfx(&"card_play")
			if VisualDB.sound(c.id) != &"":
				Audio.sfx(VisualDB.sound(c.id))
			m.toast.show_message("%s cast %s" % ["You" if d["player"] == MatchController.HUMAN else "Rival", c.display_name], 1.0)
			Burst.spawn(m, &"stars", FxDirector._hero_pos(m, d["player"]), Palette.LAND_CARD[c.land], 1.4)
			await _wait(0.3)
		&"booped":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				v.busy = true
				var base: Vector3 = v.body.scale
				var tw := v.create_tween()
				tw.tween_property(v.body, "scale", base * Vector3(1.3, 0.7, 1.3), 0.1 / speed)
				tw.tween_property(v.body, "scale", base, 0.2 / speed).set_trans(Tween.TRANS_ELASTIC)
				Burst.spawn(m, &"stars", v.global_position + Vector3(0, 0.6, 0))
				await tw.finished
				v.busy = false
		&"creature_destroyed":
			Audio.sfx(&"death")
			await _death(d)
		&"unfrozen":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				v.set_frozen(false)
				Audio.sfx(&"ice_shatter")
			await _wait(0.2)
		&"fatigue":
			var human: bool = d["player"] == MatchController.HUMAN
			DamageNumber.spawn(m, FxDirector._hero_pos(m, d["player"]), "-%d" % d["amount"], Palette.HP, 96)
			Audio.sfx(&"hero_hit")
			m.hud.shake_hero(human)
			m.hud.refresh(m.state, MatchController.HUMAN)
			await _wait(0.4)
		&"card_burned":
			m.refresh_ui()
			Audio.sfx(&"card_deal")
			m.toast.show_message("Hand full: %s burned" % CardDB.card(d["card"]).display_name, 1.0)
			await _wait(0.2)
		&"turn_started":
			_source = {}
			m.hud.refresh(m.state, MatchController.HUMAN)
			var mine: bool = d["player"] == MatchController.HUMAN
			Audio.sfx(&"turn_start", 0.0)
			Banner.show_turn(m.hud, "YOUR TURN" if mine else "RIVAL'S TURN", Color("#ffcf3a") if mine else Color("#b06cff"))
			await _wait(0.6)
		&"game_over":
			m.refresh_ui()
		_:
			m.hud.refresh(m.state, MatchController.HUMAN)


func _view(p: int, l: int) -> CreatureView:
	var v: Variant = m.creature_views[p][l]
	return v as CreatureView if is_instance_valid(v) else null


# --- Sequences -----------------------------------------------------------------

func _play_creature(d: Dictionary) -> void:
	var c: CardData = CardDB.card(d["card"])
	var p: int = d["player"]
	var lane_screen: Vector2 = m.rig.camera.unproject_position(m.board.anchor(p, d["lane"]))
	var human: bool = p == MatchController.HUMAN
	Audio.sfx(&"card_play")
	var from: Vector2 = m.hand.last_drop_pos if human and m.hand.last_drop_pos != Vector2.ZERO else m.hud.hero_screen_pos(human)
	FlyingCard.fly(m.hud, c, from, lane_screen, human, 0.22 / speed)
	await _wait(0.22)
	var v: CreatureView = m.place_creature(p, d["lane"], c)
	var target: Vector3 = v.position
	v.position = target + Vector3(0, 3, 0)
	v.busy = true
	var tw := v.create_tween()
	tw.tween_property(v, "position", target, 0.4 / speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	v.busy = false
	m.refresh_pieces()
	Audio.sfx(&"creature_land")
	var feet: Vector3 = target - Vector3(0, 0.4, 0)
	Burst.spawn(m, &"dust_ring", feet)
	Burst.spawn(m, LAND_BURSTS[c.land], feet + Vector3(0, 0.3, 0), Color.WHITE, 1.2)
	m.rig.kick(0.08)


func _play_building(d: Dictionary) -> void:
	var b: BuildingView = m.place_building(d["player"], d["lane"], CardDB.card(d["card"]))
	Audio.sfx(&"card_play")
	Audio.sfx(&"building_rise")
	var home: Vector3 = b.position
	b.position = home - Vector3(0, 1.2, 0)
	var tw := b.create_tween()
	tw.tween_property(b, "position", home, 0.35 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Burst.spawn(m, &"dust_ring", home + Vector3(0, 0.15, 0))
	m.rig.kick(0.1)
	await tw.finished


func _death(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	m.creature_views[d["player"]][d["lane"]] = null
	v.busy = true
	var death: float = v.play_death()
	if death > 0.0:
		await _wait(minf(death, 0.9) * 0.8)
	if not is_instance_valid(v):
		return
	var at: Vector3 = v.global_position + Vector3(0, 0.3, 0)
	Burst.spawn(m, &"smoke", at, Color.WHITE, 1.2)
	if v.card:
		Burst.spawn(m, LAND_BURSTS[v.card.land], at, Color.WHITE, 1.2)
	await v.dissolve(0.35 / speed)
	if is_instance_valid(v):
		v.queue_free()
	await _wait(0.1)


func _attack(d: Dictionary) -> void:
	var p: int = d["player"]
	var lane: int = d["lane"]
	var v: CreatureView = _view(p, lane)
	if v == null:
		return
	var foe: int = 1 - p
	var home: Vector3 = v.position
	var tl: int = int(d.get("target_lane", -1))
	var target: Vector3 = m.board.anchor(foe, tl) if tl >= 0 else m.board.hero_point(foe, lane)
	target = home.lerp(target, 0.78)
	v.busy = true
	# Wind-up squash, then the leap (the impact plays with the damage event that follows).
	var base: Vector3 = v.body.scale
	var wind := v.create_tween()
	wind.tween_property(v.body, "scale", base * Vector3(1.15, 0.8, 1.15), 0.12 / speed)
	wind.tween_property(v.body, "scale", base, 0.08 / speed)
	await wind.finished
	v.play_attack()
	var trail := Burst.spawn(v, &"dust_ring", v.global_position, Color(1, 1, 1, 0.6), 0.6)
	trail.one_shot = false
	var out := v.create_tween()
	out.tween_method(func(k: float) -> void:
		v.position = home.lerp(target, k * k) + Vector3(0, sin(k * PI) * 0.9, 0), 0.0, 1.0, 0.3 / speed)
	await out.finished
	if is_instance_valid(trail):
		trail.queue_free()
	var back := v.create_tween()
	back.tween_interval(0.15 / speed)
	back.tween_method(func(k: float) -> void:
		v.position = target.lerp(home, k) + Vector3(0, sin(k * PI) * 0.4, 0), 0.0, 1.0, 0.4 / speed)
	back.tween_callback(func() -> void: v.busy = false)


## Brief freeze-frame on impact. Always restores the time scale.
func hit_stop() -> void:
	Engine.time_scale = HIT_STOP_SCALE
	await get_tree().create_timer(HIT_STOP / speed, true, false, true).timeout
	Engine.time_scale = 1.0


func shake(v: Node3D) -> void:
	var base: Vector3 = v.position
	var tw := v.create_tween()
	for i: int in 5:
		tw.tween_property(v, "position", base + Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.06, 0.06)), 0.05 / speed)
	tw.tween_property(v, "position", base, 0.05 / speed)
	await tw.finished


## Moves a creature view to its new lane (a hop, or a spin for Swap Trick).
func move_piece(d: Dictionary, spin: bool) -> void:
	var p: int = d["player"]
	var from: int = d["from"]
	var to: int = d["to"]
	var key: String = "%d:%d:%d" % [p, to, from]
	if _skip_move.has(key):
		_skip_move.erase(key)
		return
	var a: Variant = m.creature_views[p][from]
	var b: Variant = m.creature_views[p][to]
	m.creature_views[p][to] = a
	m.creature_views[p][from] = b
	if is_instance_valid(b):
		_skip_move["%d:%d:%d" % [p, from, to]] = true  # Swap Trick emits the reverse move too
	var dur: float = 0.4 / speed
	var tw := create_tween().set_parallel(true)
	for pair: Array in [[a, to], [b, from]]:
		if not is_instance_valid(pair[0]):
			continue
		var node: Node3D = pair[0]
		var start: Vector3 = node.position
		var end: Vector3 = m.board.anchor(p, pair[1])
		tw.tween_method(func(k: float) -> void:
			node.position = start.lerp(end, k) + Vector3(0, sin(k * PI) * 0.8, 0), 0.0, 1.0, dur)
		if spin:
			tw.tween_property(node, "rotation:y", node.rotation.y + TAU, dur)
	await tw.finished
	m.refresh_pieces()


## The building pops up and shrinks away toward its owner's side.
func return_building(d: Dictionary) -> void:
	var b: Variant = m.building_views[d["player"]][d["lane"]]
	if not is_instance_valid(b):
		return
	m.building_views[d["player"]][d["lane"]] = null
	var node: Node3D = b
	Audio.sfx(&"candy_pop")
	Burst.spawn(m, &"sprinkles", node.global_position + Vector3(0, 0.6, 0))
	var tw := node.create_tween()
	tw.tween_property(node, "position", node.position + Vector3(0, 1.2, 0), 0.18 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector3.ZERO, 0.22 / speed)
	await tw.finished
	node.queue_free()
