"""Glimmer Morel (Mushroom Forest, 3): a morel knight, its tall honeycombed cap worn like a great helm with
a glowing visor, a stalk body in bark plate, a round bark shield studded with glowing spores and a mace."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(stalk="d8c8a0", morel="8a6a3a", pit="4a3420", glow="b8ff6a", bark="5a3e28", bark2="7a5a3a",
              metal="8a8a7a", dark="140c08")
    C.attack = "slam"
    kits.biped(C, "stalk", hip=0.6, chest=0.95, neck=1.08, head_top=1.25, shoulder_x=0.24, hip_x=0.11,
               hand=(0.36, -0.1, 0.6), r_hip=0.17, r_waist=0.15, r_chest=0.2, r_neck=0.11, r_head=0.13,
               r_arm=0.06, r_hand=0.06, r_leg=0.075, r_foot=0.08)
    h = V(C.anch["head"])
    # tall honeycombed morel cap-helm
    C.lathe("Cap", [(0.001, h.z - 0.12), (0.17, h.z - 0.12), (0.2, h.z + 0.05), (0.17, h.z + 0.25), (0.1, h.z + 0.42),
                    (0.001, h.z + 0.48)], "morel", "head", segs=16)
    for k in range(4):
        for j in range(8):
            a = 2 * math.pi * (j + 0.5 * (k % 2)) / 8
            z = h.z - 0.05 + 0.12 * k
            r = [0.19, 0.19, 0.16, 0.11][k]
            C.ellipsoid(f"Pit{k}{j}", (math.cos(a) * r, math.sin(a) * r, z), (0.045, 0.045, 0.04), "pit", "head")
    C.box("Visor", tuple(h + V((0, -0.17, -0.02))), (0.2, 0.06, 0.05), "dark", "head", bevel=0.4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.2, -0.02))), (0.03, 0.01, 0.015), "glow", "head")
    # bark plate armour
    c = V(C.anch["chest"])
    C.ellipsoid("Breastplate", tuple(c + V((0, -0.04, -0.02))), (0.23, 0.2, 0.22), "bark", "chest")
    props.pauldrons(C, "bark2", spikes=None, size=0.12)
    # bark shield with glowing spore studs
    hl = V(C.anch["hdL"])
    sc = hl + V((-0.04, -0.14, 0.08))
    props.shield(C, tuple(sc), 0.24, "bark", "bark2", "forearm.L", facing=(0, -1, 0), boss="glow")
    for k in range(6):
        a = 2 * math.pi * k / 6
        C.ellipsoid(f"Stud{k}", tuple(sc + V((math.cos(a) * 0.16, -0.05, math.sin(a) * 0.16))), (0.025,) * 3, "glow",
                    "forearm.L")
    # morel-headed mace
    hr = V(C.anch["hdR"])
    C.tube("Haft", [hr + V((0, 0, 0.1)), hr, hr + V((0, -0.05, -0.32))], [0.022, 0.022, 0.022], "bark", "forearm.R")
    C.ellipsoid("MaceHead", tuple(hr + V((0, -0.06, -0.4))), (0.08, 0.08, 0.11), "morel", "forearm.R")
    for k in range(5):
        a = 2 * math.pi * k / 5
        C.cone(f"MaceSpike{k}", tuple(hr + V((math.cos(a) * 0.06, -0.06 + math.sin(a) * 0.06, -0.4))),
               tuple(hr + V((math.cos(a) * 0.13, -0.06 + math.sin(a) * 0.13, -0.42))), 0.02, "metal", "forearm.R", segs=4)
