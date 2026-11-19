extends SceneTree
## Headless online player for end-to-end runs: the AI plays a real match through the relay.
##   godot --headless --path . --script res://tools/online_bot.gd -- --server=ws://127.0.0.1:8787 \
##     --mode=host|join=<CODE>|quick --deck=<id> --brain-seed=<n> --out=<file.json>
## The host writes its room code to <out>.code. On the end it writes
## {"winner", "reason", "digest", "turns", "seat", "moves"} to <out> and quits 0; errors quit 1.

const TIMEOUT_MS := 600000
## A bot thinks 4 times a second: the relay closes sockets that send more than 20 messages a second
## (a person can't: every move animates for half a second or more).
const STEP_MS := 250

var server: String = "ws://127.0.0.1:8787"
var mode: String = "host"
var deck_id: StringName = &"grove_guard"
var brain_seed: int = 1
var out_path: String = ""
var lobby: WsTransport
var link: WsTransport
var session: OnlineSession
var brain: BotBrain
var _code_written: bool = false
var _start_ms: int = 0
var _done: bool = false
var _last_step_ms: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--server="):
			server = arg.substr(9)
		elif arg.begins_with("--mode="):
			mode = arg.substr(7)
		elif arg.begins_with("--deck="):
			deck_id = StringName(arg.substr(7))
		elif arg.begins_with("--brain-seed="):
			brain_seed = int(arg.substr(13))
		elif arg.begins_with("--out="):
			out_path = arg.substr(6)
	_start_ms = Time.get_ticks_msec()
	brain = BotBrain.new(brain_seed)
	if mode == "host":
		_room("/host")
	elif mode.begins_with("join="):
		_room("/join/" + mode.substr(5))
	elif mode == "quick":
		lobby = WsTransport.new()
		lobby.received.connect(func(msg: Dictionary) -> void:
			if msg.get("t", "") == "matched":
				lobby.close()
				lobby = null
				_room("/join/" + String(msg["code"])))
		lobby.closed.connect(func(c: int, r: String) -> void:
			if lobby:
				_fail("lobby closed %d %s" % [c, r]))
		lobby.open(server + "/queue?v=" + NetVersion.current())
	else:
		_fail("unknown mode " + mode)


func _room(path: String) -> void:
	link = WsTransport.new()
	link.open(server + path)
	session = OnlineSession.new(link, "Bot%d" % brain_seed, CardDB.deck(deck_id), NetVersion.current())
	link.closed.connect(func(c: int, r: String) -> void:
		if session.status != &"over":
			_fail("room closed %d %s (status %s)" % [c, r, session.status]))
	session.hello()


func _process(_delta: float) -> bool:
	if _done:
		return true
	if Time.get_ticks_msec() - _start_ms > TIMEOUT_MS:
		_fail("timed out")
		return true
	if lobby:
		lobby.poll()
	if link:
		link.poll()
	if session == null:
		return false
	if session.code != "" and not _code_written and out_path != "":
		_code_written = true
		_write(out_path + ".code", session.code)
	if session.status == &"error":
		_fail("room error %s: %s" % [session.error_code, session.error_msg])
		return true
	if Time.get_ticks_msec() - _last_step_ms >= STEP_MS:
		_last_step_ms = Time.get_ticks_msec()
		brain.step(session)
	if session.status == &"over" and session.inbox.is_empty():
		_finish()
	return false


func _finish() -> void:
	var s: GameState = session.state
	var result: Dictionary = {
		"winner": int(session.over.get("winner", -1)), "reason": String(session.over.get("reason", "")),
		"digest": s.digest() if s else "", "turns": s.turn if s else 0, "seat": session.seat,
		"moves": session.applied,
	}
	print("online_bot: ", JSON.stringify(result))
	if out_path != "":
		_write(out_path, JSON.stringify(result))
	if link:
		link.close()
	_done = true
	quit(0)


func _fail(why: String) -> void:
	if _done:
		return
	_done = true
	push_error("online_bot: " + why)
	quit(1)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
