class_name Hud
extends Control
## Screen layout: hero corners (portrait, health bar, magic), the magic gems and a brass END TURN
## button bottom-right (it says how many creatures can still act), and a pause button; the slim
## hand (Hand) peeks up along the bottom, so nothing covers the board. Deck and discard are
## card piles on the table (CardStacks); pile_screen tells the HUD where they are on screen. Living board:
## an armour shield at the tip of each health bar, tribe-bonus chips under each corner and the
## field in play at the top centre.

signal end_turn_pressed
signal menu_requested
signal pause_changed(open: bool)

## The strip along the bottom edge the hand peeks into; the board stays above it.
const HAND_STRIP_H := 124.0
const END_TURN_SIZE := Vector2(200, 70)
const GEMS_PLATE := Vector2(204, 46)
const MARGIN := 12.0
const CORNER := Vector2(236, 120)
## Hero health bar size (it sits on top of the corner and runs toward the centre).
const BAR := Vector2(300, 30)
## Tribe chip colours.
const TRIBE_COLORS: Dictionary = {
	&"beast": Color("#c2702e"), &"flyer": Color("#3a8ad6"), &"blob": Color("#d0479a"),
	&"sprout": Color("#4a9a3a"), &"spirit": Color("#7a4de0"),
}

var end_turn_button: Button
var pause_button: Button
var _you: Control
var _rival: Control
var _you_bar: Control
var _rival_bar: Control
var _gems_plate: Panel
## Callable(player: int, kind: StringName) -> Vector2: a card pile's screen point (set by the
## match); flying cards start and end there.
var pile_screen: Callable
var _refs: Dictionary = {}
var _gems: MagicGems
## END TURN pulses when nothing else is left to do.
var end_turn_pulsing: bool = false
var _pulse: Tween
## Full-screen pause menu. The match moves it above the hand so it takes the mouse first.
var pause_overlay: Control
## QUIT TO MENU (online: LEAVE MATCH, which asks first through LEAVE / STAY).
var quit_button: Button
var leave_button: Button
var stay_button: Button
var _pause_title: Label
var _leave_confirm: Control
var _online: bool = false
## Online: the burning fuse on END TURN and the connection banner.
var _fuse: TurnFuse
var _banner: Label
const ARMOUR_COLOR := Color("#7ac8ff")
const SHIELD_ICON := "res://assets/icons/checked-shield.svg"
## "You" / "Rival" -> {"root": Control, "label": Label}
var _armour: Dictionary = {}
## "You" / "Rival" -> HBoxContainer of tribe chips
var _tribes: Dictionary = {}
var _field_chip: Label


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
	_build_bottom()
	_build_pause()
	for who: String in ["You", "Rival"]:
		_build_armour(who == "You", who)
		_build_tribe_row(who == "You", who)
	_field_chip = _plate("", Vector2(260, 30), 16)
	_field_chip.name = "FieldChip"
	_field_chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_field_chip.offset_left = -130
	_field_chip.offset_right = 130
	# Between the two health bars, clear of the rival's face.
	_field_chip.offset_top = 14
	_field_chip.offset_bottom = 44
	_field_chip.mouse_filter = Control.MOUSE_FILTER_PASS
	_field_chip.visible = false
	add_child(_field_chip)
	_banner = _plate("", Vector2(460, 34), 17)
	_banner.name = "Banner"
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -230
	_banner.offset_right = 230
	_banner.offset_top = 52
	_banner.offset_bottom = 86
	_banner.visible = false
	add_child(_banner)


func panels() -> Array[Control]:
	return [_you, _rival, _you_bar, _rival_bar, _gems_plate, end_turn_button, pause_button]


