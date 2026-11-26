"""Ancient Hollowneck (Mushroom Forest, 10): a colossal moss sauropod. Sculpted: a mountainous body on
four pillar legs armoured in bark, a long rising neck that is a hollow old tree trunk, a small head with
ember-gold eyes, a long tapering tail, a thick moss blanket over the back and a little forest of pines and
red mushrooms growing on it."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(hide="3f4a34", bark="4a3524", moss="4f8a2e", pine="2a5a2a", trunk="3a2818", eye="ffc23a", dark="0e0c08",
              cap="c23a2a", spot="f0e8d0", belly="7a7a5a", pupil="0a0804")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.26, 0.8), chest=(-0.2, 0.82), r_chest=(0.34, 0.3, 0.32), r_belly=(0.38, 0.32, 0.34),
                         r_hips=(0.33, 0.28, 0.32), leg_x=0.28, r_thigh=0.15, r_shin=0.13, r_paw=0.14, paw_len=1.0,
                         neck=((-0.38, 1.12), (-0.46, 1.42), (-0.5, 1.66)), r_neck=(0.2, 0.15, 0.13),
                         head=(-0.58, 1.78), r_head=(0.11, 0.14, 0.09), snout=(-0.76, 1.74), r_snout=(0.07, 0.05),
                         tail=((0.56, 0.74), (0.8, 0.56), (0.96, 0.44)), r_tail=(0.2, 0.04), digi=False, group="hide",
                         belly_group="belly")
    h = at["head"]
    for k in range(10):                                                        # moss blanket
        a = 2 * math.pi * k / 10
        cl.add((math.cos(a) * 0.22, 0.04 + math.sin(a) * 0.26, 1.08), (0.17, 0.17, 0.1), group="moss")
    for sx in (-1, 1):
        for tag in ("f", "b"):
            p = V(at["legs"]["L" if sx < 0 else "R"][tag][1])
            cl.add(tuple(p), (0.16, 0.16, 0.22), group="bark")                    # bark-armoured legs
    body = cl.build({"hide": "hide", "belly": "belly", "moss": "moss", "bark": "bark"}, voxel=0.017, budget=11000,
                    relax=2, texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.02})
    # the neck is an old hollow trunk: bark ridges along it, a dark knot hole
    recolor(body, lambda p, n: (smoothstep(0.3, 0.8, math.sin(math.atan2(p.x, p.y + 0.4) * 14)) * 0.8
                                if 1.0 < p.z < 1.7 and p.y < -0.25 else 0.0), "trunk")
    recolor(body, lambda p, n: (1.0 if p.y < -0.25 and 1.0 < p.z < 1.7 else 0.0) * 0.5, "bark")
    recolor(body, lambda p, n: cracks(p, 0.12, 0.05, seed=59) * (1.0 if p.z < 0.55 else 0.0), "trunk")
    C.ellipsoid("KnotHole", (0, -0.6, 1.3), (0.06, 0.03, 0.08), "dark", "neck2", rot=(20, 0, 0))
    skulpt.eyes(C, [(0.08, h.y - 0.08, h.z + 0.02)], 0.022, "eye", "pupil")
    rnd = random.Random(11)
    for k in range(7):                                                         # pines on its back
        x, y = rnd.uniform(-0.22, 0.22), rnd.uniform(-0.2, 0.3)
        base = V((x, y, 1.12 + 0.04 * (1 - abs(x) / 0.22)))
        ht = rnd.uniform(0.22, 0.38)
        bone = "chest" if y < 0.04 else "hips"
        for t in range(3):
            C.cone(f"Pine{k}{t}", tuple(base + V((0, 0, ht * 0.25 * t))), tuple(base + V((0, 0, ht * (0.55 + 0.25 * t)))),
                   0.09 - 0.022 * t, "pine", bone, segs=6)
    for k in range(4):
        x, y = rnd.uniform(-0.25, 0.25), rnd.uniform(-0.3, 0.4)
        C.tube(f"ShroomStalk{k}", [V((x, y, 1.08)), V((x, y, 1.16))], [0.02, 0.02], "spot", "chest" if y < 0.04 else "hips")
        C.ellipsoid(f"Shroom{k}", (x, y, 1.17), (0.06, 0.06, 0.03), "cap", "chest" if y < 0.04 else "hips")
