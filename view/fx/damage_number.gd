class_name DamageNumber
extends Label3D
## Floating number that rises and fades.


static func spawn(parent: Node, pos: Vector3, text_: String, color: Color, size: int = 72) -> DamageNumber:
	var d := DamageNumber.new()
	d.text = text_
	d.modulate = Color(color.r * 1.6, color.g * 1.6, color.b * 1.6, 1.0)
	d.font_size = size
	d.outline_size = 18
	d.outline_modulate = Palette.INK
	d.pixel_size = 0.007
	d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	d.no_depth_test = true
	d.render_priority = 10
	parent.add_child(d)
	d.global_position = pos
	d.scale = Vector3.ONE * 0.4
	var tw := d.create_tween()
	tw.tween_property(d, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(d, "global_position", pos + Vector3(0, 0.8, 0), 1.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(d, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.tween_callback(d.queue_free)
	return d
