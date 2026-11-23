class_name MatchController
extends Node3D
## Owns a match: game state, board and (later) HUD, input and playback.

## Human is always player 0 (near the camera).
const HUMAN := 0
const AI := 1
const RIVAL_MODEL := "res://assets/heroes/Barbarian.glb"
## Canvas layer of the HUD (stat bars sit below it, the board hover card above it).
const HUD_LAYER := 2

var state: GameState
var board: Board
var rig: CameraRig
var room: Room
var rival: RivalSeat
## The field spell's weather, light and table prop.
var field_fx: FieldFx
## Both players' deck and discard piles on the table.
var stacks: CardStacks
## The 3D card shown while a hand card is dragged over the board.
var drag_card: DragCard3D
## Each player's card back (CardBacks), from their deck's main land.
var card_backs: Array[Texture2D] = [null, null]
var _ui_root: Control
var action_log: ActionLog
## Creatures placed so far (seeds each one's wandering).
var _placed: int = 0
var hud: Hud
var hand: Hand
var toast: Toast
var input: InputController
var player: EventPlayer
var timing_bar: TimingBar
var results: Results
var picker: DreamUpPicker
var overlay: UnitOverlay
var attack_arrow: AttackArrow
var difficulty: AIPlayer.Difficulty = AIPlayer.Difficulty.MEDIUM
## The canonical match and what this seat sees of it (`state` is `seats.view`).
var seats: SeatView
## Who plays the other side (the AI, or a person online).
var driver: RivalDriver
const AI_PAUSE := 0.6
## Divides AI pauses (tests speed this up).
var pace: float = 1.0
var busy: bool = false
var creature_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
## Creature houses (decoration), kept in step with the creatures by _sync_houses.
var house_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
var building_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
## Where MENU / LEAVE MATCH go (tests clear it to stay in the scene).
var menu_scene: String = "res://menus/main_menu.tscn"
## How often verify_views had to rebuild pieces from the state (should stay 0).
var view_resyncs: int = 0


func _ready() -> void:
	# An online match that already ended (a rejoin can land after the end) still opens online, to
	# show its result.
	var online: OnlineSession = Online.session
	if online == null or not online.status in [&"playing", &"over"] or online.state == null:
		online = null
	var seed: int
	var deck_a: DeckData
	var deck_b: DeckData
	var opening: Array[GameEvent]
	if online:
		# Online: the session owns the canonical match; this seat sees itself as player 0.
		seed = online.seed
		deck_a = online.decks[online.seat]
		deck_b = online.decks[1 - online.seat]
		seats = SeatView.new(online.state, online.seat)
		state = seats.view
		driver = OnlineRival.new(online)
		driver.m = self
		opening = seats.events_to_view(online.take_opening())
	else:
		seed = Session.match_seed()
		difficulty = Session.difficulty
		deck_a = CardDB.deck(Session.player_deck)
		deck_b = CardDB.deck(Session.resolve_ai_deck(seed))
		seats = SeatView.new(Rules.setup(deck_a, deck_b, seed), HUMAN)
		state = seats.view
		driver = AiRival.new(AIPlayer.new(AI, difficulty, seed + 7919))
		driver.m = self
		var real_opening: Array[GameEvent] = Rules.start_turn(seats.real)
		seats.sync()
		opening = seats.events_to_view(real_opening)
	card_backs = [CardBacks.texture_for(deck_a), CardBacks.texture_for(deck_b)]
	if "--demo-board" in OS.get_cmdline_user_args() and not online:
		var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 11), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, 12)]
		AIRunner.play_match(state, ais, 6)
	rig = CameraRig.new()
	add_child(rig)
	room = Room.new()
	add_child(room)
	room.build(Settings.quality)
	field_fx = FieldFx.new()
	field_fx.name = "FieldFx"
	add_child(field_fx)
	field_fx.setup(room, Settings.quality)
	stacks = CardStacks.new()
	stacks.name = "CardStacks"
	add_child(stacks)
	stacks.set_backs(card_backs[0], card_backs[1])
	rival = RivalSeat.new()
	add_child(rival)
	rival.setup(RIVAL_MODEL)
	rival.set_back(card_backs[1])
	rival.set_hand_count(state.players[AI].hand.size(), false)
	board = Board.new()
	add_child(board)
	var lands: Array[Array] = []
	for p: int in 2:
		var row: Array[int] = []
		for l: GameState.LaneState in state.players[p].lanes:
			row.append(l.land)
		lands.append(row)
	board.build(lands, BoardLayout.make(seed))
	_build_ui()
	if driver.is_online():
		hud.set_online(driver.rival_name())
	Audio.music(GameAudio.MATCH_MUSIC)
	sync_all()
	refresh_ui()
	if online:
		_begin(opening)
		return
	if "--demo-results" in OS.get_cmdline_user_args():
		results.show_result(true, 9)
		return
	if "--auto-attack" in OS.get_cmdline_user_args():
		_demo_attack()
		return
	if "--full-board" in OS.get_cmdline_user_args():
		_demo_full_board()
	if "--demo-expansion" in OS.get_cmdline_user_args():
		_demo_expansion()
		return
	if "--demo-keywords" in OS.get_cmdline_user_args():
		_demo_keywords()
		for act: String in OS.get_cmdline_user_args():
			if act.begins_with("--demo-act="):
				_demo_act(act.substr(11))
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--demo-living"):
			_demo_living(arg.substr(14) if arg.length() > 14 else "volcano")
			for act: String in OS.get_cmdline_user_args():
				if act.begins_with("--demo-act="):
					_demo_act(act.substr(11))
			return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--sweep-at="):
			rig.hold_sweep(float(arg.substr(11)))
			return
	_begin(opening)


