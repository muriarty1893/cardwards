class_name CreatureView
extends Node3D
## A creature on the board: its VisualDB model in the cartoon style, sized by level,
## playing idle with the odd fidget, plus hit flash, dissolve and the freeze shell.

const BASE_Y := 0.58
## Standing height in world units by creature level (index 0 unused).
const HEIGHTS: Array[float] = [0.55, 0.55, 0.72, 0.95]
## Wide flyers are scaled down so they stay inside their lane.
const MAX_WIDTH := 1.05
const ATTACK_ANIMS: Array[StringName] = [&"Punch", &"Bite_Front", &"Headbutt"]
const HIT_ANIMS: Array[StringName] = [&"HitReact", &"HitRecieve"]
const IDLE_ANIMS: Array[StringName] = [&"Idle", &"Flying_Idle", &"Flying"]
const FIDGET_ANIMS: Array[StringName] = [&"Wave", &"Yes", &"Dance"]
## Clips for walking around the lane, first found wins (flyers drift with their flying loops).
const MOVE_ANIMS: Array[StringName] = [&"Walk", &"Fast_Flying", &"Flying_Idle", &"Run", &"Flying"]

var card: CardData
## Held by the event player (attacks, deaths...). Taking it pops the creature out of its house.
var busy: bool = false:
	set(v):
		busy = v
		if v and inside_house:
			exit_house(true)
## Its house (CreatureHouse), if it brought one; inside_house while it is in there.
var house: Node3D
var inside_house: bool = false
var _outside := Vector3.ZERO
var body: Node3D
var height: float = 1.0
var _shell: IceShell
## Ground blob where the sun casts no shadows (web); null otherwise.
var _blob: BlobShadow
var _anim: AnimationPlayer
var _idle: StringName = &""
var _fidget_in: float = 0.0
## Set by play_death(): the model holds its death pose instead of returning to idle.
var _dying: bool = false
## Faded out while it can't be chosen as an attack target.
var dimmed: bool = false
var hidden_look: bool = false
## A point the creature watches while standing (the card being dragged); INF for none.
var look_point := Vector3.INF
## Low health: sweats and wobbles.
var sweaty: bool = false
var _sweat_in: float = 0.0
static var _shimmer_mat: ShaderMaterial
## Wanders the lane (cosmetic); set up by the match with the roam zone.
var wanderer: Wanderer
## True while the player drags an attack from this creature; it faces `aim_at`.
var aiming: bool = false
var aim_at := Vector3.ZERO
var _moving: bool = false
## Models with no walking clip hop instead.
var _hops: bool = false
var _body_y: float = 0.0
var _t: float = 0.0

## On your turn: READY to act (glowing ring), SLEEPING (played this turn: "z" puffs) or SPENT
## (already acted: slightly darker).
enum Readiness { NONE, READY, SLEEPING, SPENT }
var readiness: Readiness = Readiness.NONE
var _ring: Node3D
var _ring_tw: Tween
var _zzz_in: float = 0.0
## Living board: level (1..3) grows the model 12% per level and adds a gold ring at Lv 2+;
## at home on its own land it now and then puffs that land's particles.
var level: int = 1
var home_land: int = -1
var base_height: float = 1.0
var _base_k: float = 1.0
var _box_y: float = 0.0
var _level_ring: Node3D
var _home_in: float = 0.0
## The field's land (-1 none): creatures shiver in Snowstorm, puff steam in Volcano, sneeze
## spores in Spore Bloom and hop for sprinkles in Sugar Rain, now and then.
var weather: int = -1
var _weather_in: float = 0.0
const LEVEL_GROWTH := 0.12
const HOME_PUFFS: Array[StringName] = [&"leaves", &"embers", &"sprinkles", &"snow", &"stars", &"sand"]


