shader_type spatial;
render_mode cull_disabled;
// Cartoon material for every model: banded light, soft rim, optional land tint,
// optional wind sway for plants. Pieces that hit-flash or dissolve use toon_fx.gdshader.
// Double-sided like the imported glTF materials it replaces.

#include "res://view/look/toon_body.gdshaderinc"
