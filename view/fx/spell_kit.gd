class_name SpellKit
extends RefCounted
## Spell effects (look & feel spec 2): reusable pieces (comet, beam, rain, magic circle, aura,
## vines, slash, falling spike, blizzard, swirl) and one recipe per spell (VisualDB.SPELL_FX), so
## every spell looks like itself. EventPlayer calls play() when a spell resolves, with the spots it
## hits (creatures or heroes, taken from the events that follow); the hit / heal / freeze results
## then play as usual.

static var _circle_shader: Shader


## Plays `recipe` from the caster's hero at `targets` (world points). Awaitable; ~0.3-0.6 s.
static func play(m: MatchController, recipe: Dictionary, caster: int, targets: Array[Vector3], speed: float) -> void:
	var col: Color = recipe.get("color", Color.WHITE)
	var from: Vector3 = FxDirector._hero_pos(m, caster)
	var kind: StringName = recipe.get("kind", &"comet")
	var snd: StringName = recipe.get("sound", &"")
	if snd != &"":
		Audio.sfx(snd)
	if targets.is_empty():
		targets = [from]
	match kind:
		&"comet":
			for i: int in targets.size():
				comet(m, from, targets[i], col, recipe.get("trail", &"sparks"), recipe.get("size", 1.0), 0.42 / speed)
				if i < targets.size() - 1:
					await _wait(m, 0.07 / speed)
			await _wait(m, 0.42 / speed)
			for t: Vector3 in targets:
				blast(m, t, col, recipe.get("size", 1.0))
		&"beam":
			for t: Vector3 in targets:
				beam(m, from, t, col, 0.35 / speed)
			await _wait(m, 0.3 / speed)
		&"rain":
			Rain.over(m, targets, recipe.get("trail", &"embers"), 0.6 / speed)
			await _wait(m, 0.45 / speed)
		&"vines":
			for t: Vector3 in targets:
				vines(m, t, col, 0.45 / speed)
			await _wait(m, 0.22 / speed)
		&"slash":
			for t: Vector3 in targets:
				dagger(m, from, t, col, 0.32 / speed)
			await _wait(m, 0.32 / speed)
			for t: Vector3 in targets:
				slash(m, t, col, 0.3 / speed)
		&"spike":
			for t: Vector3 in targets:
				spike(m, t, col, 0.32 / speed)
			await _wait(m, 0.32 / speed)
		&"blizzard":
			blizzard(m, targets, col, 0.7 / speed)
			await _wait(m, 0.5 / speed)
		&"circle":
			for t: Vector3 in targets:
				circle(m, _ground(t), col, 0.8 / speed, 1.0)
				aura(m, t, col)
			await _wait(m, 0.3 / speed)
		&"hero":
			circle(m, from - Vector3(0, 0.6, 0), col, 0.9 / speed, 1.4)
			swirl(m, from, col)
			await _wait(m, 0.3 / speed)
		&"swirl":
			for t: Vector3 in targets:
				circle(m, _ground(t), col, 0.7 / speed, 0.9)
				swirl(m, t, col)
			await _wait(m, 0.35 / speed)


static func _wait(m: MatchController, s: float) -> void:
	await m.get_tree().create_timer(maxf(s, 0.0)).timeout


static func _ground(t: Vector3) -> Vector3:
	return Vector3(t.x, Island.TOP_Y + 0.03, t.z)


static func _glow_mat(col: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.lightened(0.25), alpha)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## A fat glowing ball with a trail that arcs to `to`.
static func comet(m: MatchController, from: Vector3, to: Vector3, col: Color, trail: StringName, size: float, dur: float) -> void:
	var n := Node3D.new()
	m.add_child(n)
	n.global_position = from
	var core := MeshInstance3D.new()
	core.mesh = Palette.sphere(0.22 * size, 12)
	core.material_override = _glow_mat(col)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(core)
	var halo := MeshInstance3D.new()
	halo.mesh = Palette.sphere(0.38 * size, 12)
	halo.material_override = _glow_mat(col, 0.35)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(halo)
	var tr := Burst.spawn(n, trail, from, col, 0.8 * size)
	tr.one_shot = false
	tr.explosiveness = 0.0
	tr.amount = 20
	if tr.finished.is_connected(tr.queue_free):
		tr.finished.disconnect(tr.queue_free)
	var tw := n.create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(n):
			n.global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * 1.4, 0)
			halo.scale = Vector3.ONE * (1.0 + 0.2 * sin(k * 30.0)), 0.0, 1.0, dur).set_ease(Tween.EASE_IN)
	tw.tween_callback(n.queue_free)


