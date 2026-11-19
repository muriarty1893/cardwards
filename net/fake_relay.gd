class_name FakeRelay
extends RefCounted
## An in-memory stand-in for one room of the Cloudflare relay (server/src/referee.ts), for headless
## tests: same messages, same ordering rules, no wall clock (tests call backstop() and
## block_timeout() instead). Messages go through JSON both ways, like the real socket.
## Nothing moves until pump() is called.

## One client's connection; the same signals and methods as WsTransport.
class Link:
	extends RefCounted
	signal opened
	signal received(msg: Dictionary)
	signal closed(code: int, reason: String)
	var relay: FakeRelay
	var role: StringName = &"join"
	var seat: int = -1
	var open: bool = true

	func send(msg: Dictionary) -> void:
		if open:
			relay._incoming.append([self, JSON.stringify(msg)])

	## Client-side close: the room sees a disconnect.
	func close() -> void:
		if open:
			open = false
			relay._gone(self)

	func is_open() -> bool:
		return open

	func was_open() -> bool:
		return true

	func poll() -> void:
		pass


const ACT_TYPES: Array[int] = [Action.Type.PLAY_CARD, Action.Type.BOOP, Action.Type.CHOOSE, Action.Type.END_TURN]

var code: String = "FAKE-01"
var seed: int = 1
## Tests: drop one card from this seat's deck in `start` (an illegal deck).
var corrupt_deck: int = -1
var rng := RandomNumberGenerator.new()
var status: String = "claimed"
var version: String = ""
## Per seat: {"name", "deck", "token", "link", "connected"} or null.
var seats: Array = [null, null]
var active: int = 0
var first: int = 0
var log: Array = []
var pending: Dictionary = {}
var hashes: Dictionary = {}
var results: Array = [null, null]
var rematch: Array = [false, false]
var over: Dictionary = {}
var match_no: int = 0
var _incoming: Array = []
var _outgoing: Array = []


func _init(relay_seed: int = 1) -> void:
	seed = relay_seed
	rng.seed = relay_seed


func transport(role: StringName = &"join") -> Link:
	var l := Link.new()
	l.relay = self
	l.role = role
	return l


## Handle everything sent so far and deliver every answer, until nothing is left.
func pump() -> void:
	var guard: int = 0
	while (not _incoming.is_empty() or not _outgoing.is_empty()) and guard < 100000:
		guard += 1
		if not _incoming.is_empty():
			var x: Array = _incoming.pop_front()
			var msg: Variant = JSON.parse_string(x[1])
			if msg is Dictionary:
				_handle(x[0], msg)
			continue
		var y: Array = _outgoing.pop_front()
		var link: Link = y[0]
		if y[1] == null:
			link.open = false
			link.closed.emit(1000, "refused")
		elif link.open:
			link.received.emit(JSON.parse_string(y[1]))


## The room ends the active player's turn (70 s of silence).
func backstop() -> void:
	if status == "playing" and pending.is_empty():
		_record(_action({"type": Action.Type.END_TURN, "player": active}), true)


## The defender didn't answer within 10 s.
func block_timeout() -> void:
	if not pending.is_empty():
		_complete(false)


## The network drops this seat's connection.
func drop(seat: int) -> void:
	var link: Link = seats[seat]["link"]
	if link and link.open:
		link.open = false
		_gone(link)
		link.closed.emit(1006, "dropped")


# --- Handling --------------------------------------------------------------------------------

func _handle(link: Link, msg: Dictionary) -> void:
	var t: String = String(msg.get("t", ""))
	if link.seat < 0:
		if t == "hello":
			_hello(link, msg)
		return
	var seat: int = link.seat
	match t:
		"act":
			var a: Dictionary = msg.get("a", {})
			if status != "playing":
				_to(seat, {"t": "rejected", "why": "not playing"})
			elif seat != active:
				_to(seat, {"t": "rejected", "why": "not your turn"})
			elif not pending.is_empty():
				_to(seat, {"t": "rejected", "why": "attack pending"})
			elif not int(a.get("type", -1)) in ACT_TYPES:
				_to(seat, {"t": "rejected", "why": "bad move"})
			else:
				var full: Dictionary = _action(a)
				full["player"] = seat
				_record(full)
		"attack":
			if status != "playing" or seat != active or not pending.is_empty():
				_to(seat, {"t": "rejected", "why": "not now"})
			elif int(msg["target"]) < 0:
				_record(_attack(seat, int(msg["lane"]), -1, int(msg["hit"]), false))
			else:
				pending = {"seat": seat, "lane": int(msg["lane"]), "target": int(msg["target"]), "hit": int(msg["hit"])}
				_to(1 - seat, {"t": "block_wanted", "lane": pending["lane"], "target": pending["target"], "hit": pending["hit"]})
				_to(seat, {"t": "blocking"})
		"block":
			if not pending.is_empty() and seat != int(pending["seat"]):
				_complete(bool(msg["blocked"]))
		"hash":
			if status == "playing":
				var key: int = int(msg["seq"])
				var pair: Array = hashes.get(key, [null, null])
				pair[seat] = String(msg["d"])
				hashes[key] = pair
				if pair[0] != null and pair[1] != null and pair[0] != pair[1]:
					_end(-1, "desync")
		"desync":
			if status == "playing" or status == "waiting":
				_end(-1, "desync")
		"result":
			if status == "playing":
				results[seat] = int(msg["winner"])
				if results[0] != null and results[1] != null:
					_end(results[0] if results[0] == results[1] else -1, "normal" if results[0] == results[1] else "desync")
		"concede":
			if status == "playing":
				_end(1 - seat, "concede")
		"rematch":
			if status != "over" or over.get("reason", "") == "desync":
				_to(seat, {"t": "rejected", "why": "no rematch"})
			elif not seats[1 - seat]["connected"]:
				_to(seat, {"t": "rejected", "why": "left"})
			else:
				rematch[seat] = true
				if rematch[1 - seat]:
					match_no += 1
					_begin()
					_to_both(_start_msg())
				else:
					_to(1 - seat, {"t": "rematch_wanted"})


