class_name LandLooks
extends RefCounted
## The 12 land looks (board look 2, spec 2). Builders place their pieces with SetPieces' kit inside ctx "box" (back
## corner), "other_box", "band" / "other_band" (side strips); ctx "scale" shrinks tall pieces on your side.

const LAVA := Color("#ff7a1a")
const LAVA_HOT := Color("#ffd04a")
const BASALT := Color("#5a4a4e")
const BASALT_LIGHT := Color("#8a7c80")
const VOLCANO := Color("#7a4636")
const VOLCANO_BAND := Color("#9a5a40")
const ASH := Color("#4a4040")


## Builds ctx's land/variant look; false if that look has no builder (SetPieces then uses a rock cluster).
static func build(ctx: Dictionary) -> bool:
	match Vector2i(int(ctx["land"]), int(ctx["variant"])):
		Vector2i(1, 0):
			_volcano(ctx)
		Vector2i(1, 1):
			_lava_rift(ctx)
		Vector2i(1, 2):
			_ash_slopes(ctx)
		Vector2i(0, 0):
			_pond_glade(ctx)
		Vector2i(0, 1):
			_shroom_grove(ctx)
		Vector2i(0, 2):
			_mossy_knoll(ctx)
		Vector2i(3, 0):
			_castle_corner(ctx)
		Vector2i(3, 1):
			_frozen_lake(ctx)
		Vector2i(3, 2):
			_glacier_ridge(ctx)
		Vector2i(2, 0):
			_chocolate_river(ctx)
		Vector2i(2, 1):
			_lollipop_grove(ctx)
		Vector2i(2, 2):
			_sundae_peak(ctx)
		Vector2i(5, 0):
			_dune_sea(ctx)
		Vector2i(5, 1):
			_sandstone_ruins(ctx)
		Vector2i(5, 2):
			_oasis(ctx)
		_:
			return false
	return true


static func _rng(ctx: Dictionary) -> RandomNumberGenerator:
	return ctx["rng"]


## A tile-local point inside `r` at fractions (u, v).
static func _at(r: Rect2, u: float, v: float) -> Vector3:
	return Vector3(r.position.x + r.size.x * u, 0.0, r.position.y + r.size.y * v)


## Of the box's two z ends, the one at the owner's back edge (fraction 0 or 1).
static func _back(ctx: Dictionary) -> float:
	return 1.0 if int(ctx["player"]) == 0 else 0.0


# --- Ember Flats ------------------------------------------------------------------------------------

## A little volcano in the back corner: dark cone, glowing crater and lava trickles, a smoke wisp; erupts now and
## then (sparks, smoke puff, lava blobs, crater flare).
static func _volcano(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var r: float = minf(box.size.x * 0.5, 0.5)
	var stretch: float = clampf(box.size.y / maxf(box.size.x, 0.01), 1.0, 1.6)
	var h: float = clampf(r * 3.0, 0.75, 1.05) * sc
	var v := Node3D.new()
	v.name = "Volcano"
	var body := Node3D.new()
	body.scale = Vector3(1.0, 1.0, stretch)
	v.add_child(body)
	body.add_child(SetPieces.cyl(r * 0.3, r, h * 0.82, VOLCANO, Vector3.ZERO, 16))
	body.add_child(SetPieces.cyl(r * 0.62, r * 1.04, h * 0.16, VOLCANO_BAND, Vector3.ZERO, 16))
	body.add_child(SetPieces.cyl(r * 0.26, r * 0.36, h * 0.18, VOLCANO.darkened(0.25), Vector3(0, h * 0.82, 0), 14))
	var lava_mat := SetPieceFx.glow(LAVA)
	var crater := Palette.mesh(Palette.cylinder(r * 0.22, r * 0.22, 0.02, 14), lava_mat, Vector3(0, h * 0.995, 0), false)
	body.add_child(crater)
	# Lava trickles down the slope.
	for i: int in 3:
		var a: float = rng.randf() * TAU
		var top := Vector3(cos(a) * r * 0.27, h * 0.97, sin(a) * r * 0.27)
		var bot := Vector3(cos(a) * r * (0.55 + 0.25 * rng.randf()), h * (0.18 + 0.2 * rng.randf()), sin(a) * r * (0.55 + 0.25 * rng.randf()))
		body.add_child(_streak(top, bot, 0.06, lava_mat))
	# Scorched rocks at the foot.
	for i: int in 4:
		var a: float = rng.randf() * TAU
		body.add_child(SetPieces.sphere(r * 0.13, BASALT_LIGHT, Vector3(cos(a) * r * 0.95, r * 0.04, sin(a) * r * 0.95), Vector3(1, 0.6, 1), 8))
	var smoke: CPUParticles3D = SetPieceFx.emitter("smoke_04", Color(0.55, 0.5, 0.5, 0.55), 0.22, 4, false)
	smoke.position = Vector3(0, h + 0.05, 0)
	smoke.lifetime = 3.0
	smoke.gravity = Vector3(0, 0.12, 0)
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.initial_velocity_min = 0.05
	smoke.initial_velocity_max = 0.12
	smoke.scale_amount_min = 0.7
	smoke.scale_amount_max = 1.6
	v.add_child(smoke)
	var sparks: CPUParticles3D = SetPieceFx.emitter("spark_01", Color("#ffb347"), 0.08, 18)
	sparks.position = Vector3(0, h, 0)
	sparks.one_shot = true
	sparks.emitting = false
	sparks.explosiveness = 0.9
	sparks.lifetime = 1.1
	sparks.direction = Vector3.UP
	sparks.spread = 28.0
	sparks.initial_velocity_min = 0.9
	sparks.initial_velocity_max = 1.6
	sparks.gravity = Vector3(0, -2.6, 0)
	v.add_child(sparks)
	var puff: CPUParticles3D = SetPieceFx.emitter("smoke_07", Color(0.35, 0.3, 0.3, 0.7), 0.35, 8, false)
	puff.position = Vector3(0, h + 0.05, 0)
	puff.one_shot = true
	puff.emitting = false
	puff.explosiveness = 0.8
	puff.lifetime = 2.2
	puff.direction = Vector3.UP
	puff.spread = 20.0
	puff.initial_velocity_min = 0.25
	puff.initial_velocity_max = 0.45
	puff.gravity = Vector3(0, 0.05, 0)
	puff.scale_amount_max = 2.0
	v.add_child(puff)
	var centre: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.25))
	var seed: int = rng.randi()
	SetPieceFx.periodic(v, 12.0, 25.0, func() -> void: _erupt(v, crater, sparks, puff, r, h, stretch), seed)
	SetPieces.add_piece(ctx, v, centre, Rect2(centre.x - r, centre.z - r * stretch, r * 2.0, r * 2.0 * stretch), box)


