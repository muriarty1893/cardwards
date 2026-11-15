class_name FxDirector
extends RefCounted
## Turns (source, event) pairs into effects. choose() is a pure lookup (tested); play() runs
## the visuals for one event: first how the effect travels (projectile, rain, wave, ...),
## then its result (number, flash, burst, shell, card flight, ...).

const KINDS: Array[StringName] = [
	&"fireball", &"ember_rain", &"rain_of_spores", &"regrowth", &"sugar_rush", &"swap_trick", &"cold_snap", &"avalanche",
	&"damage", &"heal", &"draw", &"magic", &"move", &"return_building", &"freeze", &"smoke_puff", &"spore_puff", &"gem_pop", &"none",
	&"attack_hit", &"plain",
]
const ELEMENT_BY_LAND: Array[StringName] = [&"spore", &"fire", &"candy", &"ice"]
## Which event types each kind draws itself; anything else falls back to plain.
const OWNS: Dictionary = {
	&"fireball": [&"creature_damaged"],
	&"ember_rain": [&"creature_damaged"],
	&"rain_of_spores": [&"creature_healed"],
	&"regrowth": [&"card_returned"],
	&"sugar_rush": [&"card_drawn"],
	&"swap_trick": [&"creature_moved"],
	&"cold_snap": [&"frozen"],
	&"avalanche": [&"creature_damaged", &"frozen"],
	&"damage": [&"creature_damaged", &"hero_damaged"],
	&"heal": [&"creature_healed", &"hero_healed"],
	&"draw": [&"card_drawn"],
	&"magic": [&"magic_changed"],
	&"move": [&"creature_moved"],
	&"return_building": [&"building_returned"],
	&"freeze": [&"frozen"],
	&"smoke_puff": [&"hero_damaged"],
	&"spore_puff": [&"creature_healed"],
	&"gem_pop": [&"magic_changed"],
	&"attack_hit": [&"creature_damaged", &"hero_damaged"],
}
const HEAL := Color("#6aff7a")


static func choose(source: Dictionary, e: GameEvent) -> StringName:
	if source.is_empty():
		return &"plain"
	var kind: StringName = &"plain"
	if source.get("kind") == &"attack":
		kind = &"attack_hit"
	elif source.get("kind") == &"ability":
		kind = VisualDB.effect(source.get("card", &""))
	if e.type in OWNS.get(kind, []):
		return kind
	return &"plain"


# --- Playback ------------------------------------------------------------------

