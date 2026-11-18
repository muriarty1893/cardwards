shader_type spatial;
render_mode unshaded, cull_disabled;
// A lane separator ribbon (board look 2, spec 1.2-1.3): cream with ink edges, drawn outward from the middle seam as
// `reveal` goes 0 -> 1 (UV.y is world z / board half length, UV.x runs across the ribbon), with a warm glow at the
// drawing tip.

#include "res://view/look/color_space.gdshaderinc"

uniform float reveal = 0.0;
uniform vec3 cream : source_color = vec3(1.0, 0.953, 0.788);

const vec3 INK = vec3(0.133, 0.2, 0.2);

void fragment() {
	float along = abs(UV.y);
	if (along > reveal) {
		discard;
	}
	float d = abs(UV.x - 0.5) * 2.0;
	vec3 c = src_lin(cream);
	vec3 col = mix(c, c * 0.82, smoothstep(0.1, 0.55, d));
	col = mix(col, INK, smoothstep(0.62, 0.78, d));
	float tip = smoothstep(0.1, 0.0, reveal - along) * (1.0 - smoothstep(0.97, 1.0, reveal));
	col = mix(col, vec3(1.0, 0.85, 0.45), tip * 0.8);
	ALBEDO = out_col(col);
}