## Esc opens or closes the menu (not over the results). Clicking a discard pile on the table shows
## its cards.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		if hud and not results.visible:
			hud.toggle_pause()
			get_viewport().set_input_as_handled()
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or stacks == null or rig.in_cinematic:
		return
	var hit: Dictionary = stacks.stack_at(rig.camera, mb.position)
	if hit.get("kind", &"") == &"discard":
		open_discard(hit["player"])
		get_viewport().set_input_as_handled()


func open_discard(p: int) -> DiscardViewer:
	var v := DiscardViewer.new()
	_ui_root.add_child(v)
	v.show_cards(state.players[p].discard, "Your discard pile" if p == HUMAN else "Rival's discard pile")
	Audio.sfx(&"card_flip")
	return v


## Where the rival's card fan is on screen: cards it draws fly there, cards it plays leave it.
func rival_hand_screen() -> Vector2:
	if rival and rig and rig.camera and rig.camera.is_inside_tree():
		return rig.camera.unproject_position(rival.hand_point())
	return hud.hero_screen_pos(false)


func _begin(opening: Array[GameEvent]) -> void:
	busy = true
	refresh_ui()
	if _wants_sweep():
		await rig.play_sweep()
		await board.reveal_split(true)
	else:
		board.reveal_split(false)
		await get_tree().create_timer(0.4).timeout
	await player.play(opening)
	await driver.begin()
	busy = false
	refresh_ui()


## The ground cover leans away from every creature on the board.
func _process(delta: float) -> void:
	if driver:
		driver.process(delta)
	if picker and picker.is_open() and not human_choosing():
		picker.force(-1)
	if board == null:
		return
	var pts := PackedVector3Array()
	for p: int in 2:
		for l: int in 4:
			var v: Variant = creature_views[p][l]
			if is_instance_valid(v):
				pts.append((v as Node3D).global_position)
	board.set_bend_points(pts)


## The opening sweep around the room, with input locked; a click or key press skips it.
func sweep() -> void:
	var was: bool = busy
	busy = true
	refresh_ui()
	await rig.play_sweep()
	busy = was
	refresh_ui()


## No sweep headless (tests) or for a screenshot unless --sweep-at asks for one.
func _wants_sweep() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot=") or arg.begins_with("--fps-log="):
			return false
	return true


func _demo_attack() -> void:
	state.turn = 3
	state.active = HUMAN
	state.phase = GameState.Phase.MAIN
	_demo_put(0, 1, &"flarebeak")
	_demo_put(1, 1, &"glacier_tortoise")
	sync_all()
	busy = true
	await perform(Action.attack(HUMAN, 1, 1, Action.Hit.CRIT, false))


