class_name OnlineRival
extends RivalDriver
## A person on the other side of the room (spec 5.2-5.5). Local moves go to the room and play when
## it echoes them; everything the room sends waits in the session's inbox and is played one message
## at a time (moves, the live block bar, banners, the end). Runs the 50 s turn clock and its fuse.

## Our move came back from the room (or was rejected).
signal _echo

const TURN_SECONDS := 50.0
const FUSE_SECONDS := 15.0
const RECONNECT_SECONDS := 60.0

var session: OnlineSession
## Set once the opening has played; the inbox waits until then.
var live: bool = false
## Seconds left in the current turn (counted only while nothing plays).
var turn_left: float = TURN_SECONDS
var _playing: bool = false
var _awaiting_echo: bool = false
var _clock_fired: bool = false
var _turn_owner: int = -1


func _init(s: OnlineSession) -> void:
	session = s


func begin() -> void:
	live = true
	_turn_owner = m.state.active
	turn_left = TURN_SECONDS
	session.started.connect(_on_restarted)


func is_online() -> bool:
	return true


func rival_name() -> String:
	return session.rival_name()


func blocks_input() -> bool:
	return _playing or _awaiting_echo


func submit(a: Action) -> void:
	if session.status != &"playing":
		return
	_awaiting_echo = true
	session.send_act(m.seats.action_to_real(a))
	await _echo


func attack(lane: int, target_lane: int, hit: Action.Hit) -> void:
	if session.status != &"playing":
		return
	_awaiting_echo = true
	session.send_attack(lane, target_lane, int(hit))
	if target_lane >= 0:
		m.timing_bar.wait_block()
	await _echo


func leave() -> void:
	if session.started.is_connected(_on_restarted):
		session.started.disconnect(_on_restarted)
	Online.leave()


func rematch() -> void:
	session.request_rematch()
	m.results.set_rematch("Waiting for rival…", false)


func process(delta: float) -> void:
	if not live or not is_instance_valid(m):
		return
	_tick_clock(delta)
	_update_banner()
	if not _playing and not session.inbox.is_empty():
		_pump_one()


# --- The inbox -------------------------------------------------------------------------------

func _pump_one() -> void:
	_playing = true
	m.refresh_ui()
	var msg: Dictionary = session.next()
	match String(msg.get("t", "")):
		"move":
			await _play_move(msg)
		"block_wanted":
			await _live_block(msg)
		"rejected":
			if _awaiting_echo:
				m.timing_bar.hide_bar()
				m.toast.show_message("Not now", 1.0)
				_release_echo()
		"opponent":
			if session.rival_left and m.results.visible:
				m.results.set_rematch("Rival left", false)
		"rematch_wanted":
			if m.results.visible and m.results.rematch_enabled():
				m.results.set_rematch("Rival wants a rematch!", true)
		"over":
			await _show_over(msg)
	_playing = false
	if is_instance_valid(m):
		m.refresh_ui()


func _play_move(msg: Dictionary) -> void:
	var a: Action = Action.from_dict(msg["a"])
	var mine: bool = a.player == session.seat and not msg.get("auto", false)
	var va: Action = m.seats.action_to_view(a)
	if a.type == Action.Type.ATTACK:
		if not mine and a.target_lane < 0:
			await m.show_attack_arrow(MatchController.AI, va.lane, va.target_lane)
			await m.timing_bar.simulate_attack(a.hit)
		elif mine and a.target_lane >= 0:
			await m.timing_bar.simulate_block(a.blocked)
	var ev: Array[GameEvent] = session.apply_move(msg)
	m.seats.sync()
	await m.play_events(m.seats.events_to_view(ev))
	if mine:
		_release_echo()


## The rival attacks one of our creatures: their arrow and bar, then our own block bar.
func _live_block(msg: Dictionary) -> void:
	if m.hud.is_paused():
		m.hud.close_pause()
	m.input.cancel()
	await m.show_attack_arrow(MatchController.AI, int(msg["lane"]), int(msg["target"]))
	await m.timing_bar.simulate_attack(int(msg["hit"]) as Action.Hit)
	var blocked: bool = await m.timing_bar.run_block()
	session.send_block(blocked)


func _show_over(msg: Dictionary) -> void:
	var reason: String = String(msg.get("reason", ""))
	var won: bool = m.seats.flip(int(msg.get("winner", -1))) == MatchController.HUMAN
	_release_echo()
	m.timing_bar.hide_bar()
	var why: String = ""
	match reason:
		"concede":
			why = "Rival conceded" if won else "You left the match"
		"forfeit":
			why = "Rival left the match" if won else "You were away too long"
	if reason == "desync":
		m.results.show_result(false, m.state.turn, "Out of sync — no winner", "NO CONTEST")
		m.results.set_rematch("No rematch", false)
		return
	if not m.results.visible:
		await m.get_tree().create_timer(0.4).timeout
		m.results.show_result(won, m.state.turn, why)
	elif why != "":
		m.results.set_reason(why)
	if session.rival_left:
		m.results.set_rematch("Rival left", false)
	elif session.rival_wants_rematch:
		m.results.set_rematch("Rival wants a rematch!", true)


func _release_echo() -> void:
	if _awaiting_echo:
		_awaiting_echo = false
		_echo.emit()


## A new match in this room (rematch) or the same one rebuilt after a reconnect: rebuild the scene.
func _on_restarted(_rejoined: bool) -> void:
	if session.started.is_connected(_on_restarted):
		session.started.disconnect(_on_restarted)
	if is_instance_valid(m) and m.is_inside_tree():
		m.get_tree().reload_current_scene.call_deferred()


# --- Turn clock and banner -------------------------------------------------------------------

func _tick_clock(delta: float) -> void:
	var s: GameState = m.state
	if s.phase == GameState.Phase.OVER or session.status != &"playing":
		m.hud.set_fuse(-1.0)
		return
	if s.active != _turn_owner:
		_turn_owner = s.active
		turn_left = TURN_SECONDS
		_clock_fired = false
	var paused: bool = m.busy or _playing or _awaiting_echo or m.timing_bar.visible
	if not paused:
		turn_left = maxf(0.0, turn_left - delta)
	m.hud.set_fuse(turn_left if turn_left <= FUSE_SECONDS else -1.0, FUSE_SECONDS)
	if turn_left <= 0.0 and s.active == MatchController.HUMAN and not paused and not _clock_fired:
		_clock_fired = true
		m.input.cancel()
		m._on_end_turn_pressed()


func _update_banner() -> void:
	var text: String = ""
	if session.status == &"playing" and session.rival_away_at > 0:
		var gone: float = (Time.get_ticks_msec() - session.rival_away_at) / 1000.0
		text = "Rival disconnected — waiting 0:%02d" % maxi(0, ceili(RECONNECT_SECONDS - gone))
	elif Online.state == &"reconnecting":
		text = "Reconnecting…"
	m.hud.set_banner(text)