## One eruption: sparks and a smoke puff, the crater flares, a few lava blobs arc out and fade.
static func _erupt(v: Node3D, crater: MeshInstance3D, sparks: CPUParticles3D, puff: CPUParticles3D, r: float, h: float, stretch: float) -> void:
	if not v.is_inside_tree():
		return
	sparks.restart()
	puff.restart()
	var mat := crater.material_override as StandardMaterial3D
	if mat == null:
		mat = crater.get_active_material(0) as StandardMaterial3D
	if mat:
		var flare := v.create_tween()
		flare.tween_property(mat, "albedo_color", LAVA_HOT, 0.15)
		flare.tween_property(mat, "albedo_color", LAVA, 1.2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var n: int = SetPieceFx.amount(4) + (1 if rng.randf() < 0.5 else 0)
	for i: int in n:
		var blob := Palette.mesh(Palette.sphere(0.035, 8), SetPieceFx.glow(LAVA_HOT), Vector3(0, h, 0), false)
		v.add_child(blob)
		var a: float = rng.randf() * TAU
		var land_at := Vector3(cos(a) * r * rng.randf_range(1.0, 1.5), 0.02, sin(a) * r * stretch * rng.randf_range(1.0, 1.5))
		var peak := Vector3(land_at.x * 0.5, h + rng.randf_range(0.35, 0.6), land_at.z * 0.5)
		var t: float = rng.randf_range(0.7, 1.0)
		var tw := blob.create_tween()
		tw.tween_method(func(k: float) -> void:
			var a1: Vector3 = Vector3(0, h, 0).lerp(peak, k)
			var b1: Vector3 = peak.lerp(land_at, k)
			blob.position = a1.lerp(b1, k), 0.0, 1.0, t)
		tw.tween_property(blob, "scale", Vector3(1.6, 0.25, 1.6), 0.12)
		tw.tween_property(blob, "scale", Vector3.ZERO, 0.8)
		tw.tween_callback(blob.queue_free)


## A flat glowing streak from `a` to `b` (lava down a slope).
static func _streak(a: Vector3, b: Vector3, w: float, mat: Material) -> MeshInstance3D:
	var bm := BoxMesh.new()
	var d: Vector3 = b - a
	bm.size = Vector3(w, 0.012, d.length())
	var mi := Palette.mesh(bm, mat, (a + b) / 2.0, false)
	mi.basis = Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.FORWARD)
	return mi


