class_name OnlineSession
extends RefCounted
## One player's side of an online match (spec 4): talks to the room over a link (WsTransport, or a
## FakeRelay.Link in tests), owns the canonical match (host = player 0) and applies the room's
## numbered moves in order. Moves wait in `inbox` until the view (or a bot) plays them.

signal changed
## A match (re)started. `rejoined`: it was rebuilt from the room's move log.
signal started(rejoined: bool)

var link: Object
var my_name: String
var my_deck: DeckData
var version: String
var token: String = ""
var seat: int = -1
var code: String = ""
var names: Array[String] = ["", ""]
var decks: Array[DeckData] = [null, null]
var seed: int = 0
var first: int = 0
var match_no: int = 0
## The canonical match (null until `start`).
var state: GameState
## Number of the last move applied.
var applied: int = 0
## Applied moves (action dicts) and the digest after each, for desync reports.
var moves: Array[Dictionary] = []
var digests: Array[String] = []
## Room messages waiting for the view: move, block_wanted, blocking, rejected, opponent,
## rematch_wanted, over.
var inbox: Array[Dictionary] = []
## &"connecting", &"waiting", &"playing", &"over", &"error"
var status: StringName = &"connecting"
var error_code: String = ""
var error_msg: String = ""
## {"winner": int, "reason": String} once the room ended the match.
var over: Dictionary = {}
## Unix ms until which the rival may come back (0: present), and when (Time.get_ticks_msec) the
## room said so; countdowns use the local clock, the two clocks may differ.
var rival_away_until: int = 0
var rival_away_at: int = 0
var rival_left: bool = false
var rival_wants_rematch: bool = false
var _opening: Array[GameEvent] = []
var _result_sent: bool = false
var _dumped: bool = false


## Starting-hand redraws (both seats must agree; tests that script a match turn it off).
var mulligan: bool = true


func _init(l: Object, player_name: String, deck: DeckData, ver: String, saved_token: String = "") -> void:
	my_name = player_name
	my_deck = deck
	version = ver
	token = saved_token
	set_link(l)


## Talk through another link (after a reconnect).
func set_link(l: Object) -> void:
	if link and link.is_connected("received", on_message):
		link.disconnect("received", on_message)
	link = l
	link.connect("received", on_message)


func hello() -> void:
	var m: Dictionary = {"t": "hello", "v": version, "name": my_name, "deck": DeckCodec.encode(my_deck)}
	if token != "":
		m["token"] = token
	link.call("send", m)


func rival_name() -> String:
	return names[1 - seat] if seat >= 0 else ""


func is_my_turn() -> bool:
	return status == &"playing" and state != null and state.phase != GameState.Phase.OVER and state.active == seat


## The next room message for the view, or {}.
func next() -> Dictionary:
	return inbox.pop_front() if not inbox.is_empty() else {}


## The start-of-match events, once per `start` (none after a rejoin).
func take_opening() -> Array[GameEvent]:
	var o: Array[GameEvent] = _opening
	_opening = []
	return o


# --- From the room ---------------------------------------------------------------------------

func on_message(msg: Dictionary) -> void:
	match String(msg.get("t", "")):
		"welcome":
			seat = int(msg["seat"])
			token = String(msg["token"])
			code = String(msg["code"])
		"waiting":
			code = String(msg["code"])
			status = &"waiting"
		"start":
			_start(msg)
		"error":
			status = &"error"
			error_code = String(msg.get("code", ""))
			error_msg = String(msg.get("msg", ""))
		"over":
			over = {"winner": int(msg["winner"]), "reason": String(msg["reason"])}
			status = &"over"
			if over["reason"] == "desync":
				_dump_desync("room reported a desync")
			inbox.append(msg)
		"opponent":
			var st: String = String(msg.get("status", ""))
			rival_away_until = int(msg.get("until", 0)) if st == "away" else 0
			rival_away_at = Time.get_ticks_msec() if st == "away" else 0
			rival_left = st == "left"
			inbox.append(msg)
		"rematch_wanted":
			rival_wants_rematch = true
			inbox.append(msg)
		"move", "block_wanted", "blocking", "rejected":
			inbox.append(msg)
		_:
			return
	changed.emit()