static func create(c: CardData, model_override: String = "") -> CreatureView:
	var v := CreatureView.new()
	v.card = c
	v.height = HEIGHTS[clampi(c.level, 0, 3)]
	var path: String = model_override if model_override != "" else VisualDB.model_path(c.id)
	var pair: Array = VisualDB.merge_pair(c.id) if model_override == "" else []
	if not pair.is_empty():
		v.height *= MERGE_SCALE
	if path != "" and ResourceLoader.exists(path):
		v._build_model(load(path) as PackedScene, VisualDB.tint(c.id))
	else:
		v._build_fallback(c)
	if not pair.is_empty():
		v._add_rider(pair[1])
	v._fidget_in = randf_range(6.0, 12.0)
	if not BlobShadow.sun_shadows():
		v._add_blob()
	v._body_y = v.body.position.y
	v.base_height = v.height
	v._base_k = v.body.scale.x
	v._home_in = randf_range(2.0, 5.0)
	v._hops = v._anim == null or not (v._anim.has_animation(&"Walk") or v._anim.has_animation(&"Run") or v._anim.has_animation(&"Fast_Flying") or v._anim.has_animation(&"Flying"))
	v._t = randf() * TAU
	v.wanderer = Wanderer.new()
	v.wanderer.name = "Wanderer"
	v.add_child(v.wanderer)
	return v


## Merged forms: the big partner is this much taller, and carries the other partner (RIDER of its height) on top.
const MERGE_SCALE := 1.15
const RIDER := 0.55


## A merged form's second partner riding on the big one's back, with a soft aura ring in both partners' colours.
func _add_rider(rider_id: StringName) -> void:
	var path: String = VisualDB.model_path(rider_id)
	if path == "" or not ResourceLoader.exists(path):
		return
	var rider := (load(path) as PackedScene).instantiate() as Node3D
	rider.name = "Rider"
	Toon.apply(rider, VisualDB.tint(rider_id), 0.0, true)
	var big: AABB = Palette.bounds(body)
	var rb: AABB = Palette.bounds(rider)
	var k: float = (height * RIDER / body.scale.x) / maxf(rb.size.y, 0.01)
	rider.scale = Vector3.ONE * k
	# Sit a little into the big partner's top, a touch towards its back.
	rider.position = Vector3(big.get_center().x - rb.get_center().x * k, big.end.y - big.size.y * 0.14 - rb.position.y * k, big.get_center().z - big.size.z * 0.12)
	body.add_child(rider)
	var anim := rider.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		for n: StringName in IDLE_ANIMS:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
				anim.play(n)
				anim.seek(randf(), true)
				break
	height += height * RIDER * 0.8
	var aura := Node3D.new()
	aura.name = "MergeAura"
	var cols: Array[Color] = [VisualDB.tint(card.id), VisualDB.tint(rider_id)]
	for i: int in 2:
		var c: Color = cols[i] if cols[i].a > 0.0 else Color("#ffd84a")
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(c.r, c.g, c.b, 0.55)
		var ring: MeshInstance3D = _torus(0.32 + 0.07 * i, 0.03, mat)
		ring.position.y = Island.TOP_Y - BASE_Y + 0.03 + 0.01 * i
		aura.add_child(ring)
	add_child(aura)


func _add_blob() -> void:
	var box: AABB = Palette.bounds(body)
	var w: float = maxf(box.size.x, box.size.z) * body.scale.x
	_blob = BlobShadow.build(clampf(w * 0.4, 0.14, 0.34), height, Island.TOP_Y - BASE_Y + 0.02)
	add_child(_blob)


func _build_model(scene: PackedScene, tint: Color) -> void:
	body = scene.instantiate() as Node3D
	add_child(body)
	Toon.apply(body, tint, 0.0, true)
	var box: AABB = Palette.bounds(body)
	var k: float = height / maxf(box.size.y, 0.01)
	k = minf(k, MAX_WIDTH / maxf(maxf(box.size.x, box.size.z), 0.01))
	body.scale = Vector3.ONE * k
	_box_y = box.position.y
	# Feet on the lane surface; the view's origin is BASE_Y above the board's zero.
	body.position = Vector3(0, Island.TOP_Y - BASE_Y - box.position.y * k, 0)
	_anim = body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for n: StringName in IDLE_ANIMS:
			if _anim.has_animation(n):
				_idle = n
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
				break
		_anim.animation_finished.connect(func(_n: StringName) -> void: _play_idle())
		_play_idle()
		_anim.seek(randf() * 1.5, true)


## Land-coloured toon capsule, used only if a model file is missing.
func _build_fallback(c: CardData) -> void:
	body = Node3D.new()
	add_child(body)
	var cap := CapsuleMesh.new()
	cap.height = height
	cap.radius = height * 0.3
	body.add_child(Palette.mesh(cap, Toon.plain(Palette.LAND_CARD[c.land], 0.0, true), Vector3(0, height / 2.0, 0)))
	body.position = Vector3(0, Island.TOP_Y - BASE_Y, 0)


