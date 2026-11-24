shader_type spatial;
render_mode unshaded, cull_back;
// A flat pool on a land (board look 2): 0 water, 1 ice, 2 chocolate (glossy swirl). Drawn on a quad whose UV runs
// 0..1 across the pool's bounding ellipse.
// Water: an uneven shoreline (SetPieces.pond_edge, same formula), bright cartoon water from aqua shallows to a deep
// teal middle, drifting caustic light on the bottom, a wobbling foam line at the shore, ripple rings that spread now
// and then, sky at glancing angles and twinkling sun glints.
// Ice: a frosty snow rim, cloudy pale-to-blue ice with sharp cracks, a shine that sweeps across and twinkling sparkles.

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

float hash1(float n) {
	return fract(sin(n * 127.1 + shape_seed * 13.7) * 43758.5453);
}

// One ripple ring that grows from a random spot every `period` seconds (offset `off`); 0..1 brightness.
float ripple_ring(vec2 w, float i, float period, float off) {
	float t = TIME / period + off;
	float k = floor(t);
	float ph = fract(t);
	vec2 c = (vec2(hash1(k + i * 7.0), hash1(k * 1.3 + i * 3.0 + 5.0)) - 0.5) * 1.1 * radii;
	float d = length(w - c);
	float r = ph * 0.32;
	float band = 1.0 - smoothstep(0.0, 0.014, abs(d - r));
	float band2 = 1.0 - smoothstep(0.0, 0.01, abs(d - r * 0.6));
	return (band + band2 * 0.6) * (1.0 - ph) * smoothstep(0.0, 0.08, ph);
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	vec3 col;
	if (kind == 0) {
		float ang = atan(q.y, q.x);
		float edge = pond_edge(ang);
		float rr = length(q) / edge;
		if (rr > 1.0) {
			discard;
		}
		vec2 w = q * radii;                    // world-sized coordinates
		float depth = 1.0 - rr;               // 0 at the shore, 1 in the middle
		// Bottom: sand with pebbles (cell edges), seen through the shallows.
		float pebble = texture(cell_tex, w * 1.6).r;
		vec3 sand = mix(vec3(0.5, 0.42, 0.24), vec3(0.72, 0.6, 0.36), texture(fbm_tex, w * 0.9).r);
		sand = mix(sand * 0.75, sand, smoothstep(0.03, 0.12, pebble));
		// Water body: aqua shallows, teal middle, deeper blue-teal at the heart.
		vec3 shallow = vec3(0.16, 0.66, 0.62);
		vec3 mid = vec3(0.03, 0.36, 0.45);
		vec3 deep = vec3(0.012, 0.17, 0.28);
		vec3 water = mix(shallow, mid, smoothstep(0.05, 0.4, depth));
		water = mix(water, deep, smoothstep(0.45, 0.95, depth));
		float clear = 1.0 - smoothstep(0.0, 0.28, depth);
		col = mix(water, sand * vec3(0.75, 1.0, 0.95), clear * 0.55);
		// Wind ripples: two noise layers drifting different ways make a soft moving surface.
		float n1 = texture(fbm_tex, w * 1.3 + vec2(TIME * 0.035, TIME * 0.02)).r;
		float n2 = texture(fbm_tex, w * 2.1 - vec2(TIME * 0.025, -TIME * 0.04)).r;
		float ripple = n1 + n2 - 1.0;          // about -0.5..0.5
		// Caustics: light netting on the bottom, two drifting cell layers; strongest in the shallows.
		vec2 wob = vec2(ripple) * 0.05;
		float c1 = texture(cell_tex, w * 1.0 + wob + vec2(TIME * 0.03, TIME * 0.018)).r;
		float c2 = texture(cell_tex, w * 1.25 - wob + vec2(0.37, 0.71) - vec2(TIME * 0.022, -TIME * 0.03)).r;
		float caus = 1.0 - smoothstep(0.01, 0.05, min(c1, c2));
		col += vec3(0.55, 0.95, 0.85) * caus * mix(0.3, 0.08, smoothstep(0.1, 0.8, depth));
		// Sky in the water: stronger at glancing angles, broken up by the ripples.
		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float fres = pow(1.0 - facing, 3.0) * 0.4 + 0.05;
		vec3 sky = vec3(0.55, 0.78, 0.9);
		col = mix(col, sky, clamp(fres + ripple * 0.12, 0.0, 0.5) * smoothstep(0.1, 0.35, depth));
		col *= 1.0 + ripple * 0.12;
		// Ripple rings spreading now and then (a fish, a falling leaf).
		float rings = ripple_ring(w, 0.0, 3.7, 0.0) + ripple_ring(w, 1.0, 4.9, 0.45) + ripple_ring(w, 2.0, 6.1, 0.8);
		col = mix(col, vec3(0.85, 0.97, 1.0), clamp(rings, 0.0, 1.0) * 0.6 * smoothstep(0.08, 0.3, depth));
		// Sun glints: small bright sparks that twinkle where ripple crests line up.
		float spark = smoothstep(0.7, 0.78, texture(cell_tex, w * 1.5 + vec2(TIME * 0.05, -TIME * 0.03)).r);
		float glint = spark * smoothstep(0.18, 0.32, ripple) * (0.6 + 0.4 * sin(TIME * 5.0 + w.x * 40.0));
		col = mix(col, vec3(1.0, 0.99, 0.92), clamp(glint, 0.0, 1.0) * 0.95);
		// Foam at the shore: a soft white line that laps in and out.
		float lap = 0.025 * sin(TIME * 1.6 + ang * 4.0 + shape_seed) + (texture(fbm_tex, w * 3.5 + TIME * 0.06).r - 0.5) * 0.12;
		float foam = smoothstep(0.83, 0.88, rr + lap) * (1.0 - smoothstep(0.93, 0.97, rr));
		float foam_in = smoothstep(0.76, 0.8, rr + lap * 1.4) * (1.0 - smoothstep(0.8, 0.83, rr + lap * 1.4));
		col = mix(col, vec3(0.95, 1.0, 1.0), foam * 0.85 + foam_in * 0.35);
		// Wet sand bank and a soft edge line at the shore.
		col = mix(col, sand * 0.8, smoothstep(0.94, 0.98, rr) * 0.8);
		col = mix(col, INK, smoothstep(0.975, 1.0, rr) * 0.45);
	} else if (kind == 1) {
		vec2 w = q * radii;
		float wob = (texture(fbm_tex, w * 3.0).r - 0.5) * 0.14;
		float r = length(q) + wob;
		if (r > 1.0) {
			discard;
		}
		// Ice: pale at the rim, clear blue in the middle, cloudy frost patches.
		vec3 pale = vec3(0.68, 0.88, 1.0);
		vec3 blue = vec3(0.16, 0.52, 0.86);
		col = mix(blue, pale, smoothstep(0.1, 0.8, r));
		float cloud = texture(fbm_tex, w * 0.8 + 3.0).r;
		col = mix(col, vec3(0.85, 0.95, 1.0), smoothstep(0.5, 0.75, cloud) * 0.5);
		// Bubbles frozen inside.
		float bub = smoothstep(0.86, 0.93, texture(cell_tex, w * 1.8 + 1.7).r);
		col = mix(col, vec3(0.9, 0.97, 1.0), bub * 0.5 * (1.0 - smoothstep(0.5, 0.8, r)));
		// Cracks: dark blue lines with a white bright edge beside them.
		float cr = texture(cell_tex, w * 0.55 + 0.3).r;
		float crack = (1.0 - smoothstep(0.012, 0.035, cr)) * smoothstep(0.75, 0.55, r);
		float crack_hi = (1.0 - smoothstep(0.035, 0.06, cr)) * (1.0 - crack) * smoothstep(0.75, 0.55, r);
		col = mix(col, vec3(0.08, 0.3, 0.6), crack * 0.85);
		col = mix(col, vec3(1.0), crack_hi * 0.45);
		// A shine sweeping across every few seconds.
		float sw = fract(TIME / 4.5);
		float x = q.x + q.y * 0.6 - mix(-1.8, 1.8, sw);
		float sheen = (1.0 - smoothstep(0.0, 0.1, abs(x))) + (1.0 - smoothstep(0.0, 0.04, abs(x - 0.2))) * 0.7;
		col = mix(col, vec3(1.0), clamp(sheen, 0.0, 1.0) * 0.6);
		// Twinkling sparkles.
		float sc = texture(cell_tex, w * 1.6 + 0.5).r;
		float tw = 0.5 + 0.5 * sin(TIME * 3.0 + texture(fbm_tex, w * 1.6).r * 40.0);
		col = mix(col, vec3(1.0), smoothstep(0.9, 0.97, sc) * pow(tw, 4.0));
		// Frosty snow rim and an edge line.
		col = mix(col, vec3(0.97, 0.99, 1.0), smoothstep(0.8, 0.9, r));
		col = mix(col, INK, smoothstep(0.95, 1.0, r) * 0.3);
	} else {
		float r = length(q);
		if (r > 1.0) {
			discard;
		}
		col = mix(vec3(0.33, 0.18, 0.1), vec3(0.45, 0.26, 0.15), 0.5 + 0.5 * sin(atan(q.y, q.x) * 3.0 + r * 8.0 - TIME * 0.8));
		col = mix(col, vec3(0.85, 0.65, 0.5), smoothstep(0.9, 1.0, sin(r * 14.0 - TIME * 1.1)) * 0.25);
		col = mix(col, INK, smoothstep(0.9, 0.97, r));
	}
	ALBEDO = out_col(col);
}
