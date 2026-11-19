class_name OnlinePanel
extends PanelContainer
## PLAY ONLINE (spec 2.1): your name, the selected deck, QUICK MATCH, HOST ROOM and JOIN ROOM, and
## what the Online autoload is doing (searching, the room code to send, errors with RETRY).

signal closed

var _name_edit: LineEdit
var _code_edit: LineEdit
var _deck_label: Label
var _msg: Label
var _code: Label
var _hint: Label
var _copy: Button
var _retry: Button
var _cancel: Button
var _starters: Array[Button] = []
## A message from this panel itself (an illegal deck), shown instead of the autoload's.
var _local_msg: String = ""
var _search_started: int = 0


static func make() -> OnlinePanel:
	var p := OnlinePanel.new()
	p.add_theme_stylebox_override("panel", UiStyle.parchment_panel(22))
	p._build()
	return p


func _ready() -> void:
	Online.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if Online.changed.is_connected(_refresh):
		Online.changed.disconnect(_refresh)


func _process(_delta: float) -> void:
	if Online.state == &"searching":
		_refresh()


# --- Actions (buttons; tests call them directly) ---------------------------------------------

func press_quick() -> void:
	_request(&"quick")


func press_host() -> void:
	_request(&"host")


func press_join(code_text: String) -> void:
	_code_edit.text = code_text
	_request(&"join")


func press_retry() -> void:
	_local_msg = ""
	Online.retry()


func set_player_name(n: String) -> void:
	_name_edit.text = n


func deck_text() -> String:
	return _deck_label.text


func message_text() -> String:
	return _msg.text


func code_text() -> String:
	return _code.text if _code.visible else ""


func copy_visible() -> bool:
	return _copy.visible


func retry_visible() -> bool:
	return _retry.visible


## The selected deck, or a reason it can't be used online.
static func online_deck() -> Array:
	var id: StringName = Session.player_deck
	if DeckStore.is_custom(id):
		var d: DeckData = DeckStore.find(id)
		if d == null:
			return [null, "That deck can't be used online: it's missing"]
		var why: String = DeckStore.validate(d.cards)
		if why != "":
			return [null, "That deck can't be used online: %s" % why]
		return [d, ""]
	return [CardDB.deck(id), ""]


func _request(kind: StringName) -> void:
	var dk: Array = online_deck()
	if dk[1] != "":
		_local_msg = dk[1]
		_refresh()
		return
	_local_msg = ""
	Settings.set_player_name(_name_edit.text)
	_name_edit.text = Settings.player_name
	var deck: DeckData = dk[0]
	match kind:
		&"quick":
			_search_started = Time.get_ticks_msec()
			Online.quick_match(Settings.player_name, deck)
		&"host":
			Online.host(Settings.player_name, deck)
		&"join":
			Online.join(_code_edit.text, Settings.player_name, deck)


# --- Look --------------------------------------------------------------------------------------

func _refresh() -> void:
	if not is_inside_tree() and _msg == null:
		return
	var st: StringName = Online.state
	var busy: bool = st in [&"searching", &"hosting", &"joining", &"playing"]
	for b: Button in _starters:
		b.disabled = busy
	_code.visible = false
	_hint.visible = false
	_copy.visible = false
	_retry.visible = false
	_cancel.visible = busy and st != &"playing"
	_msg.add_theme_color_override("font_color", Palette.INK)
	if _local_msg != "" and st == &"idle":
		_msg.text = _local_msg
		_msg.add_theme_color_override("font_color", Palette.HP.darkened(0.2))
		return
	match st:
		&"idle":
			_msg.text = ""
		&"searching":
			var secs: int = (Time.get_ticks_msec() - _search_started) / 1000
			_msg.text = "Searching… %d:%02d" % [secs / 60, secs % 60]
		&"hosting":
			var waiting: bool = Online.session != null and Online.session.status == &"waiting"
			_msg.text = "Waiting for a friend to join…" if waiting else "Connecting…"
			if waiting:
				_code.text = Online.session.code
				_code.visible = true
				_hint.visible = true
				_copy.visible = true
		&"joining":
			_msg.text = "Joining…"
		&"playing":
			_msg.text = "Starting the match…"
		&"error":
			_msg.text = Online.message
			_msg.add_theme_color_override("font_color", Palette.HP.darkened(0.2))
			_retry.visible = true
		_:
			_msg.text = Online.message


