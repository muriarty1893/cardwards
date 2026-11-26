"""Vexa, the Grudgekeeper (Ember Flats, 7, legend): a tall fire warlock in a horned hood, eyes like coals,
a burning ledger of grudges floating at her hand, chains of old debts hanging from her belt."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(robe="3a0f14", trim="b8862a", dark="0b0809", eye="ffb02a", skin="c99a86", page="f0e0b8",
              fire="ff5a1a", hot="ffd03a", chain="5a5458", horn="1e1416", wood="2a1a14")
    C.attack = "cast"
    kits.biped(C, "robe", hip=0.95, chest=1.48, neck=1.68, head_top=2.0, shoulder_x=0.3, hip_x=0.14,
               hand=(0.5, -0.14, 0.95), r_hip=0.22, r_waist=0.17, r_chest=0.28, r_neck=0.08, r_head=0.16,
               r_arm=0.075, r_hand=0.06, r_leg=0.09, lean=0.05)
    h = V(C.anch["head"])
    props.robe(C, "robe", top_z=1.02, bottom_r=0.5, top_r=0.24, hem=0.07, wave=6)
    props.hooded_face(C, "robe", "dark", "eye", h, r=0.21, eye_gap=0.065, eye_size=0.035)
    for mx in (-1, 1):
        C.tube(f"HoodHorn{mx}", [h + V((0.12 * mx, 0.02, 0.16)), h + V((0.24 * mx, 0.1, 0.32)), h + V((0.22 * mx, 0.22, 0.46))],
               [0.045, 0.03, 0.004], "horn", "head")
    # gold trim down the robe front and on the hem
    C.box("Sash", (0, -0.25, 0.65), (0.14, 0.04, 0.75), "trim", "hips", rot=(-14, 0, 0), bevel=0.3, taper=(0.6, 1))
    C.lathe("Hem", [(0.5, 0.02), (0.51, 0.08)], "trim", None, segs=28, allowed=["hips", "leg.L", "leg.R", "shin.L", "shin.R"])
    c = C.anch["chest"]
    C.lathe("Belt", [(0.2, 0.0), (0.21, 0.07)], "trim", "hips", segs=20)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0, 1.0)))
    # chains of debts hanging from the belt, ending in padlocks
    for k, x in enumerate((-0.18, 0.05, 0.2)):
        pts = [V((x, -0.18, 1.0)), V((x * 1.2, -0.26, 0.75)), V((x * 1.3, -0.3, 0.5 - 0.08 * k))]
        C.tube(f"Chain{k}", pts, [0.02, 0.02, 0.02], "chain", "hips")
        C.box(f"Lock{k}", tuple(pts[-1] + V((0, 0, -0.06))), (0.08, 0.04, 0.09), "trim", "hips", bevel=0.3)
    # shoulder mantle with spikes
    for mx in (-1, 1):
        sh = V(C.anch["shL" if mx < 0 else "shR"])
        C.ellipsoid(f"Mantle{mx}", sh + V((0, 0, 0.06)), (0.16, 0.16, 0.09), "trim", "arm.L" if mx < 0 else "arm.R")
        C.cone(f"MSpike{mx}", sh + V((0.04 * mx, 0, 0.12)), sh + V((0.14 * mx, 0.04, 0.3)), 0.04, "horn",
               "arm.L" if mx < 0 else "arm.R")
    # the burning grudge ledger over her left hand
    hl = V(C.anch["hdL"])
    book = hl + V((0.02, -0.18, 0.16))
    C.box("Book", tuple(book), (0.26, 0.18, 0.05), "horn", "forearm.L", rot=(-25, 0, 0), bevel=0.2)
    C.box("Pages", tuple(book + V((0, 0, 0.03))), (0.24, 0.16, 0.03), "page", "forearm.L", rot=(-25, 0, 0), bevel=0.1)
    props.flame(C, book + V((0, 0, 0.05)), 0.12, "forearm.L", "fire", "hot", n=5, name="BookFire")
    # gnarled wand in the right hand, ember tip
    hr = V(C.anch["hdR"])
    C.tube("Wand", [hr + V((0, 0.05, -0.1)), hr + V((0, -0.1, 0.12)), hr + V((0.02, -0.2, 0.38))], [0.025, 0.022, 0.015],
           "wood", "forearm.R")
    C.ellipsoid("WandTip", tuple(hr + V((0.02, -0.2, 0.4))), (0.04, 0.04, 0.04), "hot", "forearm.R")
    for side in ("L", "R"):
        C.ellipsoid(f"Hand{side}", C.anch["hd" + side], (0.06, 0.06, 0.06), "skin", f"forearm.{side}")
