"""Cotton Puff (Candy Hills, 2): a sour little storm cloud of spun cotton candy. Sculpted: a billowing
cloud of pink, blue and lilac candy floss puffs with a scowling face pushed into the front, sugar-crystal
lightning forking from its dark underside and sprinkles raining down."""
import math
import random
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(puff="ffb8e0", puff2="b8d8ff", puff3="e8c8ff", eye="2a0a2a", bolt="fff47a", spr1="ff4a8a", spr2="3ad8ff",
              stick="ffffff", under="8a6aa8")
    C.plan, C.attack, C.hover = "hover", "dive", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.6), (0, 0, 0.85), "root")
    C.bone("head", (0, 0, 0.85), (0, -0.1, 1.05), "hips")
    C.bone("tail1", (0, 0, 0.6), (0, 0, 0.3), "hips")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1"]
    cl = Clay(C, "Body", res=0.016)
    rnd = random.Random(19)
    groups = ["puff", "puff2", "puff3"]
    cl.add((0, 0, 0.8), (0.3, 0.24, 0.18), group="puff")
    for k in range(16):
        a = 2 * math.pi * k / 16
        r = 0.26 + 0.06 * (k % 2)
        cl.add((math.cos(a) * r, math.sin(a) * r * 0.75, 0.78 + rnd.uniform(-0.04, 0.12)), (0.13, 0.13, 0.12),
               group=groups[k % 3])
    for k in range(5):
        cl.add((rnd.uniform(-0.16, 0.16), rnd.uniform(-0.1, 0.1), 0.98), (0.12, 0.12, 0.1), group=groups[k % 3])
    cl.add((0, -0.24, 0.84), (0.1, 0.03, 0.025), rot=(-10, 0, 0), group="puff3")          # scowl brow
    cl.mirror((0.06, -0.26, 0.8), (0.03, 0.025, 0.025), group="puff", neg=True)
    body = cl.build({"puff": "puff", "puff2": "puff2", "puff3": "puff3"}, voxel=0.009, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.015})
    recolor(body, lambda p, n: smoothstep(-0.3, -0.9, n.z) * 0.8, "under")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, -0.29, 0.8), (0.02, 0.01, 0.014), "eye", "head")
    C.box("Frown", (0, -0.3, 0.73), (0.07, 0.01, 0.012), "eye", "head", rot=(0, 0, 0), bevel=0.4)
    for k, x in enumerate((-0.12, 0.1)):
        pts = [V((x, 0, 0.62)), V((x + 0.06, -0.02, 0.48)), V((x - 0.02, 0, 0.4)), V((x + 0.04, -0.02, 0.24))]
        C.tube(f"Bolt{k}", pts, [0.03, 0.025, 0.025, 0.005], "bolt", "tail1")
    for k in range(8):
        C.box(f"Sprinkle{k}", (rnd.uniform(-0.24, 0.24), rnd.uniform(-0.18, 0.18), rnd.uniform(0.3, 0.6)),
              (0.012, 0.012, 0.04), "spr1" if k % 2 else "spr2", "tail1", rot=(rnd.uniform(-40, 40), rnd.uniform(-40, 40), 0),
              bevel=0.5)
