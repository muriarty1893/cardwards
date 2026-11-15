shader_type spatial;
render_mode cull_disabled;
// Cartoon material for every model: banded light, soft rim, optional land tint,
// per-instance hit flash and dissolve, optional wind sway for plants.
// Double-sided like the imported glTF materials it replaces.

#include "res://view/look/toon_body.gdshaderinc"
