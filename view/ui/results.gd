class_name Results
extends Control
## End-of-match overlay: VICTORY / DEFEAT, turn count, REMATCH and MENU.

signal rematch
signal menu


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func show_result(won: bool, turns: int) -> void:
	for c: Node in get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.parchment_panel(22))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)
	var title := UiStyle.title(UiStyle.label("VICTORY!" if won else "DEFEAT", 64, Palette.GOLD.darkened(0.2) if won else Palette.HP)) as Label
	title.add_theme_color_override("font_outline_color", Palette.INK)
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(360, 0)
	vb.add_child(title)
	var sub := UiStyle.label("The match lasted %d turns." % turns, 18)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)
	var again := MenuButtons.big("REMATCH", Palette.GOLD)
	again.pressed.connect(func() -> void: rematch.emit())
	hb.add_child(again)
	var back := MenuButtons.big("MENU", Color.WHITE)
	back.pressed.connect(func() -> void: menu.emit())
	hb.add_child(back)
	visible = true
	Audio.sfx(&"victory" if won else &"defeat", 0.0)
	if won:
		Confetti.burst(self)
	else:
		var vp: Vector2 = get_viewport_rect().size
		Confetti.rain_cloud(self, Vector2(vp.x / 2.0, vp.y / 2.0 - 190.0))
	panel.scale = Vector2.ONE * 0.6
	panel.pivot_offset = panel.size / 2.0
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	again.grab_focus()
