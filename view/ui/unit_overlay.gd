class_name UnitOverlay
extends Control
## Screen-space info that follows the pieces on the board: an attack number and a health bar
## above each creature, a badge on each building and an enlarged card when the mouse hovers a piece. It also sets
## the human's boop plates (on the board) lit or dim. Values come from the game state.

const BAR_SIZE := Vector2(110, 40)
const GREEN := Color("#3ad16a")
const YELLOW := Color("#ffcf3a")
const RED := Color("#e5384f")
const DRAIN := 0.3
## Where your building's badge sits relative to the building (front-right foot).
const BADGE_NEAR := Vector3(0.6, 0.25, 0.35)
const HOVER_SCALE := 1.6

var _m: MatchController
var _entries: Array[Array] = []
var _bars: Array[Array] = []
var _badges: Array[Array] = []
var _hover: CardWidget
var _hover_notes: KeywordNotes
var _hover_key: String = ""
## The enlarged card lives on its own layer above the HUD so nothing covers it.
var _hover_layer: CanvasLayer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p: int in 2:
		_entries.append([{}, {}, {}, {}])
		_bars.append([])
		_badges.append([])


func setup(m: MatchController) -> void:
	_m = m
	_hover_layer = CanvasLayer.new()
	_hover_layer.layer = MatchController.HUD_LAYER + 1
	add_child(_hover_layer)
	for p: int in 2:
		for l: int in 4:
			var bar := _make_bar()
			add_child(bar)
			_bars[p].append(bar)
			var badge := _make_badge()
			add_child(badge)
			_badges[p].append(badge)


func entry(p: int, l: int) -> Dictionary:
	var e: Dictionary = _entries[p][l]
	if e.is_empty():
		return {"visible": false, "atk": 0, "hp": 0, "max": 0, "bar_color": GREEN}
	return e


func hover_layer() -> CanvasLayer:
	return _hover_layer


## Screen rect for the enlarged hover card of a piece seen at `at`: beside the piece, kept in
## the board area (above `floor_y`, the tray top) and moved out of the `avoid` rects (HUD).
static func hover_rect(at: Vector2, vp: Vector2, avoid: Array[Rect2], floor_y: float) -> Rect2:
	var sz: Vector2 = CardWidget.SIZE * HOVER_SCALE
	var r := Rect2(Vector2(at.x + 60.0, at.y - sz.y / 2.0), sz)
	if r.end.x > vp.x - 4.0:
		r.position.x = at.x - 60.0 - sz.x
	r.position.x = clampf(r.position.x, 4.0, maxf(4.0, vp.x - sz.x - 4.0))
	r.position.y = clampf(r.position.y, 4.0, maxf(4.0, floor_y - sz.y - 4.0))
	for _pass: int in 3:
		var moved: bool = false
		for a: Rect2 in avoid:
			if not r.intersects(a):
				continue
			moved = true
			if a.end.y + 4.0 + sz.y <= floor_y:
				r.position.y = a.end.y + 4.0
			elif a.get_center().x < vp.x / 2.0:
				r.position.x = a.end.x + 4.0
			else:
				r.position.x = a.position.x - sz.x - 4.0
		if not moved:
			break
	return r


## LIT when the human's creature in lane l can boop right now, else DIM (HIDDEN until the board has split).
func plate_state(l: int) -> BoopPlate.State:
	if not _m.board.split_revealed:
		return BoopPlate.State.HIDDEN
	var cr: GameState.CreatureState = _m.state.players[MatchController.HUMAN].lanes[l].creature
	var lit: bool = cr != null and cr.card.has_effect(&"on_boop") and not cr.hushed and _m.input.can_boop(l) and not _m.busy
	return BoopPlate.State.LIT if lit else BoopPlate.State.DIM


static func bar_color(hp: int, max_hp: int) -> Color:
	var r: float = float(hp) / float(maxi(max_hp, 1))
	if r > 0.6:
		return GREEN
	if r >= 0.3:
		return YELLOW
	return RED


