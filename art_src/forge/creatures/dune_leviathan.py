"""Dune Leviathan (Sunny Dunes, 9): a colossal sandworm rearing out of the dunes, armoured ring segments
crusted with sand, a three-petal maw that opens into rings of hooked teeth, and treasure it has swallowed
glinting between its plates."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(hide="b8905a", plate="8a6a3a", sand="e8c888", maw="5a1a1a", tooth="f0e8d0", gold="ffd23a",
              gem="3ad8ff", dark="1a0a08", eye="ff6a1a")
    C.plan, C.attack = "biped", "ram"
    # a body rising out of a mound: root -> chain of four segments curving up and forward
    pts = [V((0, 0.25, 0.1)), V((0, 0.22, 0.55)), V((0, 0.05, 1.0)), V((0, -0.2, 1.38)), V((0, -0.45, 1.58))]
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("base", (0, 0.2, 0), (0, 0.2, 0.2), None)    # the dune itself stays put while the worm moves
    C.bone("hips", tuple(pts[0]), tuple(pts[1]), "root")
    C.bone("chest", tuple(pts[1]), tuple(pts[2]), "hips")
    C.bone("neck", tuple(pts[2]), tuple(pts[3]), "chest")
    C.bone("head", tuple(pts[3]), tuple(pts[4]), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    radii = [0.42, 0.38, 0.34, 0.32, 0.3]
    C.tube("Body", pts, radii, "hide", None, res=14)
    # ring plates along the body
    for k in range(9):
        t = k / 8
        i = min(int(t * 4), 3)
        u = t * 4 - i
        p = pts[i].lerp(pts[i + 1], u)
        d = (pts[i + 1] - pts[i]).normalized()
        r = radii[i] + (radii[i + 1] - radii[i]) * u
        bone = ["hips", "chest", "neck", "head"][i]
        C.lathe(f"Ring{k}", [(r * 1.02, -0.05), (r * 1.1, 0.0), (r * 1.04, 0.06)], "plate", bone, segs=20)
        ob = C.parts[-1][0]
        q = V((0, 0, 1)).rotation_difference(d)
        ob.data.transform(__import__("mathutils").Matrix.Translation(p) @ q.to_matrix().to_4x4())
    # three-petal maw at the top, facing forward and down
    tip = pts[4]
    fwd = V((0, -0.75, 0.35)).normalized()
    C.lathe("Throat", [(0.22, 0.0), (0.24, 0.06), (0.001, 0.07)], "maw", "head", segs=18)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(tip + fwd * 0.04) @
                                  V((0, 0, 1)).rotation_difference(fwd).to_matrix().to_4x4())
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 2
        side = V((math.cos(a), 0, math.sin(a)))
        side = side - fwd * side.dot(fwd)
        side.normalize()
        base = tip + side * 0.26
        C.tube(f"Petal{k}", [base, base + fwd * 0.2 + side * 0.18, base + fwd * 0.38 + side * 0.06],
               [0.12, 0.08, 0.01], "hide", "head")
        for j in range(4):
            tb = tip + side * 0.17 + fwd * 0.05 + side.cross(fwd) * (0.07 * (j - 1.5))
            C.cone(f"Tooth{k}{j}", tuple(tb), tuple(tb - side * 0.13 + fwd * 0.06), 0.025, "tooth", "head", segs=4)
    # small burning eyes around the maw
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(tip + V((0.24 * mx, 0.02, 0.18))), (0.035, 0.03, 0.03), "eye", "head")
    # the dune it bursts from, with swallowed treasure
    C.ellipsoid("Mound", (0, 0.2, -0.02), (0.75, 0.7, 0.2), "sand", "base")
    for k in range(6):
        a = 2 * math.pi * k / 6
        C.ellipsoid(f"Drift{k}", (math.cos(a) * 0.55, 0.2 + math.sin(a) * 0.5, 0.08), (0.2, 0.2, 0.1), "sand", "base")
    for k, (x, y, m) in enumerate([(0.4, -0.1, "gold"), (-0.35, 0.4, "gold"), (0.2, 0.6, "gem"), (-0.5, 0.0, "gold")]):
        C.ellipsoid(f"Treasure{k}", (x, y, 0.13), (0.05, 0.05, 0.02), m, "base")
