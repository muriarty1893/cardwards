shader_type spatial;
render_mode cull_back;
// Painted lane: 0 Mushroom Forest, 1 Ember Flats, 2 Candy Hills, 3 Frostpeak, 4 Meadow (bare).
// A land change wipes outward from `morph_origin` (morph 0 → 1) with a bright front; a field
// spell lays its weather over the lane (field_land, faded in by field_amount).
// Wavy outlined edges (outside the wave shows the soil below), a thin side-coloured rim,
// and animated highlight outlines (1 = valid drop, 2 = target, 3 = Guard that must be attacked).
// Lit with the cartoon bands.

#include "res://view/look/toon_light.gdshaderinc"
#include "res://view/look/color_space.gdshaderinc"

uniform int land = 0;
uniform vec2 size = vec2(2.44, 4.5);
uniform vec3 edge_color : source_color = vec3(1.0, 0.88, 0.29);
uniform float highlight = 0.0;
uniform float wave_seed = 0.0;
uniform sampler2D fbm_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D cell_tex : repeat_enable, filter_linear_mipmap;
uniform int prev_land = 4;
uniform float morph = 1.0;
uniform vec2 morph_origin = vec2(0.0);
uniform int field_land = -1;
uniform float field_amount = 0.0;

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

vec3 paint_meadow(vec2 p) {
	vec3 col = vec3(0.604, 0.851, 0.447);                      // #9ad972
	col = mix(col, vec3(0.690, 0.890, 0.494), smoothstep(0.5, 0.7, fbm(p * 0.9 + 3.1)) * 0.7);  // sunny patches
	float strokes = vnoise(vec2(p.x * 3.0, p.y * 14.0));
	col *= 0.95 + 0.07 * strokes;
	vec2 cell = floor(p * 7.0);
	vec2 c = fract(p * 7.0) - 0.5;
	float h = hash(cell);
	float dot_ = step(0.9, h) * (1.0 - smoothstep(0.08, 0.13, length(c)));
	vec3 petal = h > 0.97 ? vec3(1.0, 0.62, 0.78) : (h > 0.94 ? vec3(1.0, 0.9, 0.35) : vec3(1.0));
	return mix(col, petal, dot_);
}

vec3 paint(int l, vec2 p, out vec3 emi) {
	emi = vec3(0.0);
	if (l == 0) {
		return paint_forest(p);
	} else if (l == 1) {
		return paint_ember(p, emi);
	} else if (l == 2) {
		return paint_candy(p);
	} else if (l == 3) {
		return paint_frost(p, emi);
	}
	return paint_meadow(p);
}

// Weather a field spell lays over every lane.
vec3 weather(vec2 p, vec3 col, inout vec3 emi) {
	float k = field_amount;
	if (field_land == 1) {          // Volcano: ash and glowing cinders
		float ash = smoothstep(0.45, 0.75, fbm(p * 2.2 + TIME * 0.02));
		col = mix(col, col * vec3(0.55, 0.5, 0.5), ash * 0.6 * k);
		vec2 cell = floor(p * 8.0);
		float cinder = step(0.95, hash(cell)) * (1.0 - smoothstep(0.03, 0.09, length(fract(p * 8.0) - 0.5)));
		float flick = 0.5 + 0.5 * sin(TIME * 4.0 + hash(cell) * 30.0);
		emi += vec3(1.0, 0.3, 0.05) * cinder * flick * 1.5 * k;
	} else if (field_land == 3) {   // Snowstorm: snow dusting
		float snow = smoothstep(0.38, 0.6, fbm(p * 1.6 + vec2(TIME * 0.05, 0.0)));
		col = mix(col, vec3(0.95, 0.97, 1.0), snow * 0.75 * k);
	} else if (field_land == 0) {   // Spore Bloom: glowing spores
		vec2 cell = floor(p * 6.0);
		float s = step(0.9, hash(cell + 3.0)) * (1.0 - smoothstep(0.04, 0.12, length(fract(p * 6.0) - 0.5)));
		float pulse = 0.5 + 0.5 * sin(TIME * 2.0 + hash(cell) * 20.0);
		col = mix(col, vec3(0.75, 1.0, 0.55), s * k * 0.8);
		emi += vec3(0.5, 1.0, 0.3) * s * pulse * 0.8 * k;
	} else if (field_land == 2) {   // Sugar Rain: extra sprinkles
		vec2 cell = floor(p * 9.0);
		vec2 c = fract(p * 9.0) - 0.5;
		float h = hash(cell + 11.0);
		float spr = step(0.8, h) * step(abs(c.x), 0.18) * step(abs(c.y), 0.05);
		vec3 sc = h > 0.93 ? vec3(1.0, 0.35, 0.45) : (h > 0.87 ? vec3(0.4, 0.85, 1.0) : vec3(1.0, 0.9, 0.3));
		col = mix(col, sc, spr * k);
	}
	return col;
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
	vec3 col = paint(land, p, emi);
	if (morph < 1.0) {
		// Land change: the new land spreads from the origin with a wobbly, glowing front.
		float reach = morph * (length(size) + 0.6);
		float d = length(p - morph_origin) + (fbm(p * 2.5) - 0.5) * 0.5;
		vec3 old_emi;
		vec3 old_col = paint(prev_land, p, old_emi);
		float inside = smoothstep(reach, reach - 0.12, d);
		col = mix(old_col, col, inside);
		emi = mix(old_emi, emi, inside);
		float front = smoothstep(0.25, 0.0, abs(d - reach)) * (1.0 - morph);
		col = mix(col, vec3(1.0, 0.97, 0.8), front * 0.7);
		emi += vec3(1.0, 0.9, 0.6) * front * 0.8;
	}
	if (field_land >= 0 && field_amount > 0.0) {
		col = weather(p, col, emi);
	}
	// Bevel, side rim, ink edge (from inside out).
	col = mix(col, col * 1.18, 1.0 - smoothstep(0.075, 0.1, m));
	col = mix(col, src_lin(edge_color), (1.0 - smoothstep(0.05, 0.07, m)) * 0.6);
	if (highlight > 0.5) {
		bool target = highlight > 1.5;
		bool guard = highlight > 2.5;
		float beat = 0.5 + 0.5 * sin(TIME * 6.283 * 2.0);
		vec3 hc = guard ? mix(vec3(1.0, 0.25, 0.2), vec3(1.0, 0.82, 0.25), beat)
			: (target ? vec3(1.0, 0.353, 0.353) : vec3(1.0, 0.882, 0.290));
		float band = 1.0 - smoothstep(guard ? 0.16 : 0.1, guard ? 0.34 : 0.24, m);
		float anim = guard ? 0.75 + 0.25 * beat
			: (target ? 0.55 + 0.45 * sin(TIME * 6.283 * 3.0) : 0.55 + 0.45 * step(0.5, fract((p.y + p.x) * 1.5 - TIME * 1.2)));
		col = mix(col, hc, band * anim);
		emi += pow(hc, vec3(2.2)) * band * anim * 0.9;
	}
	col = mix(col, INK, 1.0 - smoothstep(0.035, 0.045, m));
	ALBEDO = out_col(pow(col, vec3(2.2)));
	EMISSION = out_col(emi);   // emi is linear
	ROUGHNESS = 1.0;
}
