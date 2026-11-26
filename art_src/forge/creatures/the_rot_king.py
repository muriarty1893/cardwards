"""The Rot King (Mushroom Forest, 6, legend): a floating dead king, skull face lit green from within,
crown of rotten antlers sprouting toadstools, tattered royal robes, a scepter with a festering orb."""
from forge import kits, props


def build(C):
    C.palette(robe="3a2a4a", rot="5a7a2a", bone="d8cfb0", glow="a8ff3a", dark="0c100a", gold="b8902a",
              toad="c23a2a", spot="f0e8d0", wood="3a2a20")
    C.attack = "cast"
    kits.biped(C, "robe", hip=1.0, chest=1.55, neck=1.76, head_top=2.1, shoulder_x=0.34, hip_x=0.15,
               hand=(0.55, -0.12, 1.0), r_hip=0.3, r_waist=0.24, r_chest=0.34, r_neck=0.08, r_head=0.17,
               r_arm=0.09, r_hand=0.06, lean=0.06, legs=False, hover=0.35)
    h = C.anch["head"]
    # skull face with green glow inside
    C.ellipsoid("Skull", (0, h[1] - 0.02, h[2]), (0.16, 0.18, 0.18), "bone", "head")
    C.ellipsoid("Jaw", (0, h[1] - 0.1, h[2] - 0.15), (0.1, 0.09, 0.06), "bone", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Socket{mx}", (0.06 * mx, h[1] - 0.16, h[2] + 0.01), (0.045, 0.03, 0.045), "dark", "head")
        C.ellipsoid(f"Glow{mx}", (0.06 * mx, h[1] - 0.18, h[2] + 0.01), (0.022, 0.012, 0.022), "glow", "head")
    C.ellipsoid("Nose", (0, h[1] - 0.18, h[2] - 0.06), (0.02, 0.015, 0.03), "dark", "head")
    for k in range(5):
        x = -0.06 + 0.03 * k
        C.box(f"Tooth{k}", (x, h[1] - 0.17, h[2] - 0.12), (0.02, 0.02, 0.035), "bone", "head", bevel=0.3)
    # rotten antler crown with toadstools
    props.crown(C, (0, h[1], h[2] + 0.12), 0.15, "gold", "head", points=5, height=0.12, m_gem="glow")
    for mx in (-1, 1):
        C.tube(f"Antler{mx}", [(0.1 * mx, h[1], h[2] + 0.2), (0.26 * mx, h[1] + 0.04, h[2] + 0.4),
                               (0.42 * mx, h[1] - 0.02, h[2] + 0.56)], [0.03, 0.022, 0.006], "rot", "head")
        C.tube(f"AntlerB{mx}", [(0.24 * mx, h[1] + 0.04, h[2] + 0.37), (0.28 * mx, h[1] + 0.14, h[2] + 0.58)],
               [0.018, 0.005], "rot", "head")
        C.ellipsoid(f"Toad{mx}", (0.32 * mx, h[1] + 0.0, h[2] + 0.5), (0.07, 0.07, 0.035), "toad", "head")
        C.ellipsoid(f"ToadSpot{mx}", (0.32 * mx, h[1] - 0.02, h[2] + 0.53), (0.015, 0.015, 0.008), "spot", "head")
    # tattered royal robe: mantle with fur trim and dangling rags
    c = C.anch["chest"]
    C.ellipsoid("Mantle", (0, c[1] + 0.04, c[2] + 0.1), (0.38, 0.28, 0.12), "robe", "chest")
    import math
    for k in range(11):
        a = 2 * math.pi * k / 11
        b = (math.cos(a) * 0.3, c[1] + 0.04 + math.sin(a) * 0.22, c[2] + 0.14)
        C.cone(f"Collar{k}", b, (math.cos(a) * 0.5, b[1] + math.sin(a) * 0.16, b[2] + 0.12 + 0.06 * (k % 2)), 0.08,
               "rot", "chest", segs=4)
    for k in range(8):
        import math
        a = math.pi * (k / 7) * 1.6 - 0.8 * math.pi + math.pi / 2
        b = (math.cos(a) * 0.32, math.sin(a) * 0.26 + c[1], c[2] - 0.2)
        C.cone(f"Rag{k}", b, (b[0] * 1.15, b[1] * 1.1, b[2] - 0.45 - 0.12 * (k % 3)), 0.09, "robe", "hips", segs=4)
    props.cape(C, "robe", c[2] + 0.12, width=0.34, length=1.5, back_y=0.18, flare=0.25)
    # scepter with a festering orb
    props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=1.1, up=0.55, top="orb", m_top="glow", top_r=0.09)
    # bony clawed hands
    for side in ("L", "R"):
        hd = C.anch["hd" + side]
        C.ellipsoid(f"Hand{side}", hd, (0.07, 0.07, 0.07), "bone", f"forearm.{side}")
