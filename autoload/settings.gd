class_name GameSettings
extends Node
## Player settings (autoload "Settings"): graphics quality, volumes and camera, saved to `path`.
## A missing or unreadable file means defaults. `--quality=low|high` overrides the file for one run.

signal changed

enum Quality { HIGH, LOW }

## Fallback default; the real default comes from default_quality() (Low on integrated GPUs).
const DEFAULT_QUALITY: Quality = Quality.HIGH
const DEFAULT_MUSIC := 0.8
const DEFAULT_SFX := 0.9
const DEFAULT_CLOSEUPS := true
const DEFAULT_ZOOM_SPEED := 1.0
const ZOOM_SPEED_MIN := 0.25
const ZOOM_SPEED_MAX := 2.0
const SECTION := "settings"

var music_volume: float = DEFAULT_MUSIC
var sfx_volume: float = DEFAULT_SFX
var quality: Quality = default_quality()
## The camera drops into the lane for each attack.
var battle_closeups: bool = DEFAULT_CLOSEUPS
## Mouse-wheel / pinch zoom speed multiplier.
var zoom_speed: float = DEFAULT_ZOOM_SPEED
## The name shown to online rivals (kept by reset()).
var player_name: String = ""
var path: String = "user://settings.cfg"


func _ready() -> void:
	load_settings()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--quality="):
			quality = Quality.LOW if arg.substr(10) == "low" else Quality.HIGH
	apply_audio()


## Pushes the volumes to the Music and SFX buses (0 mutes the bus).
func apply_audio() -> void:
	for pair: Array in [[&"Music", music_volume], [&"SFX", sfx_volume]]:
		var idx: int = AudioServer.get_bus_index(pair[0])
		if idx < 0:
			continue
		var v: float = pair[1]
		AudioServer.set_bus_mute(idx, v <= 0.0)
		AudioServer.set_bus_volume_db(idx, linear_to_db(v) if v > 0.0 else -80.0)


func reset() -> void:
	music_volume = DEFAULT_MUSIC
	sfx_volume = DEFAULT_SFX
	quality = default_quality()
	battle_closeups = DEFAULT_CLOSEUPS
	zoom_speed = DEFAULT_ZOOM_SPEED


## Integrated GPUs (like the HD 620 this was measured on) only hold 60 fps on Low.
static func default_quality() -> Quality:
	if RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU:
		return Quality.LOW
	return DEFAULT_QUALITY


func load_settings() -> void:
	reset()
	var cfg := ConfigFile.new()
	if player_name == "":
		player_name = _default_name()
	if cfg.load(path) != OK:
		return
	var pn: Variant = cfg.get_value(SECTION, "player_name", "")
	if pn is String and clean_name(pn) != "":
		player_name = clean_name(pn)
	music_volume = _volume(cfg.get_value(SECTION, "music_volume", DEFAULT_MUSIC), DEFAULT_MUSIC)
	sfx_volume = _volume(cfg.get_value(SECTION, "sfx_volume", DEFAULT_SFX), DEFAULT_SFX)
	quality = _quality(cfg.get_value(SECTION, "quality", DEFAULT_QUALITY))
	var bc: Variant = cfg.get_value(SECTION, "battle_closeups", DEFAULT_CLOSEUPS)
	battle_closeups = bool(bc) if typeof(bc) == TYPE_BOOL else DEFAULT_CLOSEUPS
	zoom_speed = _zoom_speed(cfg.get_value(SECTION, "zoom_speed", DEFAULT_ZOOM_SPEED), DEFAULT_ZOOM_SPEED)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION, "quality", int(quality))
	cfg.set_value(SECTION, "battle_closeups", battle_closeups)
	cfg.set_value(SECTION, "zoom_speed", zoom_speed)
	cfg.set_value(SECTION, "player_name", player_name)
	var err: Error = cfg.save(path)
	if err != OK:
		push_warning("Settings: could not save %s (%s)" % [path, error_string(err)])


func set_value(key: StringName, value: Variant) -> void:
	match key:
		&"music_volume":
			music_volume = _volume(value, music_volume)
		&"sfx_volume":
			sfx_volume = _volume(value, sfx_volume)
		&"quality":
			quality = _quality(value)
		&"battle_closeups":
			battle_closeups = bool(value)
		&"zoom_speed":
			zoom_speed = _zoom_speed(value, zoom_speed)
		_:
			push_warning("Settings: unknown key %s" % key)
			return
	save_settings()
	apply_audio()
	changed.emit()


## Cleaned like the server does it; nothing left → a fresh default name.
func set_player_name(n: String) -> void:
	var c: String = clean_name(n)
	player_name = c if c != "" else _default_name()
	save_settings()
	changed.emit()


## Control characters removed, trimmed, at most 16 characters (server/src/protocol.ts cleanName).
static func clean_name(n: String) -> String:
	var out: String = ""
	for ch: String in n:
		var u: int = ch.unicode_at(0)
		if u >= 32 and not (u >= 127 and u < 160):
			out += ch
	return out.strip_edges().left(16).strip_edges()


static func _default_name() -> String:
	return "Dreamer%d" % randi_range(100, 999)


func set_battle_closeups(on: bool) -> void:
	set_value(&"battle_closeups", on)


func set_zoom_speed(v: float) -> void:
	set_value(&"zoom_speed", v)


static func _zoom_speed(v: Variant, fallback: float) -> float:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return fallback
	return clampf(float(v), ZOOM_SPEED_MIN, ZOOM_SPEED_MAX)


static func _volume(v: Variant, fallback: float) -> float:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return fallback
	return clampf(float(v), 0.0, 1.0)


static func _quality(v: Variant) -> Quality:
	if typeof(v) == TYPE_INT and int(v) == Quality.LOW:
		return Quality.LOW
	return Quality.HIGH
