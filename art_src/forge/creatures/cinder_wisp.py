"""Cinder Wisp (Ember Flats, 2): a burning skull drifting on a tail of smoke and sparks, hollow sockets lit
from within, a cracked jaw that rattles when it laughs."""
from mathutils import Vector as V
from forge import props


def build(C):
    C.palette(bone="e0d4b8", crack="2a1a14", fire="ff6a1a", hot="ffd03a", core="fff4c0", smoke="4a3a3a", dark="140a08")
    C.plan, C.attack, C.hover = "hover", "dive", 0.35
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.4), (0, 0.05, 0.7), "root")
    C.bone("chest", (0, 0.05, 0.7), (0, 0, 0.85), "hips")
    C.bone("head", (0, 0, 0.85), (0, -0.25, 0.9), "chest")
    C.bone("jaw", (0, -0.05, 0.78), (0, -0.25, 0.76), "head")
    C.bone("tail1", (0, 0.1, 0.4), (0, 0.18, 0.15), "hips")
    C.spine, C.head, C.jaw, C.tail = ["hips", "chest"], "head", "jaw", ["tail1"]
    h = V((0, -0.02, 0.92))
    C.ellipsoid("Skull", tuple(h), (0.2, 0.22, 0.19), "bone", "head")
    C.ellipsoid("Cheek", tuple(h + V((0, -0.12, -0.08))), (0.15, 0.1, 0.08), "bone", "head")
    C.ellipsoid("Jaw", tuple(h + V((0, -0.12, -0.17))), (0.12, 0.1, 0.05), "bone", "jaw")
    for mx in (-1, 1):
        C.ellipsoid(f"Socket{mx}", tuple(h + V((0.075 * mx, -0.17, 0.01))), (0.06, 0.04, 0.055), "dark", "head")
        C.ellipsoid(f"Glow{mx}", tuple(h + V((0.075 * mx, -0.19, 0.01))), (0.03, 0.02, 0.03), "hot", "head")
    C.ellipsoid("NoseHole", tuple(h + V((0, -0.2, -0.06))), (0.025, 0.02, 0.03), "dark", "head")
    for k in range(4):
        C.box(f"Tooth{k}", tuple(h + V((-0.045 + 0.03 * k, -0.2, -0.12))), (0.022, 0.02, 0.03), "bone", "head", bevel=0.3)
    C.box("Crack", tuple(h + V((0.06, -0.08, 0.15))), (0.02, 0.1, 0.012), "crack", "head", rot=(0, 30, 20), bevel=0.3)
    props.flame(C, h + V((0, 0.06, 0.12)), 0.22, "head", "fire", "hot", n=6, lean=(0, 0.5, 0), m_core="core")
    # tail of smoke and sparks
    C.tube("Smoke", [V((0, 0.06, 0.72)), V((0, 0.12, 0.45)), V((0, 0.2, 0.18))], [0.12, 0.08, 0.02], "smoke", None,
           allowed=["hips", "tail1"])
    for k in range(4):
        C.ellipsoid(f"Spark{k}", (0.08 * (k % 2 * 2 - 1), 0.12 + 0.05 * k, 0.6 - 0.1 * k), (0.025,) * 3, "hot",
                    "tail1" if k > 1 else "hips")