## A glowing lava crack along one side (painted by the lane shader), a little stone bridge over it, basalt columns in
## the back corner and embers rising from the crack.
static func _lava_rift(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var band: Rect2 = ctx["band"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var cols := Node3D.new()
	cols.name = "BasaltColumns"
	var n: int = 9
	var back: float = _back(ctx)
	for i: int in n:
		var cr: float = rng.randf_range(0.07, 0.11)
		var v: float = lerpf(back, 0.5, rng.randf() * rng.randf())
		var p := Vector3(rng.randf_range(box.position.x + cr, box.end.x - cr), 0.0, clampf(lerpf(box.position.y, box.end.y, v), box.position.y + cr, box.end.y - cr))
		# Taller towards the back edge, like a cliff of columns.
		var hh: float = rng.randf_range(0.25, 0.7) * (1.0 - absf(v - back) * 0.9) * sc + 0.08
		cols.add_child(SetPieces.cyl(cr, cr, hh, BASALT, p, 6))
		cols.add_child(SetPieces.cyl(cr * 0.92, cr * 0.92, 0.02, BASALT_LIGHT, p + Vector3(0, hh, 0), 6))
	SetPieces.add_piece(ctx, cols, Vector3.ZERO, box, box)
	# The bridge spans the band (across the crack) about halfway along it.
	var bridge := Node3D.new()
	bridge.name = "Bridge"
	var span: float = band.size.x * 0.92
	var stone := Color("#8c8580")
	for sx: float in [-1.0, 1.0]:
		bridge.add_child(SetPieces.box(Vector3(0.05, 0.07, 0.12), stone.darkened(0.15), Vector3(sx * (span / 2.0 - 0.025), 0, 0)))
	bridge.add_child(SetPieces.box(Vector3(span, 0.025, 0.14), stone, Vector3(0, 0.07, 0)))
	var bz: float = lerpf(band.position.y, band.end.y, rng.randf_range(0.35, 0.65))
	var bpos := Vector3(band.get_center().x, 0.0, bz)
	SetPieces.add_piece(ctx, bridge, bpos, Rect2(bpos.x - span / 2.0, bz - 0.07, span, 0.14), band)
	var embers: CPUParticles3D = SetPieceFx.emitter("circle_05", Color("#ff9a3a"), 0.05, 8)
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3(band.size.x * 0.3, 0.02, band.size.y * 0.45)
	embers.position = Vector3(band.get_center().x, 0.03, band.get_center().y)
	embers.lifetime = 2.0
	embers.direction = Vector3.UP
	embers.spread = 15.0
	embers.gravity = Vector3(0, 0.15, 0)
	embers.initial_velocity_min = 0.12
	embers.initial_velocity_max = 0.3
	var holder := Node3D.new()
	holder.name = "RiftEmbers"
	holder.add_child(embers)
	SetPieces.add_piece(ctx, holder, Vector3.ZERO, band, band)


## Raised dark rocky ridges along both sides, smoking vents in the back corner, charred stumps in the other one.
static func _ash_slopes(ctx: Dictionary) -> void:
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	for key: String in ["band", "other_band"]:
		var band: Rect2 = ctx[key]
		var ridge := Node3D.new()
		ridge.name = "Ridge"
		var r: float = clampf(band.size.x * 0.55, 0.08, 0.2)
		var count: int = int(band.size.y / (r * 1.1)) + 1
		for i: int in count:
			var z: float = lerpf(band.position.y + r, band.end.y - r, float(i) / maxf(count - 1, 1))
			var hh: float = rng.randf_range(0.9, 1.6)
			var col: Color = ASH if i % 2 == 0 else BASALT
			ridge.add_child(SetPieces.sphere(r, col, Vector3(band.get_center().x, r * 0.2 * hh, z), Vector3(band.size.x / (2.0 * r), 0.9 * hh, 1.35), 10))
		SetPieces.add_piece(ctx, ridge, Vector3.ZERO, band, band)
	var box: Rect2 = ctx["box"]
	var vents := Node3D.new()
	vents.name = "Vents"
	var puffs: Array[CPUParticles3D] = []
	for i: int in 2:
		var p: Vector3 = _at(box, 0.5, 0.3 + 0.4 * i)
		var vr: float = minf(box.size.x * 0.42, 0.2)
		var vh: float = 0.22 * sc
		vents.add_child(SetPieces.cyl(vr * 0.4, vr, vh, BASALT, p, 12))
		vents.add_child(Palette.mesh(Palette.cylinder(vr * 0.34, vr * 0.34, 0.01, 10), SetPieceFx.glow(LAVA), p + Vector3(0, vh, 0), false))
		var smoke: CPUParticles3D = SetPieceFx.emitter("smoke_04", Color(0.6, 0.58, 0.58, 0.45), 0.16, 3, false)
		smoke.position = p + Vector3(0, vh + 0.02, 0)
		smoke.lifetime = 2.5
		smoke.direction = Vector3.UP
		smoke.spread = 10.0
		smoke.initial_velocity_min = 0.06
		smoke.initial_velocity_max = 0.12
		smoke.gravity = Vector3(0, 0.08, 0)
		vents.add_child(smoke)
		var puff: CPUParticles3D = SetPieceFx.emitter("smoke_07", Color(0.7, 0.68, 0.66, 0.6), 0.26, 6, false)
		puff.position = smoke.position
		puff.one_shot = true
		puff.emitting = false
		puff.explosiveness = 0.85
		puff.lifetime = 1.8
		puff.direction = Vector3.UP
		puff.spread = 14.0
		puff.initial_velocity_min = 0.3
		puff.initial_velocity_max = 0.5
		vents.add_child(puff)
		puffs.append(puff)
	SetPieceFx.periodic(vents, 4.0, 9.0, func() -> void:
		puffs[randi() % puffs.size()].restart(), rng.randi())
	SetPieces.add_piece(ctx, vents, Vector3.ZERO, box, box)
	var other: Rect2 = ctx["other_box"]
	var stumps := Node3D.new()
	stumps.name = "Stumps"
	for i: int in 3:
		var sr: float = rng.randf_range(0.06, 0.09)
		var p := Vector3(rng.randf_range(other.position.x + sr, other.end.x - sr), 0.0, lerpf(other.position.y + sr, other.end.y - sr, (i + 0.5) / 3.0))
		var hh: float = rng.randf_range(0.22, 0.45) * sc
		stumps.add_child(SetPieces.cyl(sr * 0.8, sr * 1.15, hh, Color("#2e2420"), p, 7))
		stumps.add_child(SetPieces.cone(sr * 0.75, 0.08, Color("#1f1814"), p + Vector3(0, hh, 0), 5))
		stumps.add_child(Palette.mesh(Palette.sphere(sr * 0.32, 6), SetPieceFx.glow(LAVA), p + Vector3(0, hh + 0.02, 0), false))
		# A charred stub of a branch.
		var br := SetPieces.cyl(sr * 0.3, sr * 0.4, hh * 0.4, Color("#2e2420"), Vector3.ZERO, 5)
		br.position = p + Vector3(sr * 0.6, hh * 0.6, 0)
		br.rotation.z = -0.9
		stumps.add_child(br)
	SetPieces.add_piece(ctx, stumps, Vector3.ZERO, other, other)


# --- Mushroom Forest -------------------------------------------------------------------------------

const GRASS: Array = ["#5bbd42", "#6fcf4c", "#86dd5e", "#52b03e"]
const MOSS := Color("#5aa84a")
const BARK := Color("#7a5232")


## A pond in the back corner: uneven shoreline, clear shallows over sand deepening to dark water, soft ripples; stones
## and grass tufts along the bank, notched lily pads with a flower, a clump of cattails. Long swaying grass along both
## sides.
static func _pond_glade(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var rx: float = box.size.x * 0.5
	var rz: float = minf(box.size.y * 0.42, rx * 1.9)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.3))
	var seed: float = rng.randf() * TAU
	var pond := Node3D.new()
	pond.name = "Pond"
	pond.add_child(SetPieces.pool(0, rx, rz, seed))
	# Lily pads (notched, different sizes) and one pink flower, in the open water.
	for i: int in 4:
		var a: float = rng.randf() * TAU
		var e: float = rng.randf_range(0.15, 0.55) * SetPieces.pond_edge(a, seed)
		var pad: MeshInstance3D = SetPieces.lily_pad(rng.randf_range(0.045, 0.085), rng.randf() * TAU)
		pad.name = "LilyPad%d" % i
		pad.position = Vector3(cos(a) * rx * e, 0.016, sin(a) * rz * e)
		pond.add_child(pad)
		if i == 0:
			var f := SetPieces.flower(0.035, Color("#ffc4e1"))
			f.position = pad.position + Vector3(0, 0.004, 0)
			pond.add_child(f)
	# Stones on part of the bank (an arc on the side away from the cattails), sitting on the shoreline.
	var arc0: float = rng.randf() * TAU
	for i: int in 7:
		var a: float = arc0 + i * 0.42 + rng.randf_range(-0.1, 0.1)
		var e: float = SetPieces.pond_edge(a, seed) * rng.randf_range(0.97, 1.06)
		var sr: float = rng.randf_range(0.025, 0.05)
		var stone := SetPieces.sphere(sr, Color("#8d8578") if i % 3 else Color("#a39a8b"), Vector3(cos(a) * rx * e, sr * 0.25, sin(a) * rz * e), Vector3(1.0, 0.55, rng.randf_range(0.8, 1.2)), 8)
		stone.name = "Stone%d" % i
		pond.add_child(stone)
	# Grass tufts at the waterline, around the rest of the bank.
	for i: int in 9:
		var a: float = arc0 + 3.1 + i * 0.36 + rng.randf_range(-0.12, 0.12)
		var e: float = SetPieces.pond_edge(a, seed) * rng.randf_range(0.98, 1.08)
		var tuft := SetPieces.grass_tuft(rng.randf_range(0.06, 0.11) * float(ctx["scale"]), Color("#3f8f3a"), rng)
		tuft.position = Vector3(cos(a) * rx * e, 0.0, sin(a) * rz * e)
		pond.add_child(tuft)
	SetPieces.add_piece(ctx, pond, c, Rect2(c.x - rx, c.z - rz, rx * 2.0, rz * 2.0), box)
	# A clump of cattails at the pond's far end.
	var reeds := Node3D.new()
	reeds.name = "Reeds"
	var side: float = 1.0 if _back(ctx) > 0.5 else -1.0
	var ca: float = PI / 2.0 * side + rng.randf_range(-0.5, 0.5)
	var cx: float = c.x + cos(ca) * rx * SetPieces.pond_edge(ca, seed)
	var cz: float = c.z + sin(ca) * rz * SetPieces.pond_edge(ca, seed)
	for i: int in 8:
		# Along the bank, half in the shallows, half on the shore.
		var a: float = ca + rng.randf_range(-0.45, 0.45)
		var e: float = SetPieces.pond_edge(a, seed) * rng.randf_range(0.9, 1.06)
		var x: float = c.x + cos(a) * rx * e
		var z: float = clampf(c.z + sin(a) * rz * e, box.position.y + 0.03, box.end.y - 0.03)
		var hh: float = rng.randf_range(0.24, 0.46) * float(ctx["scale"])
		reeds.add_child(SetPieces.cyl(0.007, 0.011, hh, Color("#5c8a3a"), Vector3(x, 0, z), 5))
		if i % 3 != 2:
			reeds.add_child(SetPieces.cyl(0.02, 0.02, 0.07, Color("#6e4426"), Vector3(x, hh * 0.76, z), 6))
	SetPieces.add_piece(ctx, reeds, Vector3.ZERO, Rect2(cx - rx * 0.3, cz - 0.1, rx * 0.6, 0.2), box)
	for key: String in ["band", "other_band"]:
		var band: Rect2 = ctx[key]
		var g := Node3D.new()
		g.name = "LongGrass"
		g.add_child(SetPieces.long_grass(ctx, band, int(band.size.y * 22.0), GRASS))
		SetPieces.add_piece(ctx, g, Vector3.ZERO, band, band)


## Giant toadstools in the back corner, a fallen log along one side with ferns, a fairy ring in the other corner.
static func _shroom_grove(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var caps: Array[Color] = [Color("#e8483c"), Color("#e8873c"), Color("#b05ad8")]
	var grove := Node3D.new()
	grove.name = "GiantShrooms"
	var n: int = 3
	for i: int in n:
		var hh: float = lerpf(0.75, 0.45, float(i) / n) * sc
		var cr: float = hh * 0.42
		var v: float = lerpf(_back(ctx), 0.5, float(i) / n) * 0.8 + 0.1
		var x: float = clampf(box.get_center().x + rng.randf_range(-0.05, 0.05), box.position.x + cr, box.end.x - cr)
		var t: Node3D = SetPieces.toadstool(hh, caps[i % caps.size()], rng)
		t.position = Vector3(x, 0, lerpf(box.position.y, box.end.y, v))
		grove.add_child(t)
	SetPieces.add_piece(ctx, grove, Vector3.ZERO, box, box)
	var band: Rect2 = ctx["band"]
	var log := Node3D.new()
	log.name = "Log"
	var lr: float = clampf(band.size.x * 0.45, 0.06, 0.1)
	var ll: float = minf(band.size.y * 0.5, 1.1)
	var lz: float = lerpf(band.position.y + ll / 2.0, band.end.y - ll / 2.0, rng.randf())
	var trunk := SetPieces.mesh(Palette.cylinder(lr, lr, ll, 12), BARK, Vector3.ZERO)
	trunk.rotation.x = PI / 2.0
	trunk.position = Vector3(band.get_center().x, lr, lz)
	log.add_child(trunk)
	for sz: float in [-1.0, 1.0]:
		var end := SetPieces.mesh(Palette.cylinder(lr * 0.85, lr * 0.85, 0.012, 12), Color("#d8b483"), Vector3.ZERO)
		end.rotation.x = PI / 2.0
		end.position = Vector3(band.get_center().x, lr, lz + sz * ll / 2.0)
		log.add_child(end)
	log.add_child(SetPieces.sphere(lr * 0.7, MOSS, Vector3(band.get_center().x, lr * 1.7, lz + ll * 0.15), Vector3(1.2, 0.45, 2.0), 8))
	var fern: Node3D = SetPieces.model("nature/Fern_1", 0.22 * sc)
	fern.position = Vector3(band.get_center().x, 0, clampf(lz + ll / 2.0 + 0.12, band.position.y, band.end.y))
	log.add_child(fern)
	SetPieces.add_piece(ctx, log, Vector3.ZERO, Rect2(band.position.x, lz - ll / 2.0, band.size.x, ll), band)
	var other: Rect2 = ctx["other_box"]
	var ring := Node3D.new()
	ring.name = "FairyRing"
	var rr: float = minf(other.size.x, other.size.y) * 0.38
	var rc: Vector3 = _at(other, 0.5, 0.5)
	for i: int in 9:
		var a: float = TAU * i / 9.0
		var t: Node3D = SetPieces.toadstool(rng.randf_range(0.08, 0.12), Color("#fff2e0") if i % 3 else Color("#ffcf6a"), rng)
		t.position = rc + Vector3(cos(a) * rr, 0, sin(a) * rr)
		ring.add_child(t)
	SetPieces.add_piece(ctx, ring, Vector3.ZERO, Rect2(rc.x - rr - 0.06, rc.z - rr - 0.06, rr * 2.0 + 0.12, rr * 2.0 + 0.12), other)


## A raised mossy knoll with a big tree in the back corner, mossy boulders in the other; the lane shader paints
## clover patches and a stepping-stone path.
static func _mossy_knoll(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var knoll := Node3D.new()
	knoll.name = "Knoll"
	var rx: float = box.size.x * 0.5
	var rz: float = minf(box.size.y * 0.45, rx * 2.2)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.2))
	knoll.add_child(SetPieces.sphere(1.0, MOSS, Vector3(0, -0.02, 0), Vector3(rx, 0.24 * sc, rz), 18))
	knoll.add_child(SetPieces.sphere(1.0, Color("#6fbf55"), Vector3(0, 0.0, 0), Vector3(rx * 0.7, 0.26 * sc, rz * 0.7), 16))
	var tree: Node3D = SetPieces.model("nature/CommonTree_1" if rng.randf() < 0.5 else "nature/CommonTree_3", 0.95 * sc, Toon.NO_TINT, 0.03)
	tree.position = Vector3(0, 0.2 * sc, 0)
	knoll.add_child(tree)
	SetPieces.add_piece(ctx, knoll, c, Rect2(c.x - rx, c.z - rz, rx * 2.0, rz * 2.0), box)
	var other: Rect2 = ctx["other_box"]
	var boulders := Node3D.new()
	boulders.name = "Boulders"
	for i: int in 3:
		var br: float = minf(other.size.x * 0.32, 0.16) * rng.randf_range(0.7, 1.0)
		var p := Vector3(clampf(other.get_center().x + rng.randf_range(-0.05, 0.05), other.position.x + br, other.end.x - br), 0.0, lerpf(other.position.y + br, other.end.y - br, (i + 0.5) / 3.0))
		boulders.add_child(SetPieces.sphere(br, Color("#8f8a80"), p + Vector3(0, br * 0.35, 0), Vector3(1.0, 0.75, 1.0), 10))
		boulders.add_child(SetPieces.sphere(br * 0.8, MOSS, p + Vector3(0, br * 0.85, 0), Vector3(1.0, 0.35, 1.0), 10))
	SetPieces.add_piece(ctx, boulders, Vector3.ZERO, other, other)


# --- Frostpeak --------------------------------------------------------------------------------------

const STONE := Color("#c3cddb")
const STONE_DARK := Color("#94a1b5")
const ROOF := Color("#4a7ac8")
const SNOW := Color("#f6fbff")
const ICE := Color("#9fd8ff")


## A round tower: stone body, snowy conical roof, base at y = 0.
static func _tower(r: float, h: float, roof: Color) -> Node3D:
	var t := Node3D.new()
	t.add_child(SetPieces.cyl(r, r * 1.08, h, STONE, Vector3.ZERO, 14))
	for i: int in 6:
		var a: float = TAU * i / 6.0
		t.add_child(SetPieces.box(Vector3(r * 0.42, r * 0.4, r * 0.42), STONE, Vector3(cos(a) * r * 0.86, h, sin(a) * r * 0.86)))
	t.add_child(SetPieces.cone(r * 1.15, r * 2.2, roof, Vector3(0, h + r * 0.1, 0), 14))
	t.add_child(SetPieces.sphere(r * 0.55, SNOW, Vector3(0, h + r * 0.55, 0), Vector3(1.6, 0.5, 1.6), 10))
	t.add_child(SetPieces.box(Vector3(r * 0.3, r * 0.55, 0.01), Color("#2a3448"), Vector3(0, h * 0.62, r * 1.0)))
	return t


## A small toy castle in the back corner (keep, two turrets, a wall with a gate, a banner) and snow drifts.
static func _castle_corner(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var castle := Node3D.new()
	castle.name = "Castle"
	var w: float = box.size.x
	var tr: float = clampf(w * 0.17, 0.06, 0.1)
	var len: float = minf(box.size.y * 0.8, 1.15)
	var cx: float = box.get_center().x
	var cz: float = lerpf(box.position.y + len / 2.0, box.end.y - len / 2.0, _back(ctx))
	var kh: float = 0.42 * sc
	# Keep in the middle.
	var kw: float = minf(w * 0.62, 0.3)
	castle.add_child(SetPieces.box(Vector3(kw, kh, kw * 1.15), STONE, Vector3(cx, 0, cz)))
	for i: int in 4:
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var sz: float = -1.0 if i < 2 else 1.0
		castle.add_child(SetPieces.box(Vector3(kw * 0.2, kw * 0.2, kw * 0.2), STONE, Vector3(cx + sx * kw * 0.4, kh, cz + sz * kw * 0.47)))
	castle.add_child(SetPieces.cone(kw * 0.62, kh * 0.6, ROOF, Vector3(cx, kh, cz), 4))
	castle.add_child(SetPieces.box(Vector3(kw * 0.34, kh * 0.42, 0.012), Color("#3a2a20"), Vector3(cx, 0, cz + kw * 0.58 * (-1.0 if _back(ctx) > 0.5 else 1.0))))
	# Turrets at both ends, joined to the keep by walls.
	for sz: float in [-1.0, 1.0]:
		var tz: float = cz + sz * (len / 2.0 - tr)
		var t: Node3D = _tower(tr, (0.5 + 0.08 * sz) * sc, ROOF)
		t.position = Vector3(cx, 0, tz)
		castle.add_child(t)
		var wl: float = absf(tz - cz) - kw * 0.55
		castle.add_child(SetPieces.box(Vector3(tr * 0.9, 0.2 * sc, wl), STONE_DARK, Vector3(cx, 0, (tz + cz) / 2.0 + sz * kw * 0.02)))
	# Banner on the keep.
	castle.add_child(SetPieces.cyl(0.006, 0.006, 0.22 * sc, Color("#5a4632"), Vector3(cx, kh + kh * 0.55, cz)))
	var flag := SetPieces.box(Vector3(0.012, 0.06, 0.1), Color("#e8483c") if rng.randf() < 0.5 else Color("#ffcf3a"), Vector3(cx, kh + kh * 0.55 + 0.14 * sc, cz + 0.05))
	castle.add_child(flag)
	SetPieces.add_piece(ctx, castle, Vector3.ZERO, Rect2(cx - maxf(kw, tr * 2.16) / 2.0, cz - len / 2.0, maxf(kw, tr * 2.16), len), box)
	for key: String in ["band", "other_band"]:
		var band: Rect2 = ctx[key]
		var drifts := Node3D.new()
		drifts.name = "Drifts"
		for i: int in 4:
			var dr: float = clampf(band.size.x * 0.5, 0.07, 0.16)
			var z: float = lerpf(band.position.y + dr, band.end.y - dr, rng.randf())
			drifts.add_child(SetPieces.sphere(dr, SNOW, Vector3(band.get_center().x, 0.0, z), Vector3(band.size.x / (2.0 * dr), 0.45, 1.8), 10))
		SetPieces.add_piece(ctx, drifts, Vector3.ZERO, band, band)


## A cracked shiny ice pond in the back corner, snowy pines along one side and a lone watchtower in the other corner.
static func _frozen_lake(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var rx: float = box.size.x * 0.5
	var rz: float = minf(box.size.y * 0.45, rx * 2.0)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.25))
	var lake := Node3D.new()
	lake.name = "FrozenLake"
	lake.add_child(SetPieces.pool(1, rx, rz))
	lake.add_child(SetPieces.sphere(0.05, SNOW, Vector3(rx * 0.55, 0.0, -rz * 0.5), Vector3(1.4, 0.4, 1.0), 8))
	SetPieces.add_piece(ctx, lake, c, Rect2(c.x - rx, c.z - rz, rx * 2.0, rz * 2.0), box)
	var band: Rect2 = ctx["other_band"]
	var pines := Node3D.new()
	pines.name = "Pines"
	for i: int in 3:
		var pine: Node3D = SetPieces.model("nature/Pine_2", rng.randf_range(0.45, 0.7) * sc, Color("#e8f4ff", 0.45))
		pine.position = Vector3(band.get_center().x, 0, lerpf(band.position.y + 0.15, band.end.y - 0.15, (i + 0.5) / 3.0))
		pine.rotation.y = rng.randf() * TAU
		pines.add_child(pine)
	SetPieces.add_piece(ctx, pines, Vector3.ZERO, band, band)
	var other: Rect2 = ctx["other_box"]
	var tower := Node3D.new()
	tower.name = "Watchtower"
	var tr: float = clampf(other.size.x * 0.22, 0.06, 0.11)
	var t: Node3D = _tower(tr, 0.62 * sc, ROOF)
	var tp: Vector3 = _at(other, 0.5, lerpf(0.5, _back(ctx), 0.5))
	t.position = tp
	tower.add_child(t)
	SetPieces.add_piece(ctx, tower, Vector3.ZERO, Rect2(tp.x - tr * 1.2, tp.z - tr * 1.2, tr * 2.4, tr * 2.4), other)


## Raised ice ridges along both sides, a cluster of big crystal spikes in the back corner, icy boulders in the other.
static func _glacier_ridge(ctx: Dictionary) -> void:
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	for key: String in ["band", "other_band"]:
		var band: Rect2 = ctx[key]
		var ridge := Node3D.new()
		ridge.name = "Ridge"
		var r: float = clampf(band.size.x * 0.55, 0.08, 0.2)
		var count: int = int(band.size.y / (r * 1.2)) + 1
		for i: int in count:
			var z: float = lerpf(band.position.y + r, band.end.y - r, float(i) / maxf(count - 1, 1))
			var col: Color = ICE if i % 3 else SNOW
			ridge.add_child(SetPieces.sphere(r, col, Vector3(band.get_center().x, r * 0.15, z), Vector3(band.size.x / (2.0 * r), rng.randf_range(0.8, 1.4), 1.3), 7))
			if i % 2 == 0:
				ridge.add_child(SetPieces.cone(r * 0.35, rng.randf_range(0.15, 0.3) * sc, Color("#c6ecff"), Vector3(band.get_center().x, r * 0.3, z), 5))
		SetPieces.add_piece(ctx, ridge, Vector3.ZERO, band, band)
	var box: Rect2 = ctx["box"]
	var crystals := Node3D.new()
	crystals.name = "Crystals"
	var cc: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.35))
	var cw: float = box.size.x * 0.42
	for i: int in 6:
		var hh: float = rng.randf_range(0.3, 0.75) * sc * (1.0 if i < 2 else 0.7)
		var cr: float = hh * 0.2
		var off := Vector3(rng.randf_range(-cw + cr, cw - cr), 0.0, rng.randf_range(-cw * 1.4, cw * 1.4))
		var spike := SetPieces.mesh(Palette.cylinder(0.0, cr, hh, 5), [Color("#7cc4f0"), Color("#9fd8ff"), Color("#c6ecff")][i % 3], Vector3.ZERO)
		spike.position = cc + off + Vector3(0, hh * 0.45, 0)
		spike.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
		crystals.add_child(spike)
	SetPieces.add_piece(ctx, crystals, Vector3.ZERO, Rect2(cc.x - cw, cc.z - cw * 1.5, cw * 2.0, cw * 3.0), box)
	var other: Rect2 = ctx["other_box"]
	var boulders := Node3D.new()
	boulders.name = "IceBoulders"
	for i: int in 3:
		var br: float = minf(other.size.x * 0.32, 0.15) * rng.randf_range(0.7, 1.0)
		var p := Vector3(clampf(other.get_center().x, other.position.x + br, other.end.x - br), 0.0, lerpf(other.position.y + br, other.end.y - br, (i + 0.5) / 3.0))
		boulders.add_child(SetPieces.sphere(br, Color("#b8cfe0"), p + Vector3(0, br * 0.4, 0), Vector3(1.0, 0.8, 1.0), 8))
		boulders.add_child(SetPieces.sphere(br * 0.75, SNOW, p + Vector3(0, br * 0.95, 0), Vector3(1.0, 0.35, 1.0), 8))
	SetPieces.add_piece(ctx, boulders, Vector3.ZERO, other, other)


