"""Mycel the Gravekeeper (Mushroom Forest, 5, legend): a tall gaunt undertaker. Sculpted: a stooped,
long-limbed figure in a long grave coat with a high collar and split tails over thin legs and heavy boots,
a pale hollow-cheeked face with glowing eyes shadowed by a broad spotted mushroom hat-cap, shelf fungi
growing from the shoulders, mycelium threads creeping up the coat, and a hooked lantern staff glowing with
spores."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(cap="6a4a2a", capspot="e8e0c8", gill="d8c8a0", eye="9dff5a", dark="0d0c10", wood="3a2a1f",
              glow="b8ff5a", shelf="b5763a", trim="4a3f52", skin="cfc7b0")
    C.plan, C.attack = "biped", "cast"
    # ---- skeleton (faces -y), stooped
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.02, 0.96), (0, -0.02, 1.26), "root")
    C.bone("chest", (0, -0.02, 1.26), (0, -0.12, 1.58), "hips")
    C.bone("neck", (0, -0.12, 1.58), (0, -0.2, 1.72), "chest")
    C.bone("head", (0, -0.2, 1.72), (0, -0.22, 1.98), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        sh, el, hd = (0.27 * sx, -0.08, 1.56), (0.38 * sx, -0.06, 1.24), (0.44 * sx, -0.18, 0.98)
        C.bone(f"arm.{side}", sh, el, "chest")
        C.bone(f"forearm.{side}", el, hd, f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
        C.anch["hd" + side] = hd
        C.bone(f"leg.{side}", (0.12 * sx, 0.02, 0.94), (0.13 * sx, -0.04, 0.5), "hips")
        C.bone(f"shin.{side}", (0.13 * sx, -0.04, 0.5), (0.13 * sx, 0.02, 0.06), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.024)
    cl.add((0, -0.06, 1.42), (0.21, 0.14, 0.2), rot=(-15, 0, 0), group="coat")         # narrow chest
    cl.mirror((0.22, -0.06, 1.54), (0.09, 0.1, 0.08), group="coat")                    # bony shoulders
    cl.add((0, 0.02, 1.16), (0.17, 0.13, 0.16), group="coat")                          # waist
    # long coat skirts, split at front and back into tails that hang to the shins
    for sx in (-1, 1):
        cl.chain([(0.1 * sx, 0.02, 1.02), (0.15 * sx, 0.04, 0.7), (0.19 * sx, 0.06, 0.4)],
                 [(0.13, 0.15, 0.12), (0.15, 0.17, 0.14), (0.17, 0.18, 0.08)], group="coat")
        for k in range(3):
            cl.add((0.2 * sx, -0.06 + 0.1 * k, 0.6), (0.035, 0.035, 0.24), group="coat")      # folds
        # long thin arms in sleeves, bony hands
        cl.chain([(0.27 * sx, -0.08, 1.56), (0.38 * sx, -0.06, 1.24), (0.43 * sx, -0.16, 1.02)],
                 [0.065, 0.06, (0.08, 0.08, 0.05)], group="coat")
        cl.chain([(0.44 * sx, -0.19, 0.98), (0.45 * sx, -0.22, 0.92)], [0.035, 0.03], group="skin")
        # thin legs, heavy boots
        cl.chain([(0.13 * sx, -0.04, 0.5), (0.13 * sx, 0.02, 0.16)], [0.06, 0.055], group="trousers")
        cl.add((0.13 * sx, -0.04, 0.07), (0.075, 0.13, 0.07), group="boot")
        cl.add((0.13 * sx, 0.0, 0.2), (0.07, 0.07, 0.1), group="boot")
    cl.add((0, 0.02, 0.4), (0.04, 0.06, 0.2), group="coat", neg=True)          # split up the back
    # high collar and gaunt head
    for k in range(5):
        a = math.pi * (0.1 + 0.8 * k / 4)
        cl.add((math.cos(a) * 0.13, -0.06 + math.sin(a) * 0.06, 1.7), (0.05, 0.025, 0.12),
               rot=(-15, -math.degrees(math.cos(a)) * 0.6, 0), group="trim")
    cl.add((0, -0.16, 1.66), (0.045, 0.045, 0.07), group="skin")               # neck
    cl.add((0, -0.24, 1.82), (0.1, 0.11, 0.13), group="skin")                  # long skull
    cl.add((0, -0.3, 1.72), (0.05, 0.05, 0.04), group="skin")                  # long chin
    cl.mirror((0.06, -0.31, 1.78), (0.03, 0.025, 0.035), group="skin", neg=True)   # hollow cheeks
    cl.mirror((0.045, -0.32, 1.85), (0.03, 0.022, 0.022), group="skin", neg=True)  # sunken eyes
    cl.add((0, -0.36, 1.82), (0.016, 0.03, 0.035), group="skin")               # nose
    body = cl.build({"coat": "2a2630", "trim": "4a3f52", "skin": "cfc7b0", "trousers": "1a1820", "boot": "1a120c"},
                    voxel=0.012, budget=12000, relax=3, texture={"type": 'CLOUDS', "scale": 0.07, "strength": 0.005})
    # pale mycelium threads creeping up the coat from the hem
    recolor(body, lambda p, n: cracks(p, 0.07, 0.04, seed=7) * smoothstep(0.75, 0.3, p.z) * (1.0 if p.z > 0.32 else 0.0)
            * 0.8, "d8d0b8")
    recolor(body, lambda p, n: smoothstep(0.035, 0.0, abs(p.x)) * (1.0 if p.y < -0.1 and 1.0 < p.z < 1.6 else 0.0),
            "4a3f52")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, -0.325, 1.85), (0.018, 0.01, 0.013), "eye", "head")
    C.box("Mouth", (0, -0.335, 1.75), (0.06, 0.012, 0.008), "dark", "head", bevel=0.3)
    h = V((0, -0.24, 1.82))
    C.lathe("Cap", [(0.001, h.z + 0.08), (0.42, h.z + 0.04), (0.5, h.z + 0.08), (0.44, h.z + 0.18),
                    (0.24, h.z + 0.32), (0.001, h.z + 0.36)], "cap", "head", segs=30, wave=(5, 0.1, 0.38))
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y, 0)))
    C.lathe("Gills", [(0.1, h.z + 0.08), (0.48, h.z + 0.075)], "gill", "head", segs=30)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y, 0)))
    for k, (x, y) in enumerate([(0.15, -0.12), (-0.2, 0.05), (0.05, 0.22), (-0.05, -0.28), (0.28, 0.15), (-0.3, -0.1)]):
        C.decal(f"CapSpot{k}", x, 3.0, (0.05, 0.05, 0.02), "capspot", "head", part="Cap", dir=(0, 0, -1), y=h.y + y)
    for k in range(3):
        C.ellipsoid(f"Button{k}", (0, -0.2 + 0.02 * k, 1.42 - 0.13 * k), (0.022, 0.012, 0.022), "capspot", "chest")
    for side, mx in (("L", -1), ("R", 1)):
        for k in range(3):
            C.ellipsoid(f"Shelf{side}{k}", (0.26 * mx, -0.04 + 0.06 * k, 1.64 - 0.09 * k),
                        (0.13 - 0.025 * k, 0.1 - 0.02 * k, 0.035), "shelf", f"arm.{side}", rot=(0, -15 * mx, 0))
        for k in range(4):
            C.tube(f"Finger{side}{k}", [V((0.45 * mx + 0.012 * (k - 1.5), -0.23, 0.92)),
                                        V((0.46 * mx + 0.02 * (k - 1.5), -0.27, 0.84)),
                                        V((0.46 * mx + 0.024 * (k - 1.5), -0.25, 0.77))], [0.012, 0.01, 0.004], "skin",
                   f"forearm.{side}")
    props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=2.0, up=1.0, top="hook", m_top="glow")
    for k in range(6):                                                         # spores drifting from the lantern
        a = 2 * math.pi * k / 6
        C.ellipsoid(f"Spore{k}", (0.44 + math.cos(a) * 0.14, -0.2 + math.sin(a) * 0.1, 2.0 + 0.08 * (k % 3)),
                    (0.016,) * 3, "glow", "forearm.R")
