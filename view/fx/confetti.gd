class_name Confetti
extends CPUParticles2D
## Victory confetti from the top of the screen, and a sad rain cloud for defeat.

const COLORS: Array[Color] = [Color("#ff5a5a"), Color("#ffd84a"), Color("#5ad1ff"), Color("#7aff7a"), Color("#ff8ad8"), Color("#ffffff")]


static func burst(parent: Control) -> Confetti:
	var c := Confetti.new()
	var vp: Vector2 = parent.get_viewport_rect().size
	c.amount = 140
	c.lifetime = 3.0
	c.one_shot = true
	c.explosiveness = 0.85
	c.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	c.emission_rect_extents = Vector2(vp.x / 2.0, 10)
	c.position = Vector2(vp.x / 2.0, -20)
	c.direction = Vector2.DOWN
	c.spread = 30.0
	c.gravity = Vector2(0, 260)
	c.initial_velocity_min = 80.0
	c.initial_velocity_max = 260.0
	c.angular_velocity_min = -360.0
	c.angular_velocity_max = 360.0
	c.scale_amount_min = 6.0
	c.scale_amount_max = 11.0
	var ramp := Gradient.new()
	var offs := PackedFloat32Array()
	for i: int in COLORS.size():
		offs.append(float(i) / float(COLORS.size() - 1))
	ramp.offsets = offs
	ramp.colors = PackedColorArray(COLORS)
	c.color_initial_ramp = ramp
	parent.add_child(c)
	c.emitting = true
	c.finished.connect(c.queue_free)
	return c


## A grey cloud with falling drops, drawn above `at` (centre top of the results panel).
static func rain_cloud(parent: Control, at: Vector2 = Vector2.ZERO) -> Node2D:
	var cloud := Node2D.new()
	cloud.position = at if at != Vector2.ZERO else Vector2(parent.get_viewport_rect().size.x / 2.0, 120)
	var puff := Polygon2D.new()
	var pts := PackedVector2Array()
	for i: int in 48:
		var a: float = TAU * float(i) / 48.0
		var r: float = 36.0 + 10.0 * sin(a * 5.0)
		pts.append(Vector2(cos(a) * r * 2.2, sin(a) * r * 0.9))
	puff.polygon = pts
	puff.color = Color("#8a8fa0")
	cloud.add_child(puff)
	var drops := CPUParticles2D.new()
	drops.amount = 40
	drops.lifetime = 0.8
	drops.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drops.emission_rect_extents = Vector2(70, 4)
	drops.position = Vector2(0, 30)
	drops.direction = Vector2.DOWN
	drops.spread = 4.0
	drops.gravity = Vector2(0, 600)
	drops.initial_velocity_min = 120.0
	drops.initial_velocity_max = 180.0
	drops.scale_amount_min = 2.0
	drops.scale_amount_max = 3.0
	drops.color = Color("#7ab8ff")
	cloud.add_child(drops)
	parent.add_child(cloud)
	drops.emitting = true
	return cloud
