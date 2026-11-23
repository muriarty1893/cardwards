shader_type spatial;
render_mode blend_mix, cull_back, unshaded, depth_draw_never, shadows_disabled;
// Soap bubble around a creature with Bubble: clear middle, rainbow fresnel rim that slowly swirls,
// and a soft white highlight.

uniform float strength = 1.0;

#include "res://view/look/color_space.gdshaderinc"

void fragment() {
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + f * 1.3 + TIME * 0.12 + UV.y * 1.5));
	vec3 col = mix(vec3(0.85, 0.95, 1.0), rainbow, 0.75);
	float spot = smoothstep(0.93, 0.985, dot(NORMAL, normalize(vec3(-0.45, 0.55, 0.7))));
	col = mix(col, vec3(1.0), spot);
	ALBEDO = out_col(col);
	ALPHA = clamp((0.05 + f * 0.6 + spot * 0.7) * strength, 0.0, 0.85);
}
