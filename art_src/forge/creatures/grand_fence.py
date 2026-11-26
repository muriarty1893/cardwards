"""Grand Fence (Sunny Dunes, 4): a heavyset dealer in stolen goods, a tall jewelled turban, a rich
striped robe, gold chains and rings, a ledger of debts in one hand and a fat sack of loot over the shoulder;
a sly smile under a curled moustache."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="b07850", robe="5a2a8a", stripe="ffcf3a", turban="2a8a7a", gem="ff2a4a", gold="ffd23a",
              eye="1a1008", dark="1a0e08", sack="b8905a", rope="6a4a2a", book="6a1a1a", page="f0e8d0")
    C.attack = "swipe"
    kits.biped(C, "robe", hip=0.82, chest=1.25, neck=1.42, head_top=1.68, shoulder_x=0.34, hip_x=0.16,
               hand=(0.48, -0.16, 0.85), r_hip=0.32, r_waist=0.36, r_chest=0.36, r_neck=0.1, r_head=0.15,
               r_arm=0.09, r_hand=0.07, r_leg=0.11, r_foot=0.1, lean=0.04)
    h = V(C.anch["head"])
    props.robe(C, "robe", top_z=0.88, bottom_r=0.46, top_r=0.34, hem=0.03, wave=5)
    for k in range(5):
        C.lathe(f"Stripe{k}", [(0.47 - 0.025 * k, 0.12 + 0.15 * k), (0.47 - 0.025 * k, 0.15 + 0.15 * k)], "stripe", None,
                segs=24, allowed=["hips", "leg.L", "leg.R", "shin.L", "shin.R"])
    C.ellipsoid("Face", tuple(h + V((0, -0.04, -0.02))), (0.15, 0.14, 0.15), "skin", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.055 * mx, -0.165, 0.02))), (0.025, 0.01, 0.012), "eye", "head")
        C.box(f"Lid{mx}", tuple(h + V((0.055 * mx, -0.165, 0.035))), (0.05, 0.015, 0.012), "skin", "head", bevel=0.4)
        C.tube(f"Mustache{mx}", [h + V((0, -0.17, -0.05)), h + V((0.08 * mx, -0.17, -0.06)), h + V((0.13 * mx, -0.14, 0.0))],
               [0.02, 0.016, 0.004], "dark", "head")
    C.box("Smile", tuple(h + V((0.01, -0.165, -0.09))), (0.06, 0.01, 0.01), "dark", "head", rot=(0, -8, 0), bevel=0.4)
    # tall jewelled turban
    C.ellipsoid("Turban", tuple(h + V((0, 0.0, 0.14))), (0.19, 0.19, 0.16), "turban", "head")
    C.ellipsoid("TurbanTop", tuple(h + V((0, 0.0, 0.28))), (0.13, 0.13, 0.12), "turban", "head")
    C.ellipsoid("TurbanGem", tuple(h + V((0, -0.18, 0.16))), (0.04, 0.02, 0.05), "gem", "head")
    C.tube("Plume", [h + V((0, -0.15, 0.2)), h + V((0.04, -0.12, 0.42)), h + V((0.1, -0.02, 0.55))], [0.02, 0.025, 0.005],
           "stripe", "head")
    # gold chains and rings
    c = V(C.anch["chest"])
    for k in range(2):
        C.lathe(f"Chain{k}", [(0.24 + 0.04 * k, 0.0), (0.25 + 0.04 * k, 0.025)], "gold", "chest", segs=20)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(c + V((0, -0.06, 0.12 - 0.12 * k))) @
                                      __import__("mathutils").Matrix.Rotation(-0.5, 4, 'X'))
    C.ellipsoid("Medallion", tuple(c + V((0, -0.36, -0.02))), (0.06, 0.02, 0.06), "gold", "chest")
    for side in ("L", "R"):
        hd = V(C.anch["hd" + side])
        C.ellipsoid(f"Hand{side}", tuple(hd), (0.065, 0.065, 0.065), "skin", f"forearm.{side}")
        C.ellipsoid(f"Ring{side}", tuple(hd + V((0, -0.05, 0.02))), (0.03, 0.02, 0.03), "gem", f"forearm.{side}")
    # ledger in the left hand, loot sack over the right shoulder
    hl = V(C.anch["hdL"])
    C.box("Ledger", tuple(hl + V((0, -0.1, 0.06))), (0.2, 0.06, 0.26), "book", "forearm.L", rot=(-15, 0, 0), bevel=0.2)
    C.box("LedgerPages", tuple(hl + V((0, -0.13, 0.06))), (0.18, 0.02, 0.24), "page", "forearm.L", rot=(-15, 0, 0), bevel=0.2)
    shr = V(C.anch["shR"])
    C.ellipsoid("Sack", tuple(shr + V((0.05, 0.26, 0.12))), (0.24, 0.22, 0.26), "sack", "chest")
    C.tube("SackNeck", [shr + V((0.02, 0.1, 0.2)), shr + V((0.0, -0.02, 0.18))], [0.06, 0.04], "rope", "chest")
    for k in range(3):
        C.ellipsoid(f"Spill{k}", tuple(shr + V((0.08 * (k - 1), 0.2, 0.36))), (0.04, 0.04, 0.012), "gold", "chest")
