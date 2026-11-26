"""Mycel the Gravekeeper (Mushroom Forest, 5, legend): a tall gaunt undertaker under a broad fungal
hat-cap, long grave coat, shelf fungi on the shoulders, a hooked lantern staff glowing with spores."""
from forge import kits, props


def build(C):
    C.palette(coat="2a2630", trim="4a3f52", skin="cfc7b0", cap="6a4a2a", capspot="e8e0c8", gill="d8c8a0",
              eye="9dff5a", dark="0d0c10", wood="3a2a1f", glow="b8ff5a", shelf="b5763a")
    C.attack = "cast"
    kits.biped(C, "coat", hip=0.95, chest=1.5, neck=1.72, head_top=2.08, shoulder_x=0.3, hip_x=0.14,
               hand=(0.46, -0.1, 0.92), r_hip=0.22, r_waist=0.18, r_chest=0.28, r_neck=0.08, r_head=0.17,
               r_arm=0.075, r_hand=0.07, r_leg=0.09, r_foot=0.09, lean=0.1)
    h = C.anch["head"]
    props.robe(C, "coat", top_z=1.0, bottom_r=0.42, top_r=0.24, hem=0.05, wave=9)
    # pale gaunt face with glowing eyes, shadowed by the cap brim
    C.ellipsoid("Face", (0, h[1] - 0.1, h[2] - 0.02), (0.13, 0.1, 0.15), "skin", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Socket{mx}", (0.055 * mx, h[1] - 0.18, h[2] + 0.02), (0.04, 0.02, 0.03), "dark", "head")
        C.ellipsoid(f"Eye{mx}", (0.055 * mx, h[1] - 0.195, h[2] + 0.02), (0.022, 0.012, 0.016), "eye", "head")
    C.box("Mouth", (0, h[1] - 0.19, h[2] - 0.09), (0.08, 0.02, 0.012), "dark", "head", bevel=0.3)
    # broad mushroom hat-cap
    C.lathe("Cap", [(0.001, h[2] + 0.1), (0.42, h[2] + 0.06), (0.5, h[2] + 0.1), (0.44, h[2] + 0.2),
                    (0.24, h[2] + 0.34), (0.001, h[2] + 0.38)], "cap", "head", segs=30, wave=(5, 0.1, 0.38))
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h[1], 0)))
    C.lathe("Gills", [(0.1, h[2] + 0.1), (0.48, h[2] + 0.095)], "gill", "head", segs=30)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h[1], 0)))
    for k, (x, y) in enumerate([(0.15, -0.12), (-0.2, 0.05), (0.05, 0.22), (-0.05, -0.28), (0.28, 0.15)]):
        C.decal(f"CapSpot{k}", x, 3.0, (0.05, 0.05, 0.02), "capspot", "head", part="Cap", dir=(0, 0, -1), y=h[1] + y)
    # coat collar and buttons
    c = C.anch["chest"]
    C.lathe("Collar", [(0.2, c[2] + 0.08), (0.3, c[2] + 0.2), (0.26, c[2] + 0.28)], "trim", "chest", segs=20)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, c[1], 0)))
    for k in range(3):
        C.decal(f"Button{k}", 0, c[2] - 0.05 - 0.15 * k, (0.03, 0.03, 0.02), "capspot", "chest")
    # shelf fungi growing from the shoulders
    for side, mx in (("L", -1), ("R", 1)):
        sh = C.anch["sh" + side]
        for k in range(3):
            C.ellipsoid(f"Shelf{side}{k}", (sh[0] + 0.05 * mx, sh[1] + 0.02 + 0.06 * k, sh[2] + 0.08 - 0.09 * k),
                        (0.13 - 0.025 * k, 0.1 - 0.02 * k, 0.035), "shelf", f"arm.{side}", rot=(0, -15 * mx, 0))
    # hooked lantern staff in the right hand
    props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=2.0, up=1.0, top="hook", m_top="glow")
    props.cape(C, "trim", C.anch["chest"][2] + 0.1, width=0.28, back_y=0.2, flare=0.2)
