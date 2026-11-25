extends Control
## Dev: every card face in a grid, saved as a picture (checks text fit by eye).
##   godot --path . res://tools/card_sheet.tscn -- --shot=/tmp/cards.png [--only=a,b] [--scale=1.0]

var _frames: int = 0
var _shot: String = "/tmp/cards.png"


func _ready() -> void:
	var only: PackedStringArray = []
	var sc: float = 1.0
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
		elif a.begins_with("--scale="):
			sc = float(a.substr(8))
	var cards: Array[CardData] = []
	for c: CardData in CardDB.all_cards():
		if only.is_empty() or String(c.id) in only:
			cards.append(c)
	var cols: int = mini(14, cards.size())
	var rows: int = ceili(cards.size() / float(cols))
	var cell := CardWidget.SIZE * sc + Vector2(6, 6)
	get_window().size = Vector2i(int(cols * cell.x) + 6, int(rows * cell.y) + 6)
	var bg := ColorRect.new()
	bg.color = Color("#30304a")
	bg.size = Vector2(get_window().size)
	add_child(bg)
	for i: int in cards.size():
		var w := CardWidget.new()
		w.setup(cards[i], i)
		w.scale = Vector2(sc, sc)
		w.position = Vector2(6 + (i % cols) * cell.x, 6 + (i / cols) * cell.y)
		add_child(w)


func _process(_d: float) -> void:
	_frames += 1
	if _frames == 6:
		get_viewport().get_texture().get_image().save_png(_shot)
		print("saved ", _shot)
		get_tree().quit()
