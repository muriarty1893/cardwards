shader_type spatial;
// Procedural land strip: 0 mushroom meadow, 1 ember rock, 2 candy, 3 frost. Glowing border + highlight.
uniform int land = 0;
uniform vec2 size = vec2(2.3, 4.5);
uniform vec3 edge_color : source_color = vec3(1.0, 0.85, 0.3);
uniform float highlight = 0.0; // 0 off, 1 valid drop, 2 target

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 hash2(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
vec2 voronoi(vec2 p) {
	vec2 n = floor(p); vec2 f = fract(p); float d1 = 8.0; float d2 = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			float d = length(g + hash2(n + g) - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return vec2(d1, d2 - d1);
}

void fragment() {
	vec2 p = UV * size;
	vec3 col; vec3 emi = vec3(0.0); float rough = 0.85;
	if (land == 0) {
		float n = vnoise(p * 1.6) * 0.5 + vnoise(vec2(p.x * 26.0, p.y * 5.0)) * 0.5;
		col = mix(vec3(0.24, 0.60, 0.22), vec3(0.45, 0.80, 0.30), n);
		col *= 0.93 + 0.07 * step(0.5, fract(p.y * 0.9));
		vec2 c = fract(p * 7.0) - 0.5;
		float dots = step(0.93, hash(floor(p * 7.0))) * step(length(c), 0.26);
		col = mix(col, vec3(0.99, 0.95, 0.72), dots);
	} else if (land == 1) {
		vec2 v = voronoi(p * 1.6);
		float crack = 1.0 - smoothstep(0.0, 0.09, v.y);
		col = mix(vec3(0.25, 0.16, 0.17), vec3(0.42, 0.26, 0.22), vnoise(p * 4.0));
		col = mix(col, vec3(1.0, 0.45, 0.1), crack);
		emi = vec3(1.0, 0.25, 0.02) * crack * (0.7 + 0.3 * sin(TIME * 2.0 + p.y * 3.0));
	} else if (land == 2) {
		float s = fract((p.x + p.y) * 0.9);
		float stripe = smoothstep(0.45, 0.5, s) - smoothstep(0.95, 1.0, s);
		col = mix(vec3(1.0, 0.66, 0.84), vec3(1.0, 0.86, 0.93), stripe);
		vec2 cell = floor(p * 5.0); vec2 c = fract(p * 5.0) - 0.5;
		float h = hash(cell); float a = h * 6.283;
		vec2 r = vec2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a));
		float spr = step(0.6, h) * step(abs(r.x), 0.22) * step(abs(r.y), 0.06);
		col = mix(col, 0.5 + 0.5 * cos(6.283 * (h * 7.0 + vec3(0.0, 0.33, 0.67))), spr);
		rough = 0.5;
	} else {
		vec2 v = voronoi(p * 1.3);
		float edge = 1.0 - smoothstep(0.0, 0.06, v.y);
		col = mix(vec3(0.58, 0.80, 0.96), vec3(0.84, 0.94, 1.0), vnoise(p * 3.0));
		col = mix(col, vec3(1.0), edge * 0.9);
		rough = 0.25;
	}
	col = pow(col, vec3(2.2)); // authored in sRGB
	vec2 d = min(p, size - p);
	float m = min(d.x, d.y);
	float border = 1.0 - smoothstep(0.05, 0.09, m);
	col = mix(col, edge_color, border);
	emi += edge_color * border * 0.35;
	if (highlight > 0.5) {
		vec3 hc = highlight > 1.5 ? vec3(1.0, 0.8, 0.2) : vec3(1.0);
		float pulse = 0.5 + 0.5 * sin(TIME * 6.0);
		float inner = 1.0 - smoothstep(0.05, 0.45, m);
		col = mix(col, hc, (0.15 + inner * 0.6) * (0.5 + 0.5 * pulse));
		emi += hc * inner * pulse * 0.8;
	}
	ALBEDO = col; EMISSION = emi; ROUGHNESS = rough;
}