## Dev: a ready creature in all 8 half-lanes (for frame-rate checks and screenshots).
func _demo_full_board() -> void:
	var ids: Array[StringName] = [&"mossback", &"flarebeak", &"gumdrop", &"iceling", &"glacier_tortoise", &"lollibat", &"cinderpup", &"sporeling"]
	for p: int in 2:
		for l: int in 4:
			_demo_put(p, l, ids[p * 4 + l])
	sync_all()


## Dev view of board look 2 + card expansion 2 (screenshots): every land claimed (so each shows a look), merged
## creatures and the new buildings, with the board already split.
func _demo_expansion() -> void:
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	var ids: Array[StringName] = [&"sporemoth", &"twinflame_hound", &"gummy_goliath", &"glacial_wisp", &"snowfang_alpha", &"candyfloss_bat", &"magma_wraith", &"mossback_colossus"]
	for p: int in 2:
		for l: int in 4:
			state.players[p].lanes[l].land = lands[p][l]
			_demo_put(p, l, ids[p * 4 + l])
	state.players[0].lanes[1].building = CardDB.card(&"bellows_forge")
	state.players[0].lanes[3].building = CardDB.card(&"frost_lookout")
	state.players[1].lanes[1].building = CardDB.card(&"gingerbread_gate")
	state.players[1].lanes[3].building = CardDB.card(&"fairy_ring")
	sync_all()
	board.reveal_split(false)
	refresh_ui()


## Dev view of the living board (screenshots): claimed lands, a field (--demo-living=<field id>),
## levelled creatures, buildings and armour.
func _demo_living(field_id: String) -> void:
	var lands: Array[Array] = [[0, 1, 4, 3], [2, 1, 1, 4]]
	var ids: Array[StringName] = [&"sporeling", &"flarebeak", &"gumdrop", &"snowmite", &"taffy_snail", &"cinderpup", &"magmaw", &"iceling"]
	var levels: Array[int] = [1, 3, 1, 2, 1, 2, 1, 1]
	for p: int in 2:
		state.players[p].armour = [5, 3][p]
		for l: int in 4:
			state.players[p].lanes[l].land = lands[p][l]
			_demo_put(p, l, ids[p * 4 + l])
			state.players[p].lanes[l].creature.level = levels[p * 4 + l]
	state.players[0].lanes[1].building = CardDB.card(&"kiln_tower")
	state.players[1].lanes[0].building = CardDB.card(&"sugar_shack")
	if field_id != "none":
		state.field = CardDB.card(StringName(field_id))
		state.field_owner = 1
	sync_all()
	board.reveal_split(false)
	refresh_ui()


## One scripted action in the living demo, for mid-animation screenshots: melt (fireball on
## the rival's Frostpeak lane... made Frostpeak first), claim (a creature into Meadow), level
## (an attack that levels up), field (Snowstorm replaces the field).
func _demo_act(act: String) -> void:
	busy = true
	state.active = HUMAN
	state.players[HUMAN].magic = 9
	await get_tree().create_timer(0.8).timeout
	match act:
		"melt":
			state.players[1].lanes[3].land = CardData.Land.FROST
			board.change_land(1, 3, CardData.Land.FROST, Vector3.INF, false)
			await perform(Action.play(HUMAN, Fx_give(&"fireball"), -1, [{"player": 1, "lane": 3}]))
		"claim":
			state.players[0].lanes[2].creature = null
			sync_all()
			await perform(Action.play(HUMAN, Fx_give(&"cinderpup"), 2))
		"level":
			state.players[0].lanes[3].creature.xp = 3
			state.players[0].lanes[3].creature.attacks_used = 0
			await perform(Action.attack(HUMAN, 3, 3, Action.Hit.NORMAL, false))
		"field":
			await perform(Action.play(HUMAN, Fx_give(&"snowstorm"), -1))
		"pop":
			# (--demo-keywords) the venom gumdrop attacks a bubbled rival.
			state.players[1].lanes[2].creature.gained.append(&"bubble")
			state.players[1].lanes[2].creature.bubble = true
			refresh_pieces()
			await perform(Action.attack(HUMAN, 2, 2, Action.Hit.NORMAL, false))
		"venom":
			await perform(Action.attack(HUMAN, 2, 2, Action.Hit.NORMAL, false))
		"dreamup":
			for l: int in 4:
				state.players[HUMAN].lanes[l].land = CardData.Land.CANDY
			state.players[HUMAN].lanes[1].creature = null
			sync_all()
			busy = false
			_on_action_requested(Action.play(HUMAN, Fx_give(&"bonbon_behemoth"), 1))
		"crit":
			state.players[0].lanes[3].creature.gained.erase(&"second_wind")
			await perform(Action.attack(HUMAN, 1, 1, Action.Hit.CRIT, false))
		"burn":
			await perform(Action.play(HUMAN, Fx_give(&"fireball"), -1, [{"player": 1, "lane": 3}]))
		"shatter":
			state.players[1].lanes[3].creature.freeze_turn = state.turn
			refresh_pieces()
			await get_tree().create_timer(0.4).timeout
			await perform(Action.attack(HUMAN, 1, 3, Action.Hit.CRIT, false))
		"leech":
			state.players[0].lanes[0].creature.gained.append(&"leech")
			state.players[0].hero_hp = 30
			await perform(Action.attack(HUMAN, 0, -1, Action.Hit.NORMAL, false))