func _play_idle() -> void:
	if _anim and _idle != &"" and not _dying:
		_anim.play(_idle, 0.15)


func _play_first(names: Array[StringName]) -> float:
	if _anim == null:
		return 0.0
	for n: StringName in names:
		if _anim.has_animation(n):
			_anim.play(n, 0.08)
			return _anim.get_animation(n).length
	return 0.0


func play_attack() -> void:
	_play_first(ATTACK_ANIMS)


func play_hit() -> void:
	_play_first(HIT_ANIMS)


## Returns the death animation's length (0 if the model has none).
func play_death() -> float:
	_dying = true
	return _play_first([&"Death"])


## Walking (true) or standing (false): plays the walk / flying loop, or idle.
func play_move(on: bool) -> void:
	if on == _moving:
		return
	_moving = on
	if _anim == null or _dying:
		return
	if on:
		for n: StringName in MOVE_ANIMS:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
				_anim.play(n, 0.15)
				return
	else:
		_play_idle()


func is_moving() -> bool:
	return _moving


## A friendly wave (at a neighbour); a nod if the model can't wave.
func wave() -> void:
	if busy or _dying or _anim == null:
		return
	heart()
	for n: StringName in [&"Wave", &"Yes"]:
		if _anim.has_animation(n):
			_anim.play(n, 0.2)
			return


## Plays one of the model's fidget clips. False when busy, walking or the model has none.
func fidget() -> bool:
	if busy or _dying or _moving or _anim == null:
		return false
	var options: Array[StringName] = []
	for n: StringName in FIDGET_ANIMS:
		if _anim.has_animation(n):
			options.append(n)
	if options.is_empty():
		return false
	_anim.play(options[randi() % options.size()], 0.2)
	return true


## Brief white flash (hit feedback).
func flash(duration: float = 0.12) -> void:
	var tw := create_tween()
	tw.tween_method(func(x: float) -> void: Toon.set_flash(body, x), 1.0, 0.0, duration)