## Screen rect of a stat bar for a creature whose head is at `head` (world): centred 24 px
## above the head, kept inside the screen and moved out of any `avoid` rect (hero corners
## and their health bars).
static func bar_rect_at(cam: Camera3D, head: Vector3, avoid: Array[Rect2] = []) -> Rect2:
	var c: Vector2 = cam.unproject_position(head) - Vector2(0, 24)
	var r := Rect2(c - BAR_SIZE / 2.0, BAR_SIZE)
	var vp: Vector2 = cam.get_viewport().get_visible_rect().size
	r.position.x = clampf(r.position.x, 4.0, vp.x - BAR_SIZE.x - 4.0)
	r.position.y = clampf(r.position.y, 4.0, vp.y - BAR_SIZE.y - 4.0)
	# Wide strips (hero health bars): drop below them. Tall panels (hero corners): step
	# sideways toward the middle. Re-check, since one push can land in another rect.
	for _pass: int in 3:
		var moved: bool = false
		for a: Rect2 in avoid:
			if not r.intersects(a):
				continue
			moved = true
			if a.size.x > a.size.y * 2.0:
				r.position.y = a.end.y + 4.0
			elif a.get_center().x < vp.x / 2.0:
				r.position.x = a.end.x + 4.0
			else:
				r.position.x = a.position.x - BAR_SIZE.x - 4.0
		if not moved:
			break
	return r


func refresh(s: GameState) -> void:
	for p: int in 2:
		for l: int in 4:
			var lane: GameState.LaneState = s.players[p].lanes[l]
			var cr: GameState.CreatureState = lane.creature
			if cr == null:
				_entries[p][l] = {}
			else:
				var max_hp: int = Rules.effective_max_hp(s, p, l)
				var hp: int = max_hp - cr.damage
				_entries[p][l] = {"visible": true, "atk": Rules.effective_attack(s, p, l), "hp": hp, "max": max_hp, "bar_color": bar_color(hp, max_hp),
					"level": cr.level, "xp": cr.xp, "home": Lands.home(s, p, l)}
			_update_bar(_bars[p][l], _entries[p][l])
			var badge: Control = _badges[p][l]
			badge.visible = lane.building != null
			if lane.building:
				var icon := badge.get_node("Icon") as TextureRect
				var path: String = VisualDB.badge_icon(lane.building.id)
				icon.texture = load(path) as Texture2D if path != "" else null
	for l: int in 4:
		var st: BoopPlate.State = plate_state(l)
		if st != BoopPlate.State.HIDDEN:
			_m.board.boop_plate(l).set_state(st)


## The piece under a screen point: {"player", "lane", "kind"} or {}.
func piece_at(screen: Vector2) -> Dictionary:
	var cam: Camera3D = _m.rig.camera
	for p: int in 2:
		for l: int in 4:
			var v: Variant = _m.creature_views[p][l]
			if is_instance_valid(v) and _piece_rect(cam, (v as CreatureView).global_position, (v as CreatureView).height).has_point(screen):
				return {"player": p, "lane": l, "kind": &"creature"}
			var b: Variant = _m.building_views[p][l]
			if is_instance_valid(b) and _piece_rect(cam, (b as Node3D).global_position + Vector3(0, CreatureView.BASE_Y, 0), BuildingView.HEIGHT).has_point(screen):
				return {"player": p, "lane": l, "kind": &"building"}
	return {}


func _piece_rect(cam: Camera3D, origin: Vector3, h: float) -> Rect2:
	var feet: Vector2 = cam.unproject_position(origin + Vector3(0, Island.TOP_Y - CreatureView.BASE_Y, 0))
	var head: Vector2 = cam.unproject_position(origin + Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + h, 0))
	var tall: float = maxf(feet.y - head.y, 20.0)
	var w: float = tall * 0.9 + 20.0
	return Rect2(feet.x - w / 2.0, head.y, w, tall)


