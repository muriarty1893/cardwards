class_name CardStacks
extends Node3D
## Each player's deck and discard pile as real card piles on the table (tabletop spec 7.2):
## yours at your right of the board, the rival's mirrored at the far left. Pile height follows
## the count, a number floats over each pile, the discard pile shows its top card face up, and
## stack_at() finds the pile under the mouse (clicking a discard pile opens DiscardViewer).

## [deck, discard] spots per player (table surface, y = 0).
const SPOTS: Array[Array] = [
	[Vector3(7.7, 0.0, 4.5), Vector3(7.7, 0.0, 2.1)],
	[Vector3(-7.7, 0.0, -4.5), Vector3(-7.7, 0.0, -2.1)],
]
const CARD := Vector2(1.25, 1.75)
const PER_CARD := 0.02
const BACKS: Array[Color] = [Color("#2f7fd0"), Color("#6a46c8")]
const RIM := Color("#ffcf3a")
const EDGE := Color("#f6e7c4")

## [player][0 deck / 1 discard] -> {"root", "body", "top", "label", "count"}
var _piles: Array[Array] = [[{}, {}], [{}, {}]]
## Each player's card back art (CardBacks) for the deck pile's top face.
var _backs: Array[Texture2D] = [null, null]


func _ready() -> void:
	for p: int in 2:
		for k: int in 2:
			_piles[p][k] = _make_pile(p, k)
		_paint_deck_top(p)


func _make_pile(p: int, k: int) -> Dictionary:
	var root := Node3D.new()
	root.name = "%s%d" % ["Deck" if k == 0 else "Discard", p]
	root.position = SPOTS[p][k]
	root.rotation.y = (0.08 if k == 0 else -0.12) * (1.0 if p == 0 else -1.0)
	add_child(root)
	var box := BoxMesh.new()
	box.size = Vector3(CARD.x, 1.0, CARD.y)
	var body := Palette.mesh(box, Toon.plain(EDGE), Vector3.ZERO)
	root.add_child(body)
	var top := Node3D.new()
	root.add_child(top)
	var rim := BoxMesh.new()
	rim.size = Vector3(CARD.x, 0.006, CARD.y)
	top.add_child(Palette.mesh(rim, Toon.plain(RIM), Vector3.ZERO, false))
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = CARD - Vector2(0.16, 0.16)
	face.mesh = quad
	face.rotation.x = -PI / 2.0
	face.position.y = 0.005
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = BACKS[p]
	face.material_override = mat
	top.add_child(face)
	var label := Label3D.new()
	label.font = load(UiStyle.TITLE_FONT) as FontFile
	label.font_size = 96
	label.pixel_size = 0.006
	label.outline_size = 24
	label.outline_modulate = UiStyle.WOOD_INK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)
	var pile := {"root": root, "body": body, "top": top, "face": face, "mat": mat, "label": label, "count": -1, "card": null}
	return pile


## Pile heights (cards) and the discard piles' top cards.
func set_counts(deck: Array[int], discard: Array[int], tops: Array = [null, null]) -> void:
	for p: int in 2:
		_set_pile(_piles[p][0], deck[p], null, p)
		_set_pile(_piles[p][1], discard[p], tops[p] as CardData, p)


func _set_pile(pile: Dictionary, n: int, top_card: CardData, p: int) -> void:
	var h: float = maxf(PER_CARD * float(n), 0.004)
	var body: Node3D = pile["body"]
	body.scale = Vector3(1.0, h, 1.0)
	body.position.y = h / 2.0
	body.visible = n > 0
	(pile["top"] as Node3D).position.y = h
	(pile["top"] as Node3D).visible = n > 0
	var label: Label3D = pile["label"]
	label.text = str(n)
	label.position.y = h + 0.45
	label.visible = n > 0
	pile["count"] = n
	if pile["card"] != top_card:
		pile["card"] = top_card
		var mat: StandardMaterial3D = pile["mat"]
		if top_card:
			mat.albedo_texture = load(VisualDB.art_path(top_card.id)) as Texture2D
			mat.albedo_color = Color.WHITE
		elif pile == _piles[p][0]:
			_paint_deck_top(p)
		else:
			mat.albedo_texture = null
			mat.albedo_color = EDGE.darkened(0.2)


## Shows each deck's card back on its deck pile.
func set_backs(you: Texture2D, rival: Texture2D) -> void:
	_backs = [you, rival]
	for p: int in 2:
		_paint_deck_top(p)


func _paint_deck_top(p: int) -> void:
	var pile: Dictionary = _piles[p][0]
	if pile.is_empty():
		return
	var mat: StandardMaterial3D = pile["mat"]
	mat.albedo_texture = _backs[p]
	mat.albedo_color = Color.WHITE if _backs[p] else BACKS[p]


## The texture on player p's deck pile top (tests).
func deck_face_texture(p: int) -> Texture2D:
	return (_piles[p][0]["mat"] as StandardMaterial3D).albedo_texture


func count(p: int, kind: StringName) -> int:
	return int(_piles[p][0 if kind == &"deck" else 1]["count"])


func pile_height(p: int, kind: StringName) -> float:
	return (_piles[p][0 if kind == &"deck" else 1]["top"] as Node3D).position.y


## Top centre of a pile (world).
func point(p: int, kind: StringName) -> Vector3:
	var pile: Dictionary = _piles[p][0 if kind == &"deck" else 1]
	return (pile["root"] as Node3D).global_position + Vector3(0, (pile["top"] as Node3D).position.y, 0)


## The pile under a screen point: {"player", "kind": &"deck" | &"discard"} or {}.
func stack_at(cam: Camera3D, screen: Vector2) -> Dictionary:
	for p: int in 2:
		for k: int in 2:
			var root: Node3D = _piles[p][k]["root"]
			var y: float = (_piles[p][k]["top"] as Node3D).position.y
			var r := Rect2(cam.unproject_position(root.to_global(Vector3(-CARD.x / 2.0, y, -CARD.y / 2.0))), Vector2.ZERO)
			for c: Vector3 in [Vector3(CARD.x / 2.0, y, -CARD.y / 2.0), Vector3(-CARD.x / 2.0, y, CARD.y / 2.0), Vector3(CARD.x / 2.0, y, CARD.y / 2.0), Vector3(0, 0, 0)]:
				r = r.expand(cam.unproject_position(root.to_global(c)))
			if r.grow(6.0).has_point(screen):
				return {"player": p, "kind": &"deck" if k == 0 else &"discard"}
	return {}
