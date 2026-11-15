class_name GameAudio
extends Node
## Sound (autoload "Audio"): a pool of effect players on the SFX bus, two music players on the
## Music bus for crossfades, and named sound sets with a few variants each.

const POOL := 8
const SILENT_DB := -40.0
## Sound set -> variant files (Kenney CC0 packs and rubberduck's CC0 hits; see CREDITS.md).
const SETS: Dictionary = {
	&"ui_click": ["res://assets/audio/sfx/ui_click_1.ogg", "res://assets/audio/sfx/ui_click_2.ogg", "res://assets/audio/sfx/ui_click_3.ogg"],
	&"ui_hover": ["res://assets/audio/sfx/ui_hover_1.ogg", "res://assets/audio/sfx/ui_hover_2.ogg"],
	&"card_draw": ["res://assets/audio/sfx/card_draw_1.ogg", "res://assets/audio/sfx/card_draw_2.ogg", "res://assets/audio/sfx/card_draw_3.ogg"],
	&"card_deal": ["res://assets/audio/sfx/card_deal_1.ogg", "res://assets/audio/sfx/card_deal_2.ogg"],
	&"card_flip": ["res://assets/audio/sfx/card_flip_1.ogg", "res://assets/audio/sfx/card_flip_2.ogg"],
	&"card_play": ["res://assets/audio/sfx/card_play_1.ogg", "res://assets/audio/sfx/card_play_2.ogg", "res://assets/audio/sfx/card_play_3.ogg"],
	&"creature_land": ["res://assets/audio/sfx/creature_land_1.ogg", "res://assets/audio/sfx/creature_land_2.ogg"],
	&"building_rise": ["res://assets/audio/sfx/building_rise_1.ogg", "res://assets/audio/sfx/building_rise_2.ogg"],
	&"attack_whoosh": ["res://assets/audio/sfx/attack_whoosh_1.ogg", "res://assets/audio/sfx/attack_whoosh_2.ogg"],
	&"hit_light": ["res://assets/audio/sfx/hit_light_1.ogg", "res://assets/audio/sfx/hit_light_2.ogg"],
	&"hit_heavy": ["res://assets/audio/sfx/hit_heavy_1.ogg", "res://assets/audio/sfx/hit_heavy_2.ogg", "res://assets/audio/sfx/hit_heavy_3.ogg"],
	&"hit_crit": ["res://assets/audio/sfx/hit_crit_1.ogg", "res://assets/audio/sfx/hit_crit_2.ogg"],
	&"hero_hit": ["res://assets/audio/sfx/hero_hit_1.ogg", "res://assets/audio/sfx/hero_hit_2.ogg"],
	&"death": ["res://assets/audio/sfx/death_1.ogg", "res://assets/audio/sfx/death_2.ogg"],
	&"heal": ["res://assets/audio/sfx/heal_1.ogg", "res://assets/audio/sfx/heal_2.ogg"],
	&"freeze": ["res://assets/audio/sfx/freeze_1.ogg", "res://assets/audio/sfx/freeze_2.ogg"],
	&"ice_shatter": ["res://assets/audio/sfx/ice_shatter_1.ogg", "res://assets/audio/sfx/ice_shatter_2.ogg"],
	&"fire_whoosh": ["res://assets/audio/sfx/fire_whoosh_1.ogg", "res://assets/audio/sfx/fire_whoosh_2.ogg"],
	&"explosion": ["res://assets/audio/sfx/explosion_1.ogg", "res://assets/audio/sfx/explosion_2.ogg"],
	&"candy_pop": ["res://assets/audio/sfx/candy_pop_1.ogg", "res://assets/audio/sfx/candy_pop_2.ogg", "res://assets/audio/sfx/candy_pop_3.ogg"],
	&"magic_gain": ["res://assets/audio/sfx/magic_gain_1.ogg", "res://assets/audio/sfx/magic_gain_2.ogg"],
	&"turn_start": ["res://assets/audio/sfx/turn_start_1.ogg"],
	&"victory": ["res://assets/audio/sfx/victory_1.ogg"],
	&"defeat": ["res://assets/audio/sfx/defeat_1.ogg"],
}
const MENU_MUSIC := "res://assets/audio/music/menu.mp3"
const MATCH_MUSIC := "res://assets/audio/music/match.mp3"

## Tests: record every sound set that actually played.
var log_enabled: bool = false
var played: Array[StringName] = []

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: Array[AudioStreamPlayer] = []
var _current: int = 0
var _music_path: String = ""
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	for i: int in 2:
		var m := AudioStreamPlayer.new()
		m.bus = &"Music"
		m.volume_db = SILENT_DB
		add_child(m)
		_music.append(m)


## Plays a random variant of a sound set with a slight pitch wobble.
func sfx(name: StringName, pitch_jitter: float = 0.08) -> void:
	if not SETS.has(name):
		push_warning("Audio: unknown sound set %s" % name)
		return
	var paths: Array = SETS[name]
	var stream: AudioStream = _stream(paths[randi() % paths.size()])
	if stream == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
	if log_enabled:
		played.append(name)


## Crossfades to a music track (does nothing if it is already playing).
func music(path: String, fade: float = 1.0) -> void:
	if path == _music_path:
		return
	_music_path = path
	var old: AudioStreamPlayer = _music[_current]
	_current = 1 - _current
	var cur: AudioStreamPlayer = _music[_current]
	cur.stream = _stream(path)
	cur.volume_db = SILENT_DB
	cur.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cur, "volume_db", 0.0, fade)
	tw.tween_property(old, "volume_db", SILENT_DB, fade)
	tw.chain().tween_callback(old.stop)


func _stream(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) as AudioStream
	return _cache[path]
