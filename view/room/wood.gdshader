shader_type spatial;
render_mode cull_disabled;
// Room surfaces in the cartoon style: mode 0 = wooden planks (floor), 1 = plaster (walls,
// ceiling), 2 = timber (beams, frames, table trim). Flat colours with painted seams and soft
// grain, lit with the shared toon bands so they sit with the KayKit props.

#include "res://view/look/toon_light.gdshaderinc"
#include "res://view/look/color_space.gdshaderinc"

uniform int mode = 0;
uniform vec4 base_color : source_color = vec4(0.78, 0.55, 0.34, 1.0);
uniform vec4 seam_color : source_color = vec4(0.42, 0.26, 0.15, 1.0);
// Planks: width across, length along; in world units.
uniform float plank_width = 3.2;
uniform float plank_length = 22.0;

varying vec3 world_pos;
varying vec3 world_normal;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 base = src_lin(base_color.rgb);
	vec3 seam = src_lin(seam_color.rgb);
	vec3 n = abs(world_normal);
	// Surface coordinates: floor/ceiling use x/z, walls use their horizontal axis and y.
	vec2 uv = n.y > 0.5 ? world_pos.xz : (n.x > n.z ? world_pos.zy : world_pos.xy);
	if (mode == 0) {
		float row = floor(uv.y / plank_width);
		float along = uv.x + hash12(vec2(row, 3.0)) * plank_length;
		float col = floor(along / plank_length);
		float tone = hash12(vec2(row, col)) * 0.16 - 0.08;
		float grain = noise2(vec2(along * 0.35, uv.y * 4.0)) * 0.08;
		base *= 1.0 + tone + grain - 0.04;
		float ey = abs(fract(uv.y / plank_width) - 0.5) * plank_width;
		float ex = abs(fract(along / plank_length) - 0.5) * plank_length;
		float line = max(1.0 - smoothstep(plank_width * 0.5 - 0.12, plank_width * 0.5 - 0.04, ey) , 0.0);
		line = min(line, smoothstep(plank_length * 0.5 - 0.1, plank_length * 0.5 - 0.03, ex) > 0.5 ? 0.0 : 1.0);
		base = mix(seam, base, line);
	} else if (mode == 1) {
		float blotch = noise2(uv * 0.12) * 0.07 + noise2(uv * 0.6) * 0.03;
		base *= 0.97 + blotch;
	} else {
		float grain = noise2(vec2(uv.x * 0.25, uv.y * 3.0)) * 0.12;
		base *= 0.94 + grain;
	}
	ALBEDO = out_col(base);
	ROUGHNESS = 1.0;
}
