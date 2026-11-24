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
// The lane's left/right border curves (BoardLayout, world x): x(z) = c1.x + c1.y*sin(z*c1.z + c1.w) + c2.x*sin(z*c2.y + c2.z).
uniform vec4 left_c1 = vec4(-1.35, 0.0, 0.0, 0.0);
uniform vec4 left_c2 = vec4(0.0);
uniform vec4 right_c1 = vec4(1.35, 0.0, 0.0, 0.0);
uniform vec4 right_c2 = vec4(0.0);
// World x/z of the tile centre.
uniform vec2 tile_origin = vec2(0.0);
// The land's look (LaneDressing variant), its set-piece corner side (-1 left, 1 right) and tile-local zones
// (x0, z0, x1, z1): the back-corner box and the side band beside it, for painted features.
uniform int variant = 0;
uniform float corner_side = -1.0;
uniform vec4 corner_box = vec4(0.0);
uniform vec4 side_band = vec4(0.0);
// The old land's look while a land change sweeps the tile (so the unswept part keeps its own look).
uniform int prev_variant = 0;
uniform vec4 prev_corner_box = vec4(0.0);
uniform vec4 prev_side_band = vec4(0.0);
// Outer sides (against the tray frame) keep the painted rim and ink edge; inner sides meet the next lane.
uniform float outer_left = 0.0;
uniform float outer_right = 0.0;

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

