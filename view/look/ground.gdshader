shader_type spatial;
render_mode cull_back;
// Painted meadow: soft light and dark patches plus faint brush streaks, in world space
// so there are no tiling seams. Lit with the shared cartoon bands.

#include "res://view/look/toon_light.gdshaderinc"

uniform vec4 base_col : source_color = vec4(0.435, 0.722, 0.310, 1.0);
uniform vec4 dark_col : source_color = vec4(0.353, 0.620, 0.251, 1.0);
uniform vec4 light_col : source_color = vec4(0.561, 0.812, 0.384, 1.0);
uniform float noise_scale = 0.08;

varying vec3 world_pos;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 4; i++) {
		v += value_noise(p) * amp;
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
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
