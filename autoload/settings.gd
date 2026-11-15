class_name GameSettings
extends Node
## Player settings (autoload "Settings"): graphics quality and volumes, saved to `path`.
## A missing or unreadable file means defaults. `--quality=low|high` overrides the file for one run.

signal changed

enum Quality { HIGH, LOW }

## Fallback default; the real default comes from default_quality() (Low on integrated GPUs).
const DEFAULT_QUALITY: Quality = Quality.HIGH
const DEFAULT_MUSIC := 0.8
const DEFAULT_SFX := 0.9
const SECTION := "settings"

var music_volume: float = DEFAULT_MUSIC
var sfx_volume: float = DEFAULT_SFX
var quality: Quality = default_quality()
var path: String = "user://settings.cfg"


func _ready() -> void:
	load_settings()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--quality="):
			quality = Quality.LOW if arg.substr(10) == "low" else Quality.HIGH


func reset() -> void:
	music_volume = DEFAULT_MUSIC
	sfx_volume = DEFAULT_SFX
	quality = default_quality()


## Integrated GPUs (like the HD 620 this was measured on) only hold 60 fps on Low.
static func default_quality() -> Quality:
	if RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU:
		return Quality.LOW
	return DEFAULT_QUALITY


func load_settings() -> void:
	reset()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	music_volume = _volume(cfg.get_value(SECTION, "music_volume", DEFAULT_MUSIC), DEFAULT_MUSIC)
	sfx_volume = _volume(cfg.get_value(SECTION, "sfx_volume", DEFAULT_SFX), DEFAULT_SFX)
	quality = _quality(cfg.get_value(SECTION, "quality", DEFAULT_QUALITY))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION, "quality", int(quality))
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
		_:
			push_warning("Settings: unknown key %s" % key)
			return
	save_settings()
	changed.emit()


static func _volume(v: Variant, fallback: float) -> float:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return fallback
	return clampf(float(v), 0.0, 1.0)


static func _quality(v: Variant) -> Quality:
	if typeof(v) == TYPE_INT and int(v) == Quality.LOW:
		return Quality.LOW
	return Quality.HIGH
