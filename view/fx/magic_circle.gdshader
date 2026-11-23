shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never, shadows_disabled;
// A glowing magic circle on the ground: two rings, rune ticks between them, a star in the middle.

uniform vec4 tint : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float strength = 1.0;
uniform float spin = 0.0;

#include "res://view/look/color_space.gdshaderinc"

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) + spin;
	float outer = smoothstep(0.035, 0.0, abs(r - 0.92));
	float inner = smoothstep(0.025, 0.0, abs(r - 0.7));
	float ticks = step(0.74, r) * step(r, 0.88) * step(0.85, abs(sin(a * 12.0)));
	float star = 0.0;
	for (int k = 0; k < 3; k++) {
		float ang = a + float(k) * 2.0944;
		star = max(star, smoothstep(0.02, 0.0, abs(r * cos(ang) - 0.35)) * step(r, 0.7));
	}
	float glow = smoothstep(1.0, 0.0, r) * 0.18;
	float v = (outer + inner + ticks * 0.8 + star * 0.9 + glow) * strength;
	ALBEDO = out_col(src_lin(tint.rgb) * v);
	ALPHA = clamp(v, 0.0, 1.0);
}
