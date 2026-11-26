"""Dune Bandit (Sunny Dunes, 3): a lean desert raider. Sculpted: a wiry, long-limbed raider in loose
sand-coloured wrappings, a turban wound high with a face veil leaving only narrowed eyes, a crimson sash,
bandoliers of stolen trinkets across the chest, wrapped boots and a wicked broad scimitar."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep


def build(C):
    C.palette(skin="a8704a", wrap="d8c090", wrap2="7a5a3a", sash="b8202a", eye="1a1008", dark="1a1410", metal="d8dce8",
              gold="ffcf3a", leather="5a3a22")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.9, chest=1.36, head=1.6, lean=0.1, shoulder_x=0.24, hip_x=0.12,
                          r_chest=(0.2, 0.15, 0.19), r_waist=(0.14, 0.12, 0.13), r_hips=(0.16, 0.13, 0.12),
                          r_head=(0.11, 0.12, 0.12), r_arm=(0.06, 0.05), r_hand=0.045, r_leg=(0.08, 0.065),
                          r_foot=(0.06, 0.1, 0.045), arm_len=0.6, group="wrap")
    h = at["head"]
    cl.add((0, h.y - 0.1, h.z + 0.03), (0.09, 0.04, 0.025), group="skin")               # eye slit band
    cl.add((0, -0.04, 1.06), (0.17, 0.14, 0.06), group="sash")                        # sash
    cl.mirror((0.12, -0.04, 0.5), (0.1, 0.1, 0.16), group="wrap2")                     # baggy trousers
    body = cl.build({"wrap": "wrap", "wrap2": "wrap2", "sash": "sash", "skin": "skin"}, voxel=0.01, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(0.25, 0.08, p.z), "leather")
    for k in range(4):                                                         # wound turban
        C.ellipsoid(f"Turban{k}", tuple(h + V((0, 0.01, 0.07 + 0.045 * k))), (0.15 - 0.02 * k, 0.15 - 0.02 * k, 0.05),
                    "wrap2", "head", rot=(0, 12 * (k % 2 * 2 - 1), 0))
    C.ellipsoid("Veil", tuple(h + V((0, -0.06, -0.05))), (0.11, 0.08, 0.08), "sash", "head")
    C.ellipsoid("TurbanTail", tuple(h + V((0.1, 0.1, 0.0))), (0.04, 0.04, 0.14), "wrap2", "head", rot=(20, 0, 0))
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.04 * mx, h.y - 0.13, h.z + 0.035), (0.018, 0.008, 0.008), "eye", "head", rot=(0, 15 * mx, 0))
    for k in range(7):                                                         # bandolier with trinkets
        t = k / 6
        p = V((-0.18 + 0.36 * t, -0.17 + 0.03 * abs(t - 0.5), 1.5 - 0.36 * t))
        C.ellipsoid(f"Trinket{k}", tuple(p), (0.025, 0.015, 0.025), "gold" if k % 2 else "metal", "chest")
    props.blade(C, at["hdR"], "metal", "gold", "forearm.R", length=0.6, width=0.12, direction=(0, -0.5, 1), guard=0.14)
