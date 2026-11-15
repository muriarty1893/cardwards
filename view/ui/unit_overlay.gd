class_name UnitOverlay
extends Control
## Screen-space info that follows the pieces on the board: an attack number and a health bar
## above each creature, a badge on each building, a BOOP button on each of the human's lanes
## and an enlarged card when the mouse hovers a piece. Values come from the game state.

const BAR_SIZE := Vector2(110, 40)
const GREEN := Color("#3ad16a")
const YELLOW := Color("#ffcf3a")
const RED := Color("#e5384f")
const BOOP_SIZE := Vector2(96, 34)
const BOOP_READY := Color("#ffcf3a")
const BOOP_OFF := Color("#8a86a8")
const DRAIN := 0.3
const HOVER_SCALE := 1.6
## Building badge glyph by ability (icons replace these in Task 9).
const BADGE: Dictionary = {
	&"heal_lane_creature_1": "✚", &"lane_max_hp_3": "♥", &"lane_atk_2": "⚔", &"dmg_enemy_hero_1": "☁",
	&"lane_atk_1_hp_1": "⚔", &"gain_magic_1": "◆", &"lane_damage_minus_1": "⛨", &"opposing_atk_minus_1": "▼",
}

var _m: MatchController
var _entries: Array[Array] = []
var _bars: Array[Array] = []
var _badges: Array[Array] = []
var _boops: Array[Button] = []
var _hover: CardWidget
var _hover_key: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p: int in 2:
		_entries.append([{}, {}, {}, {}])
		_bars.append([])
		_badges.append([])


func setup(m: MatchController) -> void:
	_m = m
	for p: int in 2:
		for l: int in 4:
			var bar := _make_bar()
			add_child(bar)
			_bars[p].append(bar)
			var badge := _make_badge()
			add_child(badge)
			_badges[p].append(badge)
	for l: int in 4:
		var b := Button.new()
		b.name = "Boop%d" % l
		b.text = "BOOP"
		b.size = BOOP_SIZE
		b.custom_minimum_size = BOOP_SIZE
		b.visible = false
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		_style_boop(b)
		b.pressed.connect(func() -> void: _m.input.request_boop(l))
		UiStyle.sound_button(b)
		add_child(b)
		_boops.append(b)


func entry(p: int, l: int) -> Dictionary:
	var e: Dictionary = _entries[p][l]
	if e.is_empty():
		return {"visible": false, "atk": 0, "hp": 0, "max": 0, "bar_color": GREEN}
	return e


func boop_button(l: int) -> Button:
	return _boops[l]


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
				_entries[p][l] = {"visible": true, "atk": Rules.effective_attack(s, p, l), "hp": hp, "max": max_hp, "bar_color": bar_color(hp, max_hp)}
			_update_bar(_bars[p][l], _entries[p][l])
			var badge: Control = _badges[p][l]
			badge.visible = lane.building != null
			if lane.building:
				(badge.get_child(0) as Label).text = BADGE.get(lane.building.ability_id, "★")
	for l: int in 4:
		var cr: GameState.CreatureState = s.players[MatchController.HUMAN].lanes[l].creature
		var b: Button = _boops[l]
		b.visible = cr != null and cr.card.trigger == &"on_boop"
		b.disabled = not (b.visible and _m.input.can_boop(l) and not _m.busy)
		_style_boop(b)


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
				badge.position = cam.unproject_position((bv as Node3D).global_position + Vector3(0, BuildingView.HEIGHT + 0.25, 0)) - badge.size / 2.0
	for l: int in 4:
		if _boops[l].visible:
			_boops[l].position = cam.unproject_position(_m.board.anchor(MatchController.HUMAN, l) + Vector3(0, 0, 0.95)) - BOOP_SIZE / 2.0
	_update_hover()


func _update_hover() -> void:
	var hit: Dictionary = {}
	var blocked: bool = _m.input.mode != InputController.Mode.IDLE or _m.hud.is_paused() or _m.results.visible
	if not blocked:
		hit = piece_at(get_viewport().get_mouse_position())
	var key: String = "" if hit.is_empty() else "%d:%d:%s" % [hit["player"], hit["lane"], hit["kind"]]
	if key == _hover_key:
		return
	_hover_key = key
	if _hover:
		_hover.queue_free()
		_hover = null
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
	add_child(_hover)
	var view: Variant = _m.creature_views[hit["player"]][hit["lane"]] if hit["kind"] == &"creature" else _m.building_views[hit["player"]][hit["lane"]]
	if not is_instance_valid(view):
		return
	var at: Vector2 = _m.rig.camera.unproject_position((view as Node3D).global_position + Vector3(0, 0.6, 0))
	var size_px: Vector2 = CardWidget.SIZE * HOVER_SCALE
	var pos := Vector2(at.x + 60.0, at.y - size_px.y / 2.0)
	if pos.x + size_px.x > size.x:
		pos.x = at.x - 60.0 - size_px.x
	pos.x = clampf(pos.x, 0.0, maxf(0.0, size.x - size_px.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, size.y - size_px.y))
	_hover.position = pos


# --- Widgets -----------------------------------------------------------------

func _make_bar() -> Control:
	var root := Control.new()
	root.size = BAR_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	var atk := UiStyle.bold(UiStyle.label("0", 30, Color.WHITE))
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
	var txt := UiStyle.bold(UiStyle.label("0/0", 12, Color.WHITE))
	txt.name = "Text"
	txt.size = back.size
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.add_theme_color_override("font_outline_color", Palette.INK)
	txt.add_theme_constant_override("outline_size", 5)
	back.add_child(txt)
	return root


func _update_bar(bar: Control, e: Dictionary) -> void:
	if e.is_empty():
		return
	(bar.get_node("Atk") as Label).text = str(e["atk"])
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
	sb.bg_color = Color("#fff8e8")
	sb.border_color = Palette.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(15)
	badge.add_theme_stylebox_override("panel", sb)
	var l := UiStyle.bold(UiStyle.label("★", 16))
	l.size = badge.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(l)
	return badge


func _style_boop(b: Button) -> void:
	var ready: bool = not b.disabled
	b.add_theme_font_size_override("font_size", 16)
	for st: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = BOOP_READY if ready else BOOP_OFF
		if st == "hover" and ready:
			sb.bg_color = BOOP_READY.lightened(0.2)
		if st == "pressed":
			sb.bg_color = BOOP_READY.darkened(0.15)
		sb.border_color = Palette.INK
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		if ready:
			sb.shadow_color = Color(BOOP_READY, 0.7)
			sb.shadow_size = 6
		b.add_theme_stylebox_override(st, sb)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Palette.INK if ready else Color(1, 1, 1, 0.7))
