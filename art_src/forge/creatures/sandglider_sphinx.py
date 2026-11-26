"""Sandglider Sphinx (Sunny Dunes, 6, legend): a winged lion-sphinx of the dunes. Sculpted: a powerful lion
body with a deep chest, heavy shoulders and great clawed forepaws, a proud feline face with kohl-lined
eyes under a striped gold-and-blue pharaoh headdress, a braided beard, a jewelled collar, a tufted tail,
and great falcon wings of gold built from overlapping rows of feathers."""
import math
from mathutils import Vector as V
from forge import kits
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="e0a84a", blue="1a3a8a", gold="ffd23a", kohl="0a0a14", eye="3affd8", wing="f0c050",
              wingtip="b8701a", gem="ff2a4a", claw="2a1a0a", feather2="d89a30")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.4
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.36, 0.74), (0, 0.0, 0.82), "root")
    C.bone("chest", (0, 0.0, 0.82), (0, -0.3, 0.9), "hips")
    C.bone("neck", (0, -0.3, 0.92), (0, -0.44, 1.14), "chest")
    C.bone("head", (0, -0.44, 1.14), (0, -0.74, 1.18), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    tail = [(0, 0.56, 0.76), (0, 0.8, 0.66), (0, 0.98, 0.8), (0, 1.06, 1.02)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        legs[side] = dict(f=[(0.22 * sx, -0.3, 0.72), (0.24 * sx, -0.32, 0.36), (0.24 * sx, -0.42, 0.05)],
                          b=[(0.22 * sx, 0.4, 0.7), (0.24 * sx, 0.24, 0.38), (0.24 * sx, 0.44, 0.05)])
        f, b = legs[side]["f"], legs[side]["b"]
        C.bone(f"leg_f.{side}", f[0], f[1], "chest")
        C.bone(f"shin_f.{side}", f[1], f[2], f"leg_f.{side}")
        C.bone(f"leg_b.{side}", b[0], b[1], "hips")
        C.bone(f"shin_b.{side}", b[1], b[2], f"leg_b.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    # ---- sculpted body: a lion
    cl = Clay(C, "Body", res=0.026)
    cl.add((0, -0.22, 0.82), (0.29, 0.3, 0.29), rot=(-10, 0, 0), group="hide")       # deep chest
    cl.mirror((0.2, -0.3, 0.8), (0.12, 0.16, 0.2), group="hide")                     # shoulders
    cl.add((0, 0.12, 0.78), (0.22, 0.3, 0.2), group="hide")                          # tucked waist
    cl.add((0, 0.4, 0.78), (0.24, 0.22, 0.22), group="hide")                         # haunches
    cl.mirror((0.16, 0.42, 0.66), (0.12, 0.2, 0.22), rot=(-20, 0, 0), group="hide")  # thighs
    cl.add((0, -0.12, 0.6), (0.2, 0.4, 0.08), group="belly")
    for sx in (-1, 1):
        f, b = legs["L" if sx < 0 else "R"]["f"], legs["L" if sx < 0 else "R"]["b"]
        cl.chain(f, [0.11, 0.08, 0.07], group="hide")
        cl.add((f[2][0], f[2][1] - 0.04, 0.05), (0.09, 0.1, 0.055), group="hide")    # great forepaw
        cl.chain(b, [0.1, 0.07, 0.065], group="hide")
        cl.add((b[2][0], b[2][1] - 0.04, 0.05), (0.08, 0.09, 0.05), group="hide")
    cl.chain([(0, -0.3, 0.94), (0, -0.44, 1.14)], [0.15, 0.13], group="hide")
    # feline face: broad skull, brow, short muzzle with whisker pads, strong chin
    cl.add((0, -0.52, 1.2), (0.15, 0.15, 0.14), group="hide")
    cl.mirror((0.06, -0.62, 1.24), (0.06, 0.05, 0.03), rot=(0, 0, -12), group="hide")    # brow
    cl.add((0, -0.66, 1.13), (0.075, 0.07, 0.065), group="hide")                         # muzzle
    cl.mirror((0.04, -0.7, 1.11), (0.04, 0.035, 0.035), group="muzzle")                  # whisker pads
    cl.add((0, -0.68, 1.06), (0.04, 0.035, 0.03), group="muzzle")                        # chin
    cl.mirror((0.065, -0.64, 1.2), (0.028, 0.025, 0.02), group="hide", neg=True)         # eye sockets
    cl.chain(tail, [0.055, 0.04, 0.03, 0.02], group="hide")
    cl.add(tail[-1], (0.05, 0.05, 0.08), group="tuft")
    body = cl.build({"hide": "d0902e", "belly": "f0c878", "muzzle": "f0d098", "tuft": "7a3a10"}, voxel=0.014,
                    budget=11000, texture={"type": 'CLOUDS', "scale": 0.06, "strength": 0.006})
    recolor(body, lambda p, n: smoothstep(0.7, 1.0, n.z) * 0.4 * (1.0 if p.z < 1.0 else 0.0), "c8883a")

    # ---- crisp details: headdress, collar, beard
    cr = V((0, -0.52, 1.24))
    C.ellipsoid("Nemes", tuple(cr + V((0, 0.02, 0.06))), (0.18, 0.18, 0.13), "gold", "head")
    for mx in (-1, 1):
        C.box(f"Flap{mx}", tuple(cr + V((0.15 * mx, 0.0, -0.17))), (0.06, 0.15, 0.3), "gold", "head",
              rot=(0, -8 * mx, 0), bevel=0.3, taper=(1.4, 1.2))
        for k in range(3):
            C.box(f"FlapStripe{mx}{k}", tuple(cr + V((0.165 * mx, 0.0, -0.08 - 0.09 * k))), (0.065, 0.16, 0.03), "blue",
                  "head", rot=(0, -8 * mx, 0), bevel=0.3)
        C.ellipsoid(f"Eye{mx}", (0.065 * mx, -0.655, 1.2), (0.03, 0.014, 0.018), "eye", "head")
        C.box(f"Kohl{mx}", (0.08 * mx, -0.655, 1.2), (0.09, 0.016, 0.01), "kohl", "head", rot=(0, -12 * mx, 0), bevel=0.3)
        for k in (-1, 0, 1):
            f = V(legs["L" if mx < 0 else "R"]["f"][2])
            C.cone(f"Claw{mx}{k}", (f.x + 0.04 * k, f.y - 0.12, 0.05), (f.x + 0.05 * k, f.y - 0.18, 0.01), 0.016, "claw",
                   f"shin_f.{'L' if mx < 0 else 'R'}", segs=5)
    for k in range(3):
        C.box(f"NemesStripe{k}", tuple(cr + V((0, 0.02, 0.14 - 0.05 * k))), (0.36 - 0.03 * k, 0.32, 0.022), "blue",
              "head", bevel=0.3)
    C.cone("Uraeus", tuple(cr + V((0, -0.16, 0.12))), tuple(cr + V((0, -0.2, 0.24))), 0.03, "gold", "head", segs=6)
    C.ellipsoid("UraeusGem", tuple(cr + V((0, -0.18, 0.14))), (0.022, 0.012, 0.022), "gem", "head")
    C.ellipsoid("Nose", (0, -0.73, 1.14), (0.025, 0.015, 0.018), "kohl", "head")
    C.tube("Beard", [V((0, -0.68, 1.04)), V((0, -0.68, 0.94)), V((0, -0.66, 0.84))], [0.035, 0.03, 0.026], "blue",
           "head")
    for k in range(3):
        C.ellipsoid(f"BeardBand{k}", (0, -0.68, 1.0 - 0.06 * k), (0.038, 0.038, 0.01), "gold", "head")
    for k in range(9):                                                         # jewelled collar of plates
        a = math.pi * (0.1 + 0.8 * k / 8)
        p = V((math.cos(a) * 0.17, -0.38 - math.sin(a) * 0.1, 1.0 - math.sin(a) * 0.08))
        C.box(f"Collar{k}", tuple(p), (0.07, 0.03, 0.09), "gold" if k % 2 else "blue", "chest",
              rot=(20, 0, math.degrees(a) - 90), bevel=0.3)
    C.ellipsoid("CollarGem", (0, -0.5, 0.9), (0.045, 0.025, 0.045), "gem", "chest")
    # falcon wings: a gold membrane under overlapping rows of feathers
    kits.wings(C, "wingtip", "wing", shoulder=(0.16, -0.12, 0.98), span=0.72, up=0.85, sweep=0.45, r=0.036, droop=0.75,
               fingers=3)
    for side, mx in (("L", -1), ("R", 1)):
        sh = V(C.bones[f"wing.{side}"]["head"])
        el = V(C.bones[f"wing2.{side}"]["head"])
        tip = V(C.bones[f"wing2.{side}"]["tail"])
        edge = [sh.lerp(el, t) for t in (0.3, 0.6, 0.9)] + [el.lerp(tip, t) for t in (0.2, 0.45, 0.7, 0.95)]
        for k, p in enumerate(edge):
            bone = f"wing.{side}" if k < 3 else f"wing2.{side}"
            ln = 0.3 + 0.07 * k
            d = V((0.2 * mx * (k / 6), 0.85, -0.45 + 0.08 * k)).normalized()
            C.cone(f"Primary{side}{k}", tuple(p), tuple(p + d * ln), 0.05, "wingtip", bone, segs=4)
            C.cone(f"Covert{side}{k}", tuple(p + V((0, -0.02, 0.02))), tuple(p + d * ln * 0.5), 0.055, "feather2", bone,
                   segs=4)