func Fx_give(id: StringName) -> int:
	state.players[HUMAN].hand.append(CardDB.card(id))
	return state.players[HUMAN].hand.size() - 1


## Dev view (screenshots): one creature per keyword, with Bubble and Hidden up, plus Spell Power.
func _demo_keywords() -> void:
	var ids: Array[StringName] = [&"sporeling", &"flarebeak", &"gumdrop", &"ashmite", &"taffy_snail", &"cinderpup", &"magmaw", &"iceling"]
	var kws: Array[StringName] = [&"guard", &"bubble", &"venom", &"second_wind", &"hidden", &"leech", &"flurry", &"dash"]
	for p: int in 2:
		for l: int in 4:
			_demo_put(p, l, ids[p * 4 + l])
			var cr: GameState.CreatureState = state.players[p].lanes[l].creature
			cr.gained.append(kws[p * 4 + l])
			cr.bubble = kws[p * 4 + l] == &"bubble"
			cr.hidden = kws[p * 4 + l] == &"hidden"
	sync_all()
	board.reveal_split(false)
	refresh_ui()


func _demo_put(p: int, l: int, id: StringName) -> void:
	var c := GameState.CreatureState.new()
	c.card = CardDB.card(id)
	c.ready = true
	state.players[p].lanes[l].creature = c


func _build_ui() -> void:
	# Stat bars and BOOP buttons sit under the HUD layer.
	var over_layer := CanvasLayer.new()
	over_layer.layer = 1
	add_child(over_layer)
	overlay = UnitOverlay.new()
	over_layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = HUD_LAYER
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud = Hud.new()
	root.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root = root
	action_log = ActionLog.new()
	action_log.position = Vector2(12, 196)
	root.add_child(action_log)
	hud.pile_screen = func(p: int, kind: StringName) -> Vector2:
		return rig.camera.unproject_position(stacks.point(p, kind)) if stacks and rig else Vector2.ZERO
	hand = Hand.new()
	root.add_child(hand)
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	attack_arrow = AttackArrow.new()
	root.add_child(attack_arrow)
	attack_arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast = Toast.new()
	root.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_top = 64
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	picker = DreamUpPicker.new()
	picker.m = self
	root.add_child(picker)
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	timing_bar = TimingBar.new()
	root.add_child(timing_bar)
	hud.pause_overlay.reparent(root)
	hud.pause_changed.connect(func(open: bool) -> void:
		if open:
			input.cancel()
		driver.menu_changed(open)
		refresh_ui())
	results = Results.new()
	root.add_child(results)
	results.rematch.connect(func() -> void: driver.rematch())
	results.menu.connect(_go_menu)
	input = InputController.new()
	input.match_ctl = self
	add_child(input)
	drag_card = DragCard3D.new()
	add_child(drag_card)
	hand.drag_card = drag_card
	hand.camera = rig.camera
	hand.card_drag_started.connect(input.on_drag_started)
	hand.card_dropped.connect(input.on_dropped)
	player = EventPlayer.new()
	player.m = self
	add_child(player)
	input.action_requested.connect(_on_action_requested)
	overlay.setup(self)
	hud.end_turn_pressed.connect(_on_end_turn_pressed)
	hud.menu_requested.connect(_go_menu)


