shader_type spatial;
render_mode cull_back;
// Painted lane: 0 Mushroom Forest, 1 Ember Flats, 2 Candy Hills, 3 Frostpeak.
// Wavy outlined edges (outside the wave shows the soil below), a thin side-coloured rim,
// and animated highlight outlines (1 = valid drop, 2 = target). Lit with the cartoon bands.

#include "res://view/look/toon_light.gdshaderinc"
#include "res://view/look/color_space.gdshaderinc"

uniform int land = 0;
uniform vec2 size = vec2(2.44, 4.5);
uniform vec3 edge_color : source_color = vec3(1.0, 0.88, 0.29);
uniform float highlight = 0.0;
uniform float wave_seed = 0.0;
uniform sampler2D fbm_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D cell_tex : repeat_enable, filter_linear_mipmap;

const vec3 INK = vec3(0.133, 0.2, 0.2);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 q) {
	return texture(fbm_tex, q * 0.2 + vec2(0.53, 0.19)).r;
}

float fbm(vec2 q) {
	return texture(fbm_tex, q * 0.2).r;
}

// Distance from the nearest cell border; small values are cracks.
float voronoi_edge(vec2 q) {
	return texture(cell_tex, q * 0.2).r;
}

vec3 paint_forest(vec2 p) {
	vec3 col = vec3(0.475, 0.788, 0.353);                      // #79c95a
	col = mix(col, vec3(0.353, 0.659, 0.290), smoothstep(0.55, 0.62, fbm(p * 1.4)));  // moss #5aa84a
	float strokes = vnoise(vec2(p.x * 18.0, p.y * 3.0));
	col *= 0.94 + 0.08 * strokes;
	vec2 cell = floor(p * 6.0);
	vec2 c = fract(p * 6.0) - 0.5;
	float clover = step(0.86, hash(cell)) * (1.0 - smoothstep(0.16, 0.22, length(c)));
	return mix(col, vec3(0.651, 0.878, 0.478), clover);       // clover #a6e07a
}

vec3 paint_ember(vec2 p, out vec3 emi) {
	vec3 col = mix(vec3(0.290, 0.188, 0.188), vec3(0.380, 0.250, 0.230), fbm(p * 3.0));  // #4a3030
	float e = voronoi_edge(p * 1.5);
	float crack = 1.0 - smoothstep(0.04, 0.12, e);
	float pulse = 0.6 + 0.4 * sin(TIME * 2.4 + p.y * 2.0);
	col = mix(col, vec3(1.0, 0.478, 0.102), crack);           // #ff7a1a
	emi = pow(vec3(1.0, 0.478, 0.102), vec3(2.2)) * crack * 2.0 * pulse;
	return col;
}

vec3 paint_candy(vec2 p) {
	vec3 col = vec3(1.0, 0.616, 0.800);                        // frosting #ff9dcc
	float swirl = sin(p.x * 3.0 + sin(p.y * 2.2) * 1.8 + fbm(p * 1.5) * 3.0);
	col = mix(col, vec3(0.960, 0.478, 0.706), smoothstep(0.55, 0.75, swirl) * 0.7);  // swirl #f57ab4
	vec2 cell = floor(p * 5.0);
	vec2 c = fract(p * 5.0) - 0.5;
	float h = hash(cell);
	float a = h * 6.283;
	vec2 r = vec2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a));
	float spr = step(0.55, h) * step(abs(r.x), 0.2) * step(abs(r.y), 0.055);
	int k = int(floor(hash(cell + 7.0) * 5.0));
	vec3 sc = k == 0 ? vec3(1.0, 0.353, 0.353) : k == 1 ? vec3(1.0, 0.847, 0.290) : k == 2 ? vec3(0.353, 0.820, 1.0) : k == 3 ? vec3(0.478, 1.0, 0.478) : vec3(1.0);
	return mix(col, sc, spr);
}

vec3 paint_frost(vec2 p, out vec3 emi) {
	float drift = fbm(p * 1.2);
	vec3 col = mix(vec3(0.902, 0.949, 1.0), vec3(0.663, 0.804, 0.937), smoothstep(0.42, 0.62, drift));  // #e6f2ff / #a9cdef
	col = mix(col, vec3(0.537, 0.702, 0.882), smoothstep(0.66, 0.74, drift) * 0.6);  // deeper drifts
	vec2 cell = floor(p * 9.0);
	vec2 c = fract(p * 9.0) - 0.5;
	float twinkle = 0.5 + 0.5 * sin(TIME * 3.0 + hash(cell) * 40.0);
	float sparkle = step(0.93, hash(cell)) * (1.0 - smoothstep(0.03, 0.09, length(c))) * twinkle;
	emi = vec3(sparkle) * 0.6;
	return mix(col, vec3(1.0), sparkle);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;          // lane-local x (across), y = z (along)
	float edge_x = size.x * 0.5 - 0.08 + 0.05 * sin(p.y * 2.6 + wave_seed) + 0.015 * sin(p.y * 7.0 + wave_seed * 2.0);
	float edge_z = size.y * 0.5 - 0.06 + 0.03 * sin(p.x * 4.0 + wave_seed);
	float m = min(edge_x - abs(p.x), edge_z - abs(p.y));
	if (m < 0.0) {
		discard;
	}
	vec3 emi = vec3(0.0);
	vec3 col;
	if (land == 0) {
		col = paint_forest(p);
	} else if (land == 1) {
		col = paint_ember(p, emi);
	} else if (land == 2) {
		col = paint_candy(p);
	} else {
		col = paint_frost(p, emi);
	}
	// Bevel, side rim, ink edge (from inside out).
	col = mix(col, col * 1.18, 1.0 - smoothstep(0.075, 0.1, m));
	col = mix(col, src_lin(edge_color), (1.0 - smoothstep(0.05, 0.07, m)) * 0.6);
	if (highlight > 0.5) {
		bool target = highlight > 1.5;
		vec3 hc = target ? vec3(1.0, 0.353, 0.353) : vec3(1.0, 0.882, 0.290);
		float band = 1.0 - smoothstep(0.1, 0.24, m);
		float anim = target ? 0.55 + 0.45 * sin(TIME * 6.283 * 3.0) : 0.55 + 0.45 * step(0.5, fract((p.y + p.x) * 1.5 - TIME * 1.2));
		col = mix(col, hc, band * anim);
		emi += pow(hc, vec3(2.2)) * band * anim * 0.9;
	}
	col = mix(col, INK, 1.0 - smoothstep(0.035, 0.045, m));
	ALBEDO = out_col(pow(col, vec3(2.2)));
	EMISSION = out_col(emi);   // emi is linear
	ROUGHNESS = 1.0;
}
