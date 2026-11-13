class_name Hud
extends Control
## Screen layout: hero corners (portrait, health bar, magic), a bottom tray (deck and discard
## counters, room for the hand, magic orb, BATTLE! button), and a pause button.

signal end_turn_pressed
signal menu_requested

const TRAY_H := 184.0
const TRAY_MARGIN := 60.0
const CORNER := Vector2(214, 128)

var end_turn_button: Button
var pause_button: Button
var _you: Control
var _rival: Control
var _tray: Panel
var _refs: Dictionary = {}
var _orb_label: Label
var _deck_label: Label
var _discard_label: Label
var _pause: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_you = _corner(true, "You", Color("#ffd84a"), Color("#8fd3ff"))
	_you.position = Vector2(12, 10)
	add_child(_you)
	_rival = _corner(false, "Rival", Color("#b06cff"), Color("#ffb3dd"))
	_rival.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rival.offset_left = -CORNER.x - 12
	_rival.offset_right = -12
	_rival.offset_top = 10
	_rival.offset_bottom = 10 + CORNER.y
	add_child(_rival)
	_build_tray()
	_build_pause()


func panels() -> Array[Control]:
	return [_you, _rival, _tray, end_turn_button, pause_button]


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
	var l := UiStyle.bold(UiStyle.label(text, font, Color.WHITE))
	l.size = size_
	l.custom_minimum_size = size_
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_stylebox_override("normal", _frame(Palette.TRAY_LIGHT, 10, 3))
	return l


func _orb(diameter: float, font: int) -> Label:
	var l := UiStyle.bold(UiStyle.label("0", font, Color.WHITE))
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


func _corner(left: bool, who: String, body: Color, bg: Color) -> Control:
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
	var bar := ProgressBar.new()
	bar.position = Vector2(10, 9)
	bar.size = Vector2(CORNER.x - 20, 26)
	bar.max_value = GameState.MAX_HP
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _frame(Palette.TRAY_DARK, 9, 3))
	var fill := _frame(Palette.HP, 9, 3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END if left else ProgressBar.FILL_END_TO_BEGIN
	c.add_child(bar)
	var hp := UiStyle.bold(UiStyle.label("25", 17, Color.WHITE))
	hp.position = bar.position
	hp.size = bar.size
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp.add_theme_color_override("font_outline_color", Palette.TRAY_DARK)
	hp.add_theme_constant_override("outline_size", 6)
	c.add_child(hp)
	var face := BlobPortrait.new()
	face.body_color = body
	face.bg_color = bg
	face.horns = not left
	face.size = Vector2(80, 80)
	face.position = Vector2(10, 41) if left else Vector2(CORNER.x - 90, 41)
	c.add_child(face)
	var orb := _orb(48, 22)
	orb.position = Vector2(100, 40) if left else Vector2(CORNER.x - 148, 40)
	c.add_child(orb)
	var nm := UiStyle.bold(UiStyle.label(who.to_upper(), 14, Color("#c9c4ff")))
	nm.position = Vector2(154, 52) if left else Vector2(10, 52)
	nm.size = Vector2(50, 24)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(nm)
	var plate := _plate("", Vector2(104, 28), 14)
	plate.position = Vector2(100, 93) if left else Vector2(10, 93)
	c.add_child(plate)
	_refs[who] = {"bar": bar, "hp": hp, "orb": orb, "plate": plate}
	return c


func _fill_corner(who: String, ps: GameState.PlayerState, plate_text: String) -> void:
	var r: Dictionary = _refs[who]
	(r["bar"] as ProgressBar).value = clampi(ps.hero_hp, 0, GameState.MAX_HP)
	(r["hp"] as Label).text = "♥ %d" % ps.hero_hp
	(r["orb"] as Label).text = str(ps.magic)
	(r["plate"] as Label).text = plate_text


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
	end_turn_button.add_theme_font_size_override("font_size", 30)
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Nunito", "Fredoka", "Noto Sans", "sans-serif"])
	f.font_weight = 900
	end_turn_button.add_theme_font_override("font", f)
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
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause.visible = false
	_pause.z_index = 50
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(dim)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 1, 1, 0.97), 22))
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)
	var title := UiStyle.bold(UiStyle.label("Paused", 40))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(280, 0)
	vb.add_child(title)
	var resume := MenuButtons.big("RESUME", Palette.GOLD)
	resume.pressed.connect(func() -> void: _pause.visible = false)
	vb.add_child(resume)
	var menu := MenuButtons.big("QUIT TO MENU", Color.WHITE)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	vb.add_child(menu)
	add_child(_pause)
	pause_button.pressed.connect(func() -> void: _pause.visible = true)
