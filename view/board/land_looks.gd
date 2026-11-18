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


## A pond with ripples, lily pads and reeds in the back corner; long swaying grass along both sides.
static func _pond_glade(ctx: Dictionary) -> void:
	var box: Rect2 = ctx["box"]
	var rng := _rng(ctx)
	var rx: float = box.size.x * 0.5
	var rz: float = minf(box.size.y * 0.42, rx * 1.9)
	var c: Vector3 = _at(box, 0.5, lerpf(0.5, _back(ctx), 0.3))
	var pond := Node3D.new()
	pond.name = "Pond"
	pond.add_child(SetPieces.pool(0, rx, rz))
	for i: int in 3:
		var a: float = rng.randf() * TAU
		var e: float = rng.randf_range(0.2, 0.6)
		var pad := SetPieces.cyl(0.07, 0.07, 0.008, Color("#4fbf4a"), Vector3(cos(a) * rx * e, 0.014, sin(a) * rz * e), 12)
		pond.add_child(pad)
		if i == 0:
			pond.add_child(SetPieces.sphere(0.03, Color("#ffd0e8"), Vector3(cos(a) * rx * e, 0.04, sin(a) * rz * e), Vector3(1, 0.7, 1), 8))
	SetPieces.add_piece(ctx, pond, c, Rect2(c.x - rx, c.z - rz, rx * 2.0, rz * 2.0), box)
	# Reeds at the pond's far end.
	var reeds := Node3D.new()
	reeds.name = "Reeds"
	var rz0: float = c.z + rz * (1.0 if _back(ctx) > 0.5 else -1.0) * 0.75
	for i: int in 5:
		var x: float = c.x + rng.randf_range(-rx * 0.8, rx * 0.8)
		var z: float = clampf(rz0 + rng.randf_range(-0.06, 0.06), box.position.y + 0.03, box.end.y - 0.03)
		var hh: float = rng.randf_range(0.28, 0.45) * float(ctx["scale"])
		reeds.add_child(SetPieces.cyl(0.008, 0.012, hh, Color("#5c8a3a"), Vector3(x, 0, z), 5))
		reeds.add_child(SetPieces.cyl(0.022, 0.022, 0.07, Color("#7a4a2a"), Vector3(x, hh * 0.78, z), 6))
	SetPieces.add_piece(ctx, reeds, Vector3.ZERO, Rect2(c.x - rx, rz0 - 0.1, rx * 2.0, 0.2), box)
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
