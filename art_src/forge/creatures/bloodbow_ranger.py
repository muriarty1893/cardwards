"""Bloodbow Ranger (Dark Moon, 3): a hooded night hunter with a vampire's pallor, a crimson recurve bow,
a quiver of red-fletched arrows, a tattered cloak and a mask over the lower face; eyes glint red."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(cloak="2a1a2a", leather="4a2a2a", skin="d8ccd8", eye="ff2a3a", dark="0c060c", bow="8a1020",
              string="e8e0e8", fletch="ff3a4a", metal="8a8a98", mask="1a1014")
    C.attack = "cast"
    kits.biped(C, "leather", hip=0.86, chest=1.32, neck=1.5, head_top=1.78, shoulder_x=0.24, hip_x=0.12,
               hand=(0.42, -0.14, 0.88), r_hip=0.17, r_waist=0.14, r_chest=0.21, r_neck=0.07, r_head=0.13,
               r_arm=0.06, r_hand=0.05, r_leg=0.075, r_foot=0.07, lean=0.08)
    h = V(C.anch["head"])
    props.hooded_face(C, "cloak", "skin", "eye", h, r=0.17, eye_gap=0.05, eye_size=0.025)
    C.ellipsoid("Mask", tuple(h + V((0, -0.13, -0.06))), (0.12, 0.06, 0.06), "mask", "head")
    props.cape(C, "cloak", C.anch["chest"][2] + 0.1, width=0.24, back_y=0.18, flare=0.2)
    # tattered cloak hem points
    for k in range(5):
        x = -0.24 + 0.12 * k
        C.cone(f"Tatter{k}", (x, 0.3, 0.2), (x * 1.2, 0.34, 0.02), 0.05, "cloak", "hips", segs=3)
    # bracers, belt, boots
    for side in ("L", "R"):
        fa = C.bones[f"forearm.{side}"]
        C.ellipsoid(f"Bracer{side}", tuple(fa["head"].lerp(fa["tail"], 0.55)), (0.075, 0.075, 0.1), "metal", f"forearm.{side}")
        sh = C.bones[f"shin.{side}"]
        C.ellipsoid(f"Boot{side}", tuple(sh["head"].lerp(sh["tail"], 0.6)), (0.09, 0.1, 0.16), "cloak", f"shin.{side}")
    C.lathe("Belt", [(0.18, 0.0), (0.19, 0.06)], "metal", "hips", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0, 0.88)))
    # crimson bow in the left hand, quiver on the back
    props.bow(C, C.anch["hdL"], "bow", "string", "forearm.L", size=0.6)
    q = V((0.1, 0.2, 1.25))
    C.tube("Quiver", [q + V((-0.12, 0, -0.3)), q, q + V((0.08, 0, 0.18))], [0.07, 0.07, 0.07], "leather", "chest")
    for k in range(3):
        top = q + V((0.1 + 0.03 * k, 0.0, 0.3))
        C.cone(f"Fletch{k}", tuple(top - V((0, 0, 0.08))), tuple(top + V((0.02, 0, 0.06))), 0.035, "fletch", "chest", segs=3)
    # arrow nocked in the right hand
    hr = V(C.anch["hdR"])
    C.tube("Arrow", [hr + V((0, 0.05, 0)), hr + V((0, -0.3, 0.05)), hr + V((0, -0.62, 0.1))], [0.01, 0.01, 0.01], "string",
           "forearm.R")
    C.cone("ArrowHead", tuple(hr + V((0, -0.62, 0.1))), tuple(hr + V((0, -0.72, 0.11))), 0.025, "metal", "forearm.R", segs=4)
