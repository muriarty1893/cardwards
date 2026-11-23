class_name MagicGems
extends Control
## The human's magic as GameState.MAGIC_CAP diamond gems: filled = magic to spend, empty =
## spent this turn (up to the max), hidden = not unlocked yet. Magic above the cap shows "+N".

const GEM := Vector2(20, 30)
const GAP := 4.0
const FULL := Color("#b48cff")
const SHINE := Color("#f0e2ff")
const EMPTY := Color("#2a2550")

var _magic: int = 0
var _max: int = 0
var _extra: Label
var _pop_from: int = 0
var _pop_t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(GameState.MAGIC_CAP * (GEM.x + GAP) - GAP + 16, GEM.y + 16)
	size = custom_minimum_size
	_extra = UiStyle.title(UiStyle.label("", 18, Color.WHITE)) as Label
	_extra.add_theme_color_override("font_outline_color", Palette.INK)
	_extra.add_theme_constant_override("outline_size", 6)
	_extra.position = Vector2(size.x - 8, -6)
	_extra.visible = false
	add_child(_extra)


func set_magic(magic: int, max_magic: int) -> void:
	if magic > _magic:
		# Newly filled gems pop and sparkle.
		_pop_from = _magic
		_pop_t = 1.0
		set_process(true)
	_magic = magic
	_max = max_magic
	_extra.text = "+%d" % extra()
	_extra.visible = extra() > 0
	queue_redraw()


## Per gem: 2 filled, 1 empty (spent), 0 hidden.
func gem_states() -> Array[int]:
	var out: Array[int] = []
	for i: int in GameState.MAGIC_CAP:
		out.append(2 if i < _magic else (1 if i < _max else 0))
	return out


## Magic beyond the gems (gained above the cap).
func extra() -> int:
	return maxi(0, _magic - GameState.MAGIC_CAP)


func _process(delta: float) -> void:
	_pop_t = maxf(0.0, _pop_t - delta * 2.2)
	queue_redraw()
	if _pop_t <= 0.0:
		set_process(false)


func _draw() -> void:
	var states: Array[int] = gem_states()
	for i: int in states.size():
		if states[i] == 0:
			continue
		var c := Vector2(8 + i * (GEM.x + GAP) + GEM.x / 2.0, 8 + GEM.y / 2.0)
		var pop: float = _pop_t if i >= _pop_from and i < _magic else 0.0
		var h := GEM / 2.0 * (1.0 + 0.45 * sin(pop * PI))
		if pop > 0.0:
			# Sparkle rays.
			for k: int in 4:
				var a: float = k * PI / 2.0 + pop * 2.0
				draw_line(c + Vector2(cos(a), sin(a)) * (h.y + 2.0), c + Vector2(cos(a), sin(a)) * (h.y + 2.0 + 10.0 * pop), Color(SHINE, pop), 3.0)
		var pts := PackedVector2Array([c + Vector2(0, -h.y), c + Vector2(h.x, 0), c + Vector2(0, h.y), c + Vector2(-h.x, 0)])
		var ink := PackedVector2Array([c + Vector2(0, -h.y - 4), c + Vector2(h.x + 4, 0), c + Vector2(0, h.y + 4), c + Vector2(-h.x - 4, 0)])
		draw_colored_polygon(ink, Palette.INK)
		draw_colored_polygon(pts, FULL if states[i] == 2 else EMPTY)
		if states[i] == 2:
			var glint := PackedVector2Array([c + Vector2(-2, -h.y + 5), c + Vector2(h.x - 6, -1), c + Vector2(-2, -3)])
			draw_colored_polygon(glint, SHINE)
