shader_type spatial;
render_mode cull_back;
// Painted meadow: soft light and dark patches plus faint brush streaks, in world space.
// Noise comes from a shared seamless texture (NoiseBank) rather than per-pixel maths.

#include "res://view/look/toon_light.gdshaderinc"

uniform vec4 base_col : source_color = vec4(0.435, 0.722, 0.310, 1.0);
uniform vec4 dark_col : source_color = vec4(0.353, 0.620, 0.251, 1.0);
uniform vec4 light_col : source_color = vec4(0.561, 0.812, 0.384, 1.0);
uniform float noise_scale = 0.08;

varying vec3 world_pos;

uniform sampler2D fbm_tex : repeat_enable, filter_linear_mipmap;

float fbm(vec2 q) {
	return texture(fbm_tex, q * 0.2).r;
}

float value_noise(vec2 q) {
	return texture(fbm_tex, q * 0.2 + vec2(0.37, 0.61)).r;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = fbm(p * noise_scale);
	float streak = value_noise(vec2(p.x * 0.35, p.y * 1.6));
	vec3 c = base_col.rgb;
	c = mix(c, dark_col.rgb, smoothstep(0.56, 0.62, n));
	c = mix(c, light_col.rgb, smoothstep(0.36, 0.30, n));
	c = mix(c, light_col.rgb, smoothstep(0.72, 0.78, streak) * 0.2);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