static func play(kind: StringName, source: Dictionary, e: GameEvent, m: MatchController) -> void:
	var d: Dictionary = e.data
	var sp: float = m.player.speed
	match kind:
		&"fireball":
			await _shot(m, &"fire", _source_pos(m, source), _creature_pos(m, d), 0.5 / sp)
			if not is_instance_valid(m):
				return
			Burst.spawn(m, &"smoke", _creature_pos(m, d), Color.WHITE, 1.3)
			Audio.sfx(&"explosion")
		&"ember_rain":
			if not source.get("delivered", false):
				source["delivered"] = true
				var pts: Array[Vector3] = []
				var foe: int = 1 - int(source["player"])
				for l: int in 4:
					if m.state.players[foe].lanes[l].creature != null or l == int(d["lane"]):
						pts.append(m.board.anchor(foe, l))
				Rain.over(m, pts, &"embers", 0.6 / sp)
				await _wait(m, 0.45 / sp)
				if not is_instance_valid(m):
					return
		&"rain_of_spores":
			var spot: Array[Vector3] = [m.board.anchor(d["player"], d["lane"])]
			Rain.over(m, spot, &"spores", 0.5 / sp)
			await _wait(m, 0.4 / sp)
			if not is_instance_valid(m):
				return
		&"regrowth":
			Burst.spawn(m, &"leaves", _hero_pos(m, source["player"]), Color.WHITE, 1.6)
			await _fly_card(m, d, m.hud.discard_screen_pos(), m.hand.cards_rect().get_center(), true)
			if not is_instance_valid(m):
				return
		&"sugar_rush":
			if not source.get("delivered", false):
				source["delivered"] = true
				Burst.spawn(m, &"sprinkles", _hero_pos(m, source["player"]), Color.WHITE, 1.8)
				Audio.sfx(&"candy_pop")
			await _fly_card(m, d, m.hud.deck_screen_pos(), m.hand.cards_rect().get_center(), false)
			if not is_instance_valid(m):
				return
		&"swap_trick":
			if not source.get("delivered", false):
				source["delivered"] = true
				Burst.spawn(m, &"smoke", m.board.anchor(d["player"], d["from"]), Color("#ff9fe0"), 1.2)
				Burst.spawn(m, &"smoke", m.board.anchor(d["player"], d["to"]), Color("#ff9fe0"), 1.2)
			await m.player.move_piece(d, true)
			if not is_instance_valid(m):
				return
			return
		&"cold_snap":
			await _shot(m, &"ice", _source_pos(m, source), _creature_pos(m, d), 0.4 / sp)
			if not is_instance_valid(m):
				return
		&"avalanche":
			if e.type == &"creature_damaged":
				var to: Vector3 = _creature_pos(m, d)
				for k: int in 3:
					Projectile.launch(m, &"boulder", to + Vector3(-1.2 + k * 1.2, 3.5, -1.0), to, 0.35 / sp)
				await _wait(m, 0.36 / sp)
				if not is_instance_valid(m):
					return
				m.rig.kick(0.3)
				Audio.sfx(&"explosion")
		&"damage", &"smoke_puff":
			var element: StringName = &"boulder" if kind == &"smoke_puff" else _element(m, source)
			var to: Vector3 = _creature_pos(m, d) if e.type == &"creature_damaged" else _hero_pos(m, d["player"])
			if kind == &"smoke_puff":
				Burst.spawn(m, &"smoke", _source_pos(m, source), Color.WHITE, 1.2)
			await _shot(m, element, _source_pos(m, source), to, 0.4 / sp)
			if not is_instance_valid(m):
				return
		&"spore_puff":
			Burst.spawn(m, &"heal", _source_pos(m, source), Color("#b6ff7a"), 1.2)
			await _wait(m, 0.15 / sp)
			if not is_instance_valid(m):
				return
		&"freeze":
			await _shot(m, &"ice", _source_pos(m, source), _creature_pos(m, d), 0.35 / sp)
			if not is_instance_valid(m):
				return
		&"gem_pop", &"magic":
			Burst.spawn(m, &"stars", _source_pos(m, source), Color("#b48cff"), 1.2)
			await _fly_gem(m, source)
			if not is_instance_valid(m):
				return
		&"move":
			await m.player.move_piece(d, false)
			if not is_instance_valid(m):
				return
			return
		&"return_building":
			await m.player.return_building(d)
			if not is_instance_valid(m):
				return
			return
		&"draw":
			await _fly_card(m, d, m.hud.deck_screen_pos(), m.hand.cards_rect().get_center(), false)
			if not is_instance_valid(m):
				return
	if not is_instance_valid(m):
		return
	await result(kind, source, e, m)


