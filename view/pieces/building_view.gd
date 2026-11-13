class_name BuildingView
extends Node3D
## A building model beside the creature spot (Quaternius "Ultimate Fantasy RTS", CC0).

const OFFSET := Vector3(0.72, 0, 1.5)
const HEIGHT := 1.05
const MAX_WIDTH := 0.95
## Kept for the pop-in tween in EventPlayer.
const SCALE := 1.0

var card: CardData


static func create(c: CardData) -> BuildingView:
	var v := BuildingView.new()
	v.card = c
	var path: String = "res://assets/buildings/%s.gltf" % c.id
	if ResourceLoader.exists(path):
		var mdl: Node3D = Palette.model(path, HEIGHT, MAX_WIDTH)
		mdl.position.y = Island.TOP_Y
		v.add_child(mdl)
	else:
		v.add_child(Palette.mesh(Palette.cylinder(0.3, 0.36, 0.7, 8), Palette.mat(Color("#efe3c8"), 0.8, true), Vector3(0, 0.5, 0)))
		v.add_child(Palette.mesh(Palette.cylinder(0.0, 0.42, 0.5, 8), Palette.mat(Palette.LAND_TOP[c.land].darkened(0.15), 0.7, true), Vector3(0, 1.1, 0)))
	return v
