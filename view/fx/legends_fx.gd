class_name LegendsFx
extends RefCounted
## Looks for things that used to have only a floating word (Legends & Grudges, 2026-11-25):
## the Drain siphon, a pulse on the creature whose ability fires, stats doubling, a made card
## flying into its owner's hand, and the hand shimmering when it is buffed.

const DRAIN := Color("#ff3a5a")
const TRIGGER := Color("#ffd84a")


## Drain: a ribbon of red drops pulled from the target into the drainer, which swells with it.
static func drained(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var sp: float = ep.speed
	var t: Dictionary = d.get("from", {})
	var from: Vector3 = FxDirector._hero_pos(m, int(t.get("hero", t.get("player", 0))))
	if t.has("lane") and t.has("player"):
		var tv: CreatureView = ep._view(t["player"], t["lane"])
		if tv:
			from = tv.global_position + Vector3(0, tv.height * 0.55, 0)
	var p: int = int(d["player"])
	var v: CreatureView = ep._view(p, int(d["lane"])) if int(d["lane"]) >= 0 else null
	var to: Vector3 = v.global_position + Vector3(0, v.height * 0.55, 0) if v else FxDirector._hero_pos(m, p)
	Audio.sfx(&"heal", 0.05)
	var n: int = clampi(4 + int(d.get("amount", 1)) * 2, 6, 14)
	var dur: float = 0.55 / sp
	var mat := SpellKit._glow_mat(DRAIN, 0.95)
	# Every drop follows the same curve, a little apart in time, so it reads as one stream.
	var bend: Vector3 = (from + to) * 0.5 + Vector3(0, 1.1 + from.distance_to(to) * 0.12, 0)
	for i: int in n:
		var drop := MeshInstance3D.new()
		drop.mesh = Palette.sphere(0.075 if i % 3 else 0.11, 8)
		drop.material_override = mat
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(drop)
		drop.global_position = from
		var wob: Vector3 = Vector3(randf_range(-0.18, 0.18), randf_range(-0.12, 0.12), randf_range(-0.18, 0.18))
		var tw := drop.create_tween()
		tw.tween_interval(i * 0.035 / sp)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(drop):
				var a: Vector3 = from.lerp(bend, k)
				var b: Vector3 = bend.lerp(to, k)
				drop.global_position = a.lerp(b, k) + wob * sin(k * PI)
				drop.scale = Vector3.ONE * (1.0 - 0.5 * k), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(drop.queue_free)
	Burst.spawn(m, &"sparks", from, DRAIN, 0.8)
	await ep._wait(dur + n * 0.035 / sp)
	if not is_instance_valid(m):
		return
	Burst.spawn(m, &"heal", to, DRAIN.lightened(0.3), 1.3)
	ShockRing.spawn(m, Vector3(to.x, 0.05, to.z), DRAIN, 0.7, 0.3)
	if v:
		await _swell(ep, v, 1.22)


## A gold ring and a little hop under a creature on the board whose ability just fired
## (whenever-a-creature-dies, start of turn, boop...), so you can see who did it.
static func trigger_pulse(ep: EventPlayer, p: int, lane: int) -> void:
	var v: CreatureView = ep._view(p, lane)
	if v == null or v.busy:
		return
	var m: MatchController = ep.m
	ShockRing.spawn(m, Vector3(v.global_position.x, 0.06, v.global_position.z), TRIGGER, 0.55, 0.28 / ep.speed)
	Burst.spawn(m, &"stars", v.global_position + Vector3(0, v.height * 0.9, 0), TRIGGER, 0.7)
	v.busy = true
	var base: Vector3 = v.rest_scale()
	var tw := v.create_tween()
	tw.tween_property(v.body, "scale", base * Vector3(0.9, 1.15, 0.9), 0.08 / ep.speed)
	tw.tween_property(v.body, "scale", base, 0.22 / ep.speed).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func() -> void:
		if is_instance_valid(v):
			v.busy = false)
	await ep._wait(0.16)


## Stats doubled: a big "x2" stamp, a gold burst and the creature puffing up.
static func doubled(ep: EventPlayer, d: Dictionary) -> void:
	var v: CreatureView = ep._view(d["player"], d["lane"])
	if v == null:
		return
	var m: MatchController = ep.m
	var top: Vector3 = v.global_position + Vector3(0, v.height + 0.5, 0)
	Audio.sfx(&"magic_gain")
	DamageNumber.spawn(m, top, "x2!", Palette.GOLD, 84, 1.8)
	Burst.spawn(m, &"gold", v.global_position + Vector3(0, v.height * 0.5, 0), Color.WHITE, 1.4)
	ShockRing.spawn(m, Vector3(v.global_position.x, 0.06, v.global_position.z), Palette.GOLD, 1.1, 0.4)
	await _swell(ep, v, 1.4)


## A card made for a hand flies there from its maker (the hero), turning face up for you.
static func card_added(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	var p: int = int(d["player"])
	var c: CardData = CardDB.card(d["card"])
	var from: Vector2 = m.rig.camera.unproject_position(FxDirector._hero_pos(m, p) + Vector3(0, 0.6, 0)) if m.rig and m.rig.camera else m.hud.deck_screen_pos()
	Audio.sfx(&"card_deal")
	if p == MatchController.HUMAN:
		m.hand.expect_draw(from)
		m.refresh_ui()
		DamageNumber.spawn(m, FxDirector._hero_pos(m, p) + Vector3(0, 0.8, 0), "+%s" % c.display_name.to_upper(), Palette.GOLD, 34)
		await ep._wait(Hand.DRAW_TIME * 0.7)
	else:
		var fc := FlyingCard.fly(m.hud, c, from, m.rival_hand_screen(), false, 0.35 / ep.speed, m.card_backs[MatchController.AI])
		if fc:
			await ep._wait(0.35)
		m.refresh_ui()


## The hand's creatures got stronger: each of your cards shimmers gold, one after another.
static func hand_buffed(ep: EventPlayer, d: Dictionary) -> void:
	var m: MatchController = ep.m
	m.refresh_ui()
	if int(d["player"]) == MatchController.HUMAN:
		var i: int = 0
		while true:
			var w: CardWidget = m.hand.card_widget(i)
			if w == null:
				break
			if w.card.is_creature():
				var tw := w.create_tween()
				tw.tween_interval(i * 0.05)
				tw.tween_property(w, "modulate", Color(1.7, 1.55, 0.8), 0.1)
				tw.tween_property(w, "modulate", Color.WHITE, 0.35)
			i += 1
	await DarkMoonFx.word(ep, d["player"], "HAND +%d/+%d" % [int(d["atk"]), int(d["hp"])], Color("#8fe07a"))


## The creature swells to `k` times its size and settles back.
static func _swell(ep: EventPlayer, v: CreatureView, k: float) -> void:
	if not is_instance_valid(v) or v.body == null:
		return
	var was: bool = v.busy
	v.busy = true
	var base: Vector3 = v.rest_scale()
	var tw := v.create_tween()
	tw.tween_property(v.body, "scale", base * k, 0.12 / ep.speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v.body, "scale", base, 0.3 / ep.speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(v):
		v.busy = was
