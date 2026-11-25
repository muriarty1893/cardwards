class_name EventPlayer
extends Node
## Plays GameEvents back one after another. Tracks what caused the current effects
## (ability_triggered / attack) and hands effect events to FxDirector; plays the piece
## sequences itself (play, attack, death, move, building rise, turn banner).

signal finished

## Effect events FxDirector draws (spec 6.3).
const EFFECT_EVENTS: Array[StringName] = [
	&"creature_damaged", &"creature_healed", &"hero_damaged", &"hero_healed", &"frozen",
	&"card_drawn", &"card_returned", &"creature_moved", &"building_returned", &"magic_changed",
	&"armour_gained",
]
const HIT_STOP := 0.07
## Landing / death burst preset per CardData.Land (NEUTRAL last).
const LAND_BURSTS: Array[StringName] = [&"leaves", &"embers", &"sprinkles", &"snow", &"stars", &"sand"]
const HIT_STOP_SCALE := 0.05
const HIT_STOP_CRIT := 0.16
## After a crit's freeze: this time scale for this long (real seconds).
const SLOW_MO := 0.3
const SLOW_MO_TIME := 0.18
## Sound when a lane turns into a land (CardData.Land order, Meadow last).
const LAND_SOUNDS: Array[StringName] = [&"heal", &"fire_whoosh", &"candy_pop", &"freeze", &"card_draw", &"building_rise"]
## How each event changes the hand of the player it names (the rival's fan follows it live).
const HAND_DELTA: Dictionary = {
	&"card_drawn": 1, &"card_returned": 1, &"dream_up_chosen": 1, &"card_added": 1, &"card_copied": 1, &"card_stolen": 1,
	&"curse_triggered": -1,
	&"creature_played": -1, &"building_played": -1, &"spell_cast": -1, &"creature_merged": -1,
}

var m: MatchController
var speed: float = 1.0
var _skip_move: Dictionary = {}
## {} | {"kind": &"ability", "player", "lane", "card"} | {"kind": &"attack", "player", "lane", "hit"}
var _source: Dictionary = {}
## "p:lane" of the creature just played this batch: its on-play ability needs no extra pulse.
var _just_played: String = ""
## "p:l" of creatures damaged by a Venom creature in this batch (their death turns green).
var _venomed: Dictionary = {}
## "p:l" → the last hit a creature took in this batch: {"big", "fire", "from"} (picks its death).
var _last_hit: Dictionary = {}
## The batch being played and the index of the current event (spells look ahead at their targets).
var _batch: Array[GameEvent] = []
## The last batch played (named in resync warnings, to find what left the views behind).
var last_batch: Array[GameEvent] = []
var _at: int = 0


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds / speed).timeout


func play(events: Array[GameEvent]) -> void:
	_source = {}
	_venomed = {}
	_last_hit = {}
	if m.action_log:
		m.action_log.add_action(events, m.state)
	_batch = events
	for i: int in events.size():
		_at = i
		await _play_one(events[i])
	last_batch = events
	_batch = []
	_source = {}
	if m.rival:
		m.rival.set_hand_count(m.state.players[MatchController.AI].hand.size())
	m.refresh_pieces()
	m.refresh_ui()
	m.verify_views()
	finished.emit()


