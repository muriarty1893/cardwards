"""Vexa, the Grudgekeeper (Ember Flats, 7, legend): a tall fire warlock. Sculpted: a slender, imperious
figure in a fitted crimson bodice and a long split robe whose hem smoulders into embers, a high spiked
collar, a horned hood framing a gaunt pale face with eyes like coals, chains of old debts hanging from her
belt ending in padlocks, a burning ledger of grudges floating over one hand and a gnarled wand."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(trim="b8862a", dark="0b0809", eye="ffb02a", page="f0e0b8", fire="ff5a1a", hot="ffd03a",
              chain="5a5458", horn="1e1416", wood="2a1a14", lip="5a0a10")
    C.plan, C.attack, C.hover = "hover", "cast", 0.25
    # ---- skeleton
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.02, 1.0), (0, 0.0, 1.32), "root")
    C.bone("chest", (0, 0.0, 1.32), (0, -0.03, 1.6), "hips")
    C.bone("neck", (0, -0.03, 1.6), (0, -0.05, 1.74), "chest")
    C.bone("head", (0, -0.05, 1.74), (0, -0.05, 2.02), "neck")
    C.bone("tail1", (0, 0.02, 1.0), (0, 0.1, 0.56), "hips")
    C.bone("tail2", (0, 0.1, 0.56), (0, 0.2, 0.14), "tail1")
    C.spine, C.neck, C.head, C.tail = ["hips", "chest"], ["neck"], "head", ["tail1", "tail2"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.24 * sx, 0.0, 1.56), (0.4 * sx, -0.02, 1.3), "chest")
        C.bone(f"forearm.{side}", (0.4 * sx, -0.02, 1.3), (0.46 * sx, -0.2, 1.08), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.024)
    cl.add((0, 0.0, 1.46), (0.19, 0.13, 0.17), group="bodice")                 # ribcage
    cl.mirror((0.075, -0.1, 1.44), (0.07, 0.06, 0.06), group="bodice")         # bust
    cl.add((0, 0.01, 1.24), (0.12, 0.1, 0.12), group="bodice")                 # cinched waist
    cl.mirror((0.22, 0.0, 1.56), (0.08, 0.08, 0.07), group="bodice")          # shoulders
    cl.add((0, 0.02, 1.08), (0.2, 0.16, 0.1), group="robe")                    # hips
    # long robe flaring to the floor, split open at the front
    cl.chain([(0, 0.04, 1.0), (0, 0.08, 0.66), (0, 0.14, 0.34), (0, 0.2, 0.1)],
             [(0.22, 0.17, 0.2), (0.28, 0.23, 0.2), (0.34, 0.3, 0.18), (0.42, 0.37, 0.1)], group="robe")
    for k in range(10):
        a = 2 * math.pi * k / 10
        for j, (z, r) in enumerate([(0.86, 0.22), (0.52, 0.3), (0.22, 0.38)]):
            cl.add((math.cos(a) * r, 0.1 + 0.05 * j + math.sin(a) * r * 0.85, z), (0.045, 0.045, 0.2),
                   rot=(0, 0, math.degrees(a)), group="robe")
    cl.add((0, -0.3, 0.42), (0.1, 0.12, 0.5), rot=(-15, 0, 0), group="under", neg=True)    # front split
    cl.add((0, -0.12, 0.5), (0.13, 0.06, 0.45), rot=(-12, 0, 0), group="under")            # dark underskirt
    # high spiked collar fanning behind the head
    for k in range(7):
        a = math.pi * (0.08 + 0.84 * k / 6)
        cl.add((math.cos(a) * 0.17, 0.07 + math.sin(a) * 0.05, 1.78), (0.05, 0.025, 0.17),
               rot=(-20, -math.degrees(math.cos(a)) * 0.7, 0), group="robe")
    for sx in (-1, 1):                                                         # slim arms, flared cuffs
        cl.chain([(0.24 * sx, 0.0, 1.56), (0.4 * sx, -0.02, 1.3)], [0.06, 0.055], group="bodice")
        cl.chain([(0.4 * sx, -0.02, 1.3), (0.45 * sx, -0.16, 1.12)], [0.055, (0.1, 0.1, 0.07)], group="robe")
        cl.add((0.46 * sx, -0.19, 1.09), (0.04, 0.045, 0.05), group="skin")
    cl.add((0, -0.03, 1.66), (0.05, 0.05, 0.07), group="skin")                 # neck
    cl.add((0, -0.06, 1.82), (0.09, 0.1, 0.12), group="skin")                  # gaunt face
    cl.mirror((0.055, -0.13, 1.8), (0.03, 0.03, 0.025), group="skin")          # cheekbones
    cl.add((0, -0.12, 1.72), (0.04, 0.04, 0.03), group="skin")                 # pointed chin
    cl.mirror((0.04, -0.15, 1.84), (0.024, 0.02, 0.016), group="skin", neg=True)   # sunken eyes
    cl.add((0, 0.02, 1.88), (0.16, 0.16, 0.17), group="robe")                  # hood
    cl.add((0, -0.12, 1.83), (0.115, 0.1, 0.15), group="robe", neg=True)       # hood opening
    body = cl.build({"bodice": "5a0f18", "robe": "3a0a10", "under": "140608", "skin": "c8a898"}, voxel=0.012,
                    budget=12000, relax=3, texture={"type": 'CLOUDS', "scale": 0.08, "strength": 0.006})
    # smouldering hem: ember cracks and a charred edge; gold trim on the bodice
    recolor(body, lambda p, n: smoothstep(0.35, 0.05, p.z) * 0.9, "1a0806")
    recolor(body, lambda p, n: cracks(p, 0.08, 0.06, seed=9) * smoothstep(0.4, 0.08, p.z), "ff6a1a")
    recolor(body, lambda p, n: (1.0 if 1.15 < p.z < 1.19 and p.y < 0.05 else 0.0), "b8862a")
    recolor(body, lambda p, n: (1.0 if abs(abs(p.x) - 0.05 - (1.5 - p.z) * 0.12) < 0.012 and 1.2 < p.z < 1.55
                                and p.y < -0.05 else 0.0), "b8862a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.04 * mx, -0.155, 1.84), (0.018, 0.008, 0.01), "eye", "head")
        C.tube(f"HoodHorn{mx}", [V((0.1 * mx, -0.02, 1.98)), V((0.22 * mx, 0.06, 2.12)), V((0.24 * mx, 0.2, 2.26)),
                                 V((0.2 * mx, 0.32, 2.3))], [0.04, 0.03, 0.018, 0.003], "horn", "head")
        C.ellipsoid(f"Mantle{mx}", (0.25 * mx, 0.0, 1.6), (0.12, 0.13, 0.06), "trim", f"arm.{'L' if mx < 0 else 'R'}",
                    rot=(0, -22 * mx, 0))
        C.cone(f"MSpike{mx}", (0.27 * mx, 0.0, 1.64), (0.4 * mx, 0.04, 1.8), 0.035, "horn",
               f"arm.{'L' if mx < 0 else 'R'}", segs=5)
    C.ellipsoid("Lips", (0, -0.155, 1.765), (0.022, 0.008, 0.007), "lip", "head")
    C.ellipsoid("HoodGem", (0, -0.14, 1.99), (0.028, 0.015, 0.035), "hot", "head")
    for k, x in enumerate((-0.17, 0.05, 0.19)):                                 # chains of debts
        pts = [V((x, -0.14, 1.12)), V((x * 1.2, -0.25, 0.86)), V((x * 1.3, -0.32, 0.6 - 0.08 * k))]
        C.tube(f"Chain{k}", pts, [0.018, 0.018, 0.018], "chain", "hips")
        for j in range(4):
            C.ellipsoid(f"Link{k}{j}", tuple(pts[0].lerp(pts[2], 0.15 + 0.22 * j)), (0.026, 0.026, 0.026), "chain",
                        "hips")
        C.box(f"Lock{k}", tuple(pts[-1] + V((0, 0, -0.06))), (0.08, 0.04, 0.09), "trim", "hips", bevel=0.3)
    hl = V((-0.46, -0.22, 1.06))
    book = hl + V((0.02, -0.16, 0.18))
    C.box("Book", tuple(book), (0.26, 0.18, 0.05), "horn", "forearm.L", rot=(-25, 0, 0), bevel=0.2)
    C.box("Pages", tuple(book + V((0, 0, 0.03))), (0.24, 0.16, 0.03), "page", "forearm.L", rot=(-25, 0, 0), bevel=0.1)
    props.flame(C, book + V((0, 0, 0.05)), 0.14, "forearm.L", "fire", "hot", n=5, name="BookFire")
    hr = V((0.46, -0.22, 1.06))
    C.tube("Wand", [hr + V((0, 0.05, -0.1)), hr + V((0, -0.1, 0.12)), hr + V((0.02, -0.2, 0.38))],
           [0.022, 0.02, 0.013], "wood", "forearm.R")
    props.flame(C, hr + V((0.02, -0.2, 0.38)), 0.08, "forearm.R", "fire", "hot", n=3, name="WandFire")
    for k in range(9):                                                         # embers drifting off the hem
        a = 2 * math.pi * k / 9
        p = V((math.cos(a) * 0.46, 0.2 + math.sin(a) * 0.4, 0.12 + 0.1 * (k % 3)))
        C.ellipsoid(f"Ember{k}", tuple(p), (0.018,) * 3, "fire" if k % 2 else "hot", "tail2")
