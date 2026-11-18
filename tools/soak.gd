extends SceneTree
## Soak test: AI plays the human side through the real match scene for several seeds and deck
## pairings at high speed. Errors and warnings go to the log; grep it afterwards.
##   godot --headless --path . --script res://tools/soak.gd [-- --matches=<n>]

func _initialize() -> void:
	root.add_child((load("res://tools/soak_node.gd") as GDScript).new())
