"""Aurora Skywhale (Frost Peaks, 10, legend): a vast whale swimming through the polar sky. Sculpted: a
humpback's great blunt head and long tapering body, a pale grooved throat, long knobbled wing-like pectoral
fins edged with green light, broad flukes, a deep indigo back washed with glowing aurora bands, and ice
barnacles crusting the head."""
import math
import random
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(ice="e8faff", eye="fff4c0", dark="060a1a", aur1="3affb0")
    C.plan, C.attack, C.hover = "swimmer", "dive", 0.6
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.5), (0, -0.2, 0.52), "root")
    C.bone("chest", (0, -0.2, 0.52), (0, -0.5, 0.52), "hips")
    C.bone("head", (0, -0.5, 0.52), (0, -0.9, 0.5), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    tail = [(0, 0.1, 0.5), (0, 0.4, 0.54), (0, 0.66, 0.62), (0, 0.86, 0.72)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"fin.{side}", (0.3 * sx, -0.32, 0.36), (0.62 * sx, -0.2, 0.1), "chest")
        C.bone(f"fin2.{side}", (0.62 * sx, -0.2, 0.1), (0.9 * sx, -0.06, -0.1), f"fin.{side}")
        C.wings.append((f"fin.{side}", f"fin2.{side}", side))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.03)
    cl.add((0, -0.6, 0.52), (0.33, 0.3, 0.27), group="back")                    # blunt head
    cl.add((0, -0.78, 0.46), (0.24, 0.18, 0.18), group="back")                  # rostrum
    cl.add((0, -0.6, 0.38), (0.3, 0.32, 0.16), group="belly")                   # throat pouch
    cl.add((0, -0.28, 0.54), (0.4, 0.38, 0.33), group="back")                   # chest
    cl.add((0, 0.06, 0.53), (0.33, 0.36, 0.28), group="back")                   # body
    cl.add((0, -0.2, 0.36), (0.32, 0.5, 0.16), group="belly")
    cl.chain(tail, [0.24, 0.16, 0.09, 0.05], group="back")
    cl.add((0, 0.32, 0.72), (0.03, 0.1, 0.05), group="back")                    # dorsal hump
    for sx in (-1, 1):
        # long knobbled pectoral fins
        cl.chain([(0.3 * sx, -0.32, 0.36), (0.62 * sx, -0.2, 0.1), (0.9 * sx, -0.06, -0.1)],
                 [(0.1, 0.14, 0.04), (0.08, 0.13, 0.035), (0.03, 0.06, 0.025)], group="fin")
        for k in range(4):
            p = V((0.3 * sx, -0.32, 0.36)).lerp(V((0.9 * sx, -0.06, -0.1)), 0.15 + 0.22 * k)
            cl.add(tuple(p + V((0, -0.12 + 0.02 * k, 0.0))), (0.035, 0.035, 0.03), group="fin")
        # flukes
        cl.chain([(0, 0.82, 0.72), (0.26 * sx, 0.94, 0.76), (0.54 * sx, 1.02, 0.86)],
                 [(0.14, 0.13, 0.045), (0.14, 0.12, 0.04), (0.06, 0.08, 0.025)], group="back")
        cl.add((0.3 * sx, -0.66, 0.5), (0.04, 0.04, 0.03), group="back", neg=True)       # eye socket
    cl.add((0, -0.86, 0.41), (0.2, 0.06, 0.012), group="back", neg=True)                 # mouth line
    body = cl.build({"back": "1a2a5a", "belly": "c8d8f0", "fin": "2a3a6a"}, voxel=0.017, budget=11000,
                    texture={"type": 'CLOUDS', "scale": 0.05, "strength": 0.008})
    # throat grooves; aurora bands of green, violet and cyan washing over the back; glowing fin edges
    recolor(body, lambda p, n: (smoothstep(0.6, 1.0, math.sin(p.x * 70)) * 0.6 if n.z < -0.4 and p.y < -0.1 else 0.0),
            "7a8aa8")
    def aurora(col_phase):
        return lambda p, n: (smoothstep(0.86, 0.99, math.sin(p.y * 7 + math.sin(p.x * 9) * 1.4 + col_phase))
                             * smoothstep(0.3, 0.8, n.z) * 0.8)
    recolor(body, aurora(0.0), "3affb0")
    recolor(body, aurora(2.1), "a85aff")
    recolor(body, lambda p, n: smoothstep(0.55, 0.85, abs(p.x)) * (1.0 if p.z < 0.3 else 0.0), "3affb0")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.3 * mx, -0.665, 0.5), (0.03, 0.035, 0.028), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", (0.315 * mx, -0.67, 0.5), (0.01, 0.02, 0.022), "dark", "head")
    rnd = random.Random(5)
    for k in range(16):                                                         # ice barnacles crusting the head
        x, y = rnd.uniform(-0.22, 0.22), rnd.uniform(-0.85, -0.45)
        hit, _ = C.surf(x, 3, dir=(0, 0, -1), y=y)
        if hit is None:
            continue
        r = rnd.uniform(0.02, 0.04)
        C.cone(f"Barnacle{k}", tuple(hit - V((0, 0, 0.01))), tuple(hit + V((0, 0, r * 1.4))), r, "ice",
               "head" if y < -0.5 else "chest", segs=5)
    C.ellipsoid("Blowhole", (0, -0.36, 0.86), (0.05, 0.03, 0.015), "dark", "chest")
