extends SceneTree

func _initialize() -> void:
	root.add_child((load("res://tools/diag/cam_scan_node.gd") as GDScript).new())
