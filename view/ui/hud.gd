class_name Hud
extends Control
## Screen layout: hero corners (portrait, health bar, magic), a bottom tray (deck and discard
## counters, room for the hand, magic orb, BATTLE! button), and a pause button.

signal end_turn_pressed
signal menu_requested
signal pause_changed(open: bool)

const TRAY_H := 214.0
const TRAY_MARGIN := 60.0
const CORNER := Vector2(236, 120)
## Hero health bar size (it sits on top of the corner and runs toward the centre).
const BAR := Vector2(300, 30)

var end_turn_button: Button
var pause_button: Button
var _you: Control
var _rival: Control
var _you_bar: Control
var _rival_bar: Control
var _tray: Panel
var _refs: Dictionary = {}
var _orb_label: Label
var _deck_label: Label
var _discard_label: Label
## Full-screen pause menu. The match moves it above the hand so it takes the mouse first.
var pause_overlay: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_you = _corner(true, "You", "res://assets/card_art/hero_you.png", Color("#8fd3ff"))
	_you.position = Vector2(12, 10)
	add_child(_you)
	_rival = _corner(false, "Rival", "res://assets/card_art/hero_rival.png", Color("#ffb3dd"))
	_rival.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rival.offset_left = -CORNER.x - 12
	_rival.offset_right = -12
	_rival.offset_top = 10
	_rival.offset_bottom = 10 + CORNER.y
	add_child(_rival)
	_you_bar = _hero_bar(true, "You")
	add_child(_you_bar)
	_rival_bar = _hero_bar(false, "Rival")
	add_child(_rival_bar)
	_build_tray()
	_build_pause()


func panels() -> Array[Control]:
	return [_you, _rival, _you_bar, _rival_bar, _tray, end_turn_button, pause_button]


func refresh(s: GameState, human: int) -> void:
	_fill_corner("You", s.players[human], "TURN %d" % s.turn)
	var foe: GameState.PlayerState = s.players[s.opponent(human)]
	_fill_corner("Rival", foe, "%d CARDS" % foe.hand.size())
	var me: GameState.PlayerState = s.players[human]
	_orb_label.text = str(me.magic)
	_deck_label.text = "DECK  %d" % me.deck.size()
	_discard_label.text = "DISCARD  %d" % me.discard.size()
	var mine: bool = s.active == human and s.phase != GameState.Phase.OVER
	_you.modulate = Color.WHITE if mine else Color(0.82, 0.82, 0.82)
	_rival.modulate = Color.WHITE if not mine else Color(0.82, 0.82, 0.82)
	_you_bar.modulate = _you.modulate
	_rival_bar.modulate = _rival.modulate


func is_paused() -> bool:
	return pause_overlay.visible


func close_pause() -> void:
	pause_overlay.visible = false
	pause_changed.emit(false)


func _open_pause() -> void:
	pause_overlay.visible = true
	pause_changed.emit(true)


func set_input_enabled(on: bool) -> void:
	end_turn_button.disabled = not on
	pause_button.disabled = not on


func shake_hero(human_side: bool) -> void:
	var p: Control = _you if human_side else _rival
	var base: Vector2 = p.position
	var tw := create_tween()
	for i: int in 6:
		tw.tween_property(p, "position", base + Vector2(randf_range(-6, 6), randf_range(-3, 3)), 0.04)
	tw.tween_property(p, "position", base, 0.05)


## Screen rects of the hero corners and their health bars (stat bars keep out of them).
func corner_rects() -> Array[Rect2]:
	return [_you.get_global_rect(), _rival.get_global_rect(), _you_bar.get_global_rect(), _rival_bar.get_global_rect()]


func deck_screen_pos() -> Vector2:
	return _deck_label.get_global_rect().get_center()


func discard_screen_pos() -> Vector2:
	return _discard_label.get_global_rect().get_center()


## Centre of the magic orb that a gained gem flies to.
func orb_screen_pos(human_side: bool) -> Vector2:
	if human_side:
		return _orb_label.get_global_rect().get_center()
	return (_refs["Rival"]["orb"] as Control).get_global_rect().get_center()


func hero_screen_pos(human_side: bool) -> Vector2:
	return (_you if human_side else _rival).get_global_rect().get_center()