## MENU after the results, QUIT TO MENU / LEAVE MATCH in the menu.
func _go_menu() -> void:
	driver.leave()
	if menu_scene != "":
		get_tree().change_scene_to_file(menu_scene)


## Refresh HUD, hand and input availability from the state.
func refresh_ui() -> void:
	hud.refresh(state, HUMAN)
	if stacks:
		var tops: Array = []
		for p: int in 2:
			var d: Array[CardData] = state.players[p].discard
			tops.append(d[d.size() - 1] if not d.is_empty() else null)
		stacks.set_counts([state.players[0].deck.size(), state.players[1].deck.size()], [state.players[0].discard.size(), state.players[1].discard.size()], tops)
	hand.show_hand(state.players[HUMAN].hand, hand_playable(), hand_costs())
	hand.set_combo(state.active == HUMAN and state.players[HUMAN].cards_played > 0)
	var only_end: bool = state.active == HUMAN and state.phase == GameState.Phase.MAIN and Rules.legal_actions(state).size() == 1
	hud.set_end_turn_pulse(only_end and not busy)
	var paused: bool = hud.is_paused()
	var can_act: bool = state.active == HUMAN and state.phase == GameState.Phase.MAIN and not busy and not paused \
		and not driver.blocks_input()
	input.enabled = can_act
	hand.enabled = can_act
	hud.set_input_enabled(can_act)
	overlay.refresh(state)


## Which of the human's hand cards can be played now (spells: their current cost, after any spell discount).
func hand_playable() -> Array[bool]:
	var cards: Array[CardData] = state.players[HUMAN].hand
	var playable: Array[bool] = []
	for i: int in cards.size():
		var ok: bool = false
		if cards[i].kind == CardData.Kind.SPELL:
			ok = Rules.card_cost(state, HUMAN, cards[i]) <= state.players[HUMAN].magic
		else:
			for l: int in 4:
				if Rules.validate(state, Action.play(HUMAN, i, l)) == "":
					ok = true
					break
		playable.append(ok and state.active == HUMAN)
	return playable


## What each of the human's hand cards costs right now (spells after any spell discount).
func hand_costs() -> Array[int]:
	var costs: Array[int] = []
	for c: CardData in state.players[HUMAN].hand:
		costs.append(Rules.card_cost(state, HUMAN, c))
	return costs


## Validate, apply, and play the resulting events with input locked (view-space action).
func perform(a: Action) -> void:
	var err: String = Rules.validate(state, a)
	if err != "":
		toast.show_message(err)
		return
	await play_events(apply_local(a))


## Apply a view-space action to the canonical match; returns the events in view space.
func apply_local(a: Action) -> Array[GameEvent]:
	var events: Array[GameEvent] = Rules.apply(seats.real, seats.action_to_real(a))
	seats.sync()
	return seats.events_to_view(events)


## Play view-space events; shows the results once the match is over.
func play_events(events: Array[GameEvent]) -> void:
	await player.play(events)
	if state.phase == GameState.Phase.OVER and not results.visible:
		await get_tree().create_timer(0.6 / pace).timeout
		results.show_result(state.winner == HUMAN, state.turn)


func _on_action_requested(a: Action) -> void:
	busy = true
	refresh_ui()
	await driver.submit(a)
	await _human_dream_up()
	busy = false
	refresh_ui()


## Dream Up: the picker shows the offered cards and the player keeps one. If the pick is settled
## elsewhere meanwhile (online: the room ended the turn), the picker just closes.
func _human_dream_up() -> void:
	if state.phase == GameState.Phase.CHOOSING and state.pending_player == HUMAN:
		input.cancel()
		var i: int = await picker.open(state.pending_choice.duplicate())
		if i >= 0 and state.phase == GameState.Phase.CHOOSING and state.pending_player == HUMAN:
			await driver.submit(Action.choose(HUMAN, i))


