"""Grand Fence (Sunny Dunes, 4): a heavyset dealer in stolen goods. Sculpted: a big-bellied, broad man in
a rich striped robe that sweeps to the floor, a heavy jowled face with a thick moustache, a tall jewelled
turban, gold chains on his chest and rings on his fingers, a ledger of debts in one hand and a fat sack of
loot slung over his shoulder."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(skin="b07850", robe="5a2a8a", stripe="ffcf3a", turban="2a8a7a", gem="ff2a4a", gold="ffd23a", eye="1a1008",
              dark="1a0e08", sack="b8905a", rope="6a4a2a", book="6a1a1a", page="f0e8d0")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.74, chest=1.18, head=1.46, lean=0.02, shoulder_x=0.3, hip_x=0.15,
                          r_chest=(0.3, 0.26, 0.26), r_waist=(0.34, 0.32, 0.24), r_hips=(0.32, 0.3, 0.16),
                          r_head=(0.13, 0.13, 0.14), r_arm=(0.09, 0.08), r_hand=0.06, r_leg=(0.12, 0.1),
                          r_foot=(0.08, 0.12, 0.05), arm_len=0.52, group="robe")
    h = at["head"]
    cl.chain([(0, 0.0, 0.7), (0, 0.02, 0.36), (0, 0.04, 0.08)], [(0.32, 0.3, 0.2), (0.34, 0.32, 0.2), (0.36, 0.34, 0.08)],
             group="robe")
    cl.add((0, -0.12, 0.98), (0.3, 0.26, 0.26), group="robe")                         # big belly
    cl.add((0, h.y - 0.02, h.z - 0.02), (0.13, 0.13, 0.14), group="skin")
    cl.mirror((0.08, h.y - 0.07, h.z - 0.08), (0.06, 0.06, 0.06), group="skin")        # jowls
    cl.add((0, h.y - 0.13, h.z - 0.01), (0.03, 0.04, 0.035), group="skin")             # nose
    cl.mirror((0.045, h.y - 0.12, h.z + 0.04), (0.022, 0.02, 0.018), group="skin", neg=True)
    for k in range(7):                                                         # tall turban wraps
        cl.add((0, h.y + 0.01, h.z + 0.1 + 0.035 * k), (0.15 - 0.012 * k, 0.15 - 0.012 * k, 0.05), rot=(0, 10 * (k % 2), 0),
               group="turban")
    body = cl.build({"robe": "robe", "skin": "skin", "turban": "turban"}, voxel=0.011, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.006})
    recolor(body, lambda p, n: smoothstep(0.6, 0.85, math.sin(math.atan2(p.x, p.y) * 9)) * (1.0 if p.z < 1.3 else 0.0) * 0.9,
            "stripe")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, h.y - 0.135, h.z + 0.04), (0.016, 0.008, 0.01), "eye", "head")
        C.tube(f"Moustache{mx}", [h + V((0.0, -0.15, -0.04)), h + V((0.06 * mx, -0.15, -0.05)), h + V((0.11 * mx, -0.12, -0.02))],
               [0.018, 0.016, 0.004], "dark", "head")
    C.ellipsoid("TurbanGem", tuple(h + V((0, -0.14, 0.16))), (0.03, 0.015, 0.035), "gem", "head")
    C.cone("TurbanPlume", tuple(h + V((0, -0.1, 0.3))), tuple(h + V((0.04, -0.06, 0.48))), 0.03, "gold", "head", segs=5)
    for k in range(3):
        pts = [V((-0.2 + 0.02 * k, -0.24 - 0.02 * k, 1.34 - 0.04 * k)), V((0, -0.36 - 0.02 * k, 1.12 - 0.05 * k)),
               V((0.2 - 0.02 * k, -0.24 - 0.02 * k, 1.34 - 0.04 * k))]
        C.tube(f"Chain{k}", pts, [0.012] * 3, "gold", "chest")
    hl = at["hdL"]
    C.box("Ledger", tuple(hl + V((0, -0.06, 0.06))), (0.16, 0.05, 0.2), "book", "forearm.L", rot=(-20, 0, 0), bevel=0.2)
    C.box("LedgerPages", tuple(hl + V((0, -0.09, 0.06))), (0.14, 0.02, 0.18), "page", "forearm.L", rot=(-20, 0, 0), bevel=0.2)
    sh = at["shR"]
    C.ellipsoid("Sack", tuple(sh + V((0.06, 0.22, 0.12))), (0.2, 0.2, 0.24), "sack", "arm.R", rot=(20, 0, 0))
    C.tube("SackNeck", [sh + V((0.02, 0.02, 0.1)), sh + V((0.04, 0.12, 0.28))], [0.04, 0.03], "rope", "arm.R")
    for mx in (-1, 1):
        C.ellipsoid(f"Ring{mx}", tuple(at["hd" + ("L" if mx < 0 else "R")] + V((0, -0.05, 0.0))), (0.02,) * 3, "gold",
                    f"forearm.{'L' if mx < 0 else 'R'}")