func _build() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(500, 0)
	add_child(vb)
	var title := UiStyle.title(UiStyle.label("Play Online", 44)) as Label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 10)
	vb.add_child(name_row)
	name_row.add_child(UiStyle.label("Your name", 18))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(240, 40)
	_name_edit.text = Settings.player_name
	_name_edit.add_theme_font_size_override("font_size", 18)
	name_row.add_child(_name_edit)
	_deck_label = UiStyle.label("Deck: %s" % _deck_name(), 18)
	_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_deck_label)
	var starts := HBoxContainer.new()
	starts.alignment = BoxContainer.ALIGNMENT_CENTER
	starts.add_theme_constant_override("separation", 14)
	vb.add_child(starts)
	var quick := MenuButtons.big("QUICK MATCH", Palette.GOLD, 22)
	quick.pressed.connect(press_quick)
	starts.add_child(quick)
	var host_b := MenuButtons.big("HOST ROOM", Color.WHITE, 22)
	host_b.pressed.connect(press_host)
	starts.add_child(host_b)
	var join_row := HBoxContainer.new()
	join_row.alignment = BoxContainer.ALIGNMENT_CENTER
	join_row.add_theme_constant_override("separation", 10)
	vb.add_child(join_row)
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "FROG-42"
	_code_edit.max_length = 9
	_code_edit.custom_minimum_size = Vector2(180, 44)
	_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_edit.add_theme_font_size_override("font_size", 22)
	_code_edit.text_submitted.connect(func(_t: String) -> void: _request(&"join"))
	join_row.add_child(_code_edit)
	var join_b := MenuButtons.big("JOIN ROOM", Color.WHITE, 22)
	join_b.pressed.connect(func() -> void: _request(&"join"))
	join_row.add_child(join_b)
	_starters = [quick, host_b, join_b]
	_msg = UiStyle.label("", 18)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.custom_minimum_size = Vector2(480, 0)
	vb.add_child(_msg)
	_code = UiStyle.title(UiStyle.label("", 56, Palette.GOLD.darkened(0.25))) as Label
	_code.add_theme_color_override("font_outline_color", Palette.INK)
	_code.add_theme_constant_override("outline_size", 10)
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_code)
	_hint = UiStyle.label("Send this code to a friend", 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_hint)
	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 12)
	vb.add_child(tools)
	_copy = MenuButtons.big("COPY", Palette.GOLD, 18)
	_copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(_code.text)
		_copy.text = "COPIED!")
	tools.add_child(_copy)
	_retry = MenuButtons.big("RETRY", Palette.GOLD, 18)
	_retry.pressed.connect(press_retry)
	tools.add_child(_retry)
	_cancel = MenuButtons.big("CANCEL", Color.WHITE, 18)
	_cancel.pressed.connect(func() -> void: Online.cancel())
	tools.add_child(_cancel)
	var close := MenuButtons.big("CLOSE", Color.WHITE, 20)
	close.pressed.connect(func() -> void:
		if Online.state in [&"searching", &"hosting", &"joining", &"error"]:
			Online.cancel()
		closed.emit())
	vb.add_child(close)


static func _deck_name() -> String:
	var dk: Array = online_deck()
	if dk[0]:
		return (dk[0] as DeckData).display_name
	var d: DeckData = DeckStore.find(Session.player_deck)
	return d.display_name if d else String(Session.player_deck)