func _play_one(e: GameEvent) -> void:
	var d: Dictionary = e.data
	_rival_react(e)
	if e.type in [&"creature_played", &"building_played", &"creature_merged"] and int(d.get("player", -1)) == MatchController.AI:
		await _reveal(CardDB.card(d["card"]))
	if e.type == &"creature_damaged" and _dealt_by_venom(d):
		_venomed["%d:%d" % [d["player"], d["lane"]]] = true
	if e.type == &"creature_damaged":
		_last_hit["%d:%d" % [d["player"], d["lane"]]] = _hit_info(d)
	if e.type in EFFECT_EVENTS:
		var kind: StringName = FxDirector.choose(_source, e)
		await FxDirector.play(kind, _source, e, m)
		# A gem pop / magic gain draws once; later magic updates in the batch are plain.
		if e.type == &"magic_changed" and kind in [&"gem_pop", &"magic"]:
			_source = {}
		return
	match e.type:
		&"ability_triggered":
			_source = {"kind": &"ability", "player": d["player"], "lane": d["lane"], "card": d["card"]}
			var sc: CardData = CardDB.card(d["card"])
			if sc and sc.kind == CardData.Kind.SPELL and VisualDB.SPELL_FX.has(sc.id):
				_source["kit"] = true
				await SpellKit.play(m, VisualDB.SPELL_FX[sc.id], d["player"], _spell_targets(), speed)
			elif sc and sc.kind == CardData.Kind.CREATURE and int(d["lane"]) >= 0 and "%d:%d" % [d["player"], d["lane"]] != _just_played:
				await LegendsFx.trigger_pulse(self, d["player"], d["lane"])
		&"attack":
			_just_played = ""
			_source = {"kind": &"attack", "player": d["player"], "lane": d["lane"], "hit": d["hit"], "target_lane": int(d.get("target_lane", -1))}
			Audio.sfx(&"attack_whoosh")
			await _attack(d)
		&"creature_played":
			_just_played = "%d:%d" % [d["player"], d["lane"]]
			await _play_creature(d)
		&"building_played":
			await _play_building(d)
		&"spell_cast":
			var c: CardData = CardDB.card(d["card"])
			Audio.sfx(&"card_play")
			if VisualDB.sound(c.id) != &"":
				Audio.sfx(VisualDB.sound(c.id))
			await _cast_card(c, int(d["player"]) == MatchController.HUMAN)
			Burst.spawn(m, &"stars", FxDirector._hero_pos(m, d["player"]), Palette.LAND_CARD[c.land], 1.4)
			if c.legendary:
				await DarkMoonFx.legendary(self, m.board.anchor(0, 1).lerp(m.board.anchor(1, 2), 0.5))
		&"booped":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				v.busy = true
				var base: Vector3 = v.rest_scale()
				var tw := v.create_tween()
				tw.tween_property(v.body, "scale", base * Vector3(1.3, 0.7, 1.3), 0.1 / speed)
				tw.tween_property(v.body, "scale", base, 0.2 / speed).set_trans(Tween.TRANS_ELASTIC)
				Burst.spawn(m, &"stars", v.global_position + Vector3(0, 0.6, 0))
				await tw.finished
				v.busy = false
		&"creature_destroyed":
			_just_played = ""
			Audio.sfx(&"death")
			var killer: int = int(_source.get("player", -1)) if _source.get("kind") == &"attack" else -1
			await _death(d)
			if killer >= 0 and killer != int(d["player"]):
				_cheer(killer)
		&"unfrozen":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				v.set_frozen(false)
				Audio.sfx(&"ice_shatter")
			await _wait(0.2)
		&"fatigue":
			var human: bool = d["player"] == MatchController.HUMAN
			DamageNumber.spawn(m, FxDirector._hero_pos(m, d["player"]), "-%d" % d["amount"], Palette.HP, 96)
			Audio.sfx(&"hero_hit")
			m.hud.shake_hero(human)
			m.hud.refresh(m.state, MatchController.HUMAN)
			await _wait(0.4)
		&"card_burned":
			m.refresh_ui()
			Audio.sfx(&"fire_whoosh")
			m.toast.show_message("Hand full: %s burned" % CardDB.card(d["card"]).display_name, 1.0)
			await _burn_card(CardDB.card(d["card"]), int(d["player"]) == MatchController.HUMAN)
		&"turn_started":
			_source = {}
			_just_played = ""
			m.picker.clear_rival()
			m.hud.refresh(m.state, MatchController.HUMAN)
			var mine: bool = d["player"] == MatchController.HUMAN
			Audio.sfx(&"turn_start", 0.0)
			Banner.show_turn(m.hud, "YOUR TURN" if mine else "RIVAL'S TURN", Color("#ffcf3a") if mine else Color("#b06cff"))
			await _wait(0.6)
		&"game_over":
			m.refresh_ui()
		&"second_wind":
			await _second_wind(d)
		&"creature_bounced":
			await _bounced(d)
		&"follower_entered":
			await _follower_entered(d)
		&"creature_summoned":
			await DarkMoonFx.summoned(self, d)
		&"mulligan_done":
			if int(d["count"]) > 0:
				if int(d["player"]) == MatchController.HUMAN:
					for i: int in int(d["count"]):
						m.hand.expect_draw(m.hud.deck_screen_pos())
				await DarkMoonFx.word(self, d["player"], "REDREW %d" % int(d["count"]), Color("#bfe8ff"))
				await _wait(0.3)
		&"dark_moon":
			await DarkMoonFx.dark_moon(self, d)
		&"creature_stolen":
			await DarkMoonFx.creature_stolen(self, d)
		&"card_stolen":
			await DarkMoonFx.card_taken(self, d, "STOLEN!")
		&"card_copied":
			await DarkMoonFx.card_taken(self, d, "COPIED!")
		&"curse_triggered":
			await DarkMoonFx.curse_triggered(self, d)
		&"dark_gift":
			await DarkMoonFx.dark_gift(self, d)
		&"last_breath":
			await DarkMoonFx.last_breath(self, d)
		&"card_added":
			await LegendsFx.card_added(self, d)
		&"shuffled_in":
			await DarkMoonFx.word(self, d["player"], "+%d IN DECK" % int(d["count"]), DarkMoonFx.CURSE_PURPLE.lightened(0.45))
		&"hand_buffed":
			await LegendsFx.hand_buffed(self, d)
		&"hand_card_grew":
			m.refresh_ui()
		&"spell_echoed":
			await DarkMoonFx.word(self, d["player"], "TWICE!", Palette.GOLD)
		&"spell_replayed":
			var rc: CardData = CardDB.card(d["card"])
			await _cast_card(rc, int(d["player"]) == MatchController.HUMAN)
			await DarkMoonFx.word(self, d["player"], "AGAIN: %s" % rc.display_name.to_upper(), Color("#bfe8ff"))
		&"follower_promoted":
			await move_piece(d, false)
		&"creature_merged":
			await _merged(d)
		&"creature_transformed":
			await _transformed(d)
		&"doomed":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				Burst.spawn(m, &"embers", v.global_position + Vector3(0, v.height * 0.6, 0), Color.WHITE, 1.2)
				DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.7, 0.2), "DOOMED!")
			await _wait(0.35)
		&"land_changed":
			await _land_changed(d)
		&"land_reaction":
			await _land_reaction(d)
		&"xp_gained":
			var v: CreatureView = _view(d["player"], d["lane"])
			if v:
				DamageNumber.spawn(m, v.global_position + Vector3(0.35, v.height + 0.35, 0), "+%d XP" % d["amount"], Palette.GOLD, 34)
			m.overlay.refresh(m.state)
		&"level_up":
			await _level_up(d)
		&"field_set":
			await _field_set(d)
		&"dream_up_offered":
			if int(d["player"]) == MatchController.AI:
				await m.picker.show_rival_offer((d["cards"] as Array).size(), m.card_backs[MatchController.AI], m.rival_hand_screen())
		&"dream_up_chosen":
			if int(d["player"]) == MatchController.AI:
				await m.picker.rival_pick(m.rival_hand_screen())
			m.refresh_ui()
		&"bubble_popped":
			await _bubble_popped(d)
		&"revealed":
			await _revealed(d)
		&"hushed":
			await _hushed(d)
		&"keyword_gained":
			await _keyword_gained(d)
		&"buffed":
			await _buffed(d)
		&"leeched":
			await _leeched(d)
		&"drained":
			await LegendsFx.drained(self, d)
		&"doubled":
			await LegendsFx.doubled(self, d)
		&"tribe_bonus":
			var pos: Vector3 = FxDirector._hero_pos(m, d["player"])
			DamageNumber.spawn(m, pos + Vector3(0, 0.5, 0), "%s!" % Tribes.BONUS[d["tribe"]].to_upper(), Color("#8fe07a"), 52)
		_:
			m.hud.refresh(m.state, MatchController.HUMAN)


## The seated rival reacts to what happens at the table.
func _rival_react(e: GameEvent) -> void:
	var r: RivalSeat = m.rival
	if r == null:
		return
	var d: Dictionary = e.data
	var ai: bool = int(d.get("player", -1)) == MatchController.AI
	if ai and HAND_DELTA.has(e.type):
		r.set_hand_count(r.hand_count() + int(HAND_DELTA[e.type]))
	match e.type:
		&"creature_played", &"building_played", &"spell_cast":
			if ai:
				r.play_card()
		&"hero_damaged":
			if int(d.get("amount", 0)) > 0:
				if ai:
					r.flinch()
				else:
					r.cheer()
		&"turn_started":
			r.think(ai)
		&"game_over":
			r.think(false)
			if int(d.get("winner", -1)) == MatchController.AI:
				r.win()
			else:
				r.lose()