func refresh(s: GameState, human: int) -> void:
	_fill_corner("You", s.players[human], "TURN %d" % s.turn)
	var foe: GameState.PlayerState = s.players[s.opponent(human)]
	_fill_corner("Rival", foe, "%d CARDS" % foe.hand.size())
	var me: GameState.PlayerState = s.players[human]
	_gems.set_magic(me.magic, me.max_magic)
	var mine: bool = s.active == human and s.phase != GameState.Phase.OVER
	var st: Dictionary = end_turn_state(s, human)
	end_turn_button.text = st["text"]
	end_turn_button.add_theme_font_size_override("font_size", st["font"])
	_you.modulate = Color.WHITE if mine else Color(0.82, 0.82, 0.82)
	_rival.modulate = Color.WHITE if not mine else Color(0.82, 0.82, 0.82)
	_you_bar.modulate = _you.modulate
	_rival_bar.modulate = _rival.modulate
	for q: int in 2:
		var who: String = "You" if q == human else "Rival"
		_fill_armour(who, s.players[q].armour)
		_fill_tribes(who, s, q)
	_fill_field(s)


## END TURN's face: "RIVAL'S TURN" on the AI's turn; "END TURN" plus "N CAN ACT" while N of
## your creatures can still attack or boop.
static func end_turn_state(s: GameState, human: int) -> Dictionary:
	if s.active != human or s.phase != GameState.Phase.MAIN:
		return {"text": "RIVAL'S TURN" if s.phase != GameState.Phase.OVER else "END TURN", "font": 20, "can_act": 0}
	var n: int = 0
	for l: int in GameState.LANES:
		if Rules.can_attack(s, human, l) or Rules.can_boop(s, human, l):
			n += 1
	if n > 0:
		return {"text": "END TURN\n%d CAN ACT" % n, "font": 20, "can_act": n}
	return {"text": "END TURN", "font": 28, "can_act": 0}


## Pops the armour shield (gained armour).
func flash_armour(human_side: bool) -> void:
	var root: Control = _armour["You" if human_side else "Rival"]["root"]
	root.pivot_offset = root.size / 2.0
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector2.ONE * 1.4, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(root, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func armour_visible(human_side: bool) -> bool:
	return (_armour["You" if human_side else "Rival"]["root"] as Control).visible


func tribe_chips(human_side: bool) -> Array[String]:
	var out: Array[String] = []
	for c: Node in (_tribes["You" if human_side else "Rival"] as Node).get_children():
		out.append((c as Label).text)
	return out


func field_text() -> String:
	return _field_chip.text if _field_chip.visible else ""


func _build_armour(left: bool, who: String) -> void:
	var root := Control.new()
	root.name = who + "Armour"
	root.size = Vector2(44, 44)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.tooltip_text = Keywords.RULES[&"armour"]
	var icon := TextureRect.new()
	icon.texture = load(SHIELD_ICON) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = root.size
	icon.modulate = ARMOUR_COLOR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)
	var n := UiStyle.title(UiStyle.label("0", 18, Color.WHITE)) as Label
	n.size = root.size
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.add_theme_color_override("font_outline_color", Color("#1a3a66"))
	n.add_theme_constant_override("outline_size", 8)
	root.add_child(n)
	# At the inner tip of the health bar.
	if left:
		root.position = Vector2(12 + 112 + BAR.x - 10, 7)
	else:
		root.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		root.offset_left = -(12 + 112 + BAR.x + 34)
		root.offset_right = root.offset_left + 44
		root.offset_top = 7
		root.offset_bottom = 51
	root.visible = false
	add_child(root)
	_armour[who] = {"root": root, "label": n}


func _fill_armour(who: String, armour: int) -> void:
	var a: Dictionary = _armour[who]
	(a["root"] as Control).visible = armour > 0
	(a["label"] as Label).text = str(armour)


func _build_tribe_row(left: bool, who: String) -> void:
	var row := HBoxContainer.new()
	row.name = who + "Tribes"
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if left:
		row.position = Vector2(14, 10 + CORNER.y + 6)
	else:
		row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		row.alignment = BoxContainer.ALIGNMENT_END
		row.offset_left = -CORNER.x - 12 - 200
		row.offset_right = -14
		row.offset_top = 10 + CORNER.y + 6
	add_child(row)
	_tribes[who] = row