func _start(msg: Dictionary) -> void:
	var raw: Array = msg.get("decks", [])
	var names_in: Array = msg.get("names", [])
	for i: int in 2:
		var why: String = DeckCodec.check(raw[i] if i < raw.size() else null)
		if why != "":
			_desync(0, "deck %d: %s" % [i, why])
			return
	decks = [DeckCodec.decode(raw[0], &"online_0"), DeckCodec.decode(raw[1], &"online_1")]
	names = [String(names_in[0]) if names_in.size() > 0 else "", String(names_in[1]) if names_in.size() > 1 else ""]
	seed = int(msg["seed"])
	first = int(msg["first"])
	match_no = int(msg.get("match", 0))
	state = Rules.setup(decks[0], decks[1], seed, first, mulligan)
	_opening = Rules.start_turn(state)
	applied = 0
	moves.clear()
	digests.clear()
	inbox.clear()
	over = {}
	rival_wants_rematch = false
	rival_left = false
	rival_away_until = 0
	_result_sent = false
	_dumped = false
	status = &"playing"
	var log: Array = msg.get("log", [])
	for a: Variant in log:
		var before: int = applied
		_apply(applied + 1, a as Dictionary, false)
		if applied == before:
			return
	if not log.is_empty():
		_opening = []
	started.emit(not log.is_empty())


## Apply the room's next move. Returns its events (canonical), or [] when it can't be applied.
func apply_move(msg: Dictionary) -> Array[GameEvent]:
	if state == null or state.phase == GameState.Phase.OVER:
		return []
	var seq: int = int(msg["seq"])
	if seq != applied + 1:
		_desync(seq, "move %d arrived after %d" % [seq, applied])
		return []
	return _apply(seq, msg["a"] as Dictionary, true)


func _apply(seq: int, a_dict: Dictionary, report: bool) -> Array[GameEvent]:
	var a: Action = Action.from_dict(a_dict)
	var ev: Array[GameEvent] = []
	# A turn the room ended (backstop) while a Dream Up pick was open: both games take the first card.
	if a.type == Action.Type.END_TURN and state.phase == GameState.Phase.CHOOSING:
		ev.append_array(Rules.apply(state, Action.choose(state.pending_player, 0)))
	var err: String = Rules.validate(state, a)
	if err != "":
		_desync(seq, "move %d refused: %s (%s)" % [seq, err, a])
		return []
	ev.append_array(Rules.apply(state, a))
	applied = seq
	moves.append(a_dict)
	var d: String = state.digest()
	digests.append(d)
	if report:
		link.call("send", {"t": "hash", "seq": seq, "d": d})
		if state.phase == GameState.Phase.OVER and not _result_sent:
			_result_sent = true
			link.call("send", {"t": "result", "winner": state.winner})
	return ev


# --- To the room -----------------------------------------------------------------------------

## A canonical action (PLAY_CARD, BOOP, CHOOSE, END_TURN).
func send_act(a: Action) -> void:
	link.call("send", {"t": "act", "a": a.to_dict()})


func send_attack(lane: int, target: int, hit: int) -> void:
	link.call("send", {"t": "attack", "lane": lane, "target": target, "hit": hit})


func send_block(blocked: bool) -> void:
	link.call("send", {"t": "block", "blocked": blocked})


func concede() -> void:
	link.call("send", {"t": "concede"})


func request_rematch() -> void:
	link.call("send", {"t": "rematch"})


# --- Desync ----------------------------------------------------------------------------------

func _desync(seq: int, why: String) -> void:
	push_warning("Online desync: " + why)
	link.call("send", {"t": "desync", "seq": seq, "why": why.left(200)})
	_dump_desync(why)


## Everything a headless replay needs: user://desync_<code>.json.
func _dump_desync(why: String) -> void:
	if _dumped:
		return
	_dumped = true
	var enc: Array = []
	for d: DeckData in decks:
		enc.append(DeckCodec.encode(d) if d else null)
	var dump: Dictionary = {
		"why": why, "code": code, "seat": seat, "version": version, "seed": seed, "first": first,
		"match": match_no, "decks": enc, "moves": moves, "digests": digests,
	}
	var f := FileAccess.open("user://desync_%s.json" % code, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dump, "\t"))
		f.close()
