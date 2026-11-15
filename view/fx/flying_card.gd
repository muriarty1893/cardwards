class_name FlyingCard
extends Control
## A card (face up, or a card back) flying between two screen points, shrinking as it goes.

signal landed


static func fly(parent: Control, card: CardData, from: Vector2, to: Vector2, face_up: bool, duration: float = 0.3) -> FlyingCard:
	var f := FlyingCard.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.size = CardWidget.SIZE
	if face_up and card:
		var w := CardWidget.new()
		w.setup(card, -1)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.add_child(w)
	else:
		var back := Panel.new()
		back.size = CardWidget.SIZE
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.TRAY_LIGHT
		sb.border_color = Palette.INK
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(12)
		back.add_theme_stylebox_override("panel", sb)
		var star := UiStyle.title(UiStyle.label("✦", 64, Palette.GOLD)) as Label
		star.size = back.size
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		back.add_child(star)
		f.add_child(back)
	f.pivot_offset = CardWidget.SIZE / 2.0
	parent.add_child(f)
	f.position = from - CardWidget.SIZE / 2.0
	f.scale = Vector2.ONE * 0.7
	var tw := f.create_tween().set_parallel(true)
	tw.tween_property(f, "position", to - CardWidget.SIZE / 2.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(f, "scale", Vector2.ONE * 0.3, duration)
	tw.tween_property(f, "rotation", 0.25, duration)
	tw.chain().tween_callback(func() -> void:
		f.landed.emit()
		f.queue_free())
	return f