## A pack's follower pops up beside its leader.
func _follower_entered(d: Dictionary) -> void:
	var p: int = d["player"]
	var sp: int = d["lane"]
	if _view(p, sp):
		return
	var v: CreatureView = m.place_creature(p, sp, CardDB.card(d["card"]))
	var full: Vector3 = v.scale
	v.scale = Vector3.ONE * 0.05
	v.busy = true
	Burst.spawn(m, &"stars", v.global_position + Vector3(0, 0.3, 0), Palette.LAND_CARD[v.card.land], 1.0)
	Audio.sfx(&"card_play")
	var tw := v.create_tween()
	tw.tween_property(v, "scale", full, 0.35 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(v):
		v.busy = false
	m.refresh_pieces()


## Second Wind: the creature that just fell springs back up in its lane with 1 HP.
## A creature is sent back to its owner's hand: it shrinks and flies up off the board.
func _bounced(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var v: CreatureView = _view(p, l)
	if v == null:
		return
	m.creature_views[p][l] = null
	v.busy = true
	Audio.sfx(&"card_deal")
	Burst.spawn(m, &"stars", v.global_position + Vector3(0, 0.3, 0), Color.WHITE, 1.0)
	var tw := v.create_tween().set_parallel()
	tw.tween_property(v, "position", v.position + Vector3(0, 1.4, 0), 0.4 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(v, "scale", Vector3.ONE * 0.05, 0.4 / speed).set_ease(Tween.EASE_IN)
	await tw.finished
	if is_instance_valid(v):
		v.queue_free()
	m.refresh_pieces()


## A creature turns into another (a token, or a merged form): a puff of smoke and the new one pops up in its place.
func _transformed(d: Dictionary, burst: StringName = &"smoke", stamp: String = "") -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var old: CreatureView = _view(p, l)
	var at: Vector3 = old.global_position if old else m.board.anchor(p, l)
	if old:
		m.creature_views[p][l] = null
		old.queue_free()
	Burst.spawn(m, burst, at + Vector3(0, 0.3, 0), Color.WHITE, 1.5)
	Audio.sfx(&"card_play")
	var v: CreatureView = m.place_creature(p, l, CardDB.card(d["card"]))
	var full: Vector3 = v.scale
	v.scale = Vector3.ONE * 0.05
	v.busy = true
	if stamp != "":
		DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.7, 0.2), stamp)
	var tw := v.create_tween()
	tw.tween_property(v, "scale", full, 0.45 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(v):
		v.busy = false
	m.refresh_pieces()


## Two partners merge: the hand creature hops in over its partner, the two spin together in a burst of sparkles,
## and the merged form pops up in their place.
func _merged(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var old: CreatureView = _view(p, l)
	var at: Vector3 = old.global_position if old else m.board.anchor(p, l)
	if old:
		old.busy = true
		old.wanderer.set_process(false)
	var hopper := CreatureView.create(CardDB.card(d["card"]))
	hopper.wanderer.set_process(false)
	m.add_child(hopper)
	var side: float = 1.0 if p == MatchController.HUMAN else -1.0
	var start: Vector3 = at + Vector3(0.0, 0.2, 1.4 * side)
	var peak: Vector3 = at + Vector3(0.0, 1.5, 0.5 * side)
	hopper.global_position = start
	hopper.rotation.y = old.rotation.y if old else 0.0
	Audio.sfx(&"card_play")
	var hop := hopper.create_tween()
	hop.tween_method(func(k: float) -> void:
		hopper.global_position = start.lerp(peak, k).lerp(peak.lerp(at + Vector3(0, 0.25, 0), k), k), 0.0, 1.0, 0.4 / speed)
	await hop.finished
	# Spin together and shrink into one.
	var spin := create_tween().set_parallel()
	for v: CreatureView in [old, hopper]:
		if is_instance_valid(v):
			spin.tween_property(v, "rotation:y", v.rotation.y + TAU * 1.5, 0.45 / speed).set_trans(Tween.TRANS_SINE)
			spin.tween_property(v, "scale", Vector3.ONE * 0.2, 0.45 / speed).set_ease(Tween.EASE_IN)
			spin.tween_property(v, "global_position", at + Vector3(0, 0.3, 0), 0.45 / speed)
	await spin.finished
	Burst.spawn(m, &"stars", at + Vector3(0, 0.45, 0), Color.WHITE, 1.8)
	Burst.spawn(m, &"sparks", at + Vector3(0, 0.45, 0), Color.WHITE, 1.4)
	if is_instance_valid(hopper):
		hopper.queue_free()
	await _transformed({"player": p, "lane": l, "card": d["into"]}, &"sprinkles", "MERGE!")


func _second_wind(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	if _view(p, l) != null:
		return
	var v: CreatureView = m.place_creature(p, l, CardDB.card(d["card"]))
	var full: Vector3 = v.scale
	v.scale = Vector3.ONE * 0.05
	v.busy = true
	Burst.spawn(m, &"heal", v.global_position + Vector3(0, 0.3, 0), Color.WHITE, 1.4)
	Burst.spawn(m, &"gold", v.global_position + Vector3(0, 0.5, 0), Color.WHITE, 1.2)
	Audio.sfx(&"heal")
	DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.7, 0.2), "SECOND WIND!")
	var tw := v.create_tween()
	tw.tween_property(v, "scale", full, 0.45 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if is_instance_valid(v):
		v.busy = false
	m.refresh_pieces()


## A lane turns into another land: the ground sweeps out from the creature or building that
## caused it, the land's sparkle bursts and its name floats up.
func _land_changed(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var land: int = d["land"]
	var origin := Vector3.INF
	var v: CreatureView = _view(p, l)
	if d.get("cause", &"") == &"building" or (v == null and is_instance_valid(m.building_views[p][l])):
		origin = m.board.building_point(p, l)
	elif v:
		origin = v.global_position
	m.board.change_land(p, l, land, origin)
	var centre := Vector3(m.board.lane_x(l, p), Island.TOP_Y + 0.3, Board.STRIP_Z[p])
	Burst.spawn(m, LAND_BURSTS[land], origin if origin.is_finite() else centre, Color.WHITE, 1.4)
	Audio.sfx(LAND_SOUNDS[land])
	DamageNumber.spawn(m, centre + Vector3(0, 0.6, 0), Lands.lane_name(land) + "!", Palette.LAND_CARD[land], 64)
	await _wait(0.5)


## A spell meets the land under its target: the reaction's name over the lane and its look.
func _land_reaction(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var r: StringName = d["reaction"]
	var pos: Vector3 = FxDirector.spot(m, p, l) + Vector3(0, 0.3, 0)
	var v: CreatureView = _view(p, l)
	if v:
		pos = v.global_position + Vector3(0, 0.2, 0)
	match r:
		&"melt", &"quench":
			Burst.spawn(m, &"steam", pos, Color.WHITE, 1.6)
			Burst.spawn(m, &"steam", pos + Vector3(0.4, 0, 0.3), Color.WHITE, 1.2)
			Audio.sfx(&"fire_whoosh" if r == &"melt" else &"ice_shatter")
		&"wildfire":
			for n: int in [l - 1, l, l + 1]:
				if n >= 0 and n < 4:
					Burst.spawn(m, &"flames", FxDirector.spot(m, p, n) + Vector3(0, 0.2, 0), Color.WHITE, 1.3)
			Audio.sfx(&"fire_whoosh")
		&"caramel":
			Burst.spawn(m, &"caramel", pos + Vector3(0, 0.5, 0), Color.WHITE, 1.4)
			Audio.sfx(&"candy_pop")
		&"scorch":
			Burst.spawn(m, &"flames", pos, Color.WHITE, 1.2)
			Burst.spawn(m, &"sand", pos, Color("#ffcf7a"), 1.4)
			Audio.sfx(&"fire_whoosh")
		&"thaw":
			Burst.spawn(m, &"steam", pos, Color.WHITE, 1.3)
			Burst.spawn(m, &"heal", pos, Color("#ffd27a"), 1.2)
			Audio.sfx(&"heal")
		&"bloom", &"sprout":
			Burst.spawn(m, &"petals", pos + Vector3(0, 0.3, 0), Color.WHITE, 1.5)
			Burst.spawn(m, &"heal", pos, Color.WHITE, 1.2)
			Audio.sfx(&"heal")
	DamageNumber.stamp(m, pos + Vector3(0, 0.9, 0.2), Lands.REACTION_NAMES[r].to_upper() + "!")
	m.toast.show_message(Lands.REACTION_RULES[r], 1.6)
	await _wait(0.45)


## A creature levels up: light column, hop and spin, gold sparkles, LEVEL UP!
func _level_up(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	Audio.sfx(&"magic_gain")
	Audio.sfx(&"candy_pop")
	Burst.spawn(m, &"gold", v.global_position + Vector3(0, 0.4, 0), Color.WHITE, 1.3)
	DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.8, 0.25), "LEVEL %d!" % d["level"])
	await v.play_level_up(d["level"], speed)
	m.overlay.refresh(m.state)


## A field spell takes over the table: banner, weather over every lane, room light and prop.
func _field_set(d: Dictionary) -> void:
	var c: CardData = CardDB.card(d["card"])
	Banner.show_turn(m.hud, c.display_name.to_upper() + "!", Palette.LAND_CARD[c.land])
	m.board.set_field(c.land)
	if m.field_fx:
		m.field_fx.set_field(c.land)
	m.hud.refresh(m.state, MatchController.HUMAN)
	await _wait(0.9)


## The rival's card shows large at the right of the board for a moment before it lands (the
## action log has the left).
## The rival's card slides in face down (their card back), flips over and lingers.
func _reveal(c: CardData) -> void:
	var w := Control.new()
	w.size = CardWidget.SIZE
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.pivot_offset = CardWidget.SIZE / 2.0
	var face := CardWidget.new()
	face.setup(c, 0)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.visible = false
	w.add_child(face)
	var back: Control = FlyingCard.back_rect(m.card_backs[MatchController.AI]) if m.card_backs[MatchController.AI] else Control.new()
	w.add_child(back)
	var vp: Vector2 = m.hud.get_viewport_rect().size
	var at := Vector2(vp.x * 0.87, vp.y * 0.44) - CardWidget.SIZE / 2.0
	m.hud.add_child(w)
	w.position = at + Vector2(220, 0)
	w.scale = Vector2.ONE * 1.25
	w.rotation = 0.08
	w.modulate.a = 0.0
	var tw := w.create_tween().set_parallel()
	tw.tween_property(w, "position", at, 0.25 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "modulate:a", 1.0, 0.15 / speed)
	# The flip: squash to an edge, swap back for face, open up again.
	tw.chain().tween_property(w, "scale:x", 0.0, 0.12 / speed).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		back.visible = false
		face.visible = true)
	tw.chain().tween_property(w, "scale:x", 1.25, 0.14 / speed).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.0 / speed)
	tw.chain().tween_property(w, "modulate:a", 0.0, 0.25 / speed)
	tw.chain().tween_callback(w.queue_free)
	await _wait(0.55)


## Allies of `p` cheer, one after another.
func _cheer(p: int) -> void:
	var k: int = 0
	for o: Variant in m.creature_views[p]:
		if is_instance_valid(o):
			var cv: CreatureView = o
			get_tree().create_timer(0.08 * k).timeout.connect(func() -> void:
				if is_instance_valid(cv):
					cv.cheer())
			k += 1


## Where the spell now resolving lands: the creatures and heroes its events touch, up to the next
## ability, attack or turn change.
func _spell_targets() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var seen: Dictionary = {}
	for i: int in range(_at + 1, _batch.size()):
		var e: GameEvent = _batch[i]
		if e.type in [&"ability_triggered", &"attack", &"spell_cast", &"turn_started", &"creature_played"]:
			break
		var d: Dictionary = e.data
		var key: String = ""
		var at := Vector3.INF
		if e.type in [&"creature_damaged", &"creature_healed", &"frozen", &"buffed", &"creature_destroyed", &"creature_bounced", &"creature_transformed", &"doomed", &"keyword_gained"]:
			key = "c%d:%d" % [d["player"], d["lane"]]
			at = FxDirector.spot(m, d["player"], d["lane"]) + Vector3(0, 0.4, 0)
		elif e.type in [&"hero_damaged", &"hero_healed", &"armour_gained"]:
			key = "h%d" % d["player"]
			at = FxDirector._hero_pos(m, d["player"])
		if key != "" and not seen.has(key):
			seen[key] = true
			out.append(at)
	return out


## Casting a spell: the card flies to the middle (the rival's flips face up on the way), glows in
## its land's colour, then bursts into the spell.
func _cast_card(c: CardData, human: bool) -> void:
	var vp: Vector2 = m.hud.get_viewport_rect().size
	var w := Control.new()
	w.size = CardWidget.SIZE
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.pivot_offset = CardWidget.SIZE / 2.0
	var glow := Panel.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.position = Vector2(-10, -10)
	glow.size = CardWidget.SIZE + Vector2(20, 20)
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(Palette.LAND_CARD[c.land], 0.0)
	gsb.set_corner_radius_all(18)
	gsb.shadow_color = Color(Palette.LAND_CARD[c.land].lightened(0.3), 0.9)
	gsb.shadow_size = 26
	glow.add_theme_stylebox_override("panel", gsb)
	glow.modulate.a = 0.0
	w.add_child(glow)
	var face := CardWidget.new()
	face.setup(c, -1)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(face)
	var back: Control = null
	if not human and m.card_backs[MatchController.AI]:
		back = FlyingCard.back_rect(m.card_backs[MatchController.AI])
		w.add_child(back)
		face.visible = false
	m.hud.add_child(w)
	var from: Vector2 = m.hand.last_drop_pos if human and m.hand.last_drop_pos != Vector2.ZERO else (Vector2(vp.x * 0.5, vp.y - 60.0) if human else m.rival_hand_screen())
	var centre := Vector2(vp.x * 0.5, vp.y * 0.42)
	w.position = from - CardWidget.SIZE / 2.0
	w.scale = Vector2.ONE * 0.6
	var tw := w.create_tween()
	tw.set_parallel(true)
	tw.tween_property(w, "position", centre - CardWidget.SIZE / 2.0, 0.24 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "scale", Vector2.ONE * 1.3, 0.24 / speed)
	if back:
		tw.chain().tween_property(w, "scale:x", 0.0, 0.08 / speed)
		tw.chain().tween_callback(func() -> void:
			back.visible = false
			face.visible = true)
		tw.chain().tween_property(w, "scale:x", 1.3, 0.09 / speed)
	tw.chain().tween_property(glow, "modulate:a", 1.0, 0.12 / speed)
	tw.chain().tween_interval(0.18 / speed)
	tw.chain().tween_property(w, "scale", Vector2.ONE * 1.75, 0.14 / speed).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(w, "modulate", Color(2.0, 2.0, 2.0, 0.0), 0.14 / speed)
	tw.chain().tween_callback(w.queue_free)
	await tw.finished


## Hand full: the card shows up, chars from the edges inward and crumbles away in embers.
func _burn_card(c: CardData, human: bool) -> void:
	if c == null:
		return
	var vp: Vector2 = m.hud.get_viewport_rect().size
	var w := CardWidget.new()
	w.setup(c, -1)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.pivot_offset = CardWidget.SIZE / 2.0
	m.hud.add_child(w)
	var at := Vector2(vp.x * (0.62 if human else 0.5), vp.y * (0.55 if human else 0.3))
	w.position = (m.hud.deck_screen_pos(human) if human else m.rival_hand_screen()) - CardWidget.SIZE / 2.0
	w.scale = Vector2.ONE * 0.5
	var embers := CPUParticles2D.new()
	embers.amount = 40
	embers.lifetime = 0.8
	embers.emitting = false
	embers.one_shot = true
	embers.explosiveness = 0.6
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = CardWidget.SIZE / 2.0
	embers.position = CardWidget.SIZE / 2.0
	embers.direction = Vector2.UP
	embers.spread = 40.0
	embers.gravity = Vector2(0, -160)
	embers.initial_velocity_min = 30.0
	embers.initial_velocity_max = 90.0
	embers.scale_amount_min = 3.0
	embers.scale_amount_max = 6.0
	embers.color = Color("#ff9a2a")
	w.add_child(embers)
	var tw := w.create_tween()
	tw.set_parallel(true)
	tw.tween_property(w, "position", at - CardWidget.SIZE / 2.0, 0.25 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "scale", Vector2.ONE * 1.1, 0.25 / speed)
	tw.chain().tween_callback(func() -> void: embers.emitting = true)
	tw.chain().tween_property(w, "modulate", Color(1.4, 0.6, 0.2, 1.0), 0.18 / speed)
	tw.chain().tween_property(w, "modulate", Color(0.15, 0.1, 0.08, 0.0), 0.35 / speed)
	tw.parallel().tween_property(w, "scale", Vector2(1.0, 0.85), 0.35 / speed)
	tw.parallel().tween_property(w, "rotation", 0.12, 0.35 / speed)
	tw.chain().tween_interval(0.5)
	tw.chain().tween_callback(w.queue_free)
	await _wait(0.8)


# --- Deaths by cause (look & feel spec 1) ----------------------------------------------------

## What the hit in `d` was like: big (crit or 4+ damage), fire (an Ember ability or spell), and
## where it came from (to knock the creature away from it).
func _hit_info(d: Dictionary) -> Dictionary:
	var crit: bool = _source.get("kind") == &"attack" and int(_source.get("hit", Action.Hit.NORMAL)) == Action.Hit.CRIT
	var fire: bool = false
	if _source.get("kind") == &"ability":
		var c: CardData = CardDB.card(_source.get("card", &""))
		fire = c != null and c.land == CardData.Land.EMBER
	var from := Vector3.INF
	if _source.has("lane") and int(_source["lane"]) >= 0:
		from = FxDirector.spot(m, _source["player"], _source["lane"])
	return {"big": crit or int(d.get("amount", 0)) >= 4, "fire": fire, "from": from}


## Knocked flying: up and away from the hit, spinning, then a puff of stars.
func _death_fly(v: CreatureView, from: Vector3) -> void:
	Audio.sfx(&"hit_heavy")
	var start: Vector3 = v.global_position
	var away := Vector3(start.x - from.x, 0, start.z - from.z) if from.is_finite() else Vector3(0, 0, -1)
	away = away.normalized() if away.length() > 0.01 else Vector3(0, 0, -1)
	var dur: float = 0.55 / speed
	var tw := v.create_tween().set_parallel(true)
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(v):
			v.global_position = start + away * 2.4 * k + Vector3(0, sin(k * PI * 0.8) * 2.2, 0), 0.0, 1.0, dur)
	tw.tween_property(v, "rotation", v.rotation + Vector3(TAU * 1.5, TAU, 0), dur)
	tw.tween_property(v, "scale", v.scale * 0.4, dur).set_ease(Tween.EASE_IN)
	await tw.finished
	if is_instance_valid(v):
		Burst.spawn(m, &"stars", v.global_position, Color.WHITE, 1.4)
		Burst.spawn(m, &"smoke", v.global_position, Color.WHITE, 0.8)
		v.queue_free()
	await _wait(0.1)


## Frozen solid: the ice and the creature burst into shards together.
func _death_shatter(v: CreatureView) -> void:
	Audio.sfx(&"ice_shatter")
	var at: Vector3 = v.global_position + Vector3(0, v.height * 0.5, 0)
	v.set_frozen(false)
	Burst.spawn(m, &"snow", at, Color("#e8f6ff"), 1.8)
	Burst.spawn(m, &"sparks", at, Color("#bfe8ff"), 1.5)
	ShockRing.spawn(m, v.global_position + Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + 0.05, 0), Color("#d6f2ff"), 0.9, 0.35 / speed)
	var tw := v.create_tween()
	tw.tween_property(v, "scale", v.scale * Vector3(1.25, 0.2, 1.25), 0.12 / speed)
	await tw.finished
	if is_instance_valid(v):
		v.queue_free()
	await _wait(0.1)


