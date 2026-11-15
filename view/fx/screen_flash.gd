class_name ScreenFlash
extends ColorRect
## Coloured vignette at the screen edges (e.g. red when a hero is hit). Fades and frees itself.

const SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float strength = 1.0;
void fragment() {
	float d = distance(UV, vec2(0.5));
	COLOR = vec4(tint.rgb, smoothstep(0.3, 0.75, d) * strength * tint.a);
}
"""

static var _shader: Shader


static func edge(parent: Control, color: Color, duration: float = 0.35) -> ScreenFlash:
	var f := ScreenFlash.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("strength", 1.0)
	f.material = m
	parent.add_child(f)
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := f.create_tween()
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("strength", v), 1.0, 0.0, duration)
	tw.tween_callback(f.queue_free)
	return f
