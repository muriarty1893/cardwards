shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;
// Full-screen ink outline: dark lines where depth or normals change sharply.
// The quad is placed on the near plane in clip space (Godot 4.3+ reverse-Z).

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_rough : hint_normal_roughness_texture, filter_nearest;
uniform vec4 ink : source_color = vec4(0.133, 0.2, 0.2, 1.0);
uniform bool use_normals = true;
uniform float depth_threshold = 0.06;
uniform float normal_threshold = 0.55;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_texture, uv).r;
	vec4 view = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -view.z / view.w;
}

void fragment() {
	vec2 px = vec2(max(1.0, VIEWPORT_SIZE.y / 720.0 * 2.0)) / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float d0 = linear_depth(uv, INV_PROJECTION_MATRIX);
	vec3 n0 = texture(normal_rough, uv).xyz * 2.0 - 1.0;
	vec2 offs[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	float ddiff = 0.0;
	float ndot = 1.0;
	for (int i = 0; i < 4; i++) {
		vec2 o = uv + offs[i];
		ddiff = max(ddiff, abs(linear_depth(o, INV_PROJECTION_MATRIX) - d0));
		if (use_normals) {
			vec3 n = texture(normal_rough, o).xyz * 2.0 - 1.0;
			ndot = min(ndot, dot(n0, n));
		}
	}
	float edge = step(depth_threshold * d0, ddiff);
	edge = max(edge, 1.0 - step(normal_threshold, ndot));
	// Distant grazing ground would read as one thick edge band at the horizon; fade far lines out.
	edge *= 1.0 - smoothstep(110.0, 150.0, d0);
	ALBEDO = ink.rgb;
	ALPHA = edge * ink.a;
}