## Burnt by fire: it chars dark, embers rise and it crumbles to ash.
func _death_ash(v: CreatureView) -> void:
	Audio.sfx(&"fire_whoosh")
	var at: Vector3 = v.global_position + Vector3(0, v.height * 0.4, 0)
	var tw := v.create_tween()
	tw.tween_method(func(x: float) -> void:
		if is_instance_valid(v) and v.body:
			Toon.set_shade(v.body, x), 0.0, 4.0, 0.25 / speed)
	await tw.finished
	if not is_instance_valid(v):
		return
	Burst.spawn(m, &"embers", at, Color.WHITE, 1.6)
	Burst.spawn(m, &"smoke", at, Color("#3a3a3a"), 1.2)
	var crumble := v.create_tween().set_parallel(true)
	crumble.tween_property(v, "scale", v.scale * Vector3(1.2, 0.05, 1.2), 0.3 / speed).set_ease(Tween.EASE_IN)
	await v.dissolve(0.3 / speed)
	if is_instance_valid(v):
		v.queue_free()
	await _wait(0.1)


# --- Keyword moments (keywords spec 4) -------------------------------------------------------

## True when the creature damaged in `d` was hit by a creature with Venom (an attacker, or a
## defender hitting back, or an ability's source).
func _dealt_by_venom(d: Dictionary) -> bool:
	if _source.is_empty() or not _source.has("lane"):
		return false
	var sp: int = _source["player"]
	var sl: int = _source["lane"]
	if _source["kind"] == &"attack" and int(d["player"]) == sp and int(d["lane"]) == sl:
		# Hit-back: the defender dealt this damage.
		sp = 1 - sp
		sl = int(_source.get("target_lane", -1))
	if sl < 0:
		return false
	if Rules.has_keyword(m.state, sp, sl, &"venom"):
		return true
	var fx: KeywordFx = KeywordFx.of(_view(sp, sl))
	return fx != null and fx.has_part(&"venom")


