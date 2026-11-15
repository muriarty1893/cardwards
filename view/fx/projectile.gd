class_name Projectile
extends Node3D
## A glowing missile that arcs from A to B with a trail, then bursts. It only remembers
## positions, so the shooter or target can vanish mid-flight without breaking anything.

signal arrived

const ELEMENTS: Array[StringName] = [&"spore", &"fire", &"candy", &"ice", &"boulder"]
const ARC := 1.2
## element -> [core colour, trail preset, impact presets]
const LOOK: Dictionary = {
	&"spore": ["#9bff6a", &"heal", [&"heal"]],
	&"fire": ["#ff7a1a", &"embers", [&"sparks", &"smoke"]],
	&"candy": ["#ff8ad8", &"sprinkles", [&"sprinkles"]],
	&"ice": ["#bfe8ff", &"snow", [&"snow", &"sparks"]],
	&"boulder": ["#9a8a7a", &"smoke", [&"dust_ring", &"smoke"]],
}

var element: StringName = &"fire"


static func launch(parent: Node, element_: StringName, from: Vector3, to: Vector3, duration: float = 0.45) -> Projectile:
	var p := Projectile.new()
	p.element = element_ if LOOK.has(element_) else &"fire"
	parent.add_child(p)
	p.global_position = from
	p._build()
	var tw := p.create_tween()
	tw.tween_method(func(t: float) -> void:
		p.global_position = from.lerp(to, t) + Vector3(0, sin(t * PI) * ARC, 0)
		p.rotation.x += 0.4, 0.0, 1.0, duration)
	tw.tween_callback(p._impact)
	return p


func _build() -> void:
	var look: Array = LOOK[element]
	var core := Color(look[0] as String)
	var m := StandardMaterial3D.new()
	m.albedo_color = core
	m.emission_enabled = element != &"boulder"
	m.emission = core
	m.emission_energy_multiplier = 1.6
	var ball: MeshInstance3D
	if element == &"boulder":
		ball = Palette.mesh(Palette.sphere(0.32, 6), Toon.plain(core), Vector3.ZERO, false)
	else:
		ball = Palette.mesh(Palette.sphere(0.2, 12), m, Vector3.ZERO, false)
	add_child(ball)
	# Trail: a continuous emitter in world space that follows the missile.
	var trail := Burst.spawn(self, look[1], global_position, Color.WHITE, 0.6)
	trail.one_shot = false
	trail.explosiveness = 0.0
	trail.amount = 16
	trail.finished.disconnect(trail.queue_free)


func _impact() -> void:
	var where: Vector3 = global_position
	var parent: Node = get_parent()
	if parent and is_instance_valid(parent):
		for preset: StringName in LOOK[element][2]:
			Burst.spawn(parent, preset, where, Color.WHITE, 1.2)
	arrived.emit()
	queue_free()
