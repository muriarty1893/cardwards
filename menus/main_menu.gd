extends Node3D
## Title screen over a slowly orbiting board: pick a deck and difficulty, then play.

const FLAVOUR: Dictionary = {
	&"grove_guard": "Outlast them with healing.",
	&"blaze_rush": "Burn fast, hit hard.",
	&"sugar_storm": "Draw, trick, overwhelm.",
	&"deep_freeze": "Lock the board down.",
}

var _cam: Camera3D
var _t: float = 0.0
var _deck_buttons: Dictionary = {}
var _diff_buttons: Array[Button] = []


func _ready() -> void:
	var board := Board.new()
	add_child(board)
	var a: Array[int] = [0, 1, 2, 3]
	var b: Array[int] = [3, 2, 1, 0]
	board.build([a, b])
	var demo: Array[StringName] = [&"elder_shroomhulk", &"inferno_drake", &"bonbon_behemoth", &"blizzard_titan"]
	for l: int in 4:
		var v := CreatureView.create(CardDB.card(demo[l]))
		add_child(v)
		v.position = board.anchor(l % 2, l)
	_cam = Camera3D.new()
	_cam.fov = 45.0
	add_child(_cam)
	_cam.make_current()
	_build_ui()


func _process(delta: float) -> void:
	_t += delta * 0.12
	_cam.look_at_from_position(Vector3(sin(_t) * 12.0, 7.5, cos(_t) * 12.0 - 0.6), Vector3(0, 0, -0.6))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	root.add_child(vb)
	var title := UiStyle.bold(UiStyle.label("Dream Isles", 76, Color.WHITE))
	title.add_theme_color_override("font_outline_color", Palette.INK)
	title.add_theme_constant_override("outline_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var decks := HBoxContainer.new()
	decks.alignment = BoxContainer.ALIGNMENT_CENTER
	decks.add_theme_constant_override("separation", 14)
	vb.add_child(decks)
	for d: DeckData in CardDB.all_decks():
		var btn := Button.new()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(190, 120)
		btn.text = "%s\n%s + %s\n%s" % [d.display_name, CardData.LAND_NAMES[d.lands[0]], CardData.LAND_NAMES[d.lands[2]], FLAVOUR.get(d.id, "")]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 15)
		var base: Color = Palette.LAND_CARD[d.lands[0]]
		for st: String in ["normal", "hover", "pressed", "focus"]:
			var sb := UiStyle.panel(base.lerp(Color.WHITE, 0.55) if st == "normal" else (base.lerp(Color.WHITE, 0.3) if st == "hover" else base), 16)
			if st == "pressed":
				sb.set_border_width_all(6)
			if st == "focus":
				sb.draw_center = false
				sb.border_color = Palette.MAGIC
			btn.add_theme_stylebox_override(st, sb)
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			btn.add_theme_color_override(c, Palette.INK)
		btn.pressed.connect(_select_deck.bind(d.id))
		decks.add_child(btn)
		_deck_buttons[d.id] = btn
	var diff := HBoxContainer.new()
	diff.alignment = BoxContainer.ALIGNMENT_CENTER
	diff.add_theme_constant_override("separation", 8)
	vb.add_child(diff)
	for i: int in 3:
		var b := MenuButtons.big(["Easy", "Medium", "Hard"][i], Color.WHITE, 18)
		b.toggle_mode = true
		var on := UiStyle.panel(Palette.MAGIC.lightened(0.3), 14)
		b.add_theme_stylebox_override("pressed", on)
		b.pressed.connect(_select_difficulty.bind(i))
		diff.add_child(b)
		_diff_buttons.append(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)
	var play := MenuButtons.big("PLAY", Palette.GOLD, 30)
	play.custom_minimum_size = Vector2(200, 0)
	play.pressed.connect(_play)
	row.add_child(play)
	var quit := MenuButtons.big("QUIT", Color.WHITE, 20)
	quit.pressed.connect(func() -> void: get_tree().quit())
	row.add_child(quit)
	_select_deck(Session.player_deck)
	_select_difficulty(Session.difficulty)
	play.grab_focus()


func _select_deck(id: StringName) -> void:
	Session.player_deck = id
	for k: StringName in _deck_buttons:
		(_deck_buttons[k] as Button).set_pressed_no_signal(k == id)


func _select_difficulty(i: int) -> void:
	Session.difficulty = i as AIPlayer.Difficulty
	for j: int in 3:
		_diff_buttons[j].set_pressed_no_signal(j == i)


func _play() -> void:
	get_tree().change_scene_to_file("res://view/match.tscn")
