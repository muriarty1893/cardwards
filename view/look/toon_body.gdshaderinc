// Body of the cartoon model material; included by toon(_fx)(_cutout).gdshader.
// Define CUTOUT before including for alpha-tested leaves and grass, INSTANCE_FX for hit flash and dissolve.

#include "res://view/look/toon_light.gdshaderinc"
#include "res://view/look/color_space.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
// rgb = tint colour, a = how strongly the tint replaces the original colour.
uniform vec4 tint = vec4(1.0, 1.0, 1.0, 0.0);
uniform float sway = 0.0;
uniform float rim_strength = 0.25;
#ifdef CUTOUT
uniform float alpha_cut = 0.5;
#endif
// Hit flash and dissolve are per-instance only in the fx variants (creatures): WebGL fits
// roughly 256 instances with instance uniforms, far fewer than the scenery uses.
#ifdef INSTANCE_FX
instance uniform float flash = 0.0;
instance uniform float dissolve = 0.0;
// 1 = darkened to 80% (a creature that already acted this turn).
instance uniform float shade = 0.0;
#else
const float flash = 0.0;
const float dissolve = 0.0;
const float shade = 0.0;
#endif

varying vec3 world_pos;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash13(i), hash13(i + vec3(1, 0, 0)), f.x);
	float b = mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x);
	float c = mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x);
	float d = mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	if (sway > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float s = sin(TIME * 1.7 + w.x * 0.8) * sway * max(VERTEX.y, 0.0);
		VERTEX.x += s;
		VERTEX.z += s * 0.5;
	}
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (dissolve > 0.0 && value_noise(world_pos * 6.0) < dissolve) {
		discard;
	}
	vec4 tex = texture(albedo_tex, UV);
#ifdef CUTOUT
	ALPHA = tex.a * albedo_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
#endif
	vec3 base = src_lin(tex.rgb * albedo_color.rgb);
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}
	float luma = dot(base, vec3(0.299, 0.587, 0.114));
	// Recolour toward the tint while keeping the model's light/dark detail readable.
	base = mix(base, clamp(src_lin(tint.rgb) * (0.6 + 0.8 * luma), 0.0, 1.0), tint.a);
	base *= 1.0 - 0.2 * shade;
	base = mix(base, vec3(1.0), flash);
	ALBEDO = out_col(base);
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * rim_strength;
	EMISSION = out_col(base * rim + vec3(flash * 0.6));
}
