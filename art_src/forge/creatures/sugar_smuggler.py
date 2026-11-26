"""Sugar Smuggler (Candy Hills, 2): a shifty gremlin in an oversized trench coat lined with contraband
sweets, a low-brimmed hat, glinting eyes, long pointed ears and a grin full of sharp teeth."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="7ab84a", coat="5a3a2a", lining="ff7ab8", hat="2a1e18", band="ffd23a", eye="ffe23a", dark="0a0806",
              tooth="ffffff", c1="ff3a6a", c2="3ad8ff", c3="ffd23a")
    C.attack = "stab"
    kits.biped(C, "coat", hip=0.48, chest=0.78, neck=0.9, head_top=1.12, shoulder_x=0.17, hip_x=0.09,
               hand=(0.3, -0.12, 0.5), r_hip=0.17, r_waist=0.16, r_chest=0.18, r_neck=0.06, r_head=0.13,
               r_arm=0.06, r_hand=0.045, r_leg=0.06, r_foot=0.07, lean=0.15)
    h = V(C.anch["head"])
    props.robe(C, "coat", top_z=0.55, bottom_r=0.28, top_r=0.2, hem=0.03, wave=4)
    C.ellipsoid("Face", tuple(h + V((0, -0.03, -0.02))), (0.14, 0.13, 0.12), "skin", "head")
    for mx in (-1, 1):
        C.cone(f"Ear{mx}", tuple(h + V((0.12 * mx, 0.02, 0.02))), tuple(h + V((0.34 * mx, 0.08, 0.12))), 0.05, "skin", "head",
               segs=6, smooth=True)
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.14, 0.02))), (0.03, 0.012, 0.018), "eye", "head")
    C.box("Grin", tuple(h + V((0, -0.14, -0.06))), (0.12, 0.012, 0.03), "dark", "head", bevel=0.3)
    for k in range(5):
        C.cone(f"Tooth{k}", tuple(h + V((-0.045 + 0.022 * k, -0.15, -0.05))), tuple(h + V((-0.045 + 0.022 * k, -0.15, -0.08))),
               0.008, "tooth", "head", segs=3)
    # low-brimmed hat
    C.lathe("Brim", [(0.001, 0.0), (0.26, 0.0), (0.26, 0.02), (0.001, 0.02)], "hat", "head", segs=20)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(h + V((0, 0.0, 0.07))) @
                                  __import__("mathutils").Matrix.Rotation(0.15, 4, 'X'))
    C.lathe("Crown", [(0.13, 0.0), (0.12, 0.12), (0.001, 0.13)], "hat", "head", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(h + V((0, 0.0, 0.08))))
    C.lathe("Band", [(0.135, 0.0), (0.135, 0.03)], "band", "head", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(h + V((0, 0.0, 0.09))))
    # coat flapped open: lining full of candy
    c = V(C.anch["chest"])
    for mx in (-1, 1):
        C.box(f"Lapel{mx}", tuple(c + V((0.12 * mx, -0.16, -0.25))), (0.12, 0.03, 0.42), "lining", "chest",
              rot=(0, 0, 25 * mx), bevel=0.3)
        for k, m in enumerate(("c1", "c2", "c3")):
            C.ellipsoid(f"Candy{mx}{k}", tuple(c + V((0.14 * mx, -0.19, -0.1 - 0.12 * k))), (0.03, 0.015, 0.025), m, "chest")
    props.blade(C, C.anch["hdR"], "band", "hat", "forearm.R", length=0.18, width=0.025, direction=(0, -0.6, 0.6), guard=0.05)
