shader_type spatial;
render_mode unshaded, cull_back;
// A flat pool on a land (board look 2): 0 water (ripples + sparkles), 1 ice (cracks + sheen), 2 chocolate (glossy
// swirl). Drawn on an ellipse disc whose UV runs 0..1 across; ink rim at the shore.

#include "res://view/look/color_space.gdshaderinc"

uniform int kind = 0;
uniform sampler2D cell_tex : repeat_enable, filter_linear_mipmap;

const vec3 INK = vec3(0.133, 0.2, 0.2);

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float r = length(q);
	if (r > 1.0) {
		discard;
	}
	vec3 col;
	if (kind == 0) {
		vec3 deep = vec3(0.12, 0.42, 0.62);
		vec3 shallow = vec3(0.35, 0.75, 0.85);
		col = mix(deep, shallow, smoothstep(0.2, 0.95, r));
		float rings = sin(r * 26.0 - TIME * 2.2) * 0.5 + 0.5;
		col = mix(col, vec3(0.75, 0.93, 1.0), smoothstep(0.82, 1.0, rings) * 0.35 * (1.0 - r));
		float glint = smoothstep(0.92, 1.0, sin(q.x * 9.0 + TIME * 1.3) * sin(q.y * 7.0 - TIME * 0.9));
		col = mix(col, vec3(1.0), glint * 0.7);
	} else if (kind == 1) {
		col = mix(vec3(0.72, 0.88, 0.98), vec3(0.92, 0.97, 1.0), smoothstep(0.0, 0.9, r));
		float crack = 1.0 - smoothstep(0.02, 0.06, texture(cell_tex, UV * 0.9).r);
		col = mix(col, vec3(0.55, 0.72, 0.9), crack * 0.8);
		float sheen = smoothstep(0.15, 0.0, abs(q.x + q.y * 0.6 - 0.3 + 0.15 * sin(TIME * 0.5)));
		col = mix(col, vec3(1.0), sheen * 0.6);
	} else {
		col = mix(vec3(0.33, 0.18, 0.1), vec3(0.45, 0.26, 0.15), 0.5 + 0.5 * sin(atan(q.y, q.x) * 3.0 + r * 8.0 - TIME * 0.8));
		col = mix(col, vec3(0.85, 0.65, 0.5), smoothstep(0.9, 1.0, sin(r * 14.0 - TIME * 1.1)) * 0.25);
	}
	col = mix(col, INK, smoothstep(0.9, 0.97, r));
	ALBEDO = out_col(col);
}
