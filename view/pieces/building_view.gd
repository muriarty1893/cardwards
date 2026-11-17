class_name BuildingView
extends Node3D
## A building model on the back of its half-lane (Quaternius "Ultimate Fantasy RTS", CC0).

const HEIGHT := 0.6
const MAX_WIDTH := 1.0
## Kept for the pop-in tween in EventPlayer.
const SCALE := 1.0

var card: CardData


static func create(c: CardData) -> BuildingView:
	var v := BuildingView.new()
	v.card = c
	var path: String = VisualDB.model_path(c.id)
	if ResourceLoader.exists(path):
		var mdl: Node3D = Palette.model(path, HEIGHT, MAX_WIDTH)
		Toon.apply(mdl, VisualDB.tint(c.id))
		mdl.position.y = Island.TOP_Y
		v.add_child(mdl)
	else:
		v.add_child(Palette.mesh(Palette.cylinder(0.3, 0.36, 0.7, 8), Toon.plain(Color("#efe3c8")), Vector3(0, 0.5, 0)))
		v.add_child(Palette.mesh(Palette.cylinder(0.0, 0.42, 0.5, 8), Toon.plain(Palette.LAND_TOP[c.land].darkened(0.15)), Vector3(0, 1.1, 0)))
	if not BlobShadow.sun_shadows():
		v.add_child(BlobShadow.build(0.4, HEIGHT, Island.TOP_Y + 0.02))
	return v
