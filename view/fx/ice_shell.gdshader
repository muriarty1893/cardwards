shader_type spatial;
render_mode blend_mix, cull_back, unshaded, depth_draw_never, shadows_disabled;
// See-through ice around a frozen creature: frosty fresnel edge plus white crack lines.

uniform sampler2D cell_tex : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(0.75, 0.9, 1.0, 1.0);

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float crack = 1.0 - smoothstep(0.03, 0.09, texture(cell_tex, local_pos.xy * 0.6 + local_pos.z * 0.3).r);
	ALBEDO = mix(tint.rgb, vec3(1.0), clamp(crack * 0.8 + fres * 0.5, 0.0, 1.0));
	ALPHA = clamp(0.28 + fres * 0.5 + crack * 0.5, 0.0, 0.9);
}