# --- Candy Hills ------------------------------------------------------------------------------------

const CANDY: Array[Color] = [Color("#ff5a7a"), Color("#ffd84a"), Color("#5ad1ff"), Color("#7aff7a"), Color("#c38cff")]
const FROSTING := Color("#ffb3d6")
const CREAM := Color("#fff4e6")
const WAFER := Color("#e7b16a")


## A chocolate stream along one side (painted by the lane shader) with frosting banks, a wafer bridge over it and
## gumdrop rocks in the back corner.
static func _chocolate_river(ctx: Dictionary) -> void:
	var band: Rect2 = ctx["band"]
	var rng := _rng(ctx)
	var river := Node3D.new()
	river.name = "ChocolateRiver"
	# A frosting bank along the outer side (the stream itself is painted by the lane shader).
	var count: int = int(band.size.y / 0.16)
	var outer: float = band.position.x + 0.03 if band.get_center().x < 0.0 else band.end.x - 0.03
	for i: int in count:
		var z: float = lerpf(band.position.y + 0.05, band.end.y - 0.05, float(i) / maxf(count - 1, 1))
		river.add_child(SetPieces.sphere(0.045, CREAM if i % 2 == 0 else FROSTING, Vector3(outer, 0.01, z), Vector3(1.0, 0.7, 1.5), 8))
	SetPieces.add_piece(ctx, river, Vector3.ZERO, band, band)
	var bridge := Node3D.new()
	bridge.name = "WaferBridge"
	var span: float = band.size.x * 0.95
	var bz: float = lerpf(band.position.y, band.end.y, rng.randf_range(0.3, 0.7))
	for j: int in 3:
		bridge.add_child(SetPieces.box(Vector3(span, 0.018, 0.16), WAFER if j % 2 == 0 else Color("#c98a4a"), Vector3(0, 0.05 + j * 0.018, 0)))
	for sx: float in [-1.0, 1.0]:
		bridge.add_child(SetPieces.box(Vector3(0.04, 0.05, 0.14), Color("#c98a4a"), Vector3(sx * (span / 2.0 - 0.02), 0, 0)))
	var bpos := Vector3(band.get_center().x, 0, bz)
	SetPieces.add_piece(ctx, bridge, bpos, Rect2(bpos.x - span / 2.0, bz - 0.08, span, 0.16), band)
	var box: Rect2 = ctx["box"]
	var drops := Node3D.new()
	drops.name = "Gumdrops"
	for i: int in 3:
		var gr: float = minf(box.size.x * 0.4, 0.2) * rng.randf_range(0.7, 1.0)
		var p := Vector3(rng.randf_range(box.position.x + gr, box.end.x - gr), 0.0, lerpf(box.position.y + gr, box.end.y - gr, (i + 0.5) / 3.0))
		var g := SetPieces.mesh(Palette.cylinder(gr * 0.55, gr, gr * 1.3 * float(ctx["scale"]), 12), CANDY[rng.randi() % CANDY.size()], p + Vector3(0, gr * 0.65 * float(ctx["scale"]), 0))
		drops.add_child(g)
		drops.add_child(SetPieces.sphere(gr * 0.56, g.material_override.get_shader_parameter("albedo_color") if g.material_override else CANDY[0], p + Vector3(0, gr * 1.3 * float(ctx["scale"]), 0), Vector3(1, 0.5, 1), 10))
	SetPieces.add_piece(ctx, drops, Vector3.ZERO, box, box)


