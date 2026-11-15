class_name SettingsPanel
extends PanelContainer
## Music and effects volume sliders and a graphics quality choice. Every change goes
## straight to the Settings autoload (which saves it).

signal closed

var music_slider: HSlider
var sfx_slider: HSlider
var quality_option: OptionButton


## `with_close` adds a CLOSE button (the pause menu embeds the panel without one).
static func make(with_close: bool = true) -> SettingsPanel:
	var p := SettingsPanel.new()
	p.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 1, 1, 0.97), 22))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var title := UiStyle.title(UiStyle.label("Settings", 32)) as Label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	p.music_slider = p._slider(vb, "Music", Settings.music_volume, &"music_volume")
	p.sfx_slider = p._slider(vb, "Effects", Settings.sfx_volume, &"sfx_volume")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	var ql := UiStyle.title(UiStyle.label("Graphics", 20)) as Label
	ql.custom_minimum_size = Vector2(110, 0)
	row.add_child(ql)
	p.quality_option = OptionButton.new()
	p.quality_option.add_item("High", GameSettings.Quality.HIGH)
	p.quality_option.add_item("Low", GameSettings.Quality.LOW)
	p.quality_option.select(int(Settings.quality))
	p.quality_option.custom_minimum_size = Vector2(200, 36)
	p.quality_option.item_selected.connect(func(i: int) -> void: Settings.set_value(&"quality", i))
	row.add_child(p.quality_option)
	if with_close:
		var close := MenuButtons.big("CLOSE", Palette.GOLD, 20)
		close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		close.pressed.connect(func() -> void: p.closed.emit())
		vb.add_child(close)
	return p


func _slider(parent: Container, label: String, value: float, key: StringName) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var l := UiStyle.title(UiStyle.label(label, 20)) as Label
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(200, 32)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v: float) -> void: Settings.set_value(key, v))
	row.add_child(s)
	return s
