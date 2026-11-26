"""Molten Titan (Ember Flats, 10): a colossus of cooled basalt slabs over a river of magma. Sculpted: a
towering, top-heavy giant with a mountain of shoulders, a furnace heart blazing in its open chest, a
small hunched head with a molten visor slit, slab armour plates stacked over glowing seams, and fists
like boulders."""
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep, cracks, crease


def build(C):
    C.palette(magma="ff5a14", hot="ffc23a", core="fff0a0", rock="2e2826", rock2="4a3f3a", ash="6a605a")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.92, chest=1.62, head=1.92, lean=0.16, shoulder_x=0.56, hip_x=0.24,
                          r_chest=(0.48, 0.34, 0.38), r_waist=(0.3, 0.24, 0.24), r_hips=(0.32, 0.24, 0.2),
                          r_head=(0.14, 0.15, 0.13), r_arm=(0.19, 0.17), r_hand=0.2, r_leg=(0.2, 0.17),
                          r_foot=(0.17, 0.2, 0.09), arm_len=1.0, hand_fwd=0.1, group="rock")
    h = at["head"]
    for sx in (-1, 1):
        cl.add((0.36 * sx, 0.0, 1.86), (0.3, 0.26, 0.2), rot=(0, -25 * sx, 0), group="rock2")   # shoulder slabs
        cl.add((0.6 * sx, -0.04, 1.62), (0.22, 0.22, 0.18), group="rock2")
        cl.add((0.66 * sx, -0.14, 0.82), (0.22, 0.24, 0.24), group="rock2")                     # forearm slabs
        cl.add((0.24 * sx, -0.06, 0.4), (0.21, 0.2, 0.16), group="rock2")                       # knee slabs
    cl.add((0, -0.36, 1.48), (0.2, 0.12, 0.2), group="core", neg=True)                           # open chest
    cl.add((0, -0.24, 1.48), (0.16, 0.1, 0.16), group="core")                                    # furnace heart
    cl.add((0, h.y - 0.1, h.z + 0.02), (0.12, 0.04, 0.025), group="core", neg=True)              # visor slit
    cl.add((0, h.y - 0.02, h.z + 0.1), (0.15, 0.13, 0.08), group="rock2")                        # helm brow
    body = cl.build({"rock": "rock", "rock2": "rock2", "core": "core"}, voxel=0.02, budget=12000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.08, "strength": 0.025})
    recolor(body, lambda p, n: 0.9 * cracks(p, 0.3, 0.05, seed=29), "magma")
    crease(body, "magma", 0.62, 0.86)
    recolor(body, lambda p, n: smoothstep(0.34, 0.08, (p - V((0, -0.3, 1.48))).length), "hot")
    recolor(body, lambda p, n: smoothstep(0.035, 0.0, abs(p.z - h.z - 0.02)) * (1.0 if p.y < h.y - 0.05 else 0.0), "hot")
    recolor(body, lambda p, n: smoothstep(0.7, 1.0, n.z) * 0.4, "ash")