func _process(_delta: float) -> void:
	if _m == null or _m.rig == null:
		return
	var cam: Camera3D = _m.rig.camera
	for p: int in 2:
		for l: int in 4:
			var bar: Control = _bars[p][l]
			var v: Variant = _m.creature_views[p][l]
			var show: bool = bool(entry(p, l)["visible"]) and is_instance_valid(v)
			bar.visible = show
			if show:
				var cv := v as CreatureView
				bar.position = bar_rect_at(cam, cv.global_position + Vector3(0, cv.height + 0.15, 0), _m.hud.corner_rects()).position
			var badge: Control = _badges[p][l]
			var bv: Variant = _m.building_views[p][l]
			if badge.visible and is_instance_valid(bv):
				# Yours sit at the building's front-right foot so they never cover the boop plate in front of it.
				var off: Vector3 = BADGE_NEAR if p == MatchController.HUMAN else Vector3(0, BuildingView.HEIGHT + 0.25, 0)
				badge.position = cam.unproject_position((bv as Node3D).global_position + off) - badge.size / 2.0
	_hover_plates(cam)
	_update_hover()


func _update_hover() -> void:
	var hit: Dictionary = {}
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var blocked: bool = _m.input.mode != InputController.Mode.IDLE or _m.hud.is_paused() or _m.results.visible
	# No board hover over the HUD or while a hand card is enlarged (two big cards at once).
	blocked = blocked or _m.hand.hovered_rect().size != Vector2.ZERO
	for panel: Control in _m.hud.panels():
		blocked = blocked or panel.get_global_rect().has_point(mouse)
	if not blocked:
		hit = piece_at(mouse)
	var key: String = "" if hit.is_empty() else "%d:%d:%s" % [hit["player"], hit["lane"], hit["kind"]]
	if key == _hover_key:
		return
	_hover_key = key
	if _hover:
		_hover.queue_free()
		_hover = null
	if _hover_notes:
		_hover_notes.queue_free()
		_hover_notes = null
	if hit.is_empty():
		return
	var lane: GameState.LaneState = _m.state.players[hit["player"]].lanes[hit["lane"]]
	var c: CardData = lane.creature.card if hit["kind"] == &"creature" and lane.creature else lane.building
	if c == null:
		return
	_hover = CardWidget.new()
	_hover.setup(c, -1)
	_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover.pivot_offset = Vector2.ZERO
	_hover.scale = Vector2.ONE * HOVER_SCALE
	_hover_layer.add_child(_hover)
	var view: Variant = _m.creature_views[hit["player"]][hit["lane"]] if hit["kind"] == &"creature" else _m.building_views[hit["player"]][hit["lane"]]
	if not is_instance_valid(view):
		return
	var at: Vector2 = _m.rig.camera.unproject_position((view as Node3D).global_position + Vector3(0, 0.6, 0))
	_hover.position = hover_rect(at, size, _m.hud.corner_rects(), size.y - Hud.HAND_STRIP_H).position
	_hover_notes = KeywordNotes.make(c)
	if _hover_notes:
		_hover_layer.add_child(_hover_notes)
		_hover_notes.reset_size()
		_hover_notes.position = KeywordNotes.place(Rect2(_hover.position, CardWidget.SIZE * HOVER_SCALE), _hover_notes.size, size)


## The notes beside the enlarged board card, or null.
func hover_notes() -> KeywordNotes:
	return _hover_notes


# --- Widgets -----------------------------------------------------------------