## The impact of a comet: a flash ball, a shock ring and sparks.
static func blast(m: MatchController, at: Vector3, col: Color, size: float) -> void:
	Burst.spawn(m, &"sparks", at, col, 1.4 * size)
	Burst.spawn(m, &"smoke", at, col.lightened(0.3), 1.0 * size)
	ShockRing.spawn(m, _ground(at), col, 1.0 * size, 0.35)
	var flash := MeshInstance3D.new()
	flash.mesh = Palette.sphere(0.5 * size, 12)
	var mat := _glow_mat(col.lightened(0.5), 0.9)
	flash.material_override = mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(flash)
	flash.global_position = at
	var tw := flash.create_tween().set_parallel(true)
	tw.tween_property(flash, "scale", Vector3.ONE * 2.2, 0.2)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tw.chain().tween_callback(flash.queue_free)
	m.rig.kick(0.12 * size)


## A straight glowing beam from A to B that thins out.
static func beam(m: MatchController, from: Vector3, to: Vector3, col: Color, dur: float) -> void:
	var len: float = from.distance_to(to)
	if len < 0.01:
		return
	var b := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.09
	cyl.height = len
	cyl.radial_segments = 8
	cyl.rings = 1
	b.mesh = cyl
	var mat := _glow_mat(col, 0.9)
	b.material_override = mat
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(b)
	b.global_position = (from + to) / 2.0
	var dir: Vector3 = (to - from).normalized()
	var axis: Vector3 = Vector3.UP.cross(dir)
	if axis.length() > 0.001:
		b.global_basis = Basis(axis.normalized(), Vector3.UP.angle_to(dir))
	b.scale = Vector3(0.2, 1.0, 0.2)
	Burst.spawn(m, &"sparks", to, col, 1.0)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector3(1.4, 1.0, 1.4), dur * 0.3)
	tw.tween_property(b, "scale", Vector3(0.05, 1.0, 0.05), dur * 0.7)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, dur * 0.7)
	tw.tween_callback(b.queue_free)


## Thorny spikes burst up out of the ground around `at`.
static func vines(m: MatchController, at: Vector3, col: Color, dur: float) -> void:
	var g: Vector3 = _ground(at)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	for i: int in 6:
		var sp := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.09
		cone.height = 0.75
		cone.radial_segments = 6
		cone.rings = 1
		sp.mesh = cone
		sp.material_override = Toon.plain(col)
		m.add_child(sp)
		var ang: float = TAU * i / 6.0 + randf_range(-0.2, 0.2)
		var off := Vector3(cos(ang), 0, sin(ang)) * randf_range(0.18, 0.4)
		sp.global_position = g + off
		sp.rotation = Vector3(sin(ang) * 0.45, 0, -cos(ang) * 0.45)
		sp.scale = Vector3(1, 0.01, 1)
		var tw := sp.create_tween()
		tw.tween_interval(i * 0.02)
		tw.tween_property(sp, "scale", Vector3(1, randf_range(0.8, 1.3), 1), dur * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(dur * 0.4)
		tw.tween_property(sp, "scale", Vector3(1, 0.01, 1), dur * 0.3)
		tw.tween_callback(sp.queue_free)
	Burst.spawn(m, &"leaves", g + Vector3(0, 0.3, 0), Color.WHITE, 1.2)
	ShockRing.spawn(m, g, col, 0.7, dur * 0.6)


## A spinning blade thrown at `to`.
static func dagger(m: MatchController, from: Vector3, to: Vector3, col: Color, dur: float) -> void:
	var d := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.08, 0.14)
	d.mesh = box
	d.material_override = _glow_mat(col)
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(d)
	d.global_position = from
	var tr := Burst.spawn(d, &"sparks", from, col, 0.5)
	tr.one_shot = false
	tr.explosiveness = 0.0
	if tr.finished.is_connected(tr.queue_free):
		tr.finished.disconnect(tr.queue_free)
	var tw := d.create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(d):
			d.global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * 0.8, 0)
			d.rotation.y = k * TAU * 3.0, 0.0, 1.0, dur)
	tw.tween_callback(d.queue_free)


