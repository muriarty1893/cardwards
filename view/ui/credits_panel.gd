class_name CreditsPanel
extends PanelContainer
## Scrollable list of every third-party asset, read from res://assets/CREDITS.md.

signal closed

const SOURCE := "res://assets/CREDITS.md"


static func make() -> CreditsPanel:
	var p := CreditsPanel.new()
	p.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 1, 1, 0.97), 22))
	p.custom_minimum_size = Vector2(760, 520)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var title := UiStyle.title(UiStyle.label("Credits", 40)) as Label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var text := RichTextLabel.new()
	text.name = "Text"
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(720, 400)
	text.add_theme_color_override("default_color", Palette.INK)
	text.add_theme_font_size_override("normal_font_size", 15)
	text.text = FileAccess.get_file_as_string(SOURCE)
	vb.add_child(text)
	var close := MenuButtons.big("CLOSE", Palette.GOLD, 20)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void: p.closed.emit())
	vb.add_child(close)
	return p


func text() -> String:
	return (find_child("Text", true, false) as RichTextLabel).text
