extends Node
## Traces the rival's bones; reports any frame-to-frame jump and the hand's height range.

var seat: RivalSeat
var frames: int = 0
var t: float = 0.0
var last: Dictionary = {}
var lo: float = 99.0
var hi: float = -99.0
var mode: String = "idle"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
	seat = RivalSeat.new()
	add_child(seat)
	seat.setup(MatchController.RIVAL_MODEL)
	if mode == "think":
		seat.think(true)


func _process(delta: float) -> void:
	frames += 1
	t += delta
	if mode == "react" and frames % 240 == 60:
		seat.play_card()
		print("%5.2fs play_card" % t)
	if t > 0.6:
		for b: StringName in [&"head", &"handslot.r", &"chest"]:
			var p: Vector3 = seat.bone_position(b)
			if last.has(b) and (p - last[b]).length() > 0.05:
				print("%5.2fs %s jump %.3f" % [t, b, (p - last[b]).length()])
			last[b] = p
		var y: float = seat.bone_position(&"handslot.r").y
		lo = minf(lo, y)
		hi = maxf(hi, y)
	if t > 9.0:
		print("hand y range %.3f .. %.3f" % [lo, hi])
		get_tree().quit()
