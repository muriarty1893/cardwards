"""Rimewing (Frost Peaks, 4): a great snowy owl that hunts in silence. Sculpted: a big round-shouldered
owl body in thick white plumage barred with ice blue, a broad facial disc around burning gold eyes,
tufted horn-like ears, a hooked dark beak, feathered legs with dark talons, and wide wings whose flight
feathers are tipped with icicles."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(plume="f4f8ff", bar="7ab8e0", disc="e8f0f8", eye="ffc23a", pupil="0a0a0a", beak="3a4a5a", ice="aef4ff",
              talon="2a3a4a")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.05, 0.5), (0, 0.0, 0.78), "root")
    C.bone("chest", (0, 0.0, 0.78), (0, -0.04, 1.0), "hips")
    C.bone("head", (0, -0.04, 1.0), (0, -0.06, 1.3), "chest")
    C.bone("tail1", (0, 0.12, 0.52), (0, 0.32, 0.36), "hips")
    C.spine, C.head, C.tail = ["hips", "chest"], "head", ["tail1"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.1 * sx, 0.0, 0.46), (0.1 * sx, -0.04, 0.24), "hips")
        C.bone(f"shin.{side}", (0.1 * sx, -0.04, 0.24), (0.1 * sx, -0.06, 0.04), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    skulpt.wing_bones(C, (0.22, 0.0, 0.92), (0.55, 0.12, 1.12), (0.98, 0.3, 1.0))
    cl = Clay(C, "Body", res=0.02)
    cl.add((0, 0.0, 0.72), (0.27, 0.25, 0.32), group="plume")
    cl.add((0, -0.04, 1.06), (0.23, 0.21, 0.19), group="plume")                     # big round head
    cl.add((0, -0.16, 1.04), (0.19, 0.08, 0.16), group="disc")                       # facial disc
    cl.mirror((0.08, -0.22, 1.07), (0.06, 0.04, 0.05), group="disc", neg=True)       # eye bowls
    for sx in (-1, 1):
        cl.chain([(0.14 * sx, -0.02, 1.2), (0.17 * sx, 0.0, 1.3)], [(0.05, 0.04, 0.05), 0.012], group="plume")   # tufts
        cl.chain([(0.1 * sx, 0.0, 0.46), (0.1 * sx, -0.04, 0.24), (0.1 * sx, -0.06, 0.06)], [0.08, 0.05, 0.04],
                 group="plume")                                                        # feathered legs
        cl.chain([(0.24 * sx, 0.0, 0.9), (0.27 * sx, 0.1, 0.7), (0.24 * sx, 0.22, 0.48)],
                 [(0.06, 0.14, 0.14), (0.05, 0.14, 0.12), 0.03], group="plume")        # folded wing edge
    cl.chain([(0, 0.12, 0.52), (0, 0.32, 0.36)], [(0.12, 0.06, 0.06), (0.1, 0.04, 0.03)], group="plume")
    body = cl.build({"plume": "plume", "disc": "disc"}, voxel=0.01, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.55, 0.85, math.sin(p.z * 55 + abs(p.x) * 10)) * 0.75
            * (1.0 if p.z < 0.95 and (p.y > -0.15 or abs(p.x) > 0.15) else 0.0), "bar")
    skulpt.eyes(C, [(0.08, -0.235, 1.07)], 0.045, "eye", "pupil")
    C.cone("Beak", (0, -0.24, 1.02), (0, -0.28, 0.95), 0.03, "beak", "head", segs=6, smooth=True)
    for mx in (-1, 1):
        for k in (-1, 0, 1):
            C.cone(f"Talon{mx}{k}", (0.1 * mx + 0.03 * k, -0.1, 0.04), (0.1 * mx + 0.04 * k, -0.16, 0.0), 0.014, "talon",
                   f"shin.{'L' if mx < 0 else 'R'}", segs=4)
        side = "L" if mx < 0 else "R"
        sh, el, tip = V((0.22 * mx, 0.0, 0.92)), V((0.55 * mx, 0.12, 1.12)), V((0.98 * mx, 0.3, 1.0))
        C.tube(f"WingArm{side}", [sh, el, tip], [0.07, 0.05, 0.03], "plume", None,
               allowed=[f"wing.{side}", f"wing2.{side}"])
        for k in range(8):
            t = k / 7
            base = sh.lerp(el, min(1.0, t * 2)) if t < 0.5 else el.lerp(tip, (t - 0.5) * 2)
            d = V((0.15 * mx * t, 0.5, -0.5 - 0.3 * (1 - t))).normalized()
            ln = 0.28 + 0.12 * t
            bone = f"wing.{side}" if t < 0.5 else f"wing2.{side}"
            C.cone(f"Feather{side}{k}", tuple(base), tuple(base + d * ln), 0.06, "plume" if k % 2 else "disc", bone, segs=4)
            C.cone(f"FeatherIce{side}{k}", tuple(base + d * ln * 0.8), tuple(base + d * (ln + 0.08)), 0.02, "ice", bone,
                   segs=4)