func _make_bar() -> Control:
	var root := Control.new()
	root.size = BAR_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	var atk := UiStyle.title(UiStyle.label("0", 32, Color.WHITE)) as Label
	atk.name = "Atk"
	atk.position = Vector2(0, 0)
	atk.size = Vector2(36, 40)
	atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	atk.add_theme_color_override("font_outline_color", Palette.INK)
	atk.add_theme_constant_override("outline_size", 9)
	root.add_child(atk)
	var back := Panel.new()
	back.name = "Back"
	back.position = Vector2(38, 11)
	back.size = Vector2(72, 18)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1f2a2a")
	sb.border_color = Palette.INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	back.add_theme_stylebox_override("panel", sb)
	root.add_child(back)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.position = Vector2(2, 2)
	fill.size = Vector2(68, 14)
	fill.color = GREEN
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	var txt := UiStyle.title(UiStyle.label("0/0", 13, Color.WHITE)) as Label
	txt.name = "Text"
	txt.size = back.size
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.add_theme_color_override("font_outline_color", Palette.INK)
	txt.add_theme_constant_override("outline_size", 5)
	back.add_child(txt)
	# Level pill (Lv 2 / Lv 3) over the ATK number, XP pips under the bar, home-land dot after it.
	var lv := UiStyle.title(UiStyle.label("LV2", 11, Color("#3a2a00"))) as Label
	lv.name = "Level"
	lv.position = Vector2(2, -10)
	lv.size = Vector2(34, 15)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Palette.GOLD
	lsb.border_color = Palette.INK
	lsb.set_border_width_all(2)
	lsb.set_corner_radius_all(7)
	lv.add_theme_stylebox_override("normal", lsb)
	lv.visible = false
	root.add_child(lv)
	var pips := HBoxContainer.new()
	pips.name = "Pips"
	pips.position = Vector2(42, 30)
	pips.add_theme_constant_override("separation", 3)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in 2:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 5)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color("#1f2a2a")
		psb.set_corner_radius_all(2)
		pip.add_theme_stylebox_override("panel", psb)
		pips.add_child(pip)
	root.add_child(pips)
	var home := Panel.new()
	home.name = "Home"
	home.position = Vector2(112, 12)
	home.size = Vector2(16, 16)
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.visible = false
	root.add_child(home)
	return root


func _update_bar(bar: Control, e: Dictionary) -> void:
	if e.is_empty():
		return
	(bar.get_node("Atk") as Label).text = str(e["atk"])
	var level: int = e.get("level", 1)
	var lv := bar.get_node("Level") as Label
	lv.visible = level > 1
	lv.text = "LV%d" % level
	var pips := bar.get_node("Pips") as Control
	var xp: int = e.get("xp", 0)
	pips.visible = level < Levels.MAX and xp > 0
	var into: int = xp - Levels.XP_FOR[level] if level > 1 else xp
	for i: int in pips.get_child_count():
		var sb := (pips.get_child(i) as Panel).get_theme_stylebox("panel") as StyleBoxFlat
		sb.bg_color = Palette.GOLD if i < into else Color("#1f2a2a")
	var home := bar.get_node("Home") as Panel
	var land: int = e.get("home", -1)
	home.visible = land >= 0
	if land >= 0:
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Palette.LAND_CARD[land]
		hsb.border_color = Palette.INK
		hsb.set_border_width_all(2)
		hsb.set_corner_radius_all(8)
		home.add_theme_stylebox_override("panel", hsb)
	(bar.get_node("Back/Text") as Label).text = "%d/%d" % [e["hp"], e["max"]]
	var fill := bar.get_node("Back/Fill") as ColorRect
	var w: float = 68.0 * clampf(float(e["hp"]) / float(maxi(e["max"], 1)), 0.0, 1.0)
	var tw := fill.create_tween().set_parallel(true)
	tw.tween_property(fill, "size:x", w, DRAIN)
	tw.tween_property(fill, "color", e["bar_color"] as Color, DRAIN)


func _make_badge() -> Control:
	var badge := Panel.new()
	badge.size = Vector2(30, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiStyle.WOOD_DARK
	sb.border_color = UiStyle.WOOD_INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(15)
	badge.add_theme_stylebox_override("panel", sb)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(5, 5)
	icon.size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	return badge


## Brightens the lit boop plate under the mouse.
func _hover_plates(cam: Camera3D) -> void:
	if not _m.board.split_revealed:
		return
	var lane: int = _m.board.plate_at(_m.board.ground_at_screen(cam, get_viewport().get_mouse_position()))
	for l: int in 4:
		var plate: BoopPlate = _m.board.boop_plate(l)
		var on: bool = l == lane and plate.state == BoopPlate.State.LIT
		if plate.hovered != on:
			plate.hovered = on


func badge(p: int, l: int) -> Control:
	return _badges[p][l]


