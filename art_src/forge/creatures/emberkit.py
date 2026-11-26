"""Emberkit (Ember Flats, 2): a sly fire fox kit. Sculpted: a lean, low-slung fox with a narrow pointed
muzzle and a knowing grin, ember-orange fur with a cream chest, legs fading to soot, tall ears with
glowing tips and three bushy burning tails fanned out behind. Sand Fox reuses it with one plain tail and
enormous fennec ears."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C, tails=3, fire=True, big_ears=False):
    C.palette(fur="e8682a", fur2="fff0d8", soot="2a1a14", eye="ffe23a", pupil="1a0a08", tip="ffd03a", fire_m="ff6a1a",
              hot="ffd03a", nose="1a0e0a")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.24, 0.42), chest=(-0.18, 0.46), r_chest=(0.15, 0.2, 0.17), r_belly=(0.12, 0.2, 0.12),
                         r_hips=(0.13, 0.15, 0.14), leg_x=0.11, r_thigh=0.07, r_shin=0.035, r_paw=0.045, paw_len=1.4,
                         neck=((-0.3, 0.58),), r_neck=(0.09,), head=(-0.42, 0.66), r_head=(0.13, 0.12, 0.11),
                         snout=(-0.64, 0.6), r_snout=(0.065, 0.042), tail=((0.4, 0.5),), r_tail=(0.05, 0.04),
                         group="fur", belly_group="fur2", jaw=True)
    h, s = at["head"], at["snout"]
    ear_h = 0.34 if big_ears else 0.2
    ear_w = 0.11 if big_ears else 0.06
    for sx in (-1, 1):
        cl.add((0.08 * sx, h.y - 0.06, h.z - 0.05), (0.07, 0.07, 0.05), group="fur2")                      # cheek ruff
        cl.chain([(0.07 * sx, h.y + 0.02, h.z + 0.07), (0.12 * sx, h.y + 0.04, h.z + 0.07 + ear_h * 0.55),
                  (0.15 * sx, h.y + 0.05, h.z + 0.07 + ear_h)], [(ear_w, 0.025, ear_w * 0.8), (ear_w * 0.7, 0.02, 0.05),
                                                                  0.008], group="fur")
        cl.add((0.065 * sx, h.y - 0.09, h.z + 0.02), (0.028, 0.025, 0.02), group="fur", neg=True)
    cl.add((0, -0.24, 0.42), (0.1, 0.08, 0.12), group="fur2")                                                   # chest
    body = cl.build({"fur": "fur", "fur2": "fur2"}, voxel=0.011, budget=8000,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(0.22, 0.08, p.z), "soot")
    recolor(body, lambda p, n: smoothstep(h.z + 0.07 + ear_h * 0.6, h.z + 0.07 + ear_h, p.z), "tip")
    skulpt.eyes(C, [(0.065, h.y - 0.11, h.z + 0.02)], 0.026, "eye", "pupil", slit=True)
    C.ellipsoid("Nose", tuple(s + V((0, -0.03, 0.02))), (0.022, 0.016, 0.016), "nose", "head")
    C.box("Grin", tuple(s + V((0.01, 0.02, -0.025))), (0.07, 0.01, 0.006), "nose", "head", rot=(0, -10, 15), bevel=0.4)
    # bushy tails fanned out behind, burning at the tips
    tl = Clay(C, "Tails", res=0.018)
    root = V((0, 0.36, 0.48))
    for k in range(tails):
        a = math.radians((k - (tails - 1) / 2) * 32)
        d = V((math.sin(a) * 0.9, math.cos(a) * 0.55, 0.45)).normalized()
        pts = [root, root + d * 0.18 + V((0, 0, 0.04)), root + d * 0.38 + V((0, 0, 0.06)), root + d * 0.52]
        tl.chain(pts, [0.05, 0.085, 0.075, 0.02], group="fur")
        if fire:
            props.flame(C, tuple(root + d * 0.54), 0.12, "tail1", "fire_m", "hot", n=3, lean=tuple(d * 0.6),
                        name=f"TailFire{k}")
    tb = tl.build({"fur": "fur", "tip": "tip"}, voxel=0.01, budget=3000, texture={"type": 'CLOUDS', "scale": 0.03,
                                                                                    "strength": 0.012},
                  bone="tail1")
    recolor(tb, lambda p, n: smoothstep(0.32, 0.5, (p - root).length), "tip" if fire else "soot")
