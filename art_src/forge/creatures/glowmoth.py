"""Glowmoth (Mushroom Forest, 2): a night moth the size of a hound, a fuzzy body, feathered antennae and broad
wings marked with glowing eye-spots that stare down whatever it hunts."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(fuzz="5a4a3a", fuzz2="c8b890", wing="3a2a4a", wing2="7a5aa8", spot="b8ff6a", spotc="1a1020",
              eye="ff8a3a", leg="2a2018")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.5
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("chest", (0, 0.05, 0.8), (0, -0.2, 0.85), "root")
    C.bone("head", (0, -0.2, 0.85), (0, -0.4, 0.86), "chest")
    C.bone("tail1", (0, 0.05, 0.8), (0, 0.4, 0.65), "chest")
    C.spine, C.head, C.tail = ["chest"], "head", ["tail1"]
    C.skin("Body", {"th": (0, -0.05, 0.82, 0.16), "hd": (0, -0.28, 0.86, 0.12)}, [("th", "hd")], "fuzz")
    C.skin("Abdomen", {"a0": (0, 0.1, 0.78, 0.12), "a1": (0, 0.3, 0.7, 0.14), "a2": (0, 0.48, 0.6, 0.06)},
           [("a0", "a1"), ("a1", "a2")], "fuzz", allowed=["tail1"])
    C.ellipsoid("Ruff", (0, -0.14, 0.86), (0.18, 0.12, 0.15), "fuzz2", "chest")
    for k in range(3):
        C.ellipsoid(f"Band{k}", (0, 0.18 + 0.12 * k, 0.75 - 0.05 * k), (0.135 - 0.02 * k, 0.03, 0.13 - 0.02 * k), "fuzz2",
                    "tail1", rot=(25, 0, 0))
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.08 * mx, -0.36, 0.9), (0.06, 0.05, 0.06), "eye", "head")
        ant = [V((0.04 * mx, -0.36, 0.96)), V((0.14 * mx, -0.48, 1.12)), V((0.26 * mx, -0.45, 1.22))]
        C.tube(f"Antenna{mx}", ant, [0.012, 0.01, 0.006], "leg", "head")
        for k in range(5):
            p = ant[1].lerp(ant[2], k / 4) if k > 1 else ant[0].lerp(ant[1], 0.5 + k * 0.25)
            C.cone(f"Feather{mx}{k}", tuple(p), tuple(p + V((0.06 * mx, -0.04, 0.03))), 0.012, "fuzz2", "head", segs=4)
        for k, y in enumerate((-0.12, 0.0, 0.1)):
            C.tube(f"Leg{mx}{k}", [V((0.08 * mx, y, 0.72)), V((0.18 * mx, y - 0.03, 0.62)), V((0.16 * mx, y, 0.48))],
                   [0.018, 0.015, 0.008], "leg", "chest")
    # broad wings with glowing eye-spots
    for side, mx in (("L", -1), ("R", 1)):
        sh = (0.1 * mx, -0.05, 0.92)
        C.bone(f"wing.{side}", sh, (0.5 * mx, 0.0, 1.05), "chest")
        C.bone(f"wing2.{side}", (0.5 * mx, 0.0, 1.05), (0.85 * mx, 0.1, 1.1), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))
        fore = [sh, (0.45 * mx, -0.32, 1.08), (0.82 * mx, -0.22, 1.12), (0.86 * mx, 0.02, 1.08), (0.35 * mx, 0.08, 0.98)]
        hind = [(0.1 * mx, 0.05, 0.9), (0.55 * mx, 0.12, 0.95), (0.6 * mx, 0.4, 0.82), (0.25 * mx, 0.4, 0.78)]
        for nm, pts, m in (("Fore", fore, "wing"), ("Hind", hind, "wing2")):
            C.membrane(f"{nm}{side}", pts[::(1 if mx > 0 else -1)], m, None, thick=0.015,
                       allowed=[f"wing.{side}", f"wing2.{side}"])
        for nm, c, r in (("SpotF", (0.55 * mx, -0.12, 1.11), 0.11), ("SpotH", (0.42 * mx, 0.24, 0.9), 0.08)):
            C.ellipsoid(f"{nm}{side}", c, (r, r, 0.02), "spot", None, allowed=[f"wing.{side}", f"wing2.{side}"])
            C.ellipsoid(f"{nm}C{side}", (c[0], c[1], c[2] + 0.012), (r * 0.45, r * 0.45, 0.02), "spotc", None,
                        allowed=[f"wing.{side}", f"wing2.{side}"])
