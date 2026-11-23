shader_type spatial;
render_mode blend_add, cull_back, unshaded, depth_draw_never, shadows_disabled;
// Hidden: violet ripples drifting up over the (half see-through) body.

uniform vec4 tint : source_color = vec4(0.55, 0.45, 1.0, 1.0);

#include "res://view/look/color_space.gdshaderinc"

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.6);
	float band = smoothstep(0.55, 1.0, sin(world.y * 22.0 - TIME * 3.0 + sin(world.x * 9.0) * 1.5));
	ALBEDO = out_col(src_lin(tint.rgb) * (band * 0.55 + f * 0.8));
	ALPHA = 1.0;
}