## True while the human has a Dream Up pick waiting.
func human_choosing() -> bool:
	return state.phase == GameState.Phase.CHOOSING and state.pending_player == HUMAN


func _on_end_turn_pressed() -> void:
	if busy or state.active != HUMAN:
		return
	input.cancel()
	busy = true
	refresh_ui()
	await driver.submit(Action.end_turn(HUMAN))
	busy = false
	refresh_ui()


## Shows who attacks whom for a moment (the rival's attacks).
func show_attack_arrow(p: int, lane: int, target_lane: int) -> void:
	var cam: Camera3D = rig.camera
	var from: Vector2 = cam.unproject_position(board.anchor(p, lane))
	var to: Vector2 = cam.unproject_position(board.anchor(1 - p, target_lane)) if target_lane >= 0 \
		else hud.hero_rect(p == AI).get_center()
	attack_arrow.aim(from, to, true)
	await get_tree().create_timer(0.5 / pace).timeout
	attack_arrow.clear()


## Local attack: the attacker bar sets the hit; the driver handles the rival's block.
func request_attack(lane: int, target_lane: int) -> void:
	if busy or state.active != HUMAN:
		return
	var err: String = Rules.validate(state, Action.attack(HUMAN, lane, target_lane))
	if err != "":
		toast.show_message(err)
		return
	input.cancel()
	busy = true
	refresh_ui()
	var hit: Action.Hit = await timing_bar.run_attack()
	await driver.attack(lane, target_lane, hit)
	busy = false
	refresh_ui()


## If playback and state ever disagree, rebuild from the state.
func verify_views() -> void:
	for p: int in 2:
		for l: int in 4:
			var lane: GameState.LaneState = state.players[p].lanes[l]
			var cv: CreatureView = creature_views[p][l]
			var bv: BuildingView = building_views[p][l]
			var ok_c: bool = (lane.creature == null and cv == null) or (lane.creature != null and cv != null and cv.card == lane.creature.card)
			var ok_b: bool = (lane.building == null and bv == null) or (lane.building != null and bv != null and bv.card == lane.building)
			if board.island(p, l).land != lane.land:
				view_resyncs += 1
				push_warning("Land out of sync at p%d lane %d; resyncing" % [p, l])
				board.change_land(p, l, lane.land, Vector3.INF, false)
			if not ok_c or not ok_b:
				view_resyncs += 1
				push_warning("View out of sync at p%d lane %d; resyncing" % [p, l])
				sync_all()
				return


## Rebuild every piece (and the lands and field) from the state. Used at match start and as a
## fallback.
func sync_all() -> void:
	board.set_field(state.field.land if state.field else -1, false)
	if field_fx:
		field_fx.set_field(state.field.land if state.field else -1, false)
	for p: int in 2:
		for l: int in 4:
			if board.island(p, l).land != state.players[p].lanes[l].land:
				board.change_land(p, l, state.players[p].lanes[l].land, Vector3.INF, false)
			if creature_views[p][l]:
				(creature_views[p][l] as Node).queue_free()
				creature_views[p][l] = null
			if building_views[p][l]:
				(building_views[p][l] as Node).queue_free()
				building_views[p][l] = null
			var lane: GameState.LaneState = state.players[p].lanes[l]
			if lane.building:
				place_building(p, l, lane.building)
			if lane.creature:
				place_creature(p, l, lane.creature.card)
	refresh_pieces()


## Places a creature view in its half-lane (at `drop`, clamped into the roam zone, if given) and
## starts it wandering.
func place_creature(p: int, l: int, c: CardData, drop: Vector3 = Vector3.INF) -> CreatureView:
	var v := CreatureView.create(c)
	add_child(v)
	var zone: Rect2 = board.roam_rect(p, l)
	if CreatureHouse.wants_house(c.id):
		# Keep clear of the house on the lane's right-hand side.
		zone.size.x -= Board.HOUSE_CLEAR
	var at: Vector3 = board.anchor(p, l)
	if drop.is_finite():
		at = Vector3(clampf(drop.x, zone.position.x, zone.end.x), Board.CREATURE_Y, clampf(drop.z, zone.position.y, zone.end.y))
	v.position = at
	var heading: float = rest_heading(p)
	v.rotation.y = heading
	_placed += 1
	v.wanderer.rest_heading = heading
	v.wanderer.step_every = Wanderer.STEP_EVERY * (2.0 if Settings.quality == GameSettings.Quality.LOW else 1.0)
	v.wanderer.footstep = func(pos: Vector3) -> void: _footstep(v, pos)
	v.wanderer.neighbours = func() -> Array: return creature_views[p]
	v.wanderer.setup(v, zone, hash([p, l, String(c.id), _placed]))
	creature_views[p][l] = v
	return v


