class_name ActionLog
extends VBoxContainer
## What happened, Hearthstone style (board look 2, spec 3.3): a slim column of small card tiles at the left edge, one
## per action, newest on top. A tile shows the acting card's art, a gold (yours) or lilac (the rival's) border and a
## badge for what it did; hovering it pops out the full card and a few lines of detail.

const TILE := 56.0
const GAP := 6
const MAX_TILES := 8
const YOU := Color("#ffcf3a")
const RIVAL := Color("#c9a8ff")
## Events that make a tile, in the order they are looked for.
const PRIMARY: Array[StringName] = [&"creature_merged", &"creature_played", &"building_played", &"spell_cast", &"attack", &"booped"]
const BADGE_ICONS: Dictionary = {
	&"attack": "res://assets/icons/crossed-swords.svg",
	&"spell": "res://assets/icons/star-swirl.svg",
	&"built": "res://assets/icons/chimney.svg",
	&"destroyed": "res://assets/icons/sword-break.svg",
	&"merged": "res://assets/icons/card-exchange.svg",
	&"boop": "res://assets/icons/spiral-shell.svg",
	&"play": "res://assets/icons/sprout.svg",
}
const MAX_LINES := 5

## Newest first: {"card", "side", "badge", "lines"}.
var _entries: Array[Dictionary] = []
var _detail: PanelContainer
var _detail_card: CardWidget
var _detail_lines: VBoxContainer
var _hovered: int = -1


