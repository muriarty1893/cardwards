shader_type spatial;
render_mode unshaded, cull_back;
// A flat pool on a land (board look 2): 0 water, 1 ice (cracks + sheen), 2 chocolate (glossy swirl). Drawn on a quad
// whose UV runs 0..1 across the pool's bounding ellipse.
// Water: an uneven shoreline (SetPieces.pond_edge, same formula), clear shallows over a sandy, pebbly bottom that
// deepen to dark green-teal, soft wind ripples drifting across, sky reflected at glancing angles, small sun
// glints and a wet dark rim at the shore.

#include "res://view/look/color_space.gdshaderinc"

uniform int kind = 0;
uniform sampler2D cell_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D fbm_tex : repeat_enable, filter_linear_mipmap;
// Shoreline shape (water only): the same seed SetPieces.pond_edge uses for the stones.
uniform float shape_seed = 0.0;
// The pool's size in world units (rx, rz), so ripples keep their size on any pool.
uniform vec2 radii = vec2(0.5, 0.5);

const vec3 INK = vec3(0.133, 0.2, 0.2);

// Shoreline radius (fraction of the bounding ellipse) at angle a. Keep in step with SetPieces.pond_edge.
float pond_edge(float a) {
	float s = shape_seed;
	return clamp(0.84 + 0.07 * sin(2.0 * a + s) + 0.05 * sin(3.0 * a + s * 1.7) + 0.03 * sin(5.0 * a + s * 2.3), 0.62, 0.99);
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	vec3 col;
	if (kind == 0) {
		float edge = pond_edge(atan(q.y, q.x));
		float rr = length(q) / edge;
		if (rr > 1.0) {
			discard;
		}
		vec2 w = q * radii;                    // world-sized coordinates
		float depth = 1.0 - rr;               // 0 at the shore, 1 in the middle
		// Bottom: sand with pebbles (cell edges), seen through the shallows.
		float pebble = texture(cell_tex, w * 1.6).r;
		vec3 sand = mix(vec3(0.46, 0.37, 0.2), vec3(0.64, 0.53, 0.31), texture(fbm_tex, w * 0.9).r);
		sand = mix(sand * 0.72, sand, smoothstep(0.03, 0.12, pebble));
		// Water body: clear near the shore, dark green-teal where deep.
		vec3 shallow = vec3(0.1, 0.32, 0.29);
		vec3 deep = vec3(0.015, 0.09, 0.1);
		vec3 water = mix(shallow, deep, smoothstep(0.1, 0.75, depth));
		float clear = 1.0 - smoothstep(0.0, 0.3, depth);
		col = mix(water, sand * vec3(0.85, 0.95, 0.85), clear * 0.7);
		// Wind ripples: two noise layers drifting different ways make a soft moving surface.
		float n1 = texture(fbm_tex, w * 1.3 + vec2(TIME * 0.035, TIME * 0.02)).r;
		float n2 = texture(fbm_tex, w * 2.1 - vec2(TIME * 0.025, -TIME * 0.04)).r;
		float ripple = n1 + n2 - 1.0;          // about -0.5..0.5
		// Sky in the water: stronger at glancing angles, broken up by the ripples.
		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float fres = pow(1.0 - facing, 3.0) * 0.4 + 0.06;
		vec3 sky = vec3(0.5, 0.68, 0.76);
		col = mix(col, sky, clamp(fres + ripple * 0.12, 0.0, 0.5) * smoothstep(0.1, 0.35, depth));
		col *= 1.0 + ripple * 0.1;
		// Sun glints where ripple crests line up.
		float glint = smoothstep(0.34, 0.42, ripple) * smoothstep(0.62, 0.7, texture(cell_tex, w * 3.0 + TIME * 0.05).r);
		col = mix(col, vec3(1.0, 0.98, 0.9), glint * 0.85);
		// Wet dark rim and a soft edge line at the shore.
		col = mix(col, vec3(0.16, 0.14, 0.09), smoothstep(0.86, 0.97, rr) * 0.6);
		col = mix(col, INK, smoothstep(0.97, 1.0, rr) * 0.35);
	} else {
		float r = length(q);
		if (r > 1.0) {
			discard;
		}
		if (kind == 1) {
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
	}
	ALBEDO = out_col(col);
}
