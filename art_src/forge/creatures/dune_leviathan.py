"""Dune Leviathan (Sunny Dunes, 9): a colossal sandworm rearing out of the dunes. Sculpted: a massive
segmented body bursting up from a mound of sand, armoured ring plates crusted with sand, rearing high and
curving forward over its prey, a great three-petal maw split open into rings of hooked teeth, and
treasure it has swallowed glinting in the plates."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="b8905a", plate="5a3a1a", sand="e8c888", maw="5a1a1a", tooth="f0e8d0", gold="ffd23a", gem="3ad8ff",
              dark="1a0a08", eye="ff6a1a")
    C.plan, C.attack = "biped", "ram"
    spine = [V((0, 0.2, 0.0)), V((0, 0.16, 0.5)), V((0, 0.02, 1.0)), V((0, -0.16, 1.4)), V((0, -0.34, 1.62))]
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", tuple(spine[0]), tuple(spine[1]), "root")
    C.bone("chest", tuple(spine[1]), tuple(spine[2]), "hips")
    C.bone("neck", tuple(spine[2]), tuple(spine[3]), "chest")
    C.bone("head", tuple(spine[3]), tuple(spine[4]), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    cl = Clay(C, "Body", res=0.024)
    cl.add((0, 0.2, 0.06), (0.5, 0.5, 0.14), group="sand")                          # sand mound
    cl.chain(spine, [0.34, 0.32, 0.29, 0.27, 0.24], group="hide")
    for k in range(5):                                                              # ring plates
        t = 0.1 + 0.8 * k / 4
        seg = min(int(t * 4), 3)
        p = spine[seg].lerp(spine[seg + 1], t * 4 - seg)
        d = (spine[seg + 1] - spine[seg]).normalized()
        ang = math.degrees(math.atan2(d.y, d.z))
        cl.add(tuple(p), (0.37 - 0.02 * k, 0.37 - 0.02 * k, 0.07), rot=(-ang, 0, 0), group="plate")
    cl.add((0, -0.42, 1.68), (0.22, 0.12, 0.22), rot=(-40, 0, 0), group="maw", neg=True)
    for k in range(3):                                                              # the three petals
        a = math.radians(90 + 120 * k)
        cl.add((math.cos(a) * 0.2, -0.42, 1.68 + math.sin(a) * 0.2), (0.12, 0.06, 0.12), rot=(-40, 0, 0), group="plate")
    body = cl.build({"hide": "hide", "plate": "plate", "sand": "sand", "maw": "maw"}, voxel=0.018, budget=11000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.04, "strength": 0.016})
    recolor(body, lambda p, n: smoothstep(0.5, 0.9, n.z) * 0.6, "sand")
    recolor(body, lambda p, n: (1.0 if (p - V((0, -0.4, 1.66))).length < 0.2 and p.y < -0.3 else 0.0), "maw")
    for ring in range(2):
        for k in range(10):
            a = 2 * math.pi * k / 10
            r = 0.16 - 0.06 * ring
            b = V((math.cos(a) * r, -0.4 + 0.06 * ring, 1.66 + math.sin(a) * r))
            C.cone(f"Tooth{ring}{k}", tuple(b), tuple(b + V((-math.cos(a) * 0.06, 0.02, -math.sin(a) * 0.06))), 0.022, "tooth",
                   "head", segs=4)
    for k, (x, z) in enumerate([(0.3, 0.7), (-0.28, 1.0), (0.26, 1.24), (-0.3, 0.46)]):
        C.decal(f"Treasure{k}", x, z, (0.05, 0.05, 0.03), "gold" if k % 2 else "gem", "chest" if z < 1.0 else "neck")
