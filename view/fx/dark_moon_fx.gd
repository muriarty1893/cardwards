class_name DarkMoonFx
extends RefCounted
## Looks for the Dark Moon expansion's moments (spec 6): summons, the Dark Moon turn, stealing,
## curses, Dark Gift, Last Breath, legendaries and the cards the game makes. EventPlayer calls these.

const MOON_PURPLE := Color("#8a5aff")
const CURSE_PURPLE := Color("#6a3aa8")
const STEAL_SHADOW := Color("#3a2a5a")


## A creature put on the board without being played: it pops up in a puff.
static func summoned(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var p: int = d["player"]
	var sp: int = d["lane"]
	if ep._view(p, sp):
		return
	var c: CardData = CardDB.card(d["card"])
	var v: CreatureView = m.place_creature(p, sp, c)
	var full: Vector3 = v.scale
	v.scale = Vector3.ONE * 0.05
	v.busy = true
	Burst.spawn(m, &"smoke", v.global_position + Vector3(0, 0.3, 0), Palette.LAND_CARD[c.land], 1.2)
	Burst.spawn(m, &"stars", v.global_position + Vector3(0, 0.5, 0), Color.WHITE, 0.9)
	Audio.sfx(&"card_play")
	var tw := v.create_tween()
	tw.tween_property(v, "scale", full, 0.3 / ep.speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(v):
		v.busy = false
		v.hop_happy()
	m.refresh_pieces()


## Dark Moon: the room dims under a purple moon and every creature glides to its new land,
## arcing high over the middle when it changes sides. The views are rebuilt where they land.
static func dark_moon(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.05, 0.3, 0.0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.hud.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var moon := TextureRect.new()
	moon.texture = load(VisualDB.SPELL_ICONS[&"dark_moon"]) as Texture2D
	moon.modulate = Color(MOON_PURPLE, 0.0)
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	moon.size = Vector2(150, 150)
	moon.position = Vector2(m.hud.size.x * 0.5 - 75.0, 40.0)
	moon.pivot_offset = moon.size / 2.0
	m.hud.add_child(moon)
	Audio.sfx(&"magic_gain")
	var dim := shade.create_tween().set_parallel()
	dim.tween_property(shade, "color:a", 0.42, 0.35 / ep.speed)
	dim.tween_property(moon, "modulate:a", 0.9, 0.35 / ep.speed)
	dim.tween_property(moon, "rotation", float(d.get("dir", 1)) * 0.6, 1.4 / ep.speed)
	await dim.finished
	var moves: Array = d.get("moves", [])
	# Which views go where (main + follower move together).
	var pending: Array[Array] = []
	for mv: Dictionary in moves:
		for off: int in [0, GameState.LANES]:
			var v: CreatureView = ep._view(int(mv["from_player"]), int(mv["from_lane"]) + off)
			if v:
				pending.append([v, int(mv["to_player"]), int(mv["to_lane"]) + off, int(mv["from_player"]) != int(mv["to_player"])])
	var tw := m.create_tween().set_parallel()
	var dur: float = 0.9 / ep.speed
	for item: Array in pending:
		var v: CreatureView = item[0]
		v.busy = true
		var start: Vector3 = v.position
		var end: Vector3 = m.board.anchor(item[1], item[2])
		var lift: float = 1.6 if item[3] else 0.7
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(v):
				v.position = start.lerp(end, k) + Vector3(0, sin(k * PI) * lift, 0), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)
		Burst.spawn(m, &"stars", start + Vector3(0, 0.4, 0), MOON_PURPLE, 0.8)
	if not pending.is_empty():
		Audio.sfx(&"attack_whoosh")
		await tw.finished
	DamageNumber.stamp(m, m.board.anchor(0, 1).lerp(m.board.anchor(1, 2), 0.5) + Vector3(0, 1.4, 0), "DARK MOON!")
	# Rebuild the pieces where the state now has them (owners changed).
	m.sync_all()
	for item: Array in pending:
		var nv: CreatureView = ep._view(item[1], item[2])
		if nv:
			Burst.spawn(m, &"stars", nv.global_position + Vector3(0, 0.3, 0), MOON_PURPLE, 0.7)
	var fade := shade.create_tween().set_parallel()
	fade.tween_property(shade, "color:a", 0.0, 0.4 / ep.speed)
	fade.tween_property(moon, "modulate:a", 0.0, 0.4 / ep.speed)
	await fade.finished
	shade.queue_free()
	moon.queue_free()


## A creature taken from the rival: a shadow rises around it and it glides over to its new lane.
static func creature_stolen(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var v: CreatureView = ep._view(int(d["from_player"]), int(d["from_lane"]))
	if v:
		Burst.spawn(m, &"smoke", v.global_position + Vector3(0, 0.4, 0), STEAL_SHADOW, 1.4)
		DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.6, 0.2), "STOLEN!")
		Audio.sfx(&"attack_whoosh")
		v.busy = true
		var start: Vector3 = v.position
		var end: Vector3 = m.board.anchor(int(d["player"]), int(d["to_lane"]))
		var tw := m.create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(v):
				v.position = start.lerp(end, k) + Vector3(0, sin(k * PI) * 1.5, 0), 0.0, 1.0, 0.7 / ep.speed)
		await tw.finished
	m.sync_all()


