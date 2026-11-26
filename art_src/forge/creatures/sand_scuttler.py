"""Sand Scuttler (Sunny Dunes, 1): a desert crab. Sculpted: a wide, low, knobbly carapace bleached by the
sun and striped like the dunes, eyes on tall stalks, one oversized crushing claw and one small cutting
claw, dark claw tips and six spiky legs."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(shell="d88a3a", shell2="f0c070", stripe="a85a2a", claw="c8602a", tip="2a1408", eye="1a0a04", stalk="d89a5a",
              leg="b8682a")
    C.plan, C.attack = "quad", "bite"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.12, 0.34), (0, -0.04, 0.36), "root")
    C.bone("chest", (0, -0.04, 0.36), (0, -0.2, 0.36), "hips")
    C.bone("head", (0, -0.2, 0.36), (0, -0.34, 0.42), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        for k, y in enumerate((-0.08, 0.06, 0.2)):
            up, lo = f"leg{k}.{side}", f"shin{k}.{side}"
            C.bone(up, (0.24 * sx, y, 0.3), (0.42 * sx, y, 0.36), "chest" if y < 0 else "hips")
            C.bone(lo, (0.42 * sx, y, 0.36), (0.5 * sx, y + 0.02, 0.02), up)
            if k != 1:
                C.legs.append((up, lo, (0.0 if side == "L" else 0.5) if k == 0 else (0.5 if side == "L" else 0.0)))
        C.bone(f"arm.{side}", (0.2 * sx, -0.22, 0.32), (0.34 * sx, -0.4, 0.32), "chest")
        C.bone(f"forearm.{side}", (0.34 * sx, -0.4, 0.32), (0.3 * sx, -0.58, 0.34), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, 0.02, 0.36), (0.32, 0.26, 0.12), group="shell")
    cl.add((0, 0.02, 0.44), (0.24, 0.2, 0.06), group="shell2")
    for k in range(6):
        a = math.pi * (0.1 + 0.8 * k / 5)
        cl.add((math.cos(a) * 0.3, -0.12 - math.sin(a) * 0.08, 0.38), (0.04, 0.04, 0.04), group="shell")  # rim knobs
    body = cl.build({"shell": "shell", "shell2": "shell2"}, voxel=0.008, budget=5000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.02, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(0.55, 0.85, math.sin(p.y * 28 + math.sin(p.x * 12))) * smoothstep(0.2, 0.7, n.z),
            "stripe")
    for mx in (-1, 1):
        b = V((0.07 * mx, -0.2, 0.42))
        C.tube(f"Stalk{mx}", [b, b + V((0.02 * mx, -0.02, 0.16))], [0.015, 0.012], "stalk", "head")
        C.ellipsoid(f"Eye{mx}", tuple(b + V((0.02 * mx, -0.02, 0.18))), (0.025,) * 3, "eye", "head")
        side = "L" if mx < 0 else "R"
        for k, y in enumerate((-0.08, 0.06, 0.2)):
            C.tube(f"Leg{side}{k}", [V((0.24 * mx, y, 0.3)), V((0.42 * mx, y, 0.38)), V((0.5 * mx, y + 0.02, 0.02))],
                   [0.03, 0.022, 0.008], "leg", None, allowed=[f"leg{k}.{side}", f"shin{k}.{side}"])
            C.cone(f"Spike{side}{k}", (0.42 * mx, y, 0.38), (0.44 * mx, y, 0.46), 0.012, "tip", f"leg{k}.{side}", segs=4)
        big = mx > 0
        s = 1.6 if big else 0.9
        c = V((0.3 * mx, -0.6, 0.34))
        C.tube(f"Arm{side}", [V((0.2 * mx, -0.22, 0.32)), V((0.34 * mx, -0.4, 0.32)), c], [0.04, 0.035 * s, 0.04 * s], "claw",
               None, allowed=[f"arm.{side}", f"forearm.{side}"])
        C.ellipsoid(f"Claw{side}", tuple(c + V((0, -0.04, 0))), (0.07 * s, 0.09 * s, 0.05 * s), "claw", f"forearm.{side}")
        C.cone(f"Pincer{side}", tuple(c + V((0.02 * mx, -0.08 * s, 0.03))), tuple(c + V((0.0, -0.2 * s, 0.03))), 0.03 * s, "tip",
               f"forearm.{side}", segs=5)
        C.cone(f"Pincer2{side}", tuple(c + V((-0.02 * mx, -0.08 * s, -0.02))), tuple(c + V((-0.01 * mx, -0.17 * s, -0.03))),
               0.022 * s, "tip", f"forearm.{side}", segs=5)
