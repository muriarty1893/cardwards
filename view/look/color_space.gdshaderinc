// Colour spaces differ by renderer (measured in Godot 4.7):
//   Forward+ / Mobile: source_color inputs, and any vec4 uniform set from a script Color, arrive
//   linear; ALBEDO and EMISSION are linear.
//   Compatibility (web): all of those arrive as sRGB; ALBEDO and EMISSION are read as sRGB.
// Shaders that do colour maths (mixing, tinting, hard-coded colours, emission) do it in linear:
// wrap those inputs in src_lin() and the values written to ALBEDO / EMISSION in out_col().
// Both are no-ops on Forward+ / Mobile.

vec3 cs_srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 cs_linear_to_srgb(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

vec3 src_lin(vec3 c) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return cs_srgb_to_linear(c);
#else
	return c;
#endif
}

vec3 out_col(vec3 linear_col) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return cs_linear_to_srgb(linear_col);
#else
	return linear_col;
#endif
}
