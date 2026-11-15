class_name DamageNumber
extends Label3D
## Cartoon damage / heal number that pops, rises and fades. stamp() is the big CRIT! stamp.

static var _font: FontFile


static func _title_font() -> FontFile:
	if _font == null:
		_font = load(UiStyle.TITLE_FONT) as FontFile
	return _font


static func spawn(parent: Node, pos: Vector3, text_: String, color: Color, size: int = 72) -> DamageNumber:
	var d := DamageNumber.new()
	d.text = text_
	d.font = _title_font()
	d.modulate = color
	d.font_size = size
	d.outline_size = 20
	d.outline_modulate = Palette.INK
	d.pixel_size = 0.007
	d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	d.no_depth_test = true
	d.render_priority = 10
	parent.add_child(d)
	d.global_position = pos
	d.scale = Vector3.ONE * 1.4
	var tw := d.create_tween()
	tw.tween_property(d, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(d, "global_position", pos + Vector3(0, 0.8, 0), 1.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(d, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.tween_callback(d.queue_free)
	return d


## A tilted gold stamp ("CRIT!") that slams in and fades.
static func stamp(parent: Node, pos: Vector3, text_: String) -> DamageNumber:
	var d := DamageNumber.new()
	d.text = text_
	d.font = _title_font()
	d.modulate = Palette.GOLD
	d.font_size = 110
	d.outline_size = 26
	d.outline_modulate = Palette.INK
	d.pixel_size = 0.007
	d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	d.no_depth_test = true
	d.render_priority = 11
	parent.add_child(d)
	d.global_position = pos
	d.rotation.z = -0.18
	d.scale = Vector3.ONE * 2.2
	var tw := d.create_tween()
	tw.tween_property(d, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.45)
	tw.tween_property(d, "modulate:a", 0.0, 0.3)
	tw.tween_callback(d.queue_free)
	return d