## A lollipop tree: a striped stick with a big swirl disc on top (faces the board's long axis).
static func _lollipop(h: float, col: Color) -> Node3D:
	var t := Node3D.new()
	t.add_child(SetPieces.cyl(h * 0.035, h * 0.035, h * 0.7, Color("#fff8f0"), Vector3.ZERO, 8))
	var r: float = h * 0.3
	var disc := SetPieces.mesh(Palette.cylinder(r, r, r * 0.28, 18), col, Vector3.ZERO)
	disc.rotation.z = PI / 2.0
	disc.position = Vector3(0, h * 0.7 + r * 0.85, 0)
	t.add_child(disc)
	var swirl := SetPieces.mesh(Palette.cylinder(r * 0.62, r * 0.62, r * 0.3, 16), Color.WHITE, Vector3.ZERO)
	swirl.rotation.z = PI / 2.0
	swirl.position = disc.position
	t.add_child(swirl)
	var core := SetPieces.mesh(Palette.cylinder(r * 0.32, r * 0.32, r * 0.32, 14), col, Vector3.ZERO)
	core.rotation.z = PI / 2.0
	core.position = disc.position
	t.add_child(core)
	return t


## Lollipop trees in the back corner, a candy-cane fence along one side, soft frosting hills in the other corner.
static func _lollipop_grove(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var grove := Node3D.new()
	grove.name = "Lollipops"
	for i: int in 3:
		var hh: float = rng.randf_range(0.55, 0.85) * sc
		var lp: Node3D = _lollipop(hh, CANDY[(i * 2 + rng.randi()) % CANDY.size()])
		lp.position = Vector3(clampf(box.get_center().x + rng.randf_range(-0.06, 0.06), box.position.x + 0.05, box.end.x - 0.05), 0, lerpf(box.position.y + 0.2, box.end.y - 0.2, (i + 0.5) / 3.0))
		lp.rotation.y = rng.randf_range(-0.4, 0.4)
		grove.add_child(lp)
	SetPieces.add_piece(ctx, grove, Vector3.ZERO, box, box)
	var band: Rect2 = ctx["band"]
	var fence := Node3D.new()
	fence.name = "CaneFence"
	var posts: int = maxi(3, int(band.size.y / 0.4))
	var fx: float = band.get_center().x
	for i: int in posts:
		var z: float = lerpf(band.position.y + 0.05, band.end.y - 0.05, float(i) / (posts - 1))
		for k: int in 4:
			fence.add_child(SetPieces.cyl(0.022, 0.022, 0.06, Color("#e8303c") if k % 2 == 0 else Color.WHITE, Vector3(fx, k * 0.06, z), 8))
		fence.add_child(SetPieces.sphere(0.026, Color("#e8303c"), Vector3(fx, 0.24, z), Vector3.ONE, 8))
	var rail := SetPieces.mesh(Palette.cylinder(0.012, 0.012, band.size.y - 0.1, 6), Color.WHITE, Vector3.ZERO)
	rail.rotation.x = PI / 2.0
	rail.position = Vector3(fx, 0.17, band.get_center().y)
	fence.add_child(rail)
	SetPieces.add_piece(ctx, fence, Vector3.ZERO, band, band)
	var other: Rect2 = ctx["other_box"]
	var hills := Node3D.new()
	hills.name = "FrostingHills"
	for i: int in 2:
		var hr: float = minf(other.size.x * 0.48, 0.3)
		var p := Vector3(other.get_center().x, 0, lerpf(other.position.y + hr, other.end.y - hr, float(i)))
		hills.add_child(SetPieces.sphere(hr, FROSTING if i == 0 else Color("#ffd0e6"), p, Vector3(1.0, 0.55 * sc, 1.0), 14))
		hills.add_child(SetPieces.sphere(hr * 0.6, CREAM, p + Vector3(0, hr * 0.42 * sc, 0), Vector3(1.0, 0.45, 1.0), 12))
		hills.add_child(SetPieces.sphere(hr * 0.16, Color("#e8303c"), p + Vector3(0, hr * 0.64 * sc, 0), Vector3.ONE, 8))
	SetPieces.add_piece(ctx, hills, Vector3.ZERO, other, other)


## A big drippy sundae mountain in the back corner and a ring of donuts in the other.
static func _sundae_peak(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var peak := Node3D.new()
	peak.name = "SundaePeak"
	var r: float = minf(box.size.x * 0.5, 0.42)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.3))
	# A cone-shaped wafer base with three scoops and a cherry.
	peak.add_child(SetPieces.cyl(r * 0.95, r * 0.55, r * 0.7 * sc, WAFER, Vector3.ZERO, 14))
	var scoops: Array[Color] = [Color("#fff1d6"), Color("#ff9ec4"), Color("#8a5a3a")]
	var y: float = r * 0.7 * sc
	for i: int in 3:
		var sr: float = r * (0.88 - i * 0.16)
		peak.add_child(SetPieces.sphere(sr, scoops[i], Vector3(rng.randf_range(-0.02, 0.02), y + sr * 0.55, 0), Vector3(1.0, 0.8, 1.0), 14))
		y += sr * 1.05
	peak.add_child(SetPieces.sphere(r * 0.6, Color("#5a3220"), Vector3(0, y - r * 0.3, 0), Vector3(1.05, 0.35, 1.05), 12))
	peak.add_child(SetPieces.sphere(r * 0.16, Color("#e8303c"), Vector3(0, y + r * 0.05, 0), Vector3.ONE, 10))
	peak.add_child(SetPieces.cyl(0.006, 0.01, r * 0.3, Color("#5a7a2a"), Vector3(0.02, y + r * 0.15, 0), 5))
	SetPieces.add_piece(ctx, peak, c, Rect2(c.x - r, c.z - r, r * 2.0, r * 2.0), box)
	var other: Rect2 = ctx["other_box"]
	var donuts := Node3D.new()
	donuts.name = "Donuts"
	for i: int in 3:
		var d: Node3D = SetPieces.model("candy/donut-sprinkles.glb", 0.12 * sc)
		var dw: float = minf(other.size.x * 0.8, 0.36)
		d.scale *= dw / 0.36
		d.position = Vector3(other.get_center().x, 0.02 + (0.06 * sc if i == 2 else 0.0), lerpf(other.position.y + 0.2, other.end.y - 0.2, 0.5 if i == 2 else float(i)))
		d.rotation = Vector3(0.25 if i == 2 else 0.0, rng.randf() * TAU, 0)
		donuts.add_child(d)
	SetPieces.add_piece(ctx, donuts, Vector3.ZERO, other, other)


