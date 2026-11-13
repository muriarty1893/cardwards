class_name GameEvent
extends RefCounted
## Something that happened, returned by Rules.apply for the view to animate.

var type: StringName
var data: Dictionary


static func make(t: StringName, d: Dictionary = {}) -> GameEvent:
	var e := GameEvent.new()
	e.type = t
	e.data = d
	return e


func to_dict() -> Dictionary:
	return {"type": type, "data": data.duplicate(true)}


func _to_string() -> String:
	return "%s%s" % [type, data]
