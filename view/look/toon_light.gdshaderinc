// Shared cartoon lighting: direct light in three flat bands (0.45 / 0.75 / 1.0) with soft
// 0.03 edges at N.L*shadow = 0.05 and 0.55. No specular. Include from any lit spatial shader.

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float band = 0.45
		+ 0.30 * smoothstep(0.02, 0.08, ndl)
		+ 0.25 * smoothstep(0.52, 0.58, ndl);
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
}
