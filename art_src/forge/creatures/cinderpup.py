"""Cinderpup (Ember Flats, 1): a scrappy ash-grey hellhound pup. Sculpted: a stocky little body on
oversized paws, a big blocky head with a short muzzle and a scowling brow, tall pointed ears, glowing
cracks smouldering along its back, ember eyes, little fangs and a tail that burns at the tip. Snow Pup
reuses it in frost colours (the palette decides the look)."""
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep, cracks


def build(C, tails=1, ears=0.26, frost=False):
    C.palette(fur="4a4044", fur2="2a2428", crack="ff5a1a", eye="ffcf3a", nose="140c0c", fire="ff6a1a", hot="ffd03a",
              fang="f0e8d8", pupil="1a0a04")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.22, 0.42), chest=(-0.16, 0.46), r_chest=(0.19, 0.2, 0.19), r_belly=(0.16, 0.2, 0.15),
                         r_hips=(0.16, 0.16, 0.15), leg_x=0.14, r_thigh=0.085, r_shin=0.05, r_paw=0.075, paw_len=1.3,
                         neck=((-0.28, 0.58),), r_neck=(0.12,), head=(-0.42, 0.68), r_head=(0.16, 0.15, 0.14),
                         snout=(-0.64, 0.62), r_snout=(0.085, 0.07), tail=((0.42, 0.56), (0.52, 0.74)),
                         r_tail=(0.05, 0.03), group="fur", jaw=True)
    h, s = at["head"], at["snout"]
    for sx in (-1, 1):
        cl.add((0.07 * sx, h.y - 0.1, h.z + 0.07), (0.07, 0.05, 0.035), rot=(0, 0, -15 * sx), group="fur2")   # brow
        cl.add((0.08 * sx, h.y - 0.11, h.z + 0.03), (0.035, 0.03, 0.028), group="fur", neg=True)            # sockets
        cl.chain([(0.1 * sx, h.y + 0.02, h.z + 0.1), (0.14 * sx, h.y + 0.05, h.z + 0.1 + ears * 0.6),
                  (0.16 * sx, h.y + 0.07, h.z + 0.1 + ears)], [(0.06, 0.03, 0.05), (0.045, 0.02, 0.04), 0.008],
                 group="fur")                                                                                 # ears
        cl.add((0.1 * sx, h.y - 0.02, h.z - 0.06), (0.06, 0.06, 0.05), group="fur")                         # cheeks
    cl.add(tuple(s + V((0, 0.03, -0.05))), (0.07, 0.07, 0.035), group="fur2")                                # jaw
    cl.add(tuple(s + V((0, -0.01, -0.03))), (0.06, 0.05, 0.006), group="fur2", neg=True)                    # mouth
    cl.add(tuple(at["back"] + V((0, 0.0, -0.04))), (0.08, 0.3, 0.05), group="fur2")                         # dark spine
    body = cl.build({"fur": "fur", "fur2": "fur2"}, voxel=0.012, budget=9000,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.012})
    recolor(body, lambda p, n: cracks(p, 0.09, 0.08, seed=11) * smoothstep(0.35, 0.8, n.z) * (1.0 if p.y > -0.3 and p.z > 0.45 else 0.0),
            "crack")
    recolor(body, lambda p, n: smoothstep(0.2, 0.05, p.z) * 0.6, "fur2")
    skulpt.eyes(C, [(0.08, h.y - 0.135, h.z + 0.03)], 0.03, "eye", "pupil", slit=True)
    C.ellipsoid("Nose", tuple(s + V((0, -0.06, 0.02))), (0.035, 0.025, 0.025), "nose", "head")
    for mx in (-1, 1):
        C.cone(f"Fang{mx}", tuple(s + V((0.035 * mx, -0.04, -0.03))), tuple(s + V((0.035 * mx, -0.045, -0.09))), 0.014,
               "fang", "head", segs=4)
    tip = at["tail"][-1]
    props.flame(C, tuple(tip), 0.14, "tail2", "fire", "hot", n=4, lean=(0, 0.3, 0.6), name="TailFire")
