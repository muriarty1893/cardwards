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
	&"armour_gained",
]
const HIT_STOP := 0.07
## Landing / death burst preset per CardData.Land (NEUTRAL last).
const LAND_BURSTS: Array[StringName] = [&"leaves", &"embers", &"sprinkles", &"snow", &"stars"]
const HIT_STOP_SCALE := 0.05
## Sound when a lane turns into a land (CardData.Land order, Meadow last).
const LAND_SOUNDS: Array[StringName] = [&"heal", &"fire_whoosh", &"candy_pop", &"freeze", &"card_draw"]
## How each event changes the hand of the player it names (the rival's fan follows it live).
const HAND_DELTA: Dictionary = {
	&"card_drawn": 1, &"card_returned": 1, &"dream_up_chosen": 1,
	&"creature_played": -1, &"building_played": -1, &"spell_cast": -1,
}

var m: MatchController
var speed: float = 1.0
var _skip_move: Dictionary = {}
## {} | {"kind": &"ability", "player", "lane", "card"} | {"kind": &"attack", "player", "lane", "hit"}
var _source: Dictionary = {}


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds / speed).timeout


func play(events: Array[GameEvent]) -> void:
	_source = {}
	if m.action_log:
		m.action_log.add_action(events, m.state)
	for e: GameEvent in events:
		await _play_one(e)
	_source = {}
	if m.rival:
		m.rival.set_hand_count(m.state.players[MatchController.AI].hand.size())
	m.refresh_pieces()
	m.refresh_ui()
	m.verify_views()
	finished.emit()


func _play_one(e: GameEvent) -> void:
	var d: Dictionary = e.data
	_rival_react(e)
	if e.type in [&"creature_played", &"building_played", &"spell_cast"] and int(d.get("player", -1)) == MatchController.AI:
		await _reveal(CardDB.card(d["card"]))
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
		&"second_wind":
			await _second_wind(d)
		&"land_changed":
			await _land_changed(d)
		&"land_reaction":
			await _land_reaction(d)
		&"xp_gained":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				DamageNumber.spawn(m, v.global_position + Vector3(0.35, v.height + 0.35, 0), "+%d XP" % d["amount"], Palette.GOLD, 34)
			m.overlay.refresh(m.state)
		&"level_up":
			await _level_up(d)
		&"field_set":
			await _field_set(d)
		&"tribe_bonus":
			var pos: Vector3 = FxDirector._hero_pos(m, d["player"])
			DamageNumber.spawn(m, pos + Vector3(0, 0.5, 0), "%s!" % Tribes.BONUS[d["tribe"]].to_upper(), Color("#8fe07a"), 52)
		_:
			m.hud.refresh(m.state, MatchController.HUMAN)


## The seated rival reacts to what happens at the table.
func _rival_react(e: GameEvent) -> void:
	var r: RivalSeat = m.rival
	if r == null:
		return
	var d: Dictionary = e.data
	var ai: bool = int(d.get("player", -1)) == MatchController.AI
	if ai and HAND_DELTA.has(e.type):
		r.set_hand_count(r.hand_count() + int(HAND_DELTA[e.type]))
	match e.type:
		&"creature_played", &"building_played", &"spell_cast":
			if ai:
				r.play_card()
		&"hero_damaged":
			if int(d.get("amount", 0)) > 0:
				if ai:
					r.flinch()
				else:
					r.cheer()
		&"turn_started":
			r.think(ai)
		&"game_over":
			r.think(false)
			if int(d.get("winner", -1)) == MatchController.AI:
				r.win()
			else:
				r.lose()