func _bubble_popped(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	Audio.sfx(&"candy_pop")
	if v == null:
		return
	var fx: KeywordFx = KeywordFx.of(v)
	var pos: Vector3 = v.global_position + Vector3(0, v.height * 0.5, 0)
	if fx and fx.has_part(&"bubble"):
		var b: Node3D = fx.part(&"bubble")
		pos = b.global_position
		b.set_meta(&"settled", false)
		var tw := b.create_tween()
		tw.tween_property(b, "scale", b.scale * 1.35, 0.09 / speed)
		await tw.finished
		fx.detach(&"bubble")
	Burst.spawn(m, &"sprinkles", pos, VisualDB.KEYWORD_COLORS[&"bubble"].lightened(0.4), 1.2)
	Burst.spawn(m, &"snow", pos, Color("#e8f8ff"), 1.0)
	DamageNumber.stamp(m, pos + Vector3(0, v.height * 0.5 + 0.4, 0.2), "POP!")
	m.overlay.refresh(m.state)
	await _wait(0.2)


func _revealed(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	var fx: KeywordFx = KeywordFx.of(v)
	if fx:
		fx.detach(&"hidden")
	var pos: Vector3 = v.global_position + Vector3(0, v.height * 0.5, 0)
	Burst.spawn(m, &"stars", pos, VisualDB.KEYWORD_COLORS[&"hidden"].lightened(0.5), 1.2)
	Burst.spawn(m, &"smoke", pos, Color("#b9a8ff"), 0.8)
	Audio.sfx(&"magic_gain")
	DamageNumber.stamp(m, pos + Vector3(0, v.height * 0.5 + 0.4, 0.2), "REVEALED!")
	m.overlay.refresh(m.state)
	await _wait(0.25)


func _hushed(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	var fx: KeywordFx = KeywordFx.of(v)
	if fx:
		fx.set_keywords([] as Array[StringName])
	ShockRing.spawn(m, v.global_position + Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + 0.05, 0), Color("#cfd3dc"), 1.0, 0.45 / speed)
	Audio.sfx(&"ui_click")
	DamageNumber.stamp(m, v.global_position + Vector3(0, v.height + 0.7, 0.2), "HUSHED")
	m.overlay.refresh(m.state)
	await _wait(0.35)


func _keyword_gained(d: Dictionary) -> void:
	var p: int = d["player"]
	var l: int = d["lane"]
	var kw: StringName = d["keyword"]
	var v: CreatureView = _view(p, l)
	m.overlay.refresh(m.state)
	if v == null:
		return
	KeywordFx.sync(v, UnitOverlay.shown_keywords(m.state, p, l), MatchController.enemy_side_z(p))
	var col: Color = VisualDB.KEYWORD_COLORS.get(kw, Palette.GOLD)
	Burst.spawn(m, &"stars", v.global_position + Vector3(0, v.height * 0.6, 0), col, 1.0)
	DamageNumber.spawn(m, v.global_position + Vector3(0, v.height + 0.45, 0), "+%s" % Keywords.NAMES.get(kw, String(kw)).to_upper(), col, 44)
	await _wait(0.25)


func _buffed(d: Dictionary) -> void:
	m.hud.refresh(m.state, MatchController.HUMAN)
	m.overlay.refresh(m.state)
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	var atk: int = d.get("atk", 0)
	var hp: int = d.get("hp", 0)
	if atk == 0 and hp == 0:
		return
	var tag: Control = m.overlay.tag(d["player"], d["lane"])
	var tw := tag.create_tween()
	tw.tween_property(tag, "modulate", Color(1.6, 1.5, 0.8), 0.08 / speed)
	tw.tween_property(tag, "modulate", Color.WHITE, 0.3 / speed)
	var txt: String = "%+d/%+d" % [atk, hp] if atk != 0 and hp != 0 else ("%+d ATK" % atk if atk != 0 else "%+d HP" % hp)
	DamageNumber.spawn(m, v.global_position + Vector3(0, v.height + 0.4, 0), txt, Palette.GOLD if atk + hp > 0 else Palette.HP, 40)
	await _wait(0.12)


## Leech: red wisps fly from the creature to its hero, whose heal follows.
func _leeched(d: Dictionary) -> void:
	var v: CreatureView = _view(d["player"], d["lane"])
	var from: Vector3 = v.global_position + Vector3(0, v.height * 0.6, 0) if v else FxDirector.spot(m, d["player"], d["lane"])
	var to: Vector3 = FxDirector._hero_pos(m, d["player"])
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color("#ff3a5a", 0.9)
	var count: int = clampi(int(d.get("amount", 1)) + 2, 3, 5)
	var dur: float = 0.5 / speed
	for i: int in count:
		var w := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		sm.radial_segments = 8
		sm.rings = 4
		w.mesh = sm
		w.material_override = mat
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(w)
		w.global_position = from
		var bend := Vector3(randf_range(-1.2, 1.2), randf_range(0.8, 1.6), randf_range(-0.4, 0.4))
		var delay: float = i * 0.06 / speed
		var tw := w.create_tween()
		tw.tween_interval(delay)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(w):
				var a: Vector3 = from.lerp(from + bend, k)
				var b: Vector3 = (from + bend).lerp(to, k)
				w.global_position = a.lerp(b, k)
				w.scale = Vector3.ONE * (1.0 - k * 0.5), 0.0, 1.0, dur)
		tw.tween_callback(w.queue_free)
	Audio.sfx(&"heal")
	await _wait(0.5 + count * 0.06)
	Burst.spawn(m, &"heal", to, Color("#ff6a8a"), 1.0)


## Flurry: two quick slashes of sparks where the attack lands, with a second whoosh.
func _flurry_swoosh(v: CreatureView, target: Vector3) -> void:
	var col: Color = VisualDB.KEYWORD_COLORS[&"flurry"].lightened(0.4)
	var at: Vector3 = target + Vector3(0, v.height * 0.6, 0)
	for i: int in 2:
		get_tree().create_timer((0.22 + i * 0.1) / speed).timeout.connect(func() -> void:
			if is_instance_valid(m):
				Burst.spawn(m, &"sparks", at + Vector3(0.15 * (1 - 2 * i), 0.1 * i, 0), col, 1.1)
				Audio.sfx(&"attack_whoosh"))


func _view(p: int, l: int) -> CreatureView:
	var v: Variant = m.creature_views[p][l]
	return v as CreatureView if is_instance_valid(v) else null


# --- Sequences -----------------------------------------------------------------

func _play_creature(d: Dictionary) -> void:
	var c: CardData = CardDB.card(d["card"])
	var p: int = d["player"]
	var lane_screen: Vector2 = m.rig.camera.unproject_position(m.board.anchor(p, d["lane"]))
	var human: bool = p == MatchController.HUMAN
	Audio.sfx(&"card_play")
	var from: Vector2 = m.hand.last_drop_pos if human and m.hand.last_drop_pos != Vector2.ZERO else (m.hud.hero_screen_pos(true) if human else m.rival_hand_screen())
	FlyingCard.fly(m.hud, c, from, lane_screen, human, 0.22 / speed, m.card_backs[p])
	await _wait(0.22)
	var drop := Vector3.INF
	if human and m.hand.last_drop_pos != Vector2.ZERO:
		drop = m.board.ground_at_screen(m.rig.camera, m.hand.last_drop_pos)
	var v: CreatureView = m.place_creature(p, d["lane"], c, drop)
	var target: Vector3 = v.position
	# The card bursts into a puff of its land's colour; the creature drops out of it.
	Burst.spawn(m, &"smoke", target + Vector3(0, 2.6, 0), Palette.LAND_CARD[c.land], 1.3)
	Burst.spawn(m, &"stars", target + Vector3(0, 2.6, 0), Palette.LAND_CARD[c.land].lightened(0.3), 1.0)
	v.position = target + Vector3(0, 3, 0)
	v.busy = true
	var tw := v.create_tween()
	tw.tween_property(v, "position", target, 0.4 / speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	v.busy = false
	v.spring(0.3)
	v.hop_happy()
	m.refresh_pieces()
	Audio.sfx(&"creature_land")
	var feet: Vector3 = target - Vector3(0, 0.4, 0)
	Burst.spawn(m, &"dust_ring", feet)
	Burst.spawn(m, LAND_BURSTS[c.land], feet + Vector3(0, 0.3, 0), Color.WHITE, 1.2)
	m.rig.kick(0.08)
	if c.legendary:
		await DarkMoonFx.legendary(self, target)
	if &"dash" in c.keywords:
		# Dash: a skid of dust and speed sparks, ready to go.
		Burst.spawn(m, &"dust_ring", feet, Color.WHITE, 1.6)
		Burst.spawn(m, &"sparks", feet + Vector3(0, 0.25, 0), VisualDB.KEYWORD_COLORS[&"dash"], 1.3)
		DamageNumber.stamp(m, target + Vector3(0, v.height + 0.5, 0.2), "DASH!")


func _play_building(d: Dictionary) -> void:
	var b: BuildingView = m.place_building(d["player"], d["lane"], CardDB.card(d["card"]))
	Audio.sfx(&"card_play")
	Audio.sfx(&"building_rise")
	var home: Vector3 = b.position
	b.position = home - Vector3(0, 1.2, 0)
	var tw := b.create_tween()
	tw.tween_property(b, "position", home, 0.35 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Burst.spawn(m, &"dust_ring", home + Vector3(0, 0.15, 0))
	m.rig.kick(0.1)
	await tw.finished


func _death(d: Dictionary) -> void:
	m.input.creature_gone(d["player"], d["lane"])
	var v: CreatureView = _view(d["player"], d["lane"])
	if v == null:
		return
	m.creature_views[d["player"]][d["lane"]] = null
	v.busy = true
	var key: String = "%d:%d" % [d["player"], d["lane"]]
	var info: Dictionary = _last_hit.get(key, {})
	if not _venomed.has(key):
		if v.is_frozen_visual():
			await _death_shatter(v)
			return
		if info.get("fire", false):
			await _death_ash(v)
			return
		if info.get("big", false):
			await _death_fly(v, info.get("from", Vector3.INF))
			return
	var death: float = v.play_death()
	if death > 0.0:
		await _wait(minf(death, 0.9) * 0.8)
	if not is_instance_valid(v):
		return
	var at: Vector3 = v.global_position + Vector3(0, 0.3, 0)
	if _venomed.has("%d:%d" % [d["player"], d["lane"]]):
		# Venom: the creature melts away in green.
		Burst.spawn(m, &"smoke", at, KeywordFx.VENOM_GREEN, 1.3)
		Burst.spawn(m, &"caramel", at + Vector3(0, 0.2, 0), KeywordFx.VENOM_GREEN, 1.1)
		DamageNumber.stamp(m, at + Vector3(0, v.height + 0.4, 0.2), "VENOM!")
	else:
		Burst.spawn(m, &"smoke", at, Color.WHITE, 1.2)
	if v.card:
		Burst.spawn(m, LAND_BURSTS[v.card.land], at, Color.WHITE, 1.2)
	await v.dissolve(0.35 / speed)
	if is_instance_valid(v):
		v.queue_free()
	await _wait(0.1)


func _attack(d: Dictionary) -> void:
	var p: int = d["player"]
	var lane: int = d["lane"]
	var v: CreatureView = _view(p, lane)
	if v == null:
		return
	var foe: int = 1 - p
	var tl: int = int(d.get("target_lane", -1))
	var tv: CreatureView = _view(foe, tl) if tl >= 0 else null
	var home: Vector3 = v.position
	var hero: bool = tl < 0
	var target: Vector3
	if tv:
		tv.busy = true
		# Stop just short of the target, wherever it stands.
		var to: Vector3 = tv.position
		var gap := Vector3(to.x - home.x, 0.0, to.z - home.z)
		target = to - gap.normalized() * minf(0.35, gap.length() * 0.5)
	else:
		target = m.board.hero_point(foe, lane)
		target.x = home.x
	v.busy = true
	var out_t: float = 0.3 / speed
	var back_t: float = 0.4 / speed
	m.rig.close_up(v.global_position, Vector3(target.x, home.y, target.z), (0.2 + 0.3 + 0.15 + 0.4 + (0.35 if hero else 0.0)) / speed)
	# A big attacker makes the small creatures on that side duck.
	if v.card and (v.card.attack >= 5 or v.height >= 0.9):
		for o: Variant in m.creature_views[foe]:
			if is_instance_valid(o) and o != tv and (o as CreatureView).height < 0.7:
				(o as CreatureView).cower()
	# Wind-up squash with a glint, the target bracing and turning to face it, then the run (the
	# impact plays with the damage event that follows).
	Burst.spawn(m, &"stars", v.global_position + Vector3(0, v.height + 0.2, 0), Palette.GOLD, 0.5)
	if tv:
		var face := Vector2(v.position.x - tv.position.x, v.position.z - tv.position.z)
		if face.length() > 0.01:
			tv.rotation.y = atan2(face.x, face.y)
		if tv.body:
			var tb: Vector3 = tv.rest_scale()
			var brace := tv.create_tween()
			brace.tween_property(tv.body, "scale", tb * Vector3(1.1, 0.88, 1.1), 0.12 / speed)
			brace.tween_property(tv.body, "scale", tb, 0.3 / speed).set_delay(0.25 / speed)
	var base: Vector3 = v.rest_scale()
	var wind := v.create_tween()
	wind.tween_property(v.body, "scale", base * Vector3(1.15, 0.8, 1.15), 0.12 / speed)
	wind.tween_property(v.body, "scale", base, 0.08 / speed)
	await wind.finished
	if not is_instance_valid(v):
		return
	var flat := Vector2(target.x - home.x, target.z - home.z)
	if flat.length() > 0.01:
		v.rotation.y = atan2(flat.x, flat.y)
	v.play_attack()
	if Rules.has_keyword(m.state, p, lane, &"flurry"):
		_flurry_swoosh(v, target)
	var trail := Burst.spawn(v, &"dust_ring", v.global_position, Color(1, 1, 1, 0.6), 0.4)
	trail.one_shot = false
	var out := v.create_tween()
	out.tween_method(func(k: float) -> void:
		v.position = home.lerp(target, k * k) + Vector3(0, sin(k * PI) * 0.5, 0), 0.0, 1.0, out_t)
	await out.finished
	if is_instance_valid(trail):
		trail.queue_free()
	if not is_instance_valid(v):
		return
	var turn_back: Vector3 = target
	if hero:
		turn_back = await _hero_leap(v, target, foe)
		if not is_instance_valid(v):
			return
	if tv:
		var t_ref: CreatureView = tv
		get_tree().create_timer(0.6 / speed).timeout.connect(func() -> void:
			if is_instance_valid(t_ref):
				t_ref.busy = false)
	var back := v.create_tween()
	back.tween_interval(0.15 / speed)
	back.tween_method(func(k: float) -> void:
		v.position = turn_back.lerp(home, k) + Vector3(0, sin(k * PI) * 0.3, 0), 0.0, 1.0, back_t)
	back.tween_callback(func() -> void:
		v.position = home
		v.busy = false)


## From the board's edge: a leap at the rival (who flinches with the damage) or, when the rival's
## creature attacks you, at the camera with a shake. Returns where the creature lands again.
func _hero_leap(v: CreatureView, edge: Vector3, foe: int) -> Vector3:
	var peak: Vector3
	if foe == MatchController.AI and m.rival:
		peak = edge.lerp(m.rival.hand_point(), 0.45)
	else:
		peak = edge.lerp(m.rig.camera.global_position, 0.35)
	var up := v.create_tween()
	up.tween_method(func(k: float) -> void:
		v.position = edge.lerp(peak, k) + Vector3(0, sin(k * PI) * 0.4, 0), 0.0, 1.0, 0.18 / speed)
	await up.finished
	if foe == MatchController.HUMAN:
		m.rig.kick(0.6)
	var down := v.create_tween()
	down.tween_method(func(k: float) -> void:
		v.position = peak.lerp(edge, k), 0.0, 1.0, 0.17 / speed)
	await down.finished
	return edge


## Brief freeze-frame on impact. Always restores the time scale.
## Freeze-frame on impact, by the timing-bar result: a crit holds longer and then runs in slow
## motion for a moment; a glancing blow barely pauses.
func hit_stop(hit: int = Action.Hit.NORMAL) -> void:
	var hold: float = HIT_STOP
	if hit == Action.Hit.CRIT:
		hold = HIT_STOP_CRIT
	elif hit == Action.Hit.GLANCE:
		hold = HIT_STOP * 0.4
	Engine.time_scale = HIT_STOP_SCALE
	await get_tree().create_timer(hold / speed, true, false, true).timeout
	if hit == Action.Hit.CRIT:
		Engine.time_scale = SLOW_MO
		await get_tree().create_timer(SLOW_MO_TIME / speed, true, false, true).timeout
	Engine.time_scale = 1.0


## Knocked back by a hit from `from`: squashes and slides away, then springs home.
func knockback(v: CreatureView, from: Vector3, strength: float) -> void:
	var base: Vector3 = v.position
	var away := Vector3(base.x - from.x, 0, base.z - from.z)
	away = away.normalized() if away.length() > 0.01 else Vector3(0, 0, -1)
	var push: Vector3 = away * clampf(strength, 0.05, 0.45)
	var body_base: Vector3 = v.rest_scale()
	var tw := v.create_tween().set_parallel(true)
	tw.tween_property(v, "position", base + push, 0.07 / speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if v.body:
		tw.tween_property(v.body, "scale", body_base * Vector3(1.3, 0.7, 1.3), 0.07 / speed)
	tw.chain().tween_property(v, "position", base, 0.3 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if v.body:
		tw.parallel().tween_property(v.body, "scale", body_base, 0.3 / speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished


## A quick squash of the body: the hit-back reaction (leaves the position alone).
func recoil(v: CreatureView) -> void:
	if v.body == null:
		return
	var base: Vector3 = v.rest_scale()
	var tw := v.create_tween()
	tw.tween_property(v.body, "scale", base * Vector3(1.25, 0.75, 1.25), 0.07 / speed)
	tw.tween_property(v.body, "scale", base, 0.18 / speed).set_trans(Tween.TRANS_ELASTIC)
	await tw.finished


func shake(v: Node3D) -> void:
	var base: Vector3 = v.position
	var tw := v.create_tween()
	for i: int in 5:
		tw.tween_property(v, "position", base + Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.06, 0.06)), 0.05 / speed)
	tw.tween_property(v, "position", base, 0.05 / speed)
	await tw.finished


## Moves a creature view to its new lane (a hop, or a spin for Swap Trick).
func move_piece(d: Dictionary, spin: bool) -> void:
	var p: int = d["player"]
	var from: int = d["from"]
	var to: int = d["to"]
	var key: String = "%d:%d:%d" % [p, to, from]
	if _skip_move.has(key):
		_skip_move.erase(key)
		return
	var a: Variant = m.creature_views[p][from]
	var b: Variant = m.creature_views[p][to]
	m.creature_views[p][to] = a
	m.creature_views[p][from] = b
	if is_instance_valid(b):
		_skip_move["%d:%d:%d" % [p, from, to]] = true  # Swap Trick emits the reverse move too
	var dur: float = 0.4 / speed
	var tw := create_tween().set_parallel(true)
	var moved: Array[Array] = []
	for pair: Array in [[a, to], [b, from]]:
		if not is_instance_valid(pair[0]):
			continue
		var node: CreatureView = pair[0]
		node.busy = true
		moved.append(pair)
		var start: Vector3 = node.position
		var end: Vector3 = m.board.anchor(p, pair[1])
		tw.tween_method(func(k: float) -> void:
			node.position = start.lerp(end, k) + Vector3(0, sin(k * PI) * 0.8, 0), 0.0, 1.0, dur)
		if spin:
			tw.tween_property(node, "rotation:y", node.rotation.y + TAU, dur)
	await tw.finished
	for pair: Array in moved:
		var node: CreatureView = pair[0]
		if is_instance_valid(node):
			node.busy = false
			node.wanderer.set_zone(m.board.roam_rect(p, pair[1]))
	m.refresh_pieces()


## The building pops up and shrinks away toward its owner's side.
func return_building(d: Dictionary) -> void:
	var b: Variant = m.building_views[d["player"]][d["lane"]]
	if not is_instance_valid(b):
		return
	m.building_views[d["player"]][d["lane"]] = null
	var node: Node3D = b
	Audio.sfx(&"candy_pop")
	Burst.spawn(m, &"sprinkles", node.global_position + Vector3(0, 0.6, 0))
	var tw := node.create_tween()
	tw.tween_property(node, "position", node.position + Vector3(0, 1.2, 0), 0.18 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector3.ZERO, 0.22 / speed)
	await tw.finished
	node.queue_free()
