"""Ember Hornet (Ember Flats, 2): a giant fire hornet, ember-striped abdomen with a white-hot stinger,
four amber wings, hooked mandibles and burning red eyes."""
import math


def build(C):
    C.palette(chitin="1d1512", stripe="ff7a1c", hot="ffd24a", wing="ffb15c", eye="ff2a1a", leg="3a2a22")
    C.plan = "flyer"
    C.attack = "sting"
    C.hover = 0.55
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("chest", (0, 0.1, 0.9), (0, -0.25, 0.95), "root")
    C.bone("head", (0, -0.25, 0.95), (0, -0.55, 0.95), "chest")
    C.bone("jaw", (0, -0.5, 0.85), (0, -0.62, 0.8), "head", deform=False)
    C.bone("tail1", (0, 0.1, 0.9), (0, 0.5, 0.8), "chest")
    C.bone("tail2", (0, 0.5, 0.8), (0, 0.85, 0.55), "tail1")
    C.spine, C.head, C.tail = ["chest"], "head", ["tail1", "tail2"]
    # thorax + head + abdomen
    C.skin("Body", {"th": (0, -0.05, 0.92, 0.2, 0.18), "nk": (0, -0.28, 0.95, 0.09),
                    "hd": (0, -0.42, 0.95, 0.17, 0.15)}, [("th", "nk"), ("nk", "hd")], "chitin", subdiv=2)
    C.skin("Abdomen", {"a0": (0, 0.18, 0.88, 0.1), "a1": (0, 0.4, 0.82, 0.25, 0.22), "a2": (0, 0.66, 0.7, 0.22, 0.2),
                       "a3": (0, 0.86, 0.52, 0.1)}, [("a0", "a1"), ("a1", "a2"), ("a2", "a3")], "chitin", subdiv=2,
           allowed=["tail1", "tail2"])
    # ember stripes ringing the abdomen
    from mathutils import Vector
    axis = [Vector((0, 0.18, 0.88)), Vector((0, 0.4, 0.82)), Vector((0, 0.66, 0.7)), Vector((0, 0.86, 0.52))]
    for i, (t, r) in enumerate([(0.75, 0.215), (1.25, 0.235), (1.75, 0.2), (2.25, 0.14)]):
        k = int(t)
        a, b = axis[k], axis[k + 1]
        p = a.lerp(b, t - k)
        d = (b - a).normalized()
        ang = math.degrees(math.atan2(-d.z, d.y))
        C.ellipsoid(f"Stripe{i}", tuple(p), (r + 0.012, 0.045, r * 0.9 + 0.012), "stripe",
                    "tail1" if i == 0 else "tail2", rot=(-ang, 0, 0))
    C.cone("Stinger", (0, 0.9, 0.48), (0, 1.12, 0.22), 0.05, "hot", "tail2", segs=8)
    # red compound eyes and mandibles
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.11 * mx, -0.48, 0.99), (0.08, 0.09, 0.11), "eye", "head", rot=(0, 0, 25 * mx))
        C.tube(f"Mandible{mx}", [(0.07 * mx, -0.55, 0.86), (0.1 * mx, -0.66, 0.8), (0.02 * mx, -0.72, 0.76)],
               [0.035, 0.03, 0.006], "leg", "head")
        C.tube(f"Antenna{mx}", [(0.05 * mx, -0.52, 1.08), (0.12 * mx, -0.62, 1.28), (0.2 * mx, -0.56, 1.36)],
               [0.016, 0.012, 0.008], "leg", "head")
    # six legs tucked under the thorax
    for mx in (-1, 1):
        for k, y in enumerate((-0.18, -0.04, 0.1)):
            C.tube(f"Leg{mx}{k}", [(0.1 * mx, y, 0.82), (0.24 * mx, y - 0.03, 0.72), (0.2 * mx, y + 0.06 * k, 0.5)],
                   [0.025, 0.02, 0.01], "leg", "chest")
    # two pairs of amber wings
    for side, mx in (("L", -1), ("R", 1)):
        sh = (0.12 * mx, -0.05, 1.08)
        C.bone(f"wing.{side}", sh, (0.5 * mx, 0.1, 1.2), "chest")
        C.bone(f"wing2.{side}", (0.5 * mx, 0.1, 1.2), (0.9 * mx, 0.3, 1.25), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))
        for k, (ln, wd, dy) in enumerate(((0.95, 0.24, 0.0), (0.7, 0.17, 0.22))):
            pts = []
            for i in range(12):
                a = math.pi * i / 11
                u = (1 - math.cos(a)) / 2
                pts.append((sh[0] + mx * u * ln, sh[1] + dy + 0.12 + math.sin(a) * wd * (1 if True else 0) * 1.0 - 0.05,
                            sh[2] + 0.04 + u * 0.12))
            for i in range(10, 0, -1):
                a = math.pi * i / 11
                u = (1 - math.cos(a)) / 2
                pts.append((sh[0] + mx * u * ln, sh[1] + dy + 0.1 - math.sin(a) * wd * 0.25,
                            sh[2] + 0.04 + u * 0.12))
            if mx < 0:
                pts = pts[::-1]
            C.membrane(f"Wing{side}{k}", pts, "wing", None, thick=0.012,
                       allowed=[f"wing.{side}", f"wing2.{side}"])
