shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;
// Depth-only ink outline, for renderers without the normal-roughness buffer (Mobile).
// The quad is placed on the near plane in clip space (Godot 4.3+ reverse-Z); the Compatibility
// renderer (web) has OpenGL depth instead: 0..1 maps to NDC -1..1 and the near plane is z = -1.

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec4 ink : source_color = vec4(0.133, 0.2, 0.2, 1.0);
uniform float depth_threshold = 0.06;

void vertex() {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	POSITION = vec4(VERTEX.xy, -1.0, 1.0);
#else
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
#endif
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_texture, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 view = inv_proj * vec4(vec3(uv, d) * 2.0 - 1.0, 1.0);
#else
	vec4 view = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
#endif
	return -view.z / view.w;
}

void fragment() {
	vec2 px = vec2(max(1.0, VIEWPORT_SIZE.y / 720.0 * 2.0)) / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float d0 = linear_depth(uv, INV_PROJECTION_MATRIX);
	vec2 offs[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	float ddiff = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 o = uv + offs[i];
		ddiff = max(ddiff, abs(linear_depth(o, INV_PROJECTION_MATRIX) - d0));
	}
	float edge = step(depth_threshold * d0, ddiff);
	// Distant grazing ground would read as one thick edge band at the horizon; fade far lines out.
	edge *= 1.0 - smoothstep(110.0, 150.0, d0);
	ALBEDO = ink.rgb;
	ALPHA = edge * ink.a;
}