## Which way along z player p's enemies sit (-1: the rival's side is away from the camera).
static func enemy_side_z(p: int) -> float:
	return -1.0 if p == HUMAN else 1.0


## Where a creature looks while standing: towards the enemy side, turned to the camera.
static func rest_heading(p: int) -> float:
	return PI * 0.62 if p == HUMAN else PI * -0.12


## A small puff of the land the creature is walking on.
func _footstep(v: CreatureView, pos: Vector3) -> void:
	for p: int in 2:
		var l: int = creature_views[p].find(v)
		if l >= 0:
			Burst.spawn(self, EventPlayer.LAND_BURSTS[state.players[p].lanes[l].land], pos, Color.WHITE, 0.3)
			return


func place_building(p: int, l: int, c: CardData) -> BuildingView:
	var v := BuildingView.create(c)
	add_child(v)
	var bp: Vector3 = board.building_point(p, l)
	v.position = Vector3(bp.x, 0.0, bp.z)
	v.rotation.y = 0.0 if p == HUMAN else PI
	building_views[p][l] = v
	return v


func _readiness(p: int, l: int, cr: GameState.CreatureState) -> CreatureView.Readiness:
	if state.phase == GameState.Phase.OVER or cr.is_frozen():
		return CreatureView.Readiness.NONE
	var can_act: bool = Rules.can_attack(state, p, l) or Rules.can_boop(state, p, l)
	if not cr.ready and not can_act:
		return CreatureView.Readiness.SLEEPING
	if p != HUMAN or state.active != HUMAN:
		return CreatureView.Readiness.NONE
	if can_act:
		return CreatureView.Readiness.READY
	return CreatureView.Readiness.SPENT if cr.attacks_used > 0 or cr.booped else CreatureView.Readiness.NONE


## Update freeze and readiness visuals from the state.
func refresh_pieces() -> void:
	for p: int in 2:
		for l: int in 4:
			var v: CreatureView = creature_views[p][l]
			var cr: GameState.CreatureState = state.players[p].lanes[l].creature
			if v and cr:
				v.set_frozen(cr.is_frozen())
				v.set_readiness(_readiness(p, l, cr))
				if not v.busy:
					v.set_level(cr.level)
				v.set_home(Lands.home(state, p, l))
				v.set_weather(state.field.land if state.field else -1)
				KeywordFx.sync(v, UnitOverlay.shown_keywords(state, p, l), enemy_side_z(p))
	_sync_houses()
	overlay.refresh(state)


## Every creature that brings a house has one in its lane; houses whose creature is gone (or
## moved) sink away.
func _sync_houses() -> void:
	for p: int in 2:
		for l: int in 4:
			var cv: Variant = creature_views[p][l]
			var v: CreatureView = cv as CreatureView if is_instance_valid(cv) else null
			var hv: Variant = house_views[p][l]
			var h: CreatureHouse = hv as CreatureHouse if is_instance_valid(hv) else null
			var want: bool = v != null and CreatureHouse.wants_house(v.card.id)
			if h and (not want or h.resident != v):
				if is_instance_valid(h.resident) and (h.resident as CreatureView).house == h:
					(h.resident as CreatureView).exit_house(true)
					(h.resident as CreatureView).house = null
				h.sink_away()
				h = null
			house_views[p][l] = h
			if want and h == null:
				h = CreatureHouse.create(v.card.land, 1.0)
				add_child(h)
				h.position = board.house_point(p, l)
				h.resident = v
				v.house = h
				h.pop_in()
				house_views[p][l] = h
