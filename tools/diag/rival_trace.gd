extends SceneTree
## Diagnostic: traces the rival's head and hand bones per frame and reports jumps.

func _initialize() -> void:
	var n: Node = (load("res://tools/diag/rival_trace_node.gd") as GDScript).new()
	root.add_child(n)