vec3 paint_ember(vec2 p, float crack_k, out vec3 emi) {
	vec3 col = mix(vec3(0.290, 0.188, 0.188), vec3(0.380, 0.250, 0.230), fbm(p * 3.0));  // #4a3030
	float e = voronoi_edge(p * 1.5);
	float crack = (1.0 - smoothstep(0.04, 0.12, e)) * crack_k;
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

vec3 paint_dunes(vec2 p) {
	float f = fbm(p * 0.8 + 1.7);
	vec3 col = mix(vec3(0.941, 0.812, 0.525), vec3(0.969, 0.871, 0.651), smoothstep(0.4, 0.7, f));  // #f0cf86 / #f7dea6
	col = mix(col, vec3(0.851, 0.706, 0.416), smoothstep(0.62, 0.78, fbm(p * 1.6 + 5.0)) * 0.55);   // darker drifts #d9b46a
	// Wind ripples: soft wavy bands across the lane.
	float rip = sin(p.y * 11.0 + p.x * 2.0 + fbm(p * 2.0) * 5.0);
	col *= 0.95 + 0.05 * smoothstep(-0.2, 0.9, rip);
	col = mix(col, col * 0.86, smoothstep(0.82, 0.98, rip) * 0.6);
	// Pebbles.
	vec2 cell = floor(p * 8.0);
	vec2 c = fract(p * 8.0) - 0.5;
	float pb = step(0.93, hash(cell)) * (1.0 - smoothstep(0.06, 0.1, length(c)));
	return mix(col, vec3(0.86, 0.82, 0.74), pb);
}

// How strong the Ember base cracks are for a look: full around the volcano, faint under the rift and the ash.
float ember_cracks(int v) {
	return v == 0 ? 0.8 : (v == 1 ? 0.4 : 0.25);
}

vec3 paint(int l, int v, vec2 p, out vec3 emi) {
	emi = vec3(0.0);
	if (l == 0) {
		return paint_forest(p);
	} else if (l == 1) {
		return paint_ember(p, ember_cracks(v), emi);
	} else if (l == 2) {
		return paint_candy(p);
	} else if (l == 3) {
		return paint_frost(p, emi);
	} else if (l == 5) {
		return paint_dunes(p);
	}
	return paint_meadow(p);
}

// Flat features of land l's look v, painted in tile-local p (side_d = distance to the nearest side edge); `box` and
// `band` are that look's corner box and side band.
vec3 features(int l, int v, vec2 p, vec2 pw, float side_d, vec3 col, inout vec3 emi, vec4 box, vec4 band) {
	vec2 bc = (box.xy + box.zw) * 0.5;
	vec2 bs = max(box.zw - box.xy, vec2(0.05));
	if (l == 0) {
		if (v == 0) {          // Pond Glade: a darker damp shore around the pond
			float d = length((p - bc) / (bs * vec2(0.62, 0.55)));
			col = mix(col, col * vec3(0.72, 0.85, 0.7), (1.0 - smoothstep(0.75, 1.15, d)) * 0.7);
		} else if (v == 1) {   // Giant Shroom Grove: dappled shade
			float shade = smoothstep(0.45, 0.7, fbm(pw * 1.7 + 4.0));
			col = mix(col, col * 0.78, shade * 0.6);
		} else {               // Mossy Knoll: clover patches and a stepping-stone path from the knoll to the seam
			float clover = smoothstep(0.58, 0.66, fbm(pw * 2.3 + 7.0));
			col = mix(col, vec3(0.62, 0.86, 0.45), clover * 0.6);
			float cell = 0.42;
			float zc = (floor(p.y / cell) + 0.5) * cell;
			float px = bc.x * 0.6 + 0.22 * sin(zc * 1.7 + 0.7);
			vec2 sd = (p - vec2(px, zc)) / vec2(0.11, 0.08);
			float stone = 1.0 - smoothstep(0.85, 1.0, length(sd));
			float edge = smoothstep(0.7, 0.85, length(sd)) * stone;
			col = mix(col, vec3(0.78, 0.74, 0.66), stone);
			col = mix(col, INK, edge * 0.7);
		}
	} else if (l == 2) {
		if (v == 0) {          // Chocolate River: a glossy stream flowing along the side band
			// Wider than the band (paint may run under the roam zone): it hugs the side and bends inward a little.
			float inward = sign(-(band.x + band.z));
			float cx = (band.x + band.z) * 0.5 + inward * (0.08 + 0.05 * sin(p.y * 2.2 + 0.5));
			float half_w = 0.19;
			float z0 = band.y;
			float z1 = band.w;
			float taper = smoothstep(z0 - 0.05, z0 + 0.15, p.y) * smoothstep(z1 + 0.05, z1 - 0.15, p.y);
			float dist = abs(p.x - cx);
			float body = (1.0 - smoothstep(half_w - 0.01, half_w + 0.01, dist)) * taper;
			float across = dist / half_w;          // 0 mid-stream, 1 at the bank
			// Flow: noise stretched along the stream and carried downstream, faster in the middle.
			float speed = 0.35 * (1.0 - across * across * 0.6);
			vec2 fp = vec2((p.x - cx) * 2.6, p.y * 0.9 - TIME * speed);
			float swirl = fbm(fp) + 0.5 * fbm(fp * 2.1 + vec2(3.1, -TIME * 0.4));
			vec3 dark = vec3(0.3, 0.15, 0.07);
			vec3 milk = vec3(0.58, 0.34, 0.18);
			vec3 choc = mix(dark, milk, smoothstep(0.55, 1.05, swirl));
			// Caramel ribbons drifting along.
			float ribbon = smoothstep(0.9, 0.98, swirl) * (1.0 - smoothstep(0.98, 1.12, swirl));
			choc = mix(choc, vec3(0.86, 0.6, 0.32), ribbon * 0.6);
			// Glossy highlight streaks sliding downstream.
			float streak = smoothstep(0.86, 0.97, sin(p.y * 7.0 - TIME * 1.6 + swirl * 3.0));
			choc = mix(choc, vec3(0.98, 0.88, 0.76), streak * 0.45 * (1.0 - smoothstep(0.2, 0.7, across)));
			// Darker, thicker chocolate at the banks with a creamy lip.
			choc = mix(choc, dark * 0.85, smoothstep(0.65, 0.95, across) * 0.5);
			col = mix(col, choc, body);
			float lip = (1.0 - smoothstep(0.0, 0.03, abs(dist - half_w - 0.015))) * taper;
			col = mix(col, vec3(0.98, 0.9, 0.8), lip * 0.75);
			col = mix(col, INK, (1.0 - smoothstep(0.004, 0.012, abs(dist - half_w))) * taper * 0.7);
		} else if (v == 1) {   // Lollipop Grove: soft pink frosting swirls
			float swirl = smoothstep(0.6, 0.7, fbm(pw * 1.4 + 2.0));
			col = mix(col, vec3(1.0, 0.82, 0.9), swirl * 0.55);
		} else {               // Sundae Peak: melted cream puddles around the sundae
			float d = length((p - bc) / (bs * vec2(0.85, 0.6)));
			float cream = (1.0 - smoothstep(0.75, 0.95, d + (fbm(pw * 4.0) - 0.5) * 0.3));
			col = mix(col, vec3(1.0, 0.96, 0.9), cream * 0.85);
		}
	} else if (l == 3) {
		if (v == 1) {          // Frozen Lake: a frosty halo around the ice
			float d = length((p - bc) / (bs * vec2(0.7, 0.6)));
			col = mix(col, vec3(0.86, 0.94, 1.0), (1.0 - smoothstep(0.8, 1.3, d)) * 0.6);
		} else if (v == 2) {   // Glacier Ridge: blue ice streaks near the sides
			float streak = (1.0 - smoothstep(0.1, 0.5, side_d)) * smoothstep(0.4, 0.7, fbm(vec2(pw.x * 6.0, pw.y * 1.2)));
			col = mix(col, vec3(0.6, 0.8, 0.95), streak * 0.6);
		} else {               // Castle Corner: packed snow by the castle
			float d = length((p - bc) / (bs * vec2(0.9, 0.7)));
			col = mix(col, vec3(0.97, 0.99, 1.0), (1.0 - smoothstep(0.7, 1.2, d)) * 0.5);
		}
	} else if (l == 5) {
		if (v == 0) {          // Dune Sea: a soft shadow at the foot of the big dune
			float d = length((p - bc) / (bs * vec2(0.9, 0.7)));
			col = mix(col, col * vec3(0.86, 0.8, 0.72), (1.0 - smoothstep(0.7, 1.2, d)) * 0.6);
		} else if (v == 1) {   // Sandstone Ruins: old paving stones around the pillars
			float d = length((p - bc) / (bs * vec2(1.0, 0.8)));
			vec2 tile = fract(pw * 3.2);
			float grout = (1.0 - smoothstep(0.03, 0.07, min(min(tile.x, 1.0 - tile.x), min(tile.y, 1.0 - tile.y))));
			float paved = (1.0 - smoothstep(0.75, 1.1, d + (fbm(pw * 3.0) - 0.5) * 0.4));
			col = mix(col, vec3(0.88, 0.74, 0.52), paved * 0.7);
			col = mix(col, vec3(0.62, 0.48, 0.32), grout * paved * 0.6);
		} else {               // Oasis: damp dark sand and a ring of grass round the water
			float d = length((p - bc) / (bs * vec2(0.62, 0.55)));
			col = mix(col, vec3(0.62, 0.52, 0.34), (1.0 - smoothstep(0.85, 1.05, d)) * 0.7);
			float grass = smoothstep(0.95, 1.05, d) * (1.0 - smoothstep(1.15, 1.45, d + (fbm(pw * 3.0) - 0.5) * 0.3));
			col = mix(col, vec3(0.45, 0.72, 0.32), grass * 0.85);
		}
	} else if (l == 1) {
		if (v == 0) {          // Volcano: scorched ground with glowing cracks around its foot
			float d = length((p - bc) / (bs * vec2(1.1, 0.75)));
			float scorch = 1.0 - smoothstep(0.55, 1.25, d);
			col = mix(col, col * vec3(0.55, 0.45, 0.42), scorch * 0.8);
			float crack = 1.0 - smoothstep(0.03, 0.08, voronoi_edge(pw * 2.6));
			float pulse = 0.6 + 0.4 * sin(TIME * 2.0 + pw.y * 3.0);
			col = mix(col, vec3(1.0, 0.45, 0.1), crack * scorch);
			emi += vec3(1.0, 0.3, 0.05) * crack * scorch * 1.6 * pulse;
		} else if (v == 1) {   // Lava Rift: a glowing crack along the side band
			float cx = (band.x + band.z) * 0.5 + 0.03 * sin(p.y * 5.0 + 1.3) + 0.015 * sin(p.y * 13.0);
			float z0 = band.y;
			float z1 = band.w;
			float taper = smoothstep(z0, z0 + 0.3, p.y) * smoothstep(z1, z1 - 0.3, p.y);
			float dist = abs(p.x - cx);
			float core = (1.0 - smoothstep(0.012, 0.03, dist)) * taper;
			float crust = (1.0 - smoothstep(0.04, 0.09, dist)) * taper;
			float pulse = 0.65 + 0.35 * sin(TIME * 2.6 + p.y * 4.0);
			col = mix(col, vec3(0.16, 0.1, 0.1), crust * 0.85);
			col = mix(col, vec3(1.0, 0.55, 0.12), core);
			emi += vec3(1.0, 0.35, 0.06) * core * 2.4 * pulse + vec3(0.6, 0.15, 0.02) * crust * 0.4 * pulse;
		} else {               // Ash Slopes: grey ash dusting near the sides
			float ash = (1.0 - smoothstep(0.08, 0.55, side_d)) * smoothstep(0.35, 0.65, fbm(pw * 3.0));
			col = mix(col, vec3(0.5, 0.47, 0.46), ash * 0.7);
		}
	}
	return col;
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
	} else if (field_land == 5) {   // Heatwave: baked warm ground with shimmering hot spots
		float heat = smoothstep(0.4, 0.75, fbm(p * 1.4 + vec2(0.0, TIME * 0.06)));
		col = mix(col, col * vec3(1.12, 0.95, 0.75), 0.45 * k);
		float shimmer = 0.5 + 0.5 * sin(TIME * 3.0 + p.y * 6.0 + p.x * 2.0);
		emi += vec3(1.0, 0.55, 0.15) * heat * shimmer * 0.18 * k;
	}
	return col;
}

