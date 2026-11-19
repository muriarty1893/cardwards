class_name WsTransport
extends RefCounted
## One WebSocket to the Dream Isles relay, JSON objects in and out. Call poll() every frame.
## Messages sent before the socket opens are queued. close() is quiet: `closed` only reports
## closes the other side or the network caused.

signal opened
signal received(msg: Dictionary)
signal closed(code: int, reason: String)

var url: String = ""
var _ws: WebSocketPeer
var _queue: PackedStringArray = []
var _was_open: bool = false
var _done: bool = false


func open(to_url: String) -> void:
	url = to_url
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 18
	if _ws.connect_to_url(url) != OK:
		_done = true
		_emit_closed.call_deferred(-1, "could not connect")


func send(msg: Dictionary) -> void:
	var text: String = JSON.stringify(msg)
	if is_open():
		_ws.send_text(text)
	elif not _done:
		_queue.append(text)


func poll() -> void:
	if _ws == null or _done:
		return
	_ws.poll()
	var st: WebSocketPeer.State = _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN and not _was_open:
		_was_open = true
		for text: String in _queue:
			_ws.send_text(text)
		_queue.clear()
		opened.emit()
	while _ws.get_available_packet_count() > 0:
		var v: Variant = JSON.parse_string(_ws.get_packet().get_string_from_utf8())
		if v is Dictionary:
			received.emit(v)
	if st == WebSocketPeer.STATE_CLOSED:
		_done = true
		closed.emit(_ws.get_close_code(), _ws.get_close_reason())


func close() -> void:
	if _ws and not _done:
		_done = true
		_ws.close(1000, "bye")


func is_open() -> bool:
	return _ws != null and not _done and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN


## True once the socket has opened at least once (a close before that means "can't reach").
func was_open() -> bool:
	return _was_open


func _emit_closed(code: int, reason: String) -> void:
	closed.emit(code, reason)
