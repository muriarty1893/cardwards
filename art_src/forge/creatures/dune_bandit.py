"""Dune Bandit (Sunny Dunes, 3): a lean desert raider, a sand-wrapped turban and face veil leaving only
narrowed eyes, a crimson sash, bandoliers of stolen trinkets and a wicked broad scimitar."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="a8704a", wrap="e8d0a0", wrap2="b89868", sash="b8202a", eye="1a1008", dark="1a1410",
              metal="d8dce8", gold="ffcf3a", leather="5a3a22")
    C.attack = "swipe"
    kits.biped(C, "skin", hip=0.86, chest=1.32, neck=1.5, head_top=1.78, shoulder_x=0.26, hip_x=0.13,
               hand=(0.44, -0.12, 0.88), r_hip=0.18, r_waist=0.15, r_chest=0.23, r_neck=0.07, r_head=0.14,
               r_arm=0.065, r_hand=0.055, r_leg=0.085, r_foot=0.08, lean=0.06)
    h = V(C.anch["head"])
    # turban and veil
    C.ellipsoid("Turban", tuple(h + V((0, 0.02, 0.08))), (0.17, 0.17, 0.13), "wrap", "head")
    C.ellipsoid("Turban2", tuple(h + V((0.02, 0.0, 0.14))), (0.14, 0.15, 0.08), "wrap2", "head", rot=(0, 15, 0))
    C.tube("TurbanTail", [h + V((0.1, 0.12, 0.1)), h + V((0.16, 0.26, -0.06)), h + V((0.12, 0.3, -0.3))],
           [0.04, 0.035, 0.02], "wrap", "head")
    C.ellipsoid("Veil", tuple(h + V((0, -0.1, -0.06))), (0.14, 0.08, 0.09), "wrap2", "head")
    C.box("EyeSlit", tuple(h + V((0, -0.135, 0.02))), (0.2, 0.03, 0.04), "skin", "head", bevel=0.4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.155, 0.02))), (0.022, 0.01, 0.012), "eye", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.05 * mx, -0.155, 0.045))), (0.06, 0.015, 0.012), "dark", "head",
              rot=(0, 20 * mx, 0), bevel=0.4)
    c0 = V(C.anch["chest"])
    C.ellipsoid("Vest", tuple(c0 + V((0, 0.02, -0.05))), (0.25, 0.22, 0.3), "wrap2", "chest")
    C.ellipsoid("Hips", (0, 0, 0.84), (0.2, 0.18, 0.14), "wrap2", "hips")
    # sash, bandolier, baggy trousers
    C.lathe("Sash", [(0.17, 0.0), (0.18, 0.12)], "sash", "hips", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0, 0.84)))
    C.box("SashEnd", (0.1, -0.16, 0.72), (0.08, 0.03, 0.24), "sash", "hips", rot=(0, 10, 0), bevel=0.3)
    c = V(C.anch["chest"])
    C.tube("Bandolier", [c + V((-0.2, -0.18, 0.15)), c + V((0, -0.23, -0.02)), c + V((0.2, -0.16, -0.22))], [0.025] * 3,
           "leather", "chest")
    for k in range(4):
        C.ellipsoid(f"Loot{k}", tuple(c + V((-0.15 + 0.1 * k, -0.24, 0.1 - 0.1 * k))), (0.025, 0.015, 0.025),
                    "gold", "chest")
    for side in ("L", "R"):
        sh = C.bones[f"shin.{side}"]
        C.ellipsoid(f"Pant{side}", tuple(C.bones[f"leg.{side}"]["tail"]), (0.12, 0.12, 0.18), "wrap2", f"leg.{side}")
        C.ellipsoid(f"Boot{side}", tuple(sh["head"].lerp(sh["tail"], 0.75)), (0.075, 0.1, 0.12), "leather", f"shin.{side}")
        C.ellipsoid(f"Hand{side}", C.anch["hd" + side], (0.05, 0.05, 0.05), "skin", f"forearm.{side}")
    # broad scimitar
    props.blade(C, C.anch["hdR"], "metal", "gold", "forearm.R", length=0.75, width=0.08, direction=(0, -0.35, -1),
                curve=0.14, guard=0.16)
    props.blade(C, C.anch["hdL"], "metal", "leather", "forearm.L", length=0.25, width=0.03, direction=(0, -0.3, -1),
                guard=0.06)
