class_name Hud
extends Control
## Health, magic, hand/deck counts, turn counter and the END TURN button.

signal end_turn_pressed

var end_turn_button: Button
var _rival: PanelContainer
var _you: PanelContainer
var _turn: PanelContainer
var _rival_label: Label
var _you_label: Label
var _turn_label: Label
var _rival_avatar: Panel
var _you_avatar: Panel


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rival = _make_panel("Rival")
	_rival_avatar = _avatar(Color("#b06cff"))
	_rival_label = _row(_rival, _rival_avatar)
	_rival.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_rival.position = Vector2(18, 12)
	_you = _make_panel("You")
	_you_avatar = _avatar(Color("#ffd84a"))
	_you_label = _row(_you, _you_avatar)
	_you.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_you.offset_left = 18
	_you.offset_top = -30
	_turn = _make_panel("Turn")
	_turn_label = UiStyle.bold(UiStyle.label("Turn 1", 20))
	_turn.add_child(_turn_label)
	_turn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_turn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_turn.offset_right = -18
	_turn.offset_top = 12
	end_turn_button = Button.new()
	end_turn_button.name = "EndTurn"
	end_turn_button.text = "END TURN"
	end_turn_button.add_theme_font_size_override("font_size", 22)
	for st: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := UiStyle.panel(Palette.GOLD if st != "disabled" else Color("#c8c0a8"), 14)
		sb.shadow_offset = Vector2(0, 5) if st != "pressed" else Vector2(0, 1)
		sb.shadow_color = Palette.INK
		if st == "hover":
			sb.bg_color = Palette.GOLD.lightened(0.15)
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		sb.content_margin_left = 20
		sb.content_margin_right = 20
		end_turn_button.add_theme_stylebox_override(st, sb)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		end_turn_button.add_theme_color_override(c, Palette.INK)
	end_turn_button.add_theme_color_override("font_disabled_color", Color(Palette.INK, 0.5))
	end_turn_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	end_turn_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	end_turn_button.offset_right = -18
	end_turn_button.offset_top = -28
	end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	add_child(_rival)
	add_child(_you)
	add_child(_turn)
	add_child(end_turn_button)


func panels() -> Array[Control]:
	return [_rival, _you, _turn, end_turn_button]


func refresh(s: GameState, human: int) -> void:
	var me: GameState.PlayerState = s.players[human]
	var foe: GameState.PlayerState = s.players[s.opponent(human)]
	_rival_label.text = "Rival   ♥ %d   ✦ %d   ✋ %d   ▤ %d" % [foe.hero_hp, foe.magic, foe.hand.size(), foe.deck.size()]
	_you_label.text = "You   ♥ %d   ✦ %d/%d   ▤ %d" % [me.hero_hp, me.magic, me.magic_cap, me.deck.size()]
	_turn_label.text = "Turn %d" % s.turn
	var mine: bool = s.active == human and s.phase != GameState.Phase.OVER
	_you.modulate = Color.WHITE if mine else Color(1, 1, 1, 0.85)
	_rival.modulate = Color.WHITE if not mine else Color(1, 1, 1, 0.85)


func set_input_enabled(on: bool) -> void:
	end_turn_button.disabled = not on


## Shake a hero panel when that hero takes damage.
func shake_hero(human_side: bool) -> void:
	var p: Control = _you if human_side else _rival
	var base: Vector2 = p.position
	var tw := create_tween()
	for i: int in 6:
		tw.tween_property(p, "position", base + Vector2(randf_range(-6, 6), randf_range(-3, 3)), 0.04)
	tw.tween_property(p, "position", base, 0.05)


func hero_screen_pos(human_side: bool) -> Vector2:
	var p: Control = _you if human_side else _rival
	return p.get_global_rect().get_center()


func _make_panel(n: String) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.name = n
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_theme_stylebox_override("panel", UiStyle.panel())
	return pc


func _avatar(c: Color) -> Panel:
	var a := Panel.new()
	a.custom_minimum_size = Vector2(36, 36)
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.border_color = Palette.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	a.add_theme_stylebox_override("panel", sb)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


func _row(pc: PanelContainer, avatar: Panel) -> Label:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(avatar)
	var l := UiStyle.bold(UiStyle.label("", 20))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	pc.add_child(hb)
	return l