# --- Building blocks ---------------------------------------------------------

func _frame(bg: Color, radius: int = 16, border: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Palette.TRAY_DARK
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	return sb


func _plate(text: String, size_: Vector2, font: int = 16) -> Label:
	var l := UiStyle.title(UiStyle.label(text, font, Color.WHITE)) as Label
	l.size = size_
	l.custom_minimum_size = size_
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_stylebox_override("normal", _frame(Palette.TRAY_LIGHT, 10, 3))
	return l


func _orb(diameter: float, font: int) -> Label:
	var l := UiStyle.title(UiStyle.label("0", font, Color.WHITE)) as Label
	l.size = Vector2(diameter, diameter)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Palette.TRAY_DARK)
	l.add_theme_constant_override("outline_size", 8)
	var sb := _frame(Color("#7a4de0"), int(diameter / 2.0), 5)
	sb.shadow_color = Color("#b48cff", 0.6)
	sb.shadow_size = 6
	l.add_theme_stylebox_override("normal", sb)
	return l


func _corner(left: bool, who: String, portrait: String, bg: Color) -> Control:
	var c := Control.new()
	c.name = who
	c.size = CORNER
	c.custom_minimum_size = CORNER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := Panel.new()
	back.size = CORNER
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_theme_stylebox_override("panel", _frame(Palette.TRAY, 18))
	c.add_child(back)
	# Framed portrait in the outer corner.
	var frame := Panel.new()
	frame.size = Vector2(96, 96)
	frame.position = Vector2(8, 12) if left else Vector2(CORNER.x - 104, 12)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = bg
	fsb.border_color = Palette.INK
	fsb.set_border_width_all(4)
	fsb.set_corner_radius_all(14)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	c.add_child(frame)
	var face := TextureRect.new()
	face.texture = load(portrait) as Texture2D
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.position = Vector2(4, 4)
	face.size = Vector2(88, 88)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(face)
	var orb := _orb(44, 22)
	orb.position = Vector2(112, 46) if left else Vector2(CORNER.x - 156, 46)
	c.add_child(orb)
	var nm := UiStyle.title(UiStyle.label(who.to_upper(), 18, Color("#d9d4ff"))) as Label
	nm.position = Vector2(160, 54) if left else Vector2(8, 54)
	nm.size = Vector2(68, 26)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(nm)
	var plate := _plate("", Vector2(116, 24), 14)
	plate.position = Vector2(112, 92) if left else Vector2(8, 92)
	c.add_child(plate)
	_refs[who] = {"orb": orb, "plate": plate}
	return c


## Wide hero health bar along the top edge, running from the corner toward the centre.
func _hero_bar(left: bool, who: String) -> Control:
	var bar := ProgressBar.new()
	bar.name = "YouBar" if left else "RivalBar"
	bar.max_value = GameState.MAX_HP
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = BAR
	bar.size = BAR
	bar.add_theme_stylebox_override("background", _frame(Palette.TRAY_DARK, 10, 3))
	bar.add_theme_stylebox_override("fill", _frame(Palette.HP, 10, 3))
	bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END if left else ProgressBar.FILL_END_TO_BEGIN
	if left:
		bar.position = Vector2(12 + 112, 14)
	else:
		bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		bar.offset_left = -(12 + 112 + BAR.x)
		bar.offset_right = -(12 + 112)
		bar.offset_top = 14
		bar.offset_bottom = 14 + BAR.y
	var hp := UiStyle.title(UiStyle.label("♥ 25", 18, Color.WHITE)) as Label
	hp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp.add_theme_color_override("font_outline_color", Palette.TRAY_DARK)
	hp.add_theme_constant_override("outline_size", 7)
	bar.add_child(hp)
	_refs[who + "Bar"] = {"bar": bar, "hp": hp}
	return bar


func _fill_corner(who: String, ps: GameState.PlayerState, plate_text: String) -> void:
	var r: Dictionary = _refs[who]
	(r["orb"] as Label).text = str(ps.magic)
	(r["plate"] as Label).text = plate_text
	var b: Dictionary = _refs[who + "Bar"]
	(b["bar"] as ProgressBar).value = clampi(ps.hero_hp, 0, GameState.MAX_HP)
	(b["hp"] as Label).text = "♥ %d" % ps.hero_hp


