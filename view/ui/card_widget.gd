class_name CardWidget
extends Control
## A 120x168 card face for the hand.

const SIZE := Vector2(120, 168)
const ICONS: Dictionary = {
	&"sporeling": "🍄", &"mossback": "🐢", &"puffcap": "🌼", &"glimmer_morel": "✨", &"rootstalker": "🌳",
	&"elder_shroomhulk": "👑", &"spore_hut": "🛖", &"glowcap_lantern": "🏮", &"rain_of_spores": "🌧", &"regrowth": "🌱",
	&"cinderpup": "🐶", &"ashmite": "🪲", &"flarebeak": "🐦", &"magmaw": "👹", &"blazehorn": "🐗",
	&"inferno_drake": "🐉", &"kiln_tower": "🏭", &"smokestack": "🗼", &"fireball": "☄", &"ember_rain": "🔥",
	&"gumdrop": "🍬", &"taffy_snail": "🐌", &"lollibat": "🦇", &"sugar_sprite": "🧚", &"jellywobble": "🪼",
	&"bonbon_behemoth": "🍩", &"sugar_shack": "🏠", &"candy_mill": "🎡", &"sugar_rush": "🍭", &"swap_trick": "🔀",
	&"snowmite": "⛄", &"iceling": "🧊", &"frostfang": "🐺", &"glacier_tortoise": "🐢", &"rimewing": "🦋",
	&"blizzard_titan": "🗿", &"ice_wall": "🧱", &"frost_spire": "🏔", &"cold_snap": "❄", &"avalanche": "🌨",
}
const KIND_NAMES: Array[String] = ["creature", "building", "spell"]

var card: CardData
var index: int = -1
var _face: Panel
var _tip: PanelContainer


func setup(c: CardData, i: int) -> void:
	card = c
	index = i
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2(SIZE.x / 2.0, SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_face = Panel.new()
	_face.size = SIZE
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiStyle.panel(Palette.PAPER, 12)
	_face.add_theme_stylebox_override("panel", sb)
	add_child(_face)
	var art := Panel.new()
	art.position = Vector2(9, 10)
	art.size = Vector2(SIZE.x - 18, 62)
	var asb := StyleBoxFlat.new()
	asb.bg_color = Palette.LAND_CARD[c.land]
	asb.set_corner_radius_all(8)
	art.add_theme_stylebox_override("panel", asb)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(art)
	var icon := UiStyle.label(ICONS.get(c.id, "?"), 34)
	icon.size = art.size
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art.add_child(icon)
	var name_l := UiStyle.bold(UiStyle.label(c.display_name, 12 if c.display_name.length() > 13 else 13))
	name_l.position = Vector2(4, 74)
	name_l.size = Vector2(SIZE.x - 8, 20)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	_face.add_child(name_l)
	var kind := UiStyle.label(KIND_NAMES[c.kind].to_upper() + ("  L%d" % c.level if c.is_creature() else ""), 10, Color("#667777"))
	kind.position = Vector2(4, 93)
	kind.size = Vector2(SIZE.x - 8, 14)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_face.add_child(kind)
	if c.is_creature():
		var atk := UiStyle.bold(UiStyle.label("⚔%d" % c.attack, 17))
		atk.position = Vector2(10, 136)
		_face.add_child(atk)
		var hp := UiStyle.bold(UiStyle.label("♥%d" % c.health, 17, Palette.HP))
		hp.position = Vector2(SIZE.x - 46, 136)
		_face.add_child(hp)
	else:
		var tx := UiStyle.label(c.text, 9, Palette.INK)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tx.clip_text = false
		tx.custom_minimum_size = Vector2(SIZE.x - 16, 0)
		_face.add_child(tx)
		tx.position = Vector2(8, 108)
		tx.size = Vector2(SIZE.x - 16, 54)
	var cost := Panel.new()
	cost.position = Vector2(-6, -6)
	cost.size = Vector2(30, 30)
	var csb := StyleBoxFlat.new()
	csb.bg_color = Palette.MAGIC
	csb.border_color = Palette.INK
	csb.set_border_width_all(3)
	csb.set_corner_radius_all(15)
	cost.add_theme_stylebox_override("panel", csb)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := UiStyle.bold(UiStyle.label(str(c.cost), 16, Color.WHITE))
	cl.size = cost.size
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.add_child(cl)
	add_child(cost)
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 1, 1, 0.97), 10))
	var tl := UiStyle.label("%s\n%s" % [c.display_name, c.text if c.text != "" else "No ability."], 14)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(200, 0)
	_tip.add_child(tl)
	_tip.position = Vector2(-40, -110)
	_tip.visible = false
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tip)


func set_playable(on: bool) -> void:
	modulate = Color.WHITE if on else Color(0.72, 0.72, 0.72, 1.0)


func show_tip(on: bool) -> void:
	_tip.visible = on and card.text != ""
