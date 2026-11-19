extends Node
## Online play (autoload "Online"): connects to the Dream Isles relay, keeps the match's session alive
## across the menu → match scene change, saves what is needed to rejoin, and reconnects after a drop.
## States: &"idle", &"searching" (quick match), &"hosting", &"joining", &"playing", &"reconnecting",
## &"error". `message` says what the player should read for the current state.

signal changed
## A match started (first start, rematch or rejoin): the menu moves to the match scene.
signal match_ready

## The relay (server/, deployed with `npx wrangler deploy`). `--server=ws://127.0.0.1:8787` plays
## against a local `wrangler dev` instead.
const SERVER_URL := "wss://dream-isles-online.dream-isles-online.workers.dev"
const REJOIN_FILE := "user://online_rejoin.json"
const RECONNECT_WINDOW := 60.0
const RETRY_DELAYS: Array[float] = [1.0, 2.0, 4.0, 8.0, 16.0]
const MSG_UNREACHABLE := "Can't reach the Dream Isles server"
const MSG_LOST := "Lost the connection"
const MSG_BAD_CODE := "That isn't a room code"
const ERRORS: Dictionary = {
	"no_room": "No room called %s",
	"full": "That room is full",
	"over": "That match is over",
	"version": "Your friend has a different version — both refresh",
	"bad_token": "That match can't be rejoined",
	"bad_hello": "The server didn't accept that deck",
}

var server_url: String = SERVER_URL
var session: OnlineSession
var state: StringName = &"idle"
var message: String = ""
## Makes the link for a relay path ("/host", "/join/CODE", "/queue?v=..."). Tests swap in fake links.
var link_factory: Callable = _ws_link
var rejoin_path: String = REJOIN_FILE
var _lobby: Object
var _link: Object
var _clock: float = 0.0
var _dropped_at: float = 0.0
var _retry_at: float = -1.0
var _retries: int = 0
var _last: Callable
## The code typed for JOIN (for "No room called …").
var _asked_code: String = ""


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--server="):
			server_url = arg.substr(9)


func _process(delta: float) -> void:
	_clock += delta
	for l: Object in [_lobby, _link]:
		if l:
			l.call("poll")
	if state == &"reconnecting" and _retry_at >= 0.0 and _clock >= _retry_at:
		_reconnect()


## "frog42", "FROG 42", " frog-42 " → "FROG-42"; "" when it can't be a room code.
static func normalize_code(text: String) -> String:
	var compact: String = ""
	for ch: String in text.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			compact += ch
	var m: RegExMatch = RegEx.create_from_string("^([A-Z]{3,5})([0-9]{2})$").search(compact)
	return "%s-%s" % [m.get_string(1), m.get_string(2)] if m else ""


# --- Starting ----------------------------------------------------------------------------------

func quick_match(player_name: String, deck: DeckData) -> void:
	_close_all()
	_last = quick_match.bind(player_name, deck)
	_set_state(&"searching", "Searching…")
	_lobby = link_factory.call("/queue?v=" + NetVersion.current())
	_lobby.connect("received", func(msg: Dictionary) -> void:
		if msg.get("t", "") == "matched":
			var l: Object = _lobby
			_lobby = null
			l.call("close")
			_open_room("/join/" + String(msg["code"]), player_name, deck, "", &"joining"))
	_lobby.connect("closed", func(_code: int, _reason: String) -> void:
		if state == &"searching":
			_fail(MSG_LOST if _lobby and _lobby.call("was_open") else MSG_UNREACHABLE))


func host(player_name: String, deck: DeckData) -> void:
	_close_all()
	_last = host.bind(player_name, deck)
	_open_room("/host", player_name, deck, "", &"hosting")


func join(code_text: String, player_name: String, deck: DeckData) -> void:
	_close_all()
	_last = join.bind(code_text, player_name, deck)
	var code: String = normalize_code(code_text)
	if code == "":
		_fail(MSG_BAD_CODE)
		return
	_asked_code = code
	_open_room("/join/" + code, player_name, deck, "", &"joining")


