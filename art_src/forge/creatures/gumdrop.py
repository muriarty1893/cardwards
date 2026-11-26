"""Gumdrop (Candy Hills, 2): a hulking sugar-crusted gumdrop slime. Sculpted: a heavy, sagging gumdrop
dome of lime jelly that pools out at the base, a crust of sugar crystals over the top, one big suspicious
eye under a heavy brow, a wide frown, and half-dissolved candies floating inside."""
import math
import random
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(gum="5ad83a", gum2="a8ff7a", sugar="f4fff0", eye="ffffff", pupil="1a2a0a", mouth="1a3a0a", c1="ff4a8a",
              c2="ffd23a", c3="7a5aff")
    C.plan, C.attack, C.hover = "hover", "slam", 0.0
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.1), (0, 0, 0.45), "root")
    C.bone("chest", (0, 0, 0.45), (0, -0.02, 0.75), "hips")
    C.bone("head", (0, -0.02, 0.75), (0, -0.04, 0.95), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    cl = Clay(C, "Body", res=0.018)
    cl.add((0, 0, 0.42), (0.36, 0.34, 0.38), group="gum")
    cl.add((0, 0, 0.12), (0.44, 0.42, 0.12), group="gum")                         # pooled base
    cl.add((0, 0, 0.78), (0.18, 0.17, 0.1), group="gum")
    cl.add((0, -0.28, 0.6), (0.14, 0.06, 0.04), rot=(-15, 0, 0), group="gum2")     # heavy brow
    cl.add((0, -0.32, 0.54), (0.08, 0.06, 0.07), group="gum", neg=True)           # eye socket
    cl.add((0, -0.34, 0.36), (0.12, 0.04, 0.02), group="mouth", neg=True)
    body = cl.build({"gum": "gum", "gum2": "gum2", "mouth": "mouth"}, voxel=0.01, budget=7000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.012, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.4, 0.9, n.z) * 0.9, "sugar")
    recolor(body, lambda p, n: smoothstep(0.3, 0.0, p.z) * 0.4, "gum2")
    C.ellipsoid("Eye", (0, -0.3, 0.54), (0.07, 0.05, 0.065), "eye", "head")
    C.ellipsoid("Pupil", (0.01, -0.35, 0.53), (0.025, 0.012, 0.03), "pupil", "head")
    rnd = random.Random(29)
    for k in range(6):                                                         # swallowed candies, half sunk in
        a = math.radians(40 + 50 * k)
        z = rnd.uniform(0.2, 0.5)
        hit, nor = C.surf(0, z, dir=(-math.cos(a), -math.sin(a), 0), y=0)
        if hit is None:
            continue
        C.ellipsoid(f"Candy{k}", tuple(hit - nor * 0.02), (0.05, 0.04, 0.035), ("c1", "c2", "c3")[k % 3], "hips",
                    rot=(rnd.uniform(0, 90), 0, rnd.uniform(0, 90)))
