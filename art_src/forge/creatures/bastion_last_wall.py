"""Bastion, the Last Wall (Sunny Dunes, 6, legend): an old tortoise warrior in sandstone-plate armour,
his shell grown into a fortress back with battlements, a great tower shield carved with a sun and a short
heavy sword; a stern beaked face under a crested helm."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="6a8a4a", shell="7a5a3a", stone="d8b878", stone2="b89858", metal="a8a8b0", gold="ffcf3a",
              eye="ffd23a", dark="1a140a", sun="ff8a1a", beak="d8c8a0", plume="b8202a")
    C.attack = "slam"
    kits.biped(C, "skin", hip=0.75, chest=1.2, neck=1.38, head_top=1.62, shoulder_x=0.42, hip_x=0.2,
               hand=(0.58, -0.18, 0.75), r_hip=0.3, r_waist=0.34, r_chest=0.42, r_neck=0.13, r_head=0.15,
               r_arm=0.11, r_hand=0.1, r_leg=0.14, r_foot=0.13, lean=0.12)
    h = V(C.anch["head"])
    # fortress shell
    c = V(C.anch["chest"])
    C.ellipsoid("Shell", tuple(c + V((0, 0.2, -0.12))), (0.5, 0.38, 0.55), "shell", "chest")
    for k in range(5):
        x = -0.32 + 0.16 * k
        C.box(f"Merlon{k}", tuple(c + V((x, 0.3, 0.42 - 0.04 * abs(k - 2)))), (0.11, 0.18, 0.14), "stone", "chest", bevel=0.2)
    for k, (x, z) in enumerate([(-0.2, -0.05), (0.2, -0.05), (0.0, 0.2), (0.0, -0.32), (-0.3, -0.3), (0.3, -0.3)]):
        C.decal(f"Brick{k}", x, c.z + z, (0.12, 0.08, 0.03), "stone2", "chest", part="Shell", dir=(0, -1, 0))
    C.ellipsoid("Plastron", tuple(c + V((0, -0.24, -0.15))), (0.32, 0.12, 0.42), "stone", "chest")
    for k in range(3):
        C.box(f"PlastronLine{k}", tuple(c + V((0, -0.35, 0.05 - 0.15 * k))), (0.36, 0.03, 0.02), "stone2", "chest", bevel=0.3)
    # beaked face under a crested helm
    C.cone("Beak", tuple(h + V((0, -0.12, -0.02))), tuple(h + V((0, -0.24, -0.08))), 0.07, "beak", "head", segs=8,
           smooth=True)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.07 * mx, -0.13, 0.03))), (0.025, 0.012, 0.016), "eye", "head")
    C.ellipsoid("Helm", tuple(h + V((0, 0.01, 0.06))), (0.18, 0.18, 0.13), "metal", "head")
    C.box("Visor", tuple(h + V((0, -0.14, 0.07))), (0.26, 0.05, 0.05), "metal", "head", bevel=0.4)
    C.tube("Crest", [h + V((0, -0.08, 0.18)), h + V((0, 0.06, 0.26)), h + V((0, 0.24, 0.14))], [0.05, 0.06, 0.02], "plume",
           "head")
    props.pauldrons(C, "stone", spikes=None, size=0.2)
    # tower shield on the left arm, heavy sword in the right
    hl = V(C.anch["hdL"])
    sc = hl + V((-0.05, -0.18, 0.18))
    props.shield(C, tuple(sc), 0.42, "stone", "gold", "forearm.L", facing=(0, -1, 0), kite=True)
    C.ellipsoid("ShieldSun", tuple(sc + V((0, -0.06, 0.1))), (0.12, 0.03, 0.12), "sun", "forearm.L")
    for k in range(8):
        import math
        a = 2 * math.pi * k / 8
        C.cone(f"Ray{k}", tuple(sc + V((math.cos(a) * 0.13, -0.06, 0.1 + math.sin(a) * 0.13))),
               tuple(sc + V((math.cos(a) * 0.24, -0.06, 0.1 + math.sin(a) * 0.24))), 0.03, "gold", "forearm.L", segs=4)
    props.blade(C, C.anch["hdR"], "metal", "gold", "forearm.R", length=0.55, width=0.08, direction=(0, -0.3, -1),
                guard=0.2)
    for side in ("L", "R"):
        sh = C.bones[f"shin.{side}"]
        C.ellipsoid(f"Greave{side}", tuple(sh["head"].lerp(sh["tail"], 0.4)), (0.16, 0.16, 0.2), "metal", f"shin.{side}")