## The part every effect ends with: numbers, flashes, bursts, shells, card flights.
static func result(kind: StringName, source: Dictionary, e: GameEvent, m: MatchController) -> void:
	var d: Dictionary = e.data
	var sp: float = m.player.speed
	match e.type:
		&"creature_damaged":
			var v: CreatureView = _view(m, d)
			var hit: int = d.get("hit", Action.Hit.NORMAL)
			var amt: int = d["amount"]
			var pos: Vector3 = _number_pos(m, d["player"], d["lane"])
			var attack: bool = kind == &"attack_hit"
			if attack:
				await m.player.hit_stop()
				if not is_instance_valid(m):
					return
			if attack and hit == Action.Hit.CRIT:
				Audio.sfx(&"hit_crit")
			elif amt >= 4:
				Audio.sfx(&"hit_heavy")
			else:
				Audio.sfx(&"hit_light")
			var col: Color = Color.WHITE
			if attack and hit == Action.Hit.GLANCE:
				col = Color("#c8c8c8")
				Burst.spawn(m, &"dust_ring", pos - Vector3(0, 0.9, 0))
			else:
				Burst.spawn(m, &"sparks", pos - Vector3(0, 0.4, 0), Color.WHITE, 1.0 + amt * 0.1)
				Burst.spawn(m, &"stars", pos - Vector3(0, 0.4, 0))
			var txt: String = "-%d" % amt
			if d.get("blocked", false):
				txt += "  BLOCK"
			DamageNumber.spawn(m, pos, txt, col)
			if attack and hit == Action.Hit.CRIT:
				DamageNumber.stamp(m, pos + Vector3(0, 0.55, 0.25), "CRIT!")
				Burst.spawn(m, &"stars", pos, Palette.GOLD, 1.8)
				m.rig.punch_zoom()
			m.rig.kick(minf(0.45, 0.15 + 0.05 * amt))
			if v:
				if amt > 0:
					v.play_hit()
					v.flash()
				await m.player.shake(v)
				if not is_instance_valid(m):
					return
			m.refresh_pieces()
		&"hero_damaged":
			var human: bool = d["player"] == MatchController.HUMAN
			var pos: Vector3 = _hero_pos(m, d["player"])
			if kind == &"attack_hit":
				await m.player.hit_stop()
				if not is_instance_valid(m):
					return
			Burst.spawn(m, &"sparks", pos, Color.WHITE, 1.3)
			Audio.sfx(&"hero_hit")
			DamageNumber.spawn(m, pos, "-%d" % d["amount"], Palette.HP, 96)
			if human:
				ScreenFlash.edge(m.hud, Color("#ff3a3a"), 0.4 / sp)
			m.hud.shake_hero(human)
			m.rig.kick(0.25)
			m.hud.refresh(m.state, MatchController.HUMAN)
			await _wait(m, 0.35 / sp)
			if not is_instance_valid(m):
				return
		&"creature_healed":
			if int(d["amount"]) > 0:
				var pos: Vector3 = m.board.anchor(d["player"], d["lane"]) + Vector3(0, 0.6, 0)
				Burst.spawn(m, &"heal", pos, Color.WHITE, 1.2)
				Audio.sfx(&"heal")
				DamageNumber.spawn(m, _number_pos(m, d["player"], d["lane"]), "+%d" % d["amount"], HEAL)
				m.refresh_pieces()
				await _wait(m, 0.3 / sp)
				if not is_instance_valid(m):
					return
		&"hero_healed":
			var pos: Vector3 = _hero_pos(m, d["player"])
			Burst.spawn(m, &"heal", pos, Color.WHITE, 1.4)
			Audio.sfx(&"heal")
			DamageNumber.spawn(m, pos, "+%d" % d["amount"], HEAL, 80)
			m.hud.refresh(m.state, MatchController.HUMAN)
			await _wait(m, 0.3 / sp)
			if not is_instance_valid(m):
				return
		&"frozen":
			var v: CreatureView = _view(m, d)
			if v:
				Burst.spawn(m, &"snow", v.global_position + Vector3(0, 0.4, 0), Color.WHITE, 1.3)
				Audio.sfx(&"freeze")
				v.set_frozen(true)
			await _wait(m, 0.25 / sp)
			if not is_instance_valid(m):
				return
		&"card_drawn", &"card_returned":
			Audio.sfx(&"card_draw")
			m.refresh_ui()
			await _wait(m, 0.12 / sp)
			if not is_instance_valid(m):
				return
		&"creature_moved":
			await m.player.move_piece(d, false)
			if not is_instance_valid(m):
				return
		&"building_returned":
			await m.player.return_building(d)
			if not is_instance_valid(m):
				return
		&"magic_changed":
			m.hud.refresh(m.state, MatchController.HUMAN)


# --- Helpers -------------------------------------------------------------------

static func _wait(m: MatchController, seconds: float) -> void:
	await m.get_tree().create_timer(maxf(seconds, 0.0)).timeout


