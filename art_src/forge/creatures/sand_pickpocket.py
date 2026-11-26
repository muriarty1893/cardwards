"""Sand Pickpocket (Sunny Dunes, 2): a sly desert gecko thief, a sand-coloured hood and scarf over a
grinning reptile face with big amber eyes, a long curling tail, a stolen coin purse and a quick dagger."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(scale="7ab84a", belly="e8e0a0", hood="d8b878", scarf="c83a2a", eye="ffb02a", pupil="0a0a0a",
              dark="1a1408", metal="d8d8e0", gold="ffcf3a", purse="7a4a2a", spot="4a8a2a")
    C.attack = "stab"
    kits.biped(C, "scale", hip=0.6, chest=0.95, neck=1.08, head_top=1.38, shoulder_x=0.18, hip_x=0.1,
               hand=(0.32, -0.12, 0.6), r_hip=0.14, r_waist=0.12, r_chest=0.16, r_neck=0.06, r_head=0.16,
               r_arm=0.05, r_hand=0.05, r_leg=0.065, r_foot=0.07, lean=0.18, knee_fwd=0.05)
    h = V(C.anch["head"])
    C.ellipsoid("Snout", tuple(h + V((0, -0.14, -0.04))), (0.12, 0.13, 0.08), "scale", "head")
    C.box("Grin", tuple(h + V((0, -0.24, -0.07))), (0.14, 0.02, 0.015), "dark", "head", bevel=0.4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.11 * mx, -0.1, 0.05))), (0.06, 0.05, 0.06), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", tuple(h + V((0.13 * mx, -0.14, 0.05))), (0.01, 0.01, 0.04), "pupil", "head")
        C.box(f"Lid{mx}", tuple(h + V((0.11 * mx, -0.12, 0.1))), (0.1, 0.07, 0.03), "scale", "head", rot=(0, 20 * mx, 0),
              bevel=0.5)
    # hood and scarf
    C.ellipsoid("Hood", tuple(h + V((0, 0.06, 0.06))), (0.18, 0.18, 0.16), "hood", "head")
    C.cone("HoodTip", tuple(h + V((0, 0.14, 0.12))), tuple(h + V((0, 0.36, 0.0))), 0.08, "hood", "head", segs=8, smooth=True)
    n = V(C.anch["neck"])
    C.lathe("Scarf", [(0.09, -0.04), (0.12, 0.0), (0.11, 0.05)], "scarf", "neck", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(n))
    C.box("ScarfEnd", tuple(n + V((0.06, 0.14, -0.12))), (0.07, 0.03, 0.2), "scarf", "chest", rot=(20, 0, 10), bevel=0.3)
    C.decal("Belly", 0, 0.85, (0.11, 0.18, 0.03), "belly", "chest")
    for k, (x, z) in enumerate([(0.1, 0.95), (-0.08, 0.8), (0.0, 1.0)]):
        C.decal(f"Spot{k}", x, z, (0.03, 0.03, 0.015), "spot", "chest", dir=(0, -1, 0))
    # long curling tail
    C.bone("tail1", (0, 0.05, 0.58), (0, 0.35, 0.3), "hips")
    C.bone("tail2", (0, 0.35, 0.3), (0, 0.65, 0.25), "tail1")
    C.bone("tail3", (0, 0.65, 0.25), (0, 0.72, 0.5), "tail2")
    C.tail = ["tail1", "tail2", "tail3"]
    C.tube("Tail", [(0, 0.05, 0.58), (0, 0.35, 0.3), (0, 0.65, 0.25), (0, 0.72, 0.5), (0, 0.62, 0.6)],
           [0.08, 0.06, 0.04, 0.025, 0.01], "scale", None, allowed=["hips", "tail1", "tail2", "tail3"])
    # dagger and stolen purse
    props.blade(C, C.anch["hdR"], "metal", "purse", "forearm.R", length=0.3, width=0.035, direction=(0, -0.6, 0.6),
                guard=0.07)
    hl = V(C.anch["hdL"])
    C.ellipsoid("Purse", tuple(hl + V((0, -0.02, -0.08))), (0.07, 0.06, 0.08), "purse", "forearm.L")
    C.ellipsoid("Coin", tuple(hl + V((0, -0.07, -0.02))), (0.035, 0.01, 0.035), "gold", "forearm.L")