## Second Wind: the creature that just fell springs back up in its lane with 1 HP.
func _second_wind(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	if _view(p, l) != null:
		return
	var v: CreatureView = m.place_creature(p, l, CardDB.card(d["card"]))
	var full: Vector3 = v.scale
	v.scale = Vector3.ONE * 0.05
	v.busy = true
	Burst.spawn(m, &"heal", v.global_position + Vector3(0, 0.3, 0), Color.WHITE, 1.4)
	Audio.sfx(&"heal")
	DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.7, 0.2), "SECOND WIND!")
	var tw := v.create_tween()
	tw.tween_property(v, "scale", full, 0.45 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(v):
		v.busy = false
	m.refresh_pieces()


## A lane turns into another land: the ground sweeps out from the creature or building that
## caused it, the land's sparkle bursts and its name floats up.
func _land_changed(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var land: int = d["land"]
	var origin := Vector3.INF
	var v: CreatureView = _view(p, l)
	if d.get("cause", &"") == &"building" or (v == null and is_instance_valid(m.building_views[p][l])):
		origin = m.board.building_point(p, l)
	elif v:
		origin = v.global_position
	m.board.change_land(p, l, land, origin)
	var centre := Vector3(m.board.lane_x(l), Island.TOP_Y + 0.3, Board.STRIP_Z[p])
	Burst.spawn(m, LAND_BURSTS[land], origin if origin.is_finite() else centre, Color.WHITE, 1.4)
	Audio.sfx(LAND_SOUNDS[land])
	DamageNumber.spawn(m, centre + Vector3(0, 0.6, 0), Lands.lane_name(land) + "!", Palette.LAND_CARD[land], 64)
	await _wait(0.5)


## A spell meets the land under its target: the reaction's name over the lane and its look.
func _land_reaction(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var r: StringName = d["reaction"]
	var pos: Vector3 = FxDirector.spot(m, p, l) + Vector3(0, 0.3, 0)
	var v: CreatureView = _view(p, l)
	if v:
		pos = v.global_position + Vector3(0, 0.2, 0)
	match r:
		&"melt", &"quench":
			Burst.spawn(m, &"steam", pos, Color.WHITE, 1.6)
			Burst.spawn(m, &"steam", pos + Vector3(0.4, 0, 0.3), Color.WHITE, 1.2)
			Audio.sfx(&"fire_whoosh" if r == &"melt" else &"ice_shatter")
		&"wildfire":
			for n: int in [l - 1, l, l + 1]:
				if n >= 0 and n < 4:
					Burst.spawn(m, &"flames", FxDirector.spot(m, p, n) + Vector3(0, 0.2, 0), Color.WHITE, 1.3)
			Audio.sfx(&"fire_whoosh")
		&"caramel":
			Burst.spawn(m, &"caramel", pos + Vector3(0, 0.5, 0), Color.WHITE, 1.4)
			Audio.sfx(&"candy_pop")
		&"bloom", &"sprout":
			Burst.spawn(m, &"petals", pos + Vector3(0, 0.3, 0), Color.WHITE, 1.5)
			Burst.spawn(m, &"heal", pos, Color.WHITE, 1.2)
			Audio.sfx(&"heal")
	DamageNumber.stamp(m, pos + Vector3(0, 0.9, 0.2), Lands.REACTION_NAMES[r].to_upper() + "!")
	m.toast.show_message(Lands.REACTION_RULES[r], 1.6)
	await _wait(0.45)


## A creature levels up: light column, hop and spin, gold sparkles, LEVEL UP!
func _level_up(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	Audio.sfx(&"magic_gain")
	Audio.sfx(&"candy_pop")
	Burst.spawn(m, &"gold", v.global_position + Vector3(0, 0.4, 0), Color.WHITE, 1.3)
	DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.8, 0.25), "LEVEL %d!" % d["level"])
	await v.play_level_up(d["level"], speed)
	m.overlay.refresh(m.state)


## A field spell takes over the table: banner, weather over every lane, room light and prop.
func _field_set(d: Dictionary) -> void:
	var c: CardData = CardDB.card(d["card"])
	Banner.show_turn(m.hud, c.display_name.to_upper() + "!", Palette.LAND_CARD[c.land])
	m.board.set_field(c.land)
	if m.field_fx:
		m.field_fx.set_field(c.land)
	m.hud.refresh(m.state, MatchController.HUMAN)
	await _wait(0.9)


## The rival's card shows large at the right of the board for a moment before it lands (the
## action log has the left).
## The rival's card slides in face down (their card back), flips over and lingers.
func _reveal(c: CardData) -> void:
	var w := Control.new()
	w.size = CardWidget.SIZE
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.pivot_offset = CardWidget.SIZE / 2.0
	var face := CardWidget.new()
	face.setup(c, 0)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.visible = false
	w.add_child(face)
	var back: Control = FlyingCard.back_rect(m.card_backs[MatchController.AI]) if m.card_backs[MatchController.AI] else Control.new()
	w.add_child(back)
	var vp: Vector2 = m.hud.get_viewport_rect().size
	var at := Vector2(vp.x * 0.87, vp.y * 0.44) - CardWidget.SIZE / 2.0
	m.hud.add_child(w)
	w.position = at + Vector2(220, 0)
	w.scale = Vector2.ONE * 1.25
	w.rotation = 0.08
	w.modulate.a = 0.0
	var tw := w.create_tween().set_parallel()
	tw.tween_property(w, "position", at, 0.25 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "modulate:a", 1.0, 0.15 / speed)
	# The flip: squash to an edge, swap back for face, open up again.
	tw.chain().tween_property(w, "scale:x", 0.0, 0.12 / speed).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		back.visible = false
		face.visible = true)
	tw.chain().tween_property(w, "scale:x", 1.25, 0.14 / speed).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.0 / speed)
	tw.chain().tween_property(w, "modulate:a", 0.0, 0.25 / speed)
	tw.chain().tween_callback(w.queue_free)
	await _wait(0.55)


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
	var from: Vector2 = m.hand.last_drop_pos if human and m.hand.last_drop_pos != Vector2.ZERO else (m.hud.hero_screen_pos(true) if human else m.rival_hand_screen())
	FlyingCard.fly(m.hud, c, from, lane_screen, human, 0.22 / speed, m.card_backs[p])
	await _wait(0.22)
	var drop := Vector3.INF
	if human and m.hand.last_drop_pos != Vector2.ZERO:
		drop = m.board.ground_at_screen(m.rig.camera, m.hand.last_drop_pos)
	var v: CreatureView = m.place_creature(p, d["lane"], c, drop)
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
	m.input.creature_gone(d["player"], d["lane"])
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
	var tl: int = int(d.get("target_lane", -1))
	var tv: CreatureView = _view(foe, tl) if tl >= 0 else null
	var home: Vector3 = v.position
	var hero: bool = tl < 0
	var target: Vector3
	if tv:
		tv.busy = true
		# Stop just short of the target, wherever it stands.
		var to: Vector3 = tv.position
		var gap := Vector3(to.x - home.x, 0.0, to.z - home.z)
		target = to - gap.normalized() * minf(0.35, gap.length() * 0.5)
	else:
		target = m.board.hero_point(foe, lane)
		target.x = home.x
	v.busy = true
	var out_t: float = 0.3 / speed
	var back_t: float = 0.4 / speed
	m.rig.close_up(v.global_position, Vector3(target.x, home.y, target.z), (0.2 + 0.3 + 0.15 + 0.4 + (0.35 if hero else 0.0)) / speed)
	# Wind-up squash, then the run (the impact plays with the damage event that follows).
	var base: Vector3 = v.body.scale
	var wind := v.create_tween()
	wind.tween_property(v.body, "scale", base * Vector3(1.15, 0.8, 1.15), 0.12 / speed)
	wind.tween_property(v.body, "scale", base, 0.08 / speed)
	await wind.finished
	if not is_instance_valid(v):
		return
	var flat := Vector2(target.x - home.x, target.z - home.z)
	if flat.length() > 0.01:
		v.rotation.y = atan2(flat.x, flat.y)
	v.play_attack()
	var trail := Burst.spawn(v, &"dust_ring", v.global_position, Color(1, 1, 1, 0.6), 0.4)
	trail.one_shot = false
	var out := v.create_tween()
	out.tween_method(func(k: float) -> void:
		v.position = home.lerp(target, k * k) + Vector3(0, sin(k * PI) * 0.5, 0), 0.0, 1.0, out_t)
	await out.finished
	if is_instance_valid(trail):
		trail.queue_free()
	if not is_instance_valid(v):
		return
	var turn_back: Vector3 = target
	if hero:
		turn_back = await _hero_leap(v, target, foe)
		if not is_instance_valid(v):
			return
	if tv:
		var t_ref: CreatureView = tv
		get_tree().create_timer(0.6 / speed).timeout.connect(func() -> void:
			if is_instance_valid(t_ref):
				t_ref.busy = false)
	var back := v.create_tween()
	back.tween_interval(0.15 / speed)
	back.tween_method(func(k: float) -> void:
		v.position = turn_back.lerp(home, k) + Vector3(0, sin(k * PI) * 0.3, 0), 0.0, 1.0, back_t)
	back.tween_callback(func() -> void:
		v.position = home
		v.busy = false)


