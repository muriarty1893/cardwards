class_name DiscardViewer
extends Control
## A parchment panel listing a discard pile's cards (newest first), with a close button.
## Opened by clicking a discard pile on the table.

signal closed

var _grid: GridContainer
var _title: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb and mb.pressed:
			close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.parchment_panel(22))
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	_title = UiStyle.title(UiStyle.label("Discard pile", 30, UiStyle.WOOD_INK)) as Label
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	var close_b := MenuButtons.big("CLOSE", Palette.GOLD, 20)
	close_b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_b.pressed.connect(close)
	vb.add_child(close_b)


func show_cards(cards: Array[CardData], title: String = "Discard pile") -> void:
	_title.text = "%s (%d)" % [title, cards.size()]
	for c: Node in _grid.get_children():
		c.free()
	for i: int in range(cards.size() - 1, -1, -1):
		var holder := Control.new()
		holder.custom_minimum_size = CardWidget.SIZE
		var w := CardWidget.new()
		w.setup(cards[i], i)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(w)
		_grid.add_child(holder)
	if cards.is_empty():
		_grid.add_child(UiStyle.label("Empty.", 20, UiStyle.WOOD_INK))


func card_count() -> int:
	return _grid.get_children().filter(func(n: Node) -> bool: return n.get_child_count() > 0 and n.get_child(0) is CardWidget).size()


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and k.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