## Back into the saved match (main menu "Rejoin your match?").
func rejoin() -> void:
	var saved: Dictionary = _read_rejoin()
	_close_all()
	_last = rejoin
	if saved.is_empty():
		_fail("That match can't be rejoined")
		return
	if saved.get("version", "") != NetVersion.current():
		forget_rejoin()
		_fail("The game was updated — that match can't be rejoined")
		return
	_open_room("/join/" + String(saved["code"]), Settings.player_name, CardDB.deck(CardDB.DECK_ORDER[0]), String(saved["token"]), &"joining")


## RETRY in the panel: the last request again.
func retry() -> void:
	if _last.is_valid():
		_last.call()


func cancel() -> void:
	_close_all()
	forget_rejoin()
	_set_state(&"idle", "")


## LEAVE MATCH (concedes a running match) and MENU after the results.
func leave() -> void:
	if session and session.status == &"playing":
		session.concede()
	_close_all()
	forget_rejoin()
	_set_state(&"idle", "")


func has_rejoin() -> bool:
	return not _read_rejoin().is_empty()


func forget_rejoin() -> void:
	if FileAccess.file_exists(rejoin_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(rejoin_path))


# --- Inside ------------------------------------------------------------------------------------

func _ws_link(path: String) -> Object:
	var t := WsTransport.new()
	t.open(server_url + path)
	return t


func _open_room(path: String, player_name: String, deck: DeckData, token: String, new_state: StringName) -> void:
	_link = link_factory.call(path)
	session = OnlineSession.new(_link, player_name, deck, NetVersion.current(), token)
	session.changed.connect(_on_session_changed)
	session.started.connect(_on_started)
	_link.connect("closed", _on_link_closed.bind(_link))
	_set_state(new_state, "Connecting…")
	session.hello()


func _on_session_changed() -> void:
	match session.status:
		&"waiting":
			_set_state(&"hosting", session.code)
		&"error":
			var code: String = path_code()
			var text: String = ERRORS.get(session.error_code, session.error_msg)
			_fail(text % code if "%s" in text else text)
		&"over":
			if session.state == null:
				_fail("Out of sync — no winner")
			else:
				forget_rejoin()
				changed.emit()
		_:
			changed.emit()


## The room code the player asked for (for messages).
func path_code() -> String:
	return session.code if session and session.code != "" else _asked_code


func _on_started(_rejoined: bool) -> void:
	_retry_at = -1.0
	_save_rejoin()
	_set_state(&"playing", "")
	match_ready.emit()


func _on_link_closed(_code: int, _reason: String, link: Object) -> void:
	if link != _link:
		return
	match state:
		&"playing":
			if session.status == &"playing":
				_set_state(&"reconnecting", "Reconnecting…")
				_dropped_at = _clock
				_retries = 0
				_retry_at = _clock + RETRY_DELAYS[0]
		&"reconnecting":
			pass
		&"hosting", &"joining", &"searching":
			if session == null or session.status != &"error":
				_fail(MSG_LOST if link.call("was_open") else MSG_UNREACHABLE)


func _reconnect() -> void:
	if _clock - _dropped_at >= RECONNECT_WINDOW:
		_retry_at = -1.0
		forget_rejoin()
		_fail(MSG_LOST)
		return
	_retries += 1
	_retry_at = _clock + RETRY_DELAYS[mini(_retries, RETRY_DELAYS.size() - 1)]
	_link = link_factory.call("/join/" + session.code)
	session.set_link(_link)
	_link.connect("closed", _on_link_closed.bind(_link))
	session.hello()


func _save_rejoin() -> void:
	var f := FileAccess.open(rejoin_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"code": session.code, "token": session.token, "version": session.version}))
		f.close()


func _read_rejoin() -> Dictionary:
	if not FileAccess.file_exists(rejoin_path):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(rejoin_path))
	if v is Dictionary and v.has("code") and v.has("token") and v.has("version"):
		return v
	return {}


func _close_all() -> void:
	for l: Object in [_lobby, _link]:
		if l:
			l.call("close")
	_lobby = null
	_link = null
	_retry_at = -1.0
	if session:
		if session.changed.is_connected(_on_session_changed):
			session.changed.disconnect(_on_session_changed)
		if session.started.is_connected(_on_started):
			session.started.disconnect(_on_started)
	session = null


func _fail(text: String) -> void:
	_set_state(&"error", text)


func _set_state(new_state: StringName, text: String) -> void:
	state = new_state
	message = text
	changed.emit()