# --- Sunny Dunes ------------------------------------------------------------------------------------

const SAND := Color("#f0cf86")
const SAND_DARK := Color("#d9b46a")
const SANDSTONE := Color("#e2b878")
const SANDSTONE_DARK := Color("#b98a52")
const CACTUS := Color("#5aa84a")
const CACTUS_DARK := Color("#43873a")
const PALM_LEAF := Color("#4fae48")
const PALM_TRUNK := Color("#a8774a")


## A storybook saguaro: a ribbed column with one or two raised arms, base at y = 0.
static func cactus(h: float, rng: RandomNumberGenerator) -> Node3D:
	var c := Node3D.new()
	var r: float = h * 0.13
	c.add_child(SetPieces.cyl(r, r * 1.05, h, CACTUS, Vector3.ZERO, 8))
	c.add_child(SetPieces.sphere(r, CACTUS, Vector3(0, h, 0), Vector3.ONE, 8))
	var arms: int = 1 + int(rng.randf() < 0.6)
	for i: int in arms:
		var side: float = -1.0 if i == 0 else 1.0
		var ay: float = h * rng.randf_range(0.35, 0.55)
		var ah: float = h * rng.randf_range(0.25, 0.4)
		var ar: float = r * 0.7
		var stub := SetPieces.mesh(Palette.cylinder(ar, ar, r * 1.6, 6), CACTUS_DARK, Vector3(side * r * 1.2, ay, 0))
		stub.rotation.z = PI / 2.0
		c.add_child(stub)
		c.add_child(SetPieces.cyl(ar, ar, ah, CACTUS, Vector3(side * r * 2.0, ay, 0), 6))
		c.add_child(SetPieces.sphere(ar, CACTUS, Vector3(side * r * 2.0, ay + ah, 0), Vector3.ONE, 6))
	if rng.randf() < 0.5:
		c.add_child(SetPieces.sphere(r * 0.55, Color("#ff7aa8"), Vector3(0, h + r * 0.8, 0), Vector3(1, 0.6, 1), 6))
	return c


