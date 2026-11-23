class_name FlyingCard
extends Control
## A card (face up, or a card back) flying between two screen points, shrinking as it goes.

signal landed


## `back`: the owner's card back art (CardBacks) for a face-down card; a plain back when null.
## `flip`: starts face down and turns face up halfway (a card drawn into your hand).
static func fly(parent: Control, card: CardData, from: Vector2, to: Vector2, face_up: bool, duration: float = 0.3, back_tex: Texture2D = null, flip: bool = false) -> FlyingCard:
	var f := FlyingCard.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.size = CardWidget.SIZE
	if flip and card and back_tex:
		var face := CardWidget.new()
		face.setup(card, -1)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.visible = false
		f.add_child(face)
		var b := back_rect(back_tex)
		f.add_child(b)
		f.pivot_offset = CardWidget.SIZE / 2.0
		parent.add_child(f)
		f.position = from - CardWidget.SIZE / 2.0
		f.scale = Vector2.ONE * 0.45
		var ft := f.create_tween().set_parallel(true)
		ft.tween_property(f, "position", to - CardWidget.SIZE / 2.0 - Vector2(0, 40), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ft.tween_property(f, "scale:y", 0.8, duration)
		ft.tween_property(f, "scale:x", 0.0, duration * 0.45).set_ease(Tween.EASE_IN)
		ft.chain().tween_callback(func() -> void:
			b.visible = false
			face.visible = true)
		ft.chain().tween_property(f, "scale:x", 0.8, duration * 0.4).set_ease(Tween.EASE_OUT)
		ft.chain().tween_property(f, "modulate:a", 0.0, 0.1)
		ft.chain().tween_callback(func() -> void:
			f.landed.emit()
			f.queue_free())
		return f
	if face_up and card:
		var w := CardWidget.new()
		w.setup(card, -1)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.add_child(w)
	elif back_tex:
		f.add_child(back_rect(back_tex))
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
		var star := TextureRect.new()
		star.texture = load(VisualDB.ICON_SPARKLE) as Texture2D
		star.modulate = Palette.GOLD
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.size = Vector2(64, 64)
		star.position = (back.size - star.size) / 2.0
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


## A card-sized picture of a card back.
static func back_rect(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.size = CardWidget.SIZE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
