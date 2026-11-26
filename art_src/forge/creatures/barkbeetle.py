"""Barkbeetle (Mushroom Forest, 3): a heavy stag beetle armoured in living bark. Sculpted: a broad, domed
carapace split into two bark wing-cases with moss and leaves growing in the seam, a heavy pronotum
shield, a low wide head with huge branching antler mandibles, and six thick knobbly legs."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(bark="4a3420", bark2="6a4a2a", moss="5f9a2e", eye="ffcf3a", leg="2a1e14", horn="7a5a3a", leaf="3a8a2a")
    C.plan, C.attack = "quad", "ram"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.28, 0.42), (0, 0.0, 0.44), "root")
    C.bone("chest", (0, 0.0, 0.44), (0, -0.26, 0.44), "hips")
    C.bone("head", (0, -0.26, 0.42), (0, -0.5, 0.4), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        for k, y in enumerate((-0.18, 0.04, 0.24)):
            up, lo = f"leg{k}.{side}", f"shin{k}.{side}"
            C.bone(up, (0.22 * sx, y, 0.32), (0.4 * sx, y - 0.02 * (1 - k), 0.32), "chest" if y < 0 else "hips")
            C.bone(lo, (0.4 * sx, y - 0.02 * (1 - k), 0.32), (0.46 * sx, y + 0.04 * (k - 1), 0.02), up)
            if k != 1:
                C.legs.append((up, lo, (0.0 if side == "L" else 0.5) if k == 0 else (0.5 if side == "L" else 0.0)))
    cl = Clay(C, "Body", res=0.02)
    cl.add((0, 0.16, 0.46), (0.32, 0.36, 0.22), group="bark")                       # wing cases
    cl.add((0, 0.16, 0.66), (0.03, 0.32, 0.04), group="moss")                        # mossy seam
    cl.add((0, -0.16, 0.46), (0.28, 0.16, 0.16), group="bark2")                      # pronotum shield
    cl.add((0, -0.36, 0.42), (0.2, 0.12, 0.1), group="bark")                         # head
    cl.add((0, 0.16, 0.28), (0.24, 0.3, 0.08), group="leg")
    body = cl.build({"bark": "bark", "bark2": "bark2", "moss": "moss", "leg": "leg"}, voxel=0.01, budget=8000, relax=2,
                    texture={"type": 'STUCCI', "scale": 0.03, "strength": 0.015})
    recolor(body, lambda p, n: smoothstep(0.2, 0.7, math.sin(p.y * 40 + math.sin(p.x * 18) * 2)) * 0.6
            * (1.0 if p.z > 0.4 else 0.0), "bark2")
    recolor(body, lambda p, n: cracks(p, 0.09, 0.05, seed=61) * smoothstep(0.5, 0.9, n.z) * 0.7, "moss")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.14 * mx, -0.42, 0.46), (0.03, 0.03, 0.03), "eye", "head")
        b = V((0.1 * mx, -0.44, 0.42))
        main = [b, b + V((0.08 * mx, -0.16, 0.06)), b + V((0.04 * mx, -0.32, 0.14)), b + V((-0.06 * mx, -0.4, 0.16))]
        C.tube(f"Mandible{mx}", main, [0.04, 0.035, 0.025, 0.006], "horn", "head")
        for k, d in enumerate([(0.08 * mx, -0.04, 0.12), (0.06 * mx, 0.02, 0.1)]):
            p = V(main[k + 1])
            C.tube(f"Tine{mx}{k}", [p, p + V(d)], [0.018, 0.004], "horn", "head")
        side = "L" if mx < 0 else "R"
        for k, y in enumerate((-0.18, 0.04, 0.24)):
            a, b2, c = V((0.22 * mx, y, 0.32)), V((0.4 * mx, y - 0.02 * (1 - k), 0.36)), V((0.46 * mx, y + 0.04 * (k - 1), 0.02))
            C.tube(f"Leg{side}{k}", [a, b2, c], [0.04, 0.035, 0.015], "leg", None, allowed=[f"leg{k}.{side}", f"shin{k}.{side}"])
            C.ellipsoid(f"Knob{side}{k}", tuple(b2), (0.045,) * 3, "bark2", f"leg{k}.{side}")
    for k in range(4):
        C.ellipsoid(f"Leaf{k}", (0.06 * (k % 2 * 2 - 1), -0.02 + 0.12 * k, 0.69), (0.05, 0.03, 0.012), "leaf", "hips",
                    rot=(0, 0, 40 * (k % 2 * 2 - 1)))