## A sandstone pillar of height `h` (broken pillars are shorter with a ragged top), base at y = 0.
static func pillar(r: float, h: float, broken: bool) -> Node3D:
	var p := Node3D.new()
	p.add_child(SetPieces.cyl(r * 1.35, r * 1.4, r * 0.6, SANDSTONE_DARK, Vector3.ZERO, 10))
	p.add_child(SetPieces.cyl(r, r, h, SANDSTONE, Vector3(0, r * 0.6, 0), 10))
	if broken:
		p.add_child(SetPieces.cone(r * 1.05, r * 0.9, SANDSTONE, Vector3(r * 0.2, r * 0.6 + h, 0), 5))
	else:
		p.add_child(SetPieces.box(Vector3(r * 2.8, r * 0.5, r * 2.8), SANDSTONE_DARK, Vector3(0, r * 0.6 + h, 0)))
	return p


## A palm tree: a curved trunk of tapering segments and drooping fronds, base at y = 0.
static func palm(h: float, rng: RandomNumberGenerator) -> Node3D:
	var t := Node3D.new()
	var segs: int = 5
	var lean: float = rng.randf_range(0.12, 0.25) * h
	var top := Vector3.ZERO
	for i: int in segs:
		var k0: float = float(i) / segs
		var k1: float = float(i + 1) / segs
		var a := Vector3(lean * k0 * k0, h * k0, 0)
		var b := Vector3(lean * k1 * k1, h * k1, 0)
		var w: float = h * 0.05 * (1.0 - k0 * 0.35)
		var seg := SetPieces.mesh(Palette.cylinder(w * 0.9, w, a.distance_to(b) * 1.05, 6), PALM_TRUNK if i % 2 == 0 else PALM_TRUNK.darkened(0.15), (a + b) / 2.0)
		seg.rotation.z = -atan2(b.x - a.x, b.y - a.y)
		t.add_child(seg)
		top = b
	for i: int in 6:
		var ang: float = TAU * i / 6.0 + rng.randf_range(-0.2, 0.2)
		var leaf := SetPieces.mesh(_leaf_box(h), PALM_LEAF, top + Vector3(cos(ang), -0.25, sin(ang)) * h * 0.18)
		leaf.rotation = Vector3(0, -ang, -0.45)
		t.add_child(leaf)
	t.add_child(SetPieces.sphere(h * 0.06, Color("#7a5a32"), top + Vector3(0, -h * 0.04, 0), Vector3.ONE, 6))
	return t