## One chip per tribe bonus that is on: "PACK +1 ATK" style, with the rule as tooltip.
func _fill_tribes(who: String, s: GameState, p: int) -> void:
	var row: HBoxContainer = _tribes[who]
	var want: Array[Array] = []
	for tribe: StringName in Tribes.ORDER:
		var tier: int = Tribes.tier(s, p, tribe)
		if tier > 0:
			want.append([tribe, tier])
	var key: String = str(want)
	if row.get_meta(&"key", "") == key:
		return
	row.set_meta(&"key", key)
	for c: Node in row.get_children():
		c.free()
	for w: Array in want:
		var tribe: StringName = w[0]
		var chip := UiStyle.title(UiStyle.label("%s %s" % [Tribes.BONUS[tribe].to_upper(), "I" if w[1] == 1 else "II"], 13, Color.WHITE)) as Label
		chip.add_theme_color_override("font_outline_color", UiStyle.WOOD_INK)
		chip.add_theme_constant_override("outline_size", 5)
		chip.custom_minimum_size = Vector2(0, 24)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var sb := _frame(TRIBE_COLORS.get(tribe, UiStyle.WOOD_DARK), 10, 3)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		chip.add_theme_stylebox_override("normal", sb)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.tooltip_text = "%s (%d %s): %s" % [Tribes.BONUS[tribe], Tribes.count(s, p, tribe), Tribes.PLURALS[tribe], Tribes.bonus_text(tribe, w[1])]
		row.add_child(chip)
		chip.pivot_offset = Vector2(30, 12)
		chip.scale = Vector2.ONE * 0.3
		chip.create_tween().tween_property(chip, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fill_field(s: GameState) -> void:
	_field_chip.visible = s.field != null
	if s.field:
		_field_chip.text = "FIELD: %s" % s.field.display_name.to_upper()
		_field_chip.tooltip_text = CardText.render(s.field)
		_field_chip.add_theme_stylebox_override("normal", _frame(Palette.LAND_CARD[s.field.land].darkened(0.25), 12, 3))


func set_end_turn_pulse(on: bool) -> void:
	if on == end_turn_pulsing:
		return
	end_turn_pulsing = on
	if _pulse:
		_pulse.kill()
	end_turn_button.pivot_offset = end_turn_button.size / 2.0
	end_turn_button.scale = Vector2.ONE
	if on:
		_pulse = end_turn_button.create_tween().set_loops()
		_pulse.tween_property(end_turn_button, "scale", Vector2.ONE * 1.07, 0.45).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(end_turn_button, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func is_paused() -> bool:
	return pause_overlay.visible


func close_pause() -> void:
	pause_overlay.visible = false
	_leave_confirm.visible = false
	pause_changed.emit(false)


func _open_pause() -> void:
	pause_overlay.visible = true
	pause_changed.emit(true)


## Open or close the menu (II button, Esc).
func toggle_pause() -> void:
	if is_paused():
		close_pause()
	else:
		_open_pause()


## Online match: the rival's name in their corner; the menu can't pause, and leaving asks first.
func set_online(rival_name: String) -> void:
	_online = true
	var nm: Label = _refs["Rival"]["name"]
	nm.text = rival_name.to_upper()
	if nm.text.length() > 7:
		nm.add_theme_font_size_override("font_size", 13)
	_pause_title.text = "Menu"
	quit_button.text = "LEAVE MATCH"


func rival_name_text() -> String:
	return (_refs["Rival"]["name"] as Label).text


func pause_title_text() -> String:
	return _pause_title.text


func leave_confirm_visible() -> bool:
	return _leave_confirm.visible


## Seconds left in the turn while the fuse should show; below 0 hides it.
func set_fuse(seconds_left: float, fuse_seconds: float = 15.0) -> void:
	if seconds_left < 0.0:
		_fuse.visible = false
	else:
		_fuse.show_left(seconds_left, fuse_seconds)


func fuse_visible() -> bool:
	return _fuse.visible


## A line across the top ("Rival disconnected — waiting 0:41"); "" hides it.
func set_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = text != ""


func banner_text() -> String:
	return _banner.text if _banner.visible else ""


## END TURN follows whether the local player may act; the menu button always works.
func set_input_enabled(on: bool) -> void:
	end_turn_button.disabled = not on


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


func deck_screen_pos(human_side: bool = true) -> Vector2:
	if pile_screen.is_valid():
		return pile_screen.call(0 if human_side else 1, &"deck")
	return get_viewport_rect().size * Vector2(0.85, 0.75)


func discard_screen_pos(human_side: bool = true) -> Vector2:
	if pile_screen.is_valid():
		return pile_screen.call(0 if human_side else 1, &"discard")
	return get_viewport_rect().size * Vector2(0.85, 0.6)


## Centre of the magic orb that a gained gem flies to.
func orb_screen_pos(human_side: bool) -> Vector2:
	if human_side:
		return _gems.get_global_rect().get_center()
	return (_refs["Rival"]["orb"] as Control).get_global_rect().get_center()


## The hero corner: dropping an attack here targets that hero.
func hero_rect(human_side: bool) -> Rect2:
	return (_you if human_side else _rival).get_global_rect()


func hero_screen_pos(human_side: bool) -> Vector2:
	return (_you if human_side else _rival).get_global_rect().get_center()


# --- Building blocks ---------------------------------------------------------

func _frame(bg: Color, radius: int = 16, border: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = UiStyle.WOOD_INK
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	return sb


func _plate(text: String, size_: Vector2, font: int = 16) -> Label:
	var l := UiStyle.title(UiStyle.label(text, font, Color.WHITE)) as Label
	l.size = size_
	l.custom_minimum_size = size_
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_stylebox_override("normal", _frame(UiStyle.WOOD_DARK, 10, 3))
	return l


func _orb(diameter: float, font: int) -> Label:
	var l := UiStyle.title(UiStyle.label("0", font, Color.WHITE)) as Label
	l.size = Vector2(diameter, diameter)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", UiStyle.WOOD_INK)
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
	back.add_theme_stylebox_override("panel", _wood(18))
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
	var nm := UiStyle.title(UiStyle.label(who.to_upper(), 18, UiStyle.PARCHMENT)) as Label
	nm.position = Vector2(160, 54) if left else Vector2(8, 54)
	nm.size = Vector2(68, 26)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	c.add_child(nm)
	var plate := _plate("", Vector2(116, 24), 14)
	plate.position = Vector2(112, 92) if left else Vector2(8, 92)
	c.add_child(plate)
	_refs[who] = {"orb": orb, "plate": plate, "name": nm}
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
	bar.add_theme_stylebox_override("background", _frame(UiStyle.WOOD_INK, 10, 3))
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
	hp.add_theme_color_override("font_outline_color", UiStyle.WOOD_INK)
	hp.add_theme_constant_override("outline_size", 7)
	bar.add_child(hp)
	_refs[who + "Bar"] = {"bar": bar, "hp": hp}
	return bar


func _fill_corner(who: String, ps: GameState.PlayerState, plate_text: String) -> void:
	var r: Dictionary = _refs[who]
	(r["orb"] as Label).text = str(ps.magic) if who == "You" else "%d/%d" % [ps.magic, ps.max_magic]
	(r["plate"] as Label).text = plate_text
	var b: Dictionary = _refs[who + "Bar"]
	(b["bar"] as ProgressBar).value = clampi(ps.hero_hp, 0, GameState.MAX_HP)
	(b["hp"] as Label).text = "♥ %d" % ps.hero_hp


## Wood with a lighter top edge, like a polished board.
func _wood(radius: int = 16, col: Color = UiStyle.WOOD) -> StyleBoxFlat:
	var sb := _frame(col, radius, 4)
	sb.border_color = UiStyle.WOOD_INK
	sb.shadow_color = Color(UiStyle.WOOD_INK, 0.45)
	sb.shadow_offset = Vector2(0, 4)
	sb.shadow_size = 2
	return sb


## Magic gems on a wooden plate over the brass END TURN button, bottom-right.
func _build_bottom() -> void:
	_gems_plate = Panel.new()
	_gems_plate.name = "GemsPlate"
	_gems_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gems_plate.add_theme_stylebox_override("panel", _wood(12, UiStyle.WOOD_DARK))
	_gems_plate.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_gems_plate.offset_right = -MARGIN
	_gems_plate.offset_left = -MARGIN - GEMS_PLATE.x
	_gems_plate.offset_bottom = -MARGIN - END_TURN_SIZE.y - 8
	_gems_plate.offset_top = _gems_plate.offset_bottom - GEMS_PLATE.y
	add_child(_gems_plate)
	_gems = MagicGems.new()
	_gems.position = Vector2(-4, 0)
	_gems_plate.add_child(_gems)
	end_turn_button = Button.new()
	end_turn_button.name = "EndTurn"
	end_turn_button.text = "END TURN"
	end_turn_button.add_theme_font_size_override("font_size", 28)
	UiStyle.title(end_turn_button)
	for st: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var col: Color = UiStyle.BRASS
		match st:
			"hover":
				col = UiStyle.BRASS.lightened(0.18)
			"pressed":
				col = UiStyle.BRASS_DARK
			"disabled":
				col = Color("#8f8478")
		var b := _frame(col, 22, 5)
		b.border_color = UiStyle.WOOD_INK
		b.shadow_color = Color(UiStyle.WOOD_INK, 0.5)
		b.shadow_offset = Vector2(0, 5) if st != "pressed" else Vector2(0, 2)
		b.shadow_size = 2
		end_turn_button.add_theme_stylebox_override(st, b)
	for col: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		end_turn_button.add_theme_color_override(col, Color.WHITE)
	end_turn_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7))
	end_turn_button.add_theme_color_override("font_outline_color", UiStyle.WOOD_INK)
	end_turn_button.add_theme_constant_override("outline_size", 10)
	end_turn_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	end_turn_button.offset_right = -MARGIN
	end_turn_button.offset_left = -MARGIN - END_TURN_SIZE.x
	end_turn_button.offset_bottom = -MARGIN
	end_turn_button.offset_top = -MARGIN - END_TURN_SIZE.y
	end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	UiStyle.sound_button(end_turn_button)
	add_child(end_turn_button)
	_fuse = TurnFuse.new()
	_fuse.name = "TurnFuse"
	_fuse.position = Vector2(0, -11)
	_fuse.size = Vector2(END_TURN_SIZE.x, 22)
	end_turn_button.add_child(_fuse)


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
	box.add_theme_stylebox_override("panel", UiStyle.parchment_panel(22))
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
	_pause_title = title
	var settings := SettingsPanel.make(false)
	settings.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	vb.add_child(settings)
	var resume := MenuButtons.big("RESUME", Palette.GOLD)
	resume.pressed.connect(close_pause)
	vb.add_child(resume)
	quit_button = MenuButtons.big("QUIT TO MENU", Color.WHITE)
	quit_button.pressed.connect(func() -> void:
		if _online:
			_leave_confirm.visible = true
		else:
			menu_requested.emit())
	vb.add_child(quit_button)
	_leave_confirm = VBoxContainer.new()
	_leave_confirm.add_theme_constant_override("separation", 8)
	_leave_confirm.visible = false
	var ask := UiStyle.label("Leaving gives your rival the win — leave?", 16)
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.custom_minimum_size = Vector2(320, 0)
	_leave_confirm.add_child(ask)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	leave_button = MenuButtons.big("LEAVE", Palette.HP, 18)
	leave_button.pressed.connect(func() -> void: menu_requested.emit())
	stay_button = MenuButtons.big("STAY", Palette.GOLD, 18)
	stay_button.pressed.connect(func() -> void: _leave_confirm.visible = false)
	row.add_child(leave_button)
	row.add_child(stay_button)
	_leave_confirm.add_child(row)
	vb.add_child(_leave_confirm)
	add_child(pause_overlay)
	pause_button.pressed.connect(_open_pause)