## From the board's edge: a leap at the rival (who flinches with the damage) or, when the rival's
## creature attacks you, at the camera with a shake. Returns where the creature lands again.
func _hero_leap(v: CreatureView, edge: Vector3, foe: int) -> Vector3:
	var peak: Vector3
	if foe == MatchController.AI and m.rival:
		peak = edge.lerp(m.rival.hand_point(), 0.45)
	else:
		peak = edge.lerp(m.rig.camera.global_position, 0.35)
	var up := v.create_tween()
	up.tween_method(func(k: float) -> void:
		v.position = edge.lerp(peak, k) + Vector3(0, sin(k * PI) * 0.4, 0), 0.0, 1.0, 0.18 / speed)
	await up.finished
	if foe == MatchController.HUMAN:
		m.rig.kick(0.6)
	var down := v.create_tween()
	down.tween_method(func(k: float) -> void:
		v.position = peak.lerp(edge, k), 0.0, 1.0, 0.17 / speed)
	await down.finished
	return edge


## Brief freeze-frame on impact. Always restores the time scale.
func hit_stop() -> void:
	Engine.time_scale = HIT_STOP_SCALE
	await get_tree().create_timer(HIT_STOP / speed, true, false, true).timeout
	Engine.time_scale = 1.0


## A quick squash of the body: the hit-back reaction (leaves the position alone).
func recoil(v: CreatureView) -> void:
	if v.body == null:
		return
	var base: Vector3 = v.body.scale
	var tw := v.create_tween()
	tw.tween_property(v.body, "scale", base * Vector3(1.25, 0.75, 1.25), 0.07 / speed)
	tw.tween_property(v.body, "scale", base, 0.18 / speed).set_trans(Tween.TRANS_ELASTIC)
	await tw.finished


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
	var moved: Array[Array] = []
	for pair: Array in [[a, to], [b, from]]:
		if not is_instance_valid(pair[0]):
			continue
		var node: CreatureView = pair[0]
		node.busy = true
		moved.append(pair)
		var start: Vector3 = node.position
		var end: Vector3 = m.board.anchor(p, pair[1])
		tw.tween_method(func(k: float) -> void:
			node.position = start.lerp(end, k) + Vector3(0, sin(k * PI) * 0.8, 0), 0.0, 1.0, dur)
		if spin:
			tw.tween_property(node, "rotation:y", node.rotation.y + TAU, dur)
	await tw.finished
	for pair: Array in moved:
		var node: CreatureView = pair[0]
		if is_instance_valid(node):
			node.busy = false
			node.wanderer.set_zone(m.board.roam_rect(p, pair[1]))
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