func _hello(link: Link, msg: Dictionary) -> void:
	if msg.has("token"):
		for i: int in 2:
			if seats[i] != null and seats[i]["token"] == msg["token"]:
				_seat(link, i)
				_to(i, {"t": "welcome", "seat": i, "token": seats[i]["token"], "code": code})
				if status == "waiting":
					_to(i, {"t": "waiting", "code": code})
					return
				_to(i, _start_msg())
				if not pending.is_empty():
					if int(pending["seat"]) == i:
						_to(i, {"t": "blocking"})
					else:
						_to(i, {"t": "block_wanted", "lane": pending["lane"], "target": pending["target"], "hit": pending["hit"]})
				if status == "playing":
					_to(1 - i, {"t": "opponent", "status": "back"})
				if not over.is_empty():
					_to(i, {"t": "over", "winner": over["winner"], "reason": over["reason"]})
				return
		_refuse(link, "bad_token")
		return
	if link.role == &"host" and status == "claimed":
		seats[0] = {"name": String(msg.get("name", "")), "deck": msg["deck"], "token": "tok0-%d" % seed, "link": null, "connected": false}
		version = String(msg["v"])
		status = "waiting"
		_seat(link, 0)
		_to(0, {"t": "welcome", "seat": 0, "token": seats[0]["token"], "code": code})
		_to(0, {"t": "waiting", "code": code})
	elif link.role == &"join" and status == "waiting":
		if String(msg["v"]) != version:
			_refuse(link, "version")
			return
		seats[1] = {"name": String(msg.get("name", "")), "deck": msg["deck"], "token": "tok1-%d" % seed, "link": null, "connected": false}
		_seat(link, 1)
		_to(1, {"t": "welcome", "seat": 1, "token": seats[1]["token"], "code": code})
		_begin()
		_to_both(_start_msg())
	elif status == "playing":
		_refuse(link, "full")
	elif status == "over":
		_refuse(link, "over")
	else:
		_refuse(link, "no_room")


func _seat(link: Link, i: int) -> void:
	var old: Link = seats[i]["link"]
	if old and old != link:
		old.open = false
	link.seat = i
	seats[i]["link"] = link
	seats[i]["connected"] = true


func _refuse(link: Link, why: String) -> void:
	_outgoing.append([link, JSON.stringify({"t": "error", "code": why, "msg": why})])
	_outgoing.append([link, null])


func _gone(link: Link) -> void:
	var i: int = link.seat
	if i < 0 or seats[i] == null or seats[i]["link"] != link:
		return
	seats[i]["connected"] = false
	if status == "playing":
		_to(1 - i, {"t": "opponent", "status": "away", "until": int(Time.get_unix_time_from_system() * 1000.0) + 60000})
	elif status == "over":
		_to(1 - i, {"t": "opponent", "status": "left"})


func _begin() -> void:
	first = rng.randi_range(0, 1)
	active = first
	status = "playing"
	log.clear()
	pending = {}
	hashes = {}
	results = [null, null]
	rematch = [false, false]
	over = {}


func _start_msg() -> Dictionary:
	var decks: Array = [seats[0]["deck"], seats[1]["deck"] if seats[1] else null]
	if corrupt_deck >= 0:
		var bad: Dictionary = (decks[corrupt_deck] as Dictionary).duplicate(true)
		(bad["cards"] as Array).pop_back()
		decks[corrupt_deck] = bad
	return {
		"t": "start", "seed": seed + match_no * 7919, "first": first,
		"names": [seats[0]["name"], seats[1]["name"] if seats[1] else ""],
		"decks": decks, "log": log.duplicate(true), "match": match_no,
	}


func _action(partial: Dictionary) -> Dictionary:
	var a: Dictionary = {"type": 4, "player": 0, "hand_index": -1, "lane": -1, "targets": [], "hit": 0, "blocked": false, "choice": -1, "target_lane": -1}
	for k: String in a:
		if partial.has(k):
			a[k] = partial[k]
	return a


func _attack(seat: int, lane: int, target: int, hit: int, blocked: bool) -> Dictionary:
	return _action({"type": Action.Type.ATTACK, "player": seat, "lane": lane, "target_lane": target, "hit": hit, "blocked": blocked})


func _complete(blocked: bool) -> void:
	var p: Dictionary = pending
	pending = {}
	_record(_attack(int(p["seat"]), int(p["lane"]), int(p["target"]), int(p["hit"]), blocked))


func _record(a: Dictionary, auto: bool = false) -> void:
	log.append(a)
	if int(a["type"]) == Action.Type.END_TURN:
		active = 1 - active
	var msg: Dictionary = {"t": "move", "seq": log.size(), "a": a}
	if auto:
		msg["auto"] = true
	_to_both(msg)


func _end(winner: int, reason: String) -> void:
	status = "over"
	over = {"winner": winner, "reason": reason}
	pending = {}
	_to_both({"t": "over", "winner": winner, "reason": reason})


func _to(seat: int, msg: Dictionary) -> void:
	if seats[seat] == null:
		return
	var link: Link = seats[seat]["link"]
	if link and link.open:
		_outgoing.append([link, JSON.stringify(msg)])


func _to_both(msg: Dictionary) -> void:
	_to(0, msg)
	_to(1, msg)
