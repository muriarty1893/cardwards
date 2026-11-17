shader_type spatial;
render_mode cull_disabled, world_vertex_coords;
// Dense lane ground cover drawn with MultiMesh. Colour = the mesh's vertex colours (linear) times
// the instance's custom data rgb (linear); custom data a = how flexible the piece is: flexible
// pieces sway in the wind and bend away from creatures walking through (bend_points, set by
// Board.set_bend_points). Lit with the shared cartoon bands. Per-piece values ride in the
// MultiMesh custom data, which WebGL handles at any count.

#include "res://view/look/toon_light.gdshaderinc"
#include "res://view/look/color_space.gdshaderinc"

// xyz = a creature's position, w = bend radius (0 = unused slot).
uniform vec4 bend_points[8];
uniform float wind = 0.05;
// Largest lean, as a fraction of the piece's height.
uniform float bend_amount = 0.7;

varying vec3 v_col;

void vertex() {
	vec3 base = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float flex = INSTANCE_CUSTOM.a;
	float h = max(VERTEX.y - base.y, 0.0);
	if (flex > 0.0 && h > 0.0) {
		vec2 push = vec2(0.0);
		for (int i = 0; i < 8; i++) {
			vec4 b = bend_points[i];
			if (b.w <= 0.0) {
				continue;
			}
			vec2 d = base.xz - b.xz;
			float dist = length(d);
			float k = 1.0 - smoothstep(b.w * 0.35, b.w, dist);
			push += (d / max(dist, 0.0001)) * k;
		}
		float len = length(push);
		if (len > 1.0) {
			push /= len;
		}
		float sway = sin(TIME * 1.7 + base.x * 1.3 + base.z * 0.8) * wind;
		VERTEX.xz += (push * bend_amount + vec2(sway, sway * 0.5)) * h * flex;
		VERTEX.y -= length(push) * h * flex * 0.25;
	}
	v_col = INSTANCE_CUSTOM.rgb * COLOR.rgb;
}

void fragment() {
	ALBEDO = out_col(v_col);
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * 0.2;
	EMISSION = out_col(v_col * rim);
}