## Dissolves the model away (death). Awaitable.
func dissolve(duration: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_method(func(x: float) -> void: Toon.set_dissolve(body, x), 0.0, 1.0, duration)
	if _blob:
		tw.parallel().tween_property(_blob, "transparency", 1.0, duration)
	await tw.finished


func set_readiness(r: Readiness) -> void:
	if r == readiness:
		return
	readiness = r
	if wanderer:
		wanderer.set_resting(r == Readiness.SLEEPING)
	if body:
		Toon.set_shade(body, 1.0 if r == Readiness.SPENT else 0.0)
	if r == Readiness.READY:
		_show_ring()
	elif is_instance_valid(_ring):
		_ring.queue_free()
		_ring = null
	_zzz_in = 0.0


func _show_ring() -> void:
	if is_instance_valid(_ring):
		return
	var w: float = clampf(height * 0.55, 0.24, 0.42)
	_ring = Node3D.new()
	_ring.name = "ReadyRing"
	_ring.position.y = Island.TOP_Y - BASE_Y + 0.04
	_ring.scale = Vector3(1, 0.15, 1)
	add_child(_ring)
	# A dark ink band under a bright green one, so it reads on every lane colour.
	var ink: StandardMaterial3D = _ring_material(Color(Palette.INK, 0.6), -91)
	var glow: StandardMaterial3D = _ring_material(Color("#5dff3a", 1.0), -90)
	_ring.add_child(_torus(w, 0.07, ink))
	_ring.add_child(_torus(w, 0.045, glow))
	_ring_tw = _ring.create_tween().set_loops()
	_ring_tw.tween_property(glow, "albedo_color:a", 0.55, 0.6).set_trans(Tween.TRANS_SINE)
	_ring_tw.tween_property(glow, "albedo_color:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)


func _ring_material(col: Color, priority: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	mat.render_priority = priority
	return mat


func _torus(radius: float, half_width: float, mat: Material) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - half_width
	torus.outer_radius = radius + half_width
	torus.rings = 32
	torus.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = torus
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## One "z" drifting up from a sleeping creature.
func _puff_z() -> void:
	var z := Label3D.new()
	z.text = "z"
	z.font = load(UiStyle.TITLE_FONT) as FontFile
	z.font_size = 96
	z.pixel_size = 0.004
	z.outline_size = 22
	z.outline_modulate = Palette.INK
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.no_depth_test = true
	z.position = Vector3(0.12, Island.TOP_Y - BASE_Y + height + 0.12, 0)
	add_child(z)
	var tw := z.create_tween().set_parallel(true)
	tw.tween_property(z, "position", z.position + Vector3(0.15, 0.4, 0), 1.4)
	tw.tween_property(z, "modulate:a", 0.0, 1.4).set_ease(Tween.EASE_IN)
	tw.tween_property(z, "outline_modulate:a", 0.0, 1.4).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(z.queue_free)


## Shows level `lv`: bigger model, gold ring under it (brighter at the max level).
func set_level(lv: int, animate: bool = false) -> void:
	lv = clampi(lv, 1, Levels.MAX)
	if lv == level and is_instance_valid(_level_ring) == (lv > 1):
		return
	level = lv
	var f: float = 1.0 + LEVEL_GROWTH * float(lv - 1)
	var k: float = _base_k * f
	height = base_height * f
	_body_y = Island.TOP_Y - BASE_Y - _box_y * k
	if body:
		if animate:
			var tw := body.create_tween()
			tw.tween_property(body, "scale", Vector3.ONE * k, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		else:
			body.scale = Vector3.ONE * k
	if is_instance_valid(_level_ring):
		_level_ring.queue_free()
		_level_ring = null
	if lv > 1:
		var w: float = clampf(height * 0.62, 0.3, 0.52)
		_level_ring = Node3D.new()
		_level_ring.name = "LevelRing"
		_level_ring.position.y = Island.TOP_Y - BASE_Y + 0.03
		_level_ring.scale = Vector3(1, 0.12, 1)
		add_child(_level_ring)
		var gold: StandardMaterial3D = _ring_material(Color(Palette.GOLD, 0.95 if lv >= Levels.MAX else 0.7), -92)
		_level_ring.add_child(_torus(w, 0.035 if lv < Levels.MAX else 0.055, gold))
		if lv >= Levels.MAX:
			var spin := _level_ring.create_tween().set_loops()
			spin.tween_property(gold, "albedo_color:a", 0.5, 0.8).set_trans(Tween.TRANS_SINE)
			spin.tween_property(gold, "albedo_color:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


## The level-up moment: a hop and spin inside a column of light, a sparkle burst, growing to
## the new size. Awaitable.
func play_level_up(lv: int, speed: float = 1.0) -> void:
	busy = true
	var col := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.42
	cyl.height = 2.4
	cyl.radial_segments = 16
	cyl.rings = 1
	cyl.cap_top = false
	cyl.cap_bottom = false
	col.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.85, 0.35, 0.0)
	col.material_override = mat
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	col.position.y = Island.TOP_Y - BASE_Y + 1.2
	add_child(col)
	var d: float = 1.0 / maxf(speed, 0.01)
	var light := col.create_tween()
	light.tween_property(mat, "albedo_color:a", 0.75, 0.15 * d)
	light.tween_property(mat, "albedo_color:a", 0.0, 0.6 * d).set_delay(0.25 * d)
	light.parallel().tween_property(col, "scale", Vector3(1.6, 1.0, 1.6), 0.85 * d)
	light.tween_callback(col.queue_free)
	if body:
		var start_y: float = body.rotation.y
		var hop := create_tween()
		hop.tween_property(body, "position:y", _body_y + height * 0.6, 0.22 * d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.parallel().tween_property(body, "rotation:y", start_y + TAU, 0.5 * d).set_trans(Tween.TRANS_SINE)
		hop.tween_callback(func() -> void: set_level(lv, true))
		hop.tween_property(body, "position:y", _body_y, 0.22 * d).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await hop.finished
		if is_instance_valid(body):
			body.rotation.y = start_y
	else:
		set_level(lv, true)
	busy = false


## Walks in through the door: shrinks into the house, which lights up.
func enter_house() -> void:
	if not is_instance_valid(house) or inside_house:
		return
	inside_house = true
	_outside = position
	var into: Vector3 = house.global_position
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position", Vector3(into.x, position.y, into.z), 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		if inside_house and is_instance_valid(house):
			house.call(&"set_occupied", true))


## Comes back out of the door (instant: pops straight out, for attacks and tests).
func exit_house(instant: bool = false) -> void:
	if not inside_house:
		return
	inside_house = false
	if is_instance_valid(house):
		house.call(&"set_occupied", false)
	if instant:
		scale = Vector3.ONE
		position = _outside
		return
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position", _outside, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_weather(land: int) -> void:
	if land != weather:
		weather = land
		_weather_in = randf_range(1.5, 6.0)


func _weather_moment() -> void:
	if body == null:
		return
	var head: Vector3 = global_position + Vector3(0, Island.TOP_Y - BASE_Y + height + 0.1, 0)
	match weather:
		CardData.Land.FROST:  # shiver
			var tw := body.create_tween()
			for i: int in 6:
				tw.tween_property(body, "rotation:z", 0.12 if i % 2 == 0 else -0.12, 0.05)
			tw.tween_property(body, "rotation:z", 0.0, 0.05)
			Burst.spawn(get_parent(), &"snow", head, Color.WHITE, 0.4)
		CardData.Land.EMBER:  # too hot: a puff of steam
			Burst.spawn(get_parent(), &"steam", head, Color.WHITE, 0.45)
		CardData.Land.MUSHROOM:  # a spore sneeze
			Burst.spawn(get_parent(), &"heal", head, Color("#b8ff8a"), 0.5)
			var tw := body.create_tween()
			tw.tween_property(body, "rotation:x", -0.25, 0.12)
			tw.tween_property(body, "rotation:x", 0.0, 0.2).set_trans(Tween.TRANS_BACK)
		_:  # catching sprinkles
			var tw := body.create_tween()
			tw.tween_property(body, "position:y", _body_y + height * 0.35, 0.15).set_ease(Tween.EASE_OUT)
			tw.tween_property(body, "position:y", _body_y, 0.2).set_trans(Tween.TRANS_BOUNCE)
			Burst.spawn(get_parent(), &"sprinkles", head, Color.WHITE, 0.35)


## The body's scale at rest (grows with the level). Squashes always spring back to this.
func rest_scale() -> Vector3:
	return Vector3.ONE * _base_k * (1.0 + LEVEL_GROWTH * float(level - 1))


## Squash-and-stretch spring on the body (landing, hits).
func spring(amount: float = 0.25) -> void:
	if body == null or _dying:
		return
	var base: Vector3 = rest_scale()
	var tw := create_tween()
	tw.tween_property(body, "scale", base * Vector3(1.0 + amount, 1.0 - amount, 1.0 + amount), 0.06)
	tw.tween_property(body, "scale", base * Vector3(1.0 - amount * 0.4, 1.0 + amount * 0.5, 1.0 - amount * 0.4), 0.1)
	tw.tween_property(body, "scale", base, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Just played: a happy hop and a couple of hearts.
func hop_happy() -> void:
	if body == null or _dying:
		return
	var y: float = _body_y
	var tw := create_tween()
	tw.tween_property(body, "position:y", y + height * 0.45, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(body, "position:y", y, 0.16).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: spring(0.2))
	heart()
	var again := create_tween()
	again.tween_interval(0.2)
	again.tween_callback(func() -> void:
		if not _dying:
			heart())


## An ally scored a kill: a cheer (the model's Yes / Dance) and a little jump.
func cheer() -> void:
	if body == null or _dying or busy:
		return
	_play_first([&"Yes", &"Dance", &"Wave"])
	var y: float = _body_y
	var tw := create_tween()
	tw.tween_property(body, "position:y", y + height * 0.25, 0.12)
	tw.tween_property(body, "position:y", y, 0.14)
	Burst.spawn(get_parent(), &"stars", global_position + Vector3(0, Island.TOP_Y - BASE_Y + height + 0.1, 0), Palette.GOLD, 0.5)


## A big enemy charges nearby: duck down and tremble for a moment.
func cower() -> void:
	if body == null or _dying or busy:
		return
	var base: Vector3 = rest_scale()
	var tw := create_tween()
	tw.tween_property(body, "scale", base * Vector3(1.12, 0.72, 1.12), 0.1)
	for i: int in 4:
		tw.tween_property(body, "rotation:z", 0.08 if i % 2 == 0 else -0.08, 0.06)
	tw.tween_property(body, "rotation:z", 0.0, 0.06)
	tw.tween_interval(0.25)
	tw.tween_property(body, "scale", base, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_low_health(on: bool) -> void:
	if on == sweaty:
		return
	sweaty = on
	if not on and body:
		body.rotation.z = 0.0


func _sweat_drop() -> void:
	var d := MeshInstance3D.new()
	d.mesh = Palette.sphere(0.04, 6)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color("#8fd8ff", 0.9)
	d.material_override = mat
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(d)
	var side: float = 1.0 if randf() < 0.5 else -1.0
	var start := Vector3(0.18 * side, Island.TOP_Y - BASE_Y + height * 0.9, 0.05)
	d.position = start
	var tw := d.create_tween().set_parallel(true)
	tw.tween_property(d, "position", start + Vector3(0.15 * side, -0.35, 0), 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(d.queue_free)


## A pink heart floats up (greeting a neighbour).
func heart() -> void:
	var h := Sprite3D.new()
	h.texture = load(VisualDB.ICON_HEART) as Texture2D
	h.pixel_size = 0.0007
	h.modulate = Color("#ff6aa8")
	h.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	h.no_depth_test = true
	h.shaded = false
	h.position = Vector3(0, Island.TOP_Y - BASE_Y + height + 0.15, 0)
	add_child(h)
	var tw := h.create_tween().set_parallel(true)
	tw.tween_property(h, "position", h.position + Vector3(0, 0.45, 0), 1.2)
	tw.tween_property(h, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(h.queue_free)


## Marks the creature at home on `land` (-1: away); home creatures puff their land now and then.
func set_home(land: int) -> void:
	home_land = land


func set_dimmed(on: bool) -> void:
	if on == dimmed:
		return
	dimmed = on
	_apply_see_through()


## Hidden keyword: the body goes half see-through with violet ripples over it.
func set_hidden_look(on: bool) -> void:
	if on == hidden_look:
		return
	hidden_look = on
	if _shimmer_mat == null:
		_shimmer_mat = ShaderMaterial.new()
		_shimmer_mat.shader = load("res://view/fx/hidden_shimmer.gdshader") as Shader
	if body:
		for n: Node in body.find_children("*", "MeshInstance3D", true, false):
			(n as GeometryInstance3D).material_overlay = _shimmer_mat if on else null
	_apply_see_through()


func _apply_see_through() -> void:
	if body == null:
		return
	var t: float = 0.55 if dimmed else (0.42 if hidden_look else 0.0)
	for n: Node in body.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).transparency = t


## Ice shell on while frozen; it shatters when the freeze ends.
func set_frozen(on: bool) -> void:
	if on and not is_instance_valid(_shell):
		_shell = IceShell.attach(self)
	elif not on and is_instance_valid(_shell):
		_shell.shatter()
		_shell = null


func is_frozen_visual() -> bool:
	return is_instance_valid(_shell)


func _process(delta: float) -> void:
	_t += delta
	if body and not _dying:
		var lift: float = 0.0
		if _moving and _hops:
			lift = absf(sin(_t * 9.0)) * height * 0.12
		elif not _moving and readiness == Readiness.READY and not busy:
			lift = absf(sin(_t * 5.0)) * height * 0.04
		body.position.y = _body_y + lift
	if sweaty and body and not _dying:
		body.rotation.z = sin(_t * 7.0) * 0.06
		_sweat_in -= delta
		if _sweat_in <= 0.0:
			_sweat_in = randf_range(0.7, 1.2)
			_sweat_drop()
	if readiness == Readiness.SLEEPING:
		_zzz_in -= delta
		if _zzz_in <= 0.0:
			_zzz_in = 0.9
			_puff_z()
	_fidget_in -= delta
	if _fidget_in <= 0.0:
		_fidget_in = randf_range(6.0, 12.0)
		fidget()
	if weather >= 0 and not _dying and not busy and not inside_house and is_inside_tree():
		_weather_in -= delta
		if _weather_in <= 0.0:
			_weather_in = randf_range(7.0, 14.0)
			_weather_moment()
	if home_land >= 0 and not _dying and is_inside_tree():
		_home_in -= delta
		if _home_in <= 0.0:
			_home_in = randf_range(3.5, 7.0)
			Burst.spawn(get_parent(), HOME_PUFFS[home_land], global_position + Vector3(0, Island.TOP_Y - BASE_Y + 0.15, 0), Color.WHITE, 0.45)