func _init() -> void:
	name = "ActionLog"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", GAP)
	custom_minimum_size = Vector2(TILE, 0)
	_detail = PanelContainer.new()
	_detail.top_level = true
	_detail.visible = false
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_theme_stylebox_override("panel", UiStyle.parchment_panel(14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_detail.add_child(row)
	_detail_card = CardWidget.new()
	row.add_child(_detail_card)
	_detail_lines = VBoxContainer.new()
	_detail_lines.custom_minimum_size = Vector2(230, 0)
	_detail_lines.add_theme_constant_override("separation", 4)
	row.add_child(_detail_lines)
	add_child(_detail)


## Adds a tile for the action whose events are `events` (none if nothing acted, e.g. a turn start).
func add_action(events: Array[GameEvent], s: GameState) -> void:
	var e: Dictionary = summarize(events, s)
	if e.is_empty():
		return
	_entries.push_front(e)
	if _entries.size() > MAX_TILES:
		_entries.resize(MAX_TILES)
	var tile: Control = _make_tile(e)
	add_child(tile)
	move_child(tile, 0)
	var tiles: Array[Control] = _tiles()
	while tiles.size() > MAX_TILES:
		var old: Control = tiles.pop_back()
		remove_child(old)
		old.queue_free()
	for i: int in tiles.size():
		tiles[i].modulate.a = lerpf(1.0, 0.55, float(i) / float(MAX_TILES))
		_wire(tiles[i], i)
	tile.scale = Vector2(0.4, 0.4)
	tile.pivot_offset = Vector2(TILE, TILE) / 2.0
	if tile.is_inside_tree():
		tile.create_tween().tween_property(tile, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tile.scale = Vector2.ONE
	if _hovered >= 0:
		hover_tile(-1)


func entries() -> Array[Dictionary]:
	return _entries


func _tiles() -> Array[Control]:
	var out: Array[Control] = []
	for c: Node in get_children():
		if c != _detail and not c.is_queued_for_deletion():
			out.append(c as Control)
	return out


func _wire(tile: Control, i: int) -> void:
	for sig: StringName in [&"mouse_entered", &"mouse_exited"]:
		for conn: Dictionary in tile.get_signal_connection_list(sig):
			tile.disconnect(sig, conn["callable"])
	tile.mouse_entered.connect(func() -> void: hover_tile(i))
	tile.mouse_exited.connect(func() -> void:
		if _hovered == i:
			hover_tile(-1))


func _make_tile(e: Dictionary) -> Control:
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(TILE, TILE)
	tile.size = Vector2(TILE, TILE)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#3a2a1a")
	sb.border_color = YOU if int(e["side"]) == 0 else RIVAL
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(9)
	tile.add_theme_stylebox_override("panel", sb)
	var art := TextureRect.new()
	var path: String = VisualDB.art_path(e["card"])
	art.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = Vector2(3, 3)
	art.size = Vector2(TILE - 6, TILE - 6)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(art)
	var badge := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = YOU if int(e["side"]) == 0 else RIVAL
	bsb.border_color = UiStyle.WOOD_INK
	bsb.set_border_width_all(2)
	bsb.set_corner_radius_all(11)
	badge.add_theme_stylebox_override("panel", bsb)
	badge.size = Vector2(22, 22)
	badge.position = Vector2(TILE - 24, TILE - 24)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	var ip: String = BADGE_ICONS.get(e["badge"], "")
	icon.texture = load(ip) as Texture2D if ip != "" else null
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = UiStyle.WOOD_INK
	icon.position = Vector2(3, 3)
	icon.size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	tile.add_child(badge)
	return tile


## Shows the detail panel for tile i (-1 hides it).
func hover_tile(i: int) -> void:
	_hovered = i
	if i < 0 or i >= _entries.size():
		_detail.visible = false
		return
	var e: Dictionary = _entries[i]
	_detail_card.setup(CardDB.card(e["card"]) if CardDB.has_card(e["card"]) else null, -1)
	_detail_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c: Node in _detail_lines.get_children():
		c.free()
	var first: bool = true
	for line: String in e["lines"]:
		var l := UiStyle.label(line, 17 if first else 15, UiStyle.WOOD_INK)
		if first:
			UiStyle.title(l)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(230, 0)
		_detail_lines.add_child(l)
		first = false
	_detail.visible = true
	_detail.reset_size()
	var tiles: Array[Control] = _tiles()
	var y: float = tiles[i].global_position.y if i < tiles.size() and tiles[i].is_inside_tree() else global_position.y
	_detail.global_position = Vector2(global_position.x + TILE + 12.0, maxf(8.0, y - 40.0))


func detail_visible() -> bool:
	return _detail.visible


## The tile for an action: {} when no card acted.
static func summarize(events: Array[GameEvent], s: GameState) -> Dictionary:
	var primary: GameEvent = null
	for t: StringName in PRIMARY:
		for e: GameEvent in events:
			if e.type == t:
				primary = e
				break
		if primary:
			break
	if primary == null:
		return {}
	var d: Dictionary = primary.data
	var p: int = int(d.get("player", -1))
	var card := StringName(str(d.get("into", d.get("card", ""))))
	if primary.type == &"booped" or (primary.type == &"attack" and card == &""):
		var cr: GameState.CreatureState = s.players[p].at(int(d["lane"]))
		card = cr.card.id if cr else _destroyed_card(events, p, int(d["lane"]))
	var badge: StringName = {&"creature_merged": &"merged", &"creature_played": &"play", &"building_played": &"built",
		&"spell_cast": &"spell", &"attack": &"attack", &"booped": &"boop"}[primary.type]
	var lines: Array[String] = []
	var head: String = describe(primary, s)
	if primary.type == &"booped":
		head = "%s booped %s" % ["You" if p == MatchController.HUMAN else "Rival", _card_name(card)]
	if head != "":
		lines.append(head)
	var killed: bool = false
	for line: String in _results(events, s):
		if line.contains("destroyed"):
			killed = true
		if lines.size() < MAX_LINES:
			lines.append(line)
	if killed and badge != &"merged":
		badge = &"destroyed"
	return {"card": card, "side": p, "badge": badge, "lines": lines}


static func _destroyed_card(events: Array[GameEvent], p: int, lane: int) -> StringName:
	for e: GameEvent in events:
		if e.type == &"creature_destroyed" and int(e.data["player"]) == p and int(e.data["lane"]) == lane:
			return StringName(str(e.data["card"]))
	return &""


## "→ <target>: <what happened>" lines, one per creature or hero touched, in the order first touched; then land
## changes and armour.
static func _results(events: Array[GameEvent], s: GameState) -> Array[String]:
	var order: Array[String] = []
	var acc: Dictionary = {}
	var extra: Array[String] = []
	for e: GameEvent in events:
		var d: Dictionary = e.data
		var key: String = ""
		if e.type in [&"creature_damaged", &"creature_destroyed", &"creature_healed", &"buffed", &"frozen"]:
			key = "%d:%d" % [int(d["player"]), int(d["lane"])]
		elif e.type in [&"hero_damaged", &"hero_healed"]:
			key = "hero%d" % int(d["player"])
		elif e.type in [&"land_changed", &"armour_gained"]:
			var line: String = describe(e, s)
			if line != "":
				extra.append(line)
			continue
		else:
			continue
		if not acc.has(key):
			acc[key] = {"dmg": 0, "heal": 0, "atk": 0, "hp": 0, "frozen": false, "dead": false, "p": int(d["player"]), "lane": int(d.get("lane", -1)), "card": &""}
			order.append(key)
		var a: Dictionary = acc[key]
		match e.type:
			&"creature_damaged", &"hero_damaged":
				a["dmg"] += int(d["amount"])
			&"creature_healed", &"hero_healed":
				a["heal"] += int(d["amount"])
			&"buffed":
				a["atk"] += int(d["atk"])
				a["hp"] += int(d["hp"])
			&"frozen":
				a["frozen"] = true
			&"creature_destroyed":
				a["dead"] = true
				a["card"] = StringName(str(d["card"]))
	var out: Array[String] = []
	for key: String in order:
		var a: Dictionary = acc[key]
		var bits: Array[String] = []
		if a["dmg"] > 0:
			bits.append("%d damage" % a["dmg"])
		if a["heal"] > 0:
			bits.append("+%d HP" % a["heal"])
		if a["atk"] != 0 or a["hp"] != 0:
			bits.append("%+d/%+d" % [a["atk"], a["hp"]])
		if a["frozen"]:
			bits.append("frozen")
		if a["dead"]:
			bits.append("destroyed")
		if bits.is_empty():
			continue
		var who: String
		if key.begins_with("hero"):
			who = "the Rival" if int(a["p"]) != MatchController.HUMAN else "you"
		elif a["card"] != &"":
			who = _card_name(a["card"])
		else:
			who = _name_at(s, a["p"], a["lane"])
		out.append("→ %s: %s" % [who, ", ".join(bits)])
	out.append_array(extra)
	return out




## One line for an event, or "" when it isn't worth a row.
static func describe(e: GameEvent, s: GameState) -> String:
	var d: Dictionary = e.data
	var p: int = int(d.get("player", -1))
	var who: String = "You" if p == MatchController.HUMAN else "Rival"
	var whose: String = "Your" if p == MatchController.HUMAN else "Rival's"
	match e.type:
		&"creature_played":
			return "%s played %s" % [who, _card_name(d["card"])]
		&"creature_merged":
			return "%s merged %s + %s into %s" % [who, _card_name(d["from"]), _card_name(d["card"]), _card_name(d["into"])]
		&"creature_bounced":
			return "%s %s went back to hand" % [whose, _card_name(d["card"])]
		&"creature_transformed":
			return "%s %s turned into %s" % [whose, _card_name(d["from"]), _card_name(d["card"])]
		&"building_played":
			return "%s built %s" % [who, _card_name(d["card"])]
		&"spell_cast":
			return "%s cast %s" % [who, _card_name(d["card"])]
		&"attack":
			var attacker: String = _card_name(d["card"]) if d.has("card") else _name_at(s, p, d["lane"])
			var target: String = "the Rival" if p == MatchController.HUMAN else "you"
			if int(d["target_lane"]) >= 0:
				target = _card_name(d["target_card"]) if String(d.get("target_card", "")) != "" else _name_at(s, 1 - p, d["target_lane"])
			return "%s %s attacks %s" % [whose, attacker, target]
		&"creature_destroyed":
			return "%s %s was destroyed" % [whose, _card_name(d["card"])]
		&"land_changed":
			return "%s lane %d became %s" % [whose, int(d["lane"]) + 1, Lands.lane_name(d["land"])]
		&"land_reaction":
			return "%s! (%s)" % [Lands.REACTION_NAMES[d["reaction"]], _card_name(d["card"])]
		&"level_up":
			return "%s %s reached Lv %d" % [whose, _card_name(d["card"]), d["level"]]
		&"field_set":
			return "%s covers the table" % _card_name(d["card"])
		&"armour_gained":
			return "%s gained %d armour" % [who, d["amount"]] if int(d["amount"]) > 0 else ""
		&"game_over":
			return "You win!" if int(d["winner"]) == MatchController.HUMAN else "The Rival wins"
	return ""


static func _card_name(id: Variant) -> String:
	var sid := StringName(str(id))
	var c: CardData = CardDB.card(sid) if CardDB.has_card(sid) else null
	return c.display_name if c else str(id).capitalize()


## The creature's name in the lane now, or "a creature" if it's gone already.
static func _name_at(s: GameState, p: int, lane: int) -> String:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	return cr.card.display_name if cr else "a creature"
