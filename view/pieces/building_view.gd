class_name BuildingView
extends Node3D
## A little tower whose roof is coloured by land. Sits at the back corner of an island.

const OFFSET := Vector3(0.62, 0, -0.45)

var card: CardData


static func create(c: CardData) -> BuildingView:
	var v := BuildingView.new()
	v.card = c
	v.scale = Vector3.ONE * 0.75
	v.add_child(Palette.mesh(Palette.cylinder(0.3, 0.36, 0.7, 8), Palette.mat(Color("#efe3c8"), 0.8, true), Vector3(0, 0.5, 0)))
	v.add_child(Palette.mesh(Palette.cylinder(0.0, 0.42, 0.5, 8), Palette.mat(Palette.LAND_TOP[c.land].darkened(0.15), 0.7, true), Vector3(0, 1.1, 0)))
	v.add_child(Palette.mesh(BoxMesh.new(), Palette.mat(Palette.INK), Vector3(0, 0.45, 0.33), false))
	v.get_child(2).scale = Vector3(0.14, 0.22, 0.02)
	return v
