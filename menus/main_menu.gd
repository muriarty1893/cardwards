extends Node3D
## Title screen over the table in the cottage, the camera drifting gently from the player's side:
## pick a deck and difficulty, then play.

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
var _ui_root: Control


func _ready() -> void:
	var room := Room.new()
	add_child(room)
	room.build(Settings.quality)
	var rival := RivalSeat.new()
	add_child(rival)
	rival.setup(MatchController.RIVAL_MODEL)
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
	Outline.attach(_cam)
	_build_ui()
	Audio.music(GameAudio.MENU_MUSIC)


func _process(delta: float) -> void:
	_t += delta * 0.12
	_cam.look_at_from_position(Vector3(sin(_t) * 7.0, 11.0 + sin(_t * 0.7) * 1.0, 20.0), Vector3(sin(_t) * 2.0, 1.5, -5.0))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_ui_root = root
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	root.add_child(vb)
	var title := UiStyle.title(UiStyle.label("Dream Isles", 84, Color.WHITE)) as Label
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
		btn.name = "Deck_%s" % d.id
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(200, 214)
		btn.text = "%s\n%s + %s\n%s" % [d.display_name, CardData.LAND_NAMES[d.lands[0]], CardData.LAND_NAMES[d.lands[2]], FLAVOUR.get(d.id, "")]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 14)
		btn.icon = load(VisualDB.art_path(_champion(d))) as Texture2D
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.expand_icon = false
		btn.add_theme_constant_override("icon_max_width", 160)
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
		UiStyle.sound_button(btn)
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
	var settings := MenuButtons.big("SETTINGS", Color.WHITE, 20)
	settings.pressed.connect(func() -> void: _open_panel(SettingsPanel.make()))
	row.add_child(settings)
	var credits := MenuButtons.big("CREDITS", Color.WHITE, 20)
	credits.pressed.connect(func() -> void: _open_panel(CreditsPanel.make()))
	row.add_child(credits)
	# A browser tab cannot be closed from inside the page.
	if not OS.has_feature("web"):
		var quit := MenuButtons.big("QUIT", Color.WHITE, 20)
		quit.pressed.connect(func() -> void: get_tree().quit())
		row.add_child(quit)
	_select_deck(Session.player_deck)
	_select_difficulty(Session.difficulty)
	play.grab_focus()


## The deck's showcase creature: its highest-level creature, first in card order.
static func _champion(d: DeckData) -> StringName:
	var best: CardData = null
	for c: CardData in d.cards:
		if c.is_creature() and (best == null or c.level > best.level):
			best = c
	return best.id if best else d.cards[0].id


## Shows a Settings or Credits panel centred over a dimmed menu; its `closed` signal hides it.
func _open_panel(panel: PanelContainer) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	center.add_child(panel)
	panel.connect("closed", dim.queue_free)


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