## Launch sound per projectile element.
const SHOT_SOUND: Dictionary = {&"fire": &"fire_whoosh", &"ice": &"freeze", &"candy": &"candy_pop", &"spore": &"candy_pop", &"boulder": &"attack_whoosh"}


static func _shot(m: MatchController, element: StringName, from: Vector3, to: Vector3, duration: float) -> void:
	Audio.sfx(SHOT_SOUND.get(element, &"attack_whoosh"))
	Projectile.launch(m, element, from, to, duration)
	await _wait(m, duration + 0.01)


static func _view(m: MatchController, d: Dictionary) -> CreatureView:
	var v: Variant = m.creature_views[d["player"]][d["lane"]]
	return v as CreatureView if is_instance_valid(v) else null


## Where a creature's damage/heal number appears. The rival row is near the top of the
## screen, so its numbers sit lower and toward the middle line to stay visible.
static func _number_pos(m: MatchController, p: int, lane: int) -> Vector3:
	if p == MatchController.HUMAN:
		return m.board.anchor(p, lane) + Vector3(0, 1.2, 0)
	return m.board.anchor(p, lane) + Vector3(0, 0.7, 1.0)


static func _creature_pos(m: MatchController, d: Dictionary) -> Vector3:
	return m.board.anchor(d["player"], d["lane"]) + Vector3(0, 0.5, 0)


## Where a hero "stands": behind the middle of their lanes, toward their own edge.
static func _hero_pos(m: MatchController, p: int) -> Vector3:
	return Vector3(0, 1.4, 3.6 if p == MatchController.HUMAN else -3.6)


static func _source_pos(m: MatchController, source: Dictionary) -> Vector3:
	var p: int = source.get("player", MatchController.HUMAN)
	var lane: int = source.get("lane", -1)
	if lane < 0:
		return _hero_pos(m, p)
	var c: CardData = CardDB.card(source.get("card", &""))
	if c and c.kind == CardData.Kind.BUILDING:
		var b: Variant = m.building_views[p][lane]
		if is_instance_valid(b):
			return (b as Node3D).global_position + Vector3(0, 1.0, 0)
	return m.board.anchor(p, lane) + Vector3(0, 0.6, 0)


static func _element(m: MatchController, source: Dictionary) -> StringName:
	var c: CardData = CardDB.card(source.get("card", &""))
	return ELEMENT_BY_LAND[c.land] if c else &"fire"


static func _fly_card(m: MatchController, d: Dictionary, from: Vector2, to: Vector2, face_up: bool) -> void:
	var human: bool = int(d.get("player", 0)) == MatchController.HUMAN
	var target: Vector2 = to if human else m.hud.hero_screen_pos(false)
	var start: Vector2 = from if human else m.hud.hero_screen_pos(false) + Vector2(0, 60)
	var c: CardData = CardDB.card(d.get("card", &"")) if d.has("card") else null
	FlyingCard.fly(m.hud, c, start, target, face_up and human, 0.3 / m.player.speed)
	await _wait(m, 0.3 / m.player.speed)
	if not is_instance_valid(m):
		return


static func _fly_gem(m: MatchController, source: Dictionary) -> void:
	var p: int = source.get("player", MatchController.HUMAN)
	var from: Vector2 = m.rig.camera.unproject_position(_source_pos(m, source))
	var to: Vector2 = m.hud.orb_screen_pos(p == MatchController.HUMAN)
	var gem := Panel.new()
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.size = Vector2(26, 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#b48cff")
	sb.border_color = Palette.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	gem.add_theme_stylebox_override("panel", sb)
	gem.rotation = PI / 4.0
	gem.pivot_offset = gem.size / 2.0
	m.hud.add_child(gem)
	Audio.sfx(&"magic_gain")
	gem.position = from - gem.size / 2.0
	var tw := gem.create_tween()
	tw.tween_property(gem, "position", to - gem.size / 2.0, 0.35 / m.player.speed).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(gem.queue_free)
	await tw.finished
	if not is_instance_valid(m):
		return
	m.hud.refresh(m.state, MatchController.HUMAN)