float curve_x(vec4 c1, vec4 c2, float z) {
	return c1.x + c1.y * sin(z * c1.z + c1.w) + c2.x * sin(z * c2.y + c2.z);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;          // lane-local x (across), y = z (along)
	float wz = tile_origin.y + p.y;
	float dl = p.x - (curve_x(left_c1, left_c2, wz) - tile_origin.x);
	float dr = (curve_x(right_c1, right_c2, wz) - tile_origin.x) - p.x;
	float edge_z = size.y * 0.5 - 0.06 + 0.03 * sin(p.x * 4.0 + wave_seed);
	float dz = edge_z - abs(p.y);
	if (min(min(dl, dr), dz) < 0.0) {
		discard;
	}
	// Distance to every edge (highlights) and to the edges that get a rim and ink (outer sides and ends).
	float m = min(min(dl, dr), dz);
	float m_ink = min(dz, min(mix(9.0, dl, outer_left), mix(9.0, dr, outer_right)));
	vec3 emi = vec3(0.0);
	// Paint in world space so neighbouring tiles of one land continue into each other.
	vec2 pw = tile_origin + p;
	vec3 col = paint(land, variant, pw, emi);
	col = features(land, variant, p, pw, min(dl, dr), col, emi, corner_box, side_band);
	if (morph < 1.0) {
		// Land change: the new land spreads from the origin with a wobbly, glowing front; outside it the old land
		// keeps its own look until the front passes.
		float reach = morph * (length(size) + 0.6);
		float d = length(p - morph_origin) + (fbm(p * 2.5) - 0.5) * 0.5;
		vec3 old_emi;
		vec3 old_col = paint(prev_land, prev_variant, pw, old_emi);
		old_col = features(prev_land, prev_variant, p, pw, min(dl, dr), old_col, old_emi, prev_corner_box, prev_side_band);
		float inside = smoothstep(reach, reach - 0.12, d);
		col = mix(old_col, col, inside);
		emi = mix(old_emi, emi, inside);
		float front = smoothstep(0.25, 0.0, abs(d - reach)) * (1.0 - morph);
		col = mix(col, vec3(1.0, 0.97, 0.8), front * 0.7);
		emi += vec3(1.0, 0.9, 0.6) * front * 0.8;
	}
	if (field_land >= 0 && field_amount > 0.0) {
		col = weather(pw, col, emi);
	}
	// Bevel, side rim, ink edge (from inside out) on the outer sides and ends.
	col = mix(col, col * 1.18, 1.0 - smoothstep(0.075, 0.1, m_ink));
	col = mix(col, src_lin(edge_color), (1.0 - smoothstep(0.05, 0.07, m_ink)) * 0.6);
	if (highlight > 3.5) {
		// Merge: a wide band swirling between gold and candy pink around the tile.
		float band = 1.0 - smoothstep(0.14, 0.36, m);
		float swirl = 0.5 + 0.5 * sin((p.x - p.y) * 5.0 - TIME * 5.0);
		vec3 hc = mix(vec3(1.0, 0.86, 0.3), vec3(1.0, 0.45, 0.8), swirl);
		col = mix(col, hc, band * 0.85);
		emi += pow(hc, vec3(2.2)) * band * 1.1;
	} else if (highlight > 0.5) {
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
	col = mix(col, INK, 1.0 - smoothstep(0.035, 0.045, m_ink));
	ALBEDO = out_col(pow(col, vec3(2.2)));
	EMISSION = out_col(emi);   // emi is linear
	ROUGHNESS = 1.0;
}