## A card taken (or copied) from the rival's hand flies across to the thief's hand.
static func card_taken(ep: EventPlayer, d: Dictionary, word: String) -> void:
	var m: MatchController = ep.m
	var to_human: bool = int(d["player"]) == MatchController.HUMAN
	var from: Vector2 = m.rival_hand_screen() if to_human else m.hud.hero_screen_pos(true)
	var to: Vector2 = m.hud.hero_screen_pos(true) if to_human else m.rival_hand_screen()
	FlyingCard.fly(m.hud, CardDB.card(d["card"]), from, to, to_human, 0.45 / ep.speed, m.card_backs[int(d["from"])])
	Audio.sfx(&"card_deal")
	DamageNumber.spawn(m, FxDirector._hero_pos(m, int(d["player"])) + Vector3(0, 0.6, 0), word, STEAL_SHADOW.lightened(0.5), 46)
	await ep._wait(0.45)
	m.refresh_ui()


## A curse went off as it was drawn: a purple burst on its victim.
static func curse_triggered(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var pos: Vector3 = FxDirector._hero_pos(m, int(d["player"]))
	Burst.spawn(m, &"smoke", pos + Vector3(0, 0.4, 0), CURSE_PURPLE, 1.6)
	Burst.spawn(m, &"sparks", pos + Vector3(0, 0.6, 0), CURSE_PURPLE.lightened(0.3), 1.2)
	DamageNumber.spawn(m, pos + Vector3(0, 1.0, 0), "%s!" % CardDB.card(d["card"]).display_name.to_upper(), CURSE_PURPLE.lightened(0.45), 52)
	Audio.sfx(&"explosion")
	await ep._wait(0.45)


## A boon went off as it was drawn: a golden burst over its drawer, its name, then the spell's own effects.
static func drawn_cast(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var c: CardData = CardDB.card(d["card"])
	var col: Color = Palette.LAND_CARD[c.land].lightened(0.25)
	var pos: Vector3 = FxDirector._hero_pos(m, int(d["player"]))
	Burst.spawn(m, &"stars", pos + Vector3(0, 0.5, 0), Palette.GOLD, 1.3)
	Burst.spawn(m, &"sparks", pos + Vector3(0, 0.6, 0), col, 1.0)
	DamageNumber.spawn(m, pos + Vector3(0, 1.0, 0), "%s!" % c.display_name.to_upper(), col, 48)
	Audio.sfx(&"magic_gain")
	await ep._wait(0.4)


## Dark Gift: the pick's bonus is announced over its owner.
static func dark_gift(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var pos: Vector3 = FxDirector._hero_pos(m, int(d["player"]))
	Burst.spawn(m, &"stars", pos + Vector3(0, 0.5, 0), MOON_PURPLE, 1.3)
	DamageNumber.spawn(m, pos + Vector3(0, 1.0, 0), "DARK GIFT: %s" % String(Gifts.TEXT.get(d["gift"], "")).to_upper(), MOON_PURPLE.lightened(0.4), 40)
	Audio.sfx(&"magic_gain")
	await ep._wait(0.5)


## Last Breath: ghostly wisps rise from where the creature fell.
static func last_breath(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var at: Vector3 = m.board.anchor(int(d["player"]), int(d["lane"]))
	Burst.spawn(m, &"smoke", at + Vector3(0, 0.6, 0), Color("#d8e8ff"), 1.3)
	Burst.spawn(m, &"stars", at + Vector3(0, 1.0, 0), Color("#b8d0ff"), 1.0)
	DamageNumber.stamp(m, at + Vector3(0, 1.4, 0.2), "LAST BREATH")
	Audio.sfx(&"heal")
	await ep._wait(0.35)


## A legendary arrives: the camera pushes in and gold bursts around it.
static func legendary(ep: EventPlayer, at: Vector3) -> void:
	var m: MatchController = ep.m
	m.rig.punch_zoom(6.0, 0.35 / ep.speed)
	Burst.spawn(m, &"gold", at + Vector3(0, 0.8, 0), Palette.GOLD, 1.8)
	Burst.spawn(m, &"stars", at + Vector3(0, 1.2, 0), Palette.GOLD.lightened(0.3), 1.4)
	DamageNumber.stamp(m, at + Vector3(0, 1.8, 0.2), "LEGENDARY!")
	Audio.sfx(&"magic_gain")
	await ep._wait(0.3)


## Short word over a hero (cards made, spells echoed or replayed, hand buffed).
static func word(ep: EventPlayer, p: int, text: String, color: Color) -> void:
	var m: MatchController = ep.m
	DamageNumber.spawn(m, FxDirector._hero_pos(m, p) + Vector3(0, 0.8, 0), text, color, 40)
	m.refresh_ui()
	await ep._wait(0.3)