func _build_tray() -> void:
	_tray = Panel.new()
	_tray.name = "Tray"
	_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _frame(Palette.TRAY, 22, 5)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.border_width_bottom = 0
	_tray.add_theme_stylebox_override("panel", sb)
	_tray.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_tray.offset_left = TRAY_MARGIN
	_tray.offset_right = -TRAY_MARGIN
	_tray.offset_top = -TRAY_H
	_tray.offset_bottom = 0
	add_child(_tray)
	# Inner felt where the hand sits.
	var felt := Panel.new()
	felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	felt.add_theme_stylebox_override("panel", _frame(Color("#1f1c40"), 14, 3))
	felt.set_anchors_preset(Control.PRESET_FULL_RECT)
	felt.offset_left = 172
	felt.offset_right = -222
	felt.offset_top = 10
	felt.offset_bottom = 6
	_tray.add_child(felt)
	_deck_label = _plate("DECK", Vector2(148, 44))
	_deck_label.position = Vector2(14, 38)
	_tray.add_child(_deck_label)
	_discard_label = _plate("DISCARD", Vector2(148, 44))
	_discard_label.position = Vector2(14, 96)
	_tray.add_child(_discard_label)
	_orb_label = _orb(92, 44)
	_orb_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_orb_label.offset_left = -158
	_orb_label.offset_right = -66
	_orb_label.offset_top = -40
	_orb_label.offset_bottom = 52
	_tray.add_child(_orb_label)
	end_turn_button = Button.new()
	end_turn_button.name = "Battle"
	end_turn_button.text = "BATTLE!"
	end_turn_button.add_theme_font_size_override("font_size", 34)
	UiStyle.title(end_turn_button)
	for st: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var b := _frame(Palette.GREEN if st != "disabled" else Color("#6c6a8a"), 16, 5)
		if st == "hover":
			b.bg_color = Palette.GREEN.lightened(0.2)
		if st == "pressed":
			b.bg_color = Palette.GREEN.darkened(0.15)
		end_turn_button.add_theme_stylebox_override(st, b)
	for col: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		end_turn_button.add_theme_color_override(col, Color.WHITE)
	end_turn_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	end_turn_button.add_theme_color_override("font_outline_color", Palette.TRAY_DARK)
	end_turn_button.add_theme_constant_override("outline_size", 10)
	end_turn_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	end_turn_button.offset_left = -210
	end_turn_button.offset_right = -14
	end_turn_button.offset_top = 62
	end_turn_button.offset_bottom = 170
	end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	UiStyle.sound_button(end_turn_button)
	_tray.add_child(end_turn_button)


func _build_pause() -> void:
	pause_button = Button.new()
	pause_button.name = "Pause"
	pause_button.text = "II"
	pause_button.add_theme_font_size_override("font_size", 22)
	for st: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var b := _frame(Color("#ff9a3a") if st != "disabled" else Color("#8a86a8"), 28, 4)
		if st == "hover":
			b.bg_color = Color("#ffb86a")
		pause_button.add_theme_stylebox_override(st, b)
	for col: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		pause_button.add_theme_color_override(col, Color.WHITE)
	pause_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	pause_button.offset_left = -70
	pause_button.offset_right = -14
	pause_button.offset_top = -70
	pause_button.offset_bottom = -14
	add_child(pause_button)
	UiStyle.sound_button(pause_button)
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	pause_overlay.z_index = 50
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(dim)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 1, 1, 0.97), 22))
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_overlay.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)
	var title := UiStyle.title(UiStyle.label("Paused", 44)) as Label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(320, 0)
	vb.add_child(title)
	var settings := SettingsPanel.make(false)
	settings.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	vb.add_child(settings)
	var resume := MenuButtons.big("RESUME", Palette.GOLD)
	resume.pressed.connect(close_pause)
	vb.add_child(resume)
	var menu := MenuButtons.big("QUIT TO MENU", Color.WHITE)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	vb.add_child(menu)
	add_child(pause_overlay)
	pause_button.pressed.connect(_open_pause)
