"""Ice Sage (Frost Peaks, 3): a small, stooped frost hermit in a heavy hooded fur cloak, a long beard
frozen into icicles, two pale glints under the hood and a lantern of blue ice hung from a crooked staff."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(cloak="3a5a8a", fur="eef4fa", dark="0a1420", eye="aef8ff", beard="e8f4ff", ice="9ee8ff", wood="5a4030",
              lamp="cff8ff", trim="b8c8d8")
    C.attack = "cast"
    kits.biped(C, "cloak", hip=0.55, chest=0.85, neck=0.96, head_top=1.18, shoulder_x=0.2, hip_x=0.1,
               hand=(0.34, -0.14, 0.55), r_hip=0.2, r_waist=0.18, r_chest=0.2, r_neck=0.07, r_head=0.13,
               r_arm=0.06, r_hand=0.05, r_leg=0.07, r_foot=0.07, lean=0.22)
    h = V(C.anch["head"])
    props.robe(C, "cloak", top_z=0.62, bottom_r=0.36, top_r=0.22, hem=0.04, wave=6)
    C.lathe("FurHem", [(0.36, 0.02), (0.38, 0.08)], "fur", None, segs=24, allowed=["hips", "leg.L", "leg.R", "shin.L", "shin.R"])
    props.hooded_face(C, "cloak", "dark", "eye", h, r=0.16, eye_gap=0.05, eye_size=0.022)
    C.ellipsoid("HoodTrim", tuple(h + V((0, -0.09, 0.0))), (0.16, 0.06, 0.17), "fur", "head")
    beard = [h + V((0, -0.14, -0.06)), h + V((0, -0.18, -0.25)), h + V((0, -0.16, -0.45))]
    C.tube("Beard", beard, [0.07, 0.05, 0.015], "beard", None, allowed=["head", "neck", "chest"])
    for k in range(3):
        b = V(beard[1]).lerp(V(beard[2]), 0.3 * k)
        C.cone(f"BeardIcicle{k}", tuple(b + V((0.04 * (k - 1), -0.03, 0))), tuple(b + V((0.04 * (k - 1), -0.04, -0.14))), 0.02,
               "ice", "chest", segs=4)
    c = V(C.anch["chest"])
    C.ellipsoid("Mantle", tuple(c + V((0, 0.02, 0.08))), (0.26, 0.22, 0.1), "fur", "chest")
    top = props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=1.2, up=0.6, top="hook")
    C.lathe("Lamp", [(0.03, -0.07), (0.06, -0.04), (0.06, 0.04), (0.03, 0.07)], "lamp", "forearm.R", segs=8)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(top + V((0, -0.26, -0.16))))
    C.cone("LampSpike", tuple(top + V((0, -0.26, -0.23))), tuple(top + V((0, -0.26, -0.33))), 0.025, "ice", "forearm.R", segs=4)