static func _leaf_box(h: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(h * 0.42, h * 0.02, h * 0.1)
	return b


## A big rolling dune in the back corner with cacti on its flank; bleached rocks in the other corner.
static func _dune_sea(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var rx: float = box.size.x * 0.5
	var rz: float = minf(box.size.y * 0.45, rx * 2.4)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.3))
	var dune := Node3D.new()
	dune.name = "Dune"
	dune.add_child(SetPieces.sphere(1.0, SAND, Vector3(0, -0.02, 0), Vector3(rx, 0.28 * sc, rz), 18))
	dune.add_child(SetPieces.sphere(1.0, Color("#f7dea6"), Vector3(rx * 0.15, 0.02, -rz * 0.1), Vector3(rx * 0.6, 0.3 * sc, rz * 0.55), 14))
	for i: int in 2:
		var cac: Node3D = cactus(rng.randf_range(0.42, 0.6) * sc, rng)
		cac.position = Vector3(rx * (0.35 if i == 0 else -0.4), 0.12 * sc, rz * (0.3 if i == 0 else -0.35))
		cac.rotation.y = rng.randf() * TAU
		dune.add_child(cac)
	SetPieces.add_piece(ctx, dune, c, Rect2(c.x - rx, c.z - rz, rx * 2.0, rz * 2.0), box)
	var other: Rect2 = ctx["other_box"]
	var rocks := Node3D.new()
	rocks.name = "BleachedRocks"
	for i: int in 3:
		var br: float = minf(other.size.x * 0.3, 0.15) * rng.randf_range(0.6, 1.0)
		var bp := Vector3(clampf(other.get_center().x + rng.randf_range(-0.05, 0.05), other.position.x + br, other.end.x - br), 0.0, lerpf(other.position.y + br, other.end.y - br, (i + 0.5) / 3.0))
		rocks.add_child(SetPieces.sphere(br, Color("#efe6d2"), bp + Vector3(0, br * 0.3, 0), Vector3(1.0, 0.6, 0.9), 8))
	SetPieces.add_piece(ctx, rocks, Vector3.ZERO, other, other)


## Old sandstone pillars (one standing with its capital, two broken) in the back corner, a toppled drum and blocks
## in the other corner.
static func _sandstone_ruins(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var ruins := Node3D.new()
	ruins.name = "Ruins"
	var r: float = clampf(box.size.x * 0.12, 0.05, 0.09)
	var heights: Array[float] = [0.7, 0.4, 0.26]
	for i: int in 3:
		var pp: Vector3 = _at(box, 0.3 + 0.4 * float(i % 2), lerpf(0.2, 0.8, float(i) / 2.0))
		var col: Node3D = pillar(r, heights[i] * sc, i > 0)
		col.position = pp
		col.rotation.y = rng.randf() * TAU
		ruins.add_child(col)
	SetPieces.add_piece(ctx, ruins, Vector3.ZERO, box, box)
	var other: Rect2 = ctx["other_box"]
	var fallen := Node3D.new()
	fallen.name = "Fallen"
	var fp: Vector3 = _at(other, 0.5, 0.5)
	var drum := SetPieces.mesh(Palette.cylinder(r, r, minf(other.size.y * 0.5, 0.4), 10), SANDSTONE, fp + Vector3(0, r, 0))
	drum.rotation.x = PI / 2.0
	fallen.add_child(drum)
	for i: int in 2:
		var b := r * rng.randf_range(1.2, 1.6)
		fallen.add_child(SetPieces.box(Vector3(b, b * 0.8, b), SANDSTONE_DARK, _at(other, 0.5, 0.15 + 0.7 * i)))
	SetPieces.add_piece(ctx, fallen, Vector3.ZERO, other, other)


## A small oasis: a pond with reeds and a palm in the back corner, cacti along one side.
static func _oasis(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var sc: float = ctx["scale"]
	var rx: float = box.size.x * 0.46
	var rz: float = minf(box.size.y * 0.4, rx * 1.8)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.3))
	var oasis := Node3D.new()
	oasis.name = "Oasis"
	oasis.add_child(SetPieces.pool(0, rx, rz, rng.randf() * 10.0))
	var p: Node3D = palm(0.85 * sc, rng)
	p.position = Vector3(rx * 0.75, 0, -rz * 0.6 * (1.0 if _back(ctx) > 0.5 else -1.0))
	p.rotation.y = rng.randf() * TAU
	oasis.add_child(p)
	for i: int in 4:
		var ang: float = rng.randf() * TAU
		var tuft: Node3D = SetPieces.grass_tuft(0.16, Color("#5aa84a"), rng)
		tuft.position = Vector3(cos(ang) * rx * 1.05, 0, sin(ang) * rz * 1.05)
		oasis.add_child(tuft)
	SetPieces.add_piece(ctx, oasis, c, Rect2(c.x - rx, c.z - rz, rx * 2.0, rz * 2.0), box)
	var band: Rect2 = ctx["other_band"]
	var cacti := Node3D.new()
	cacti.name = "Cacti"
	for i: int in 2:
		var cac: Node3D = cactus(rng.randf_range(0.3, 0.45) * sc, rng)
		cac.position = Vector3(band.get_center().x, 0, lerpf(band.position.y + 0.15, band.end.y - 0.15, (i + 0.5) / 2.0))
		cac.rotation.y = rng.randf() * TAU
		cacti.add_child(cac)
	SetPieces.add_piece(ctx, cacti, Vector3.ZERO, band, band)
