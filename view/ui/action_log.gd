class_name ActionLog
extends VBoxContainer
## The last few things that happened, as small rows at the left edge (tabletop spec 7.2): newest
## at the bottom, older rows fading. Rows are tinted by side (yours gold, the rival's lilac).

const MAX_ROWS := 6
const WIDTH := 262.0
const YOU := Color("#fff2c8")
const RIVAL := Color("#ead8ff")
const NEUTRAL := Color("#f6e7c4")


func _init() -> void:
	name = "ActionLog"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	custom_minimum_size = Vector2(WIDTH, 0)


func add(text: String, side: int = -1) -> void:
	var l := UiStyle.title(UiStyle.label(text, 14, UiStyle.WOOD_INK)) as Label
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(YOU if side == 0 else (RIVAL if side == 1 else NEUTRAL), 0.92)
	sb.border_color = UiStyle.WOOD_INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", sb)
	add_child(l)
	while get_child_count() > MAX_ROWS:
		var old: Node = get_child(0)
		remove_child(old)
		old.queue_free()
	var n: int = get_child_count()
	for i: int in n:
		(get_child(i) as Control).modulate.a = lerpf(0.45, 1.0, float(i + 1) / float(n))
	l.modulate.a = 0.0
	l.create_tween().tween_property(l, "modulate:a", 1.0, 0.2)


func rows() -> Array[String]:
	var out: Array[String] = []
	for c: Node in get_children():
		if not c.is_queued_for_deletion():
			out.append((c as Label).text)
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
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	return cr.card.display_name if cr else "a creature"