## Two crossed slashes that flash across `at`.
static func slash(m: MatchController, at: Vector3, col: Color, dur: float) -> void:
	for i: int in 2:
		var q := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.3, 0.12)
		q.mesh = mesh
		var mat := _glow_mat(col.lightened(0.4), 1.0)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		q.material_override = mat
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(q)
		q.global_position = at + Vector3(0, 0.2, 0)
		q.rotation.z = 0.7 if i == 0 else -0.7
		mat.billboard_keep_scale = true
		q.scale = Vector3(0.05, 1, 1)
		var tw := q.create_tween()
		tw.tween_interval(i * 0.07)
		tw.tween_property(q, "scale", Vector3(1, 1, 1), dur * 0.3).set_ease(Tween.EASE_OUT)
		tw.tween_property(mat, "albedo_color:a", 0.0, dur * 0.5)
		tw.tween_callback(q.queue_free)
	Burst.spawn(m, &"sparks", at, col, 1.2)
	Audio.sfx(&"attack_whoosh")


## A big icy spike drops from the sky onto `at`.
static func spike(m: MatchController, at: Vector3, col: Color, dur: float) -> void:
	var sp := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.22
	cone.bottom_radius = 0.0
	cone.height = 1.2
	cone.radial_segments = 6
	cone.rings = 1
	sp.mesh = cone
	sp.material_override = _glow_mat(col, 0.95)
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(sp)
	var top: Vector3 = at + Vector3(0, 4.0, 0)
	sp.global_position = top
	var tw := sp.create_tween()
	tw.tween_property(sp, "global_position", at + Vector3(0, 0.3, 0), dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		Burst.spawn(m, &"snow", at, Color.WHITE, 1.5)
		Burst.spawn(m, &"sparks", at, col, 1.2)
		ShockRing.spawn(m, _ground(at), col, 1.0, 0.35)
		Audio.sfx(&"ice_shatter")
		m.rig.kick(0.2))
	tw.tween_property(sp, "scale", Vector3(1.6, 0.05, 1.6), 0.12)
	tw.tween_callback(sp.queue_free)


## Wind and snow sweep across the given spots.
static func blizzard(m: MatchController, spots: Array[Vector3], col: Color, dur: float) -> void:
	Rain.over(m, spots, &"snow", dur)
	for t: Vector3 in spots:
		for i: int in 3:
			var streak := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(1.4, 0.05)
			streak.mesh = q
			var mat := _glow_mat(col, 0.7)
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			streak.material_override = mat
			streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.add_child(streak)
			var y: float = 0.3 + i * 0.35
			streak.global_position = t + Vector3(-1.6, y, 0)
			var tw := streak.create_tween().set_parallel(true)
			tw.tween_property(streak, "global_position", t + Vector3(1.6, y - 0.1, 0), dur * 0.6).set_delay(i * 0.08)
			tw.tween_property(mat, "albedo_color:a", 0.0, dur * 0.6).set_delay(i * 0.08)
			tw.chain().tween_callback(streak.queue_free)


## A glowing magic circle on the ground that spins and fades.
static func circle(m: MatchController, at: Vector3, col: Color, dur: float, radius: float) -> void:
	if _circle_shader == null:
		_circle_shader = load("res://view/fx/magic_circle.gdshader") as Shader
	var q := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.6, 1.6) * radius
	q.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = _circle_shader
	mat.set_shader_parameter("tint", col)
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(q)
	q.global_position = at
	q.scale = Vector3.ONE * 0.2
	var tw := q.create_tween().set_parallel(true)
	tw.tween_property(q, "scale", Vector3.ONE, dur * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("spin", v), 0.0, 2.0, dur)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("strength", v), 1.0, 0.0, dur * 0.5).set_delay(dur * 0.5)
	tw.chain().tween_callback(q.queue_free)


## Sparkles rising around `at` (buffs and heals).
static func aura(m: MatchController, at: Vector3, col: Color) -> void:
	Burst.spawn(m, &"heal", _ground(at) + Vector3(0, 0.2, 0), col, 1.4)
	Burst.spawn(m, &"stars", at, col, 0.9)


## A spiral of sparkles (draw, magic, transforms).
static func swirl(m: MatchController, at: Vector3, col: Color) -> void:
	for i: int in 8:
		var s := MeshInstance3D.new()
		s.mesh = Palette.sphere(0.06, 6)
		s.material_override = _glow_mat(col)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(s)
		var phase: float = TAU * i / 8.0
		var tw := s.create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(s):
				var a: float = phase + k * TAU * 1.5
				s.global_position = at + Vector3(cos(a) * (0.6 - k * 0.4), -0.4 + k * 1.2, sin(a) * (0.6 - k * 0.4))
				s.scale = Vector3.ONE * (1.0 - k * 0.6), 0.0, 1.0, 0.55)
		tw.tween_callback(s.queue_free)
	Burst.spawn(m, &"stars", at + Vector3(0, 0.6, 0), col, 1.0)
