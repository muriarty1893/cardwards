shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_draw_never, shadows_disabled;
// Guard: a see-through wall of glowing hexagons standing in front of the creature.

uniform vec4 tint : source_color = vec4(1.0, 0.82, 0.35, 1.0);
uniform float cells = 5.0;
uniform float strength = 1.0;

#include "res://view/look/color_space.gdshaderinc"

const vec2 HS = vec2(1.0, 1.7320508);

// Nearest hexagon centre: xy = offset from it, zw = its id.
vec4 hex_coords(vec2 p) {
	vec4 c = floor(vec4(p, p - vec2(0.5, 1.0)) / HS.xyxy) + 0.5;
	vec4 h = vec4(p - c.xy * HS, p - (c.zw + 0.5) * HS);
	return dot(h.xy, h.xy) < dot(h.zw, h.zw) ? vec4(h.xy, c.xy) : vec4(h.zw, c.zw + 0.5);
}

float hex_edge(vec2 p) {
	p = abs(p);
	return max(dot(p, HS * 0.5), p.x);
}

void fragment() {
	// Fades out at the arc's two ends; a bright rim runs along the top edge.
	float sides = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	float rim = smoothstep(0.1, 0.0, UV.y);
	vec4 h = hex_coords(UV * vec2(cells * 2.2, cells * 1.1));
	float edge = smoothstep(0.36, 0.47, hex_edge(h.xy));
	float wave = 0.5 + 0.5 * sin(TIME * 2.2 - UV.y * 7.0 + h.z * 1.7 + h.w * 0.9);
	float a = (0.28 + edge * (0.55 + 0.35 * wave) + rim * 0.8) * sides * strength;
	vec3 gold = src_lin(tint.rgb);
	vec3 col = mix(gold * 0.75, gold, edge);
	col = mix(col, vec3(1.0, 0.96, 0.8), rim + edge * wave * 0.35);
	ALBEDO = out_col(col);
	ALPHA = clamp(a, 0.0, 0.95);
}
