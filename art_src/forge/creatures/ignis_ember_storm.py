"""Ignis, the Ember Storm (Ember Flats, 9, legend): a great fire dragon. Sculpted body: a deep barrel chest
and powerful haunches, digitigrade hind legs, an S-curved neck, a wedge skull with heavy brow ridges and
swept horns, crimson scales over a molten-gold belly, raised ember-veined wings and a tail tipped in fire."""
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(horn="2a1614", horn2="5a3a30", tooth="f4ead8", claw="1a1010", eye="fff0a0", pupil="2a0a04",
              socket="1a0404", wing="b8301a", wingdark="5a1010", wingbone="3a0e0a", fire="ff6a1a", hot="ffd03a",
              glow="ff9a2a")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.45
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.38, 0.9), (0, 0.0, 0.98), "root")
    C.bone("chest", (0, 0.0, 0.98), (0, -0.36, 1.1), "hips")
    C.bone("neck", (0, -0.36, 1.1), (0, -0.5, 1.4), "chest")
    C.bone("neck2", (0, -0.5, 1.4), (0, -0.58, 1.66), "neck")
    C.bone("head", (0, -0.58, 1.66), (0, -1.0, 1.68), "neck2")
    C.bone("jaw", (0, -0.62, 1.6), (0, -0.98, 1.55), "head")
    C.spine, C.neck, C.head, C.jaw = ["hips", "chest"], ["neck", "neck2"], "head", "jaw"
    tail = [(0, 0.38, 0.9), (0, 0.72, 0.8), (0, 1.0, 0.64), (0.14, 1.24, 0.52), (0.34, 1.38, 0.5)]
    for i in range(4):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg_b.{side}", (0.26 * sx, 0.38, 0.85), (0.32 * sx, 0.16, 0.48), "hips")
        C.bone(f"shin_b.{side}", (0.32 * sx, 0.16, 0.48), (0.3 * sx, 0.4, 0.15), f"leg_b.{side}")
        C.bone(f"leg_f.{side}", (0.28 * sx, -0.3, 0.95), (0.33 * sx, -0.2, 0.55), "chest")
        C.bone(f"shin_f.{side}", (0.33 * sx, -0.2, 0.55), (0.31 * sx, -0.38, 0.14), f"leg_f.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.03)
    cl.add((0, -0.2, 1.0), (0.33, 0.4, 0.35), rot=(-12, 0, 0), group="scale")          # barrel chest
    cl.mirror((0.2, -0.36, 0.98), (0.15, 0.17, 0.19), rot=(0, 0, 15), group="scale")   # pectorals
    cl.add((0, 0.12, 0.88), (0.27, 0.32, 0.28), group="scale")                         # belly
    cl.add((0, 0.4, 0.92), (0.27, 0.27, 0.27), group="scale")                          # pelvis
    cl.add((0, -0.08, 1.24), (0.18, 0.4, 0.1), rot=(-10, 0, 0), group="dark")          # dorsal ridge mass
    cl.mirror((0.24, 0.32, 0.74), (0.18, 0.27, 0.31), rot=(-25, 0, 0), group="scale")   # thighs
    cl.mirror((0.2, -0.3, 1.08), (0.14, 0.16, 0.14), group="dark")                     # shoulder blades
    for sx in (-1, 1):
        # hind legs: shin back to the heel, then the foot forward
        cl.chain([(0.32 * sx, 0.16, 0.48), (0.31 * sx, 0.3, 0.3), (0.3 * sx, 0.4, 0.15)], [0.125, 0.095, 0.075],
                 group="scale")
        cl.chain([(0.3 * sx, 0.4, 0.12), (0.3 * sx, 0.26, 0.06), (0.3 * sx, 0.14, 0.05)], [0.08, 0.085, 0.075],
                 group="scale")
        for k in (-1, 0, 1):
            cl.add((0.3 * sx + 0.06 * k, 0.07, 0.04), (0.035, 0.07, 0.035), rot=(0, 0, 20 * k * sx), group="scale")
        # forelegs: shoulder, elbow, wrist, hand
        cl.chain([(0.28 * sx, -0.3, 0.92), (0.33 * sx, -0.2, 0.55), (0.31 * sx, -0.38, 0.14)], [0.16, 0.115, 0.085],
                 group="scale")
        cl.add((0.31 * sx, -0.45, 0.06), (0.095, 0.12, 0.06), group="scale")
        for k in (-1, 0, 1):
            cl.add((0.31 * sx + 0.05 * k, -0.54, 0.04), (0.03, 0.06, 0.03), rot=(0, 0, 15 * k * sx), group="scale")
    # neck: thick at the shoulders, curving up; a paler throat underneath
    cl.chain([(0, -0.36, 1.12), (0, -0.5, 1.4), (0, -0.57, 1.62)], [(0.2, 0.2, 0.2), 0.15, 0.13], group="scale")
    cl.chain([(0, -0.42, 1.06), (0, -0.58, 1.36), (0, -0.66, 1.56)], [0.12, 0.1, 0.08], group="belly")
    # head: cranium, cheeks, brow ridges, long snout, lower jaw, carved mouth line and eye sockets
    cl.add((0, -0.66, 1.73), (0.18, 0.2, 0.155), group="scale")
    cl.mirror((0.12, -0.72, 1.65), (0.085, 0.12, 0.085), group="scale")
    cl.mirror((0.08, -0.79, 1.79), (0.065, 0.12, 0.045), rot=(-8, 0, -12), group="dark")
    cl.chain([(0, -0.78, 1.72), (0, -0.92, 1.7), (0, -1.04, 1.67)], [(0.13, 0.12, 0.105), (0.105, 0.095, 0.085),
                                                                      (0.085, 0.07, 0.065)], group="scale")
    cl.mirror((0.045, -1.04, 1.7), (0.03, 0.035, 0.03), group="dark")
    cl.chain([(0, -0.66, 1.6), (0, -0.84, 1.59), (0, -1.0, 1.59)], [(0.12, 0.12, 0.07), (0.095, 0.095, 0.06),
                                                                    (0.065, 0.06, 0.042)], group="belly")
    cl.add((0, -0.92, 1.632), (0.08, 0.16, 0.018), group="scale", neg=True)
    cl.mirror((0.075, -0.77, 1.735), (0.035, 0.035, 0.028), group="scale", neg=True)
    cl.chain(tail, [0.2, 0.15, 0.1, 0.065, 0.035], group="scale")
    body = cl.build({"scale": "9a1c12", "dark": "4a0c0a", "belly": "ffb03a"}, voxel=0.017, budget=11000,
                    texture={"type": 'VORONOI', "scale": 0.035, "strength": 0.012})
    # golden belly plates from throat to tail root, darker scales along the spine
    recolor(body, lambda p, n: smoothstep(-0.4, -0.8, n.z) * (1.0 if -0.75 < p.y < 0.75 and p.z > 0.55 else 0.0),
            "ffb03a")
    recolor(body, lambda p, n: smoothstep(0.75, 0.97, n.z) * (1.0 if p.z > 0.9 else 0.0) * 0.7, "4a0c0a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Socket{mx}", (0.085 * mx, -0.78, 1.74), (0.04, 0.04, 0.028), "socket", "head")
        C.ellipsoid(f"Eye{mx}", (0.095 * mx, -0.795, 1.742), (0.032, 0.036, 0.02), "eye", "head", rot=(0, 0, 25 * mx))
        C.ellipsoid(f"Pupil{mx}", (0.11 * mx, -0.81, 1.742), (0.006, 0.015, 0.018), "pupil", "head", rot=(0, 0, 25 * mx))
        base = V((0.09 * mx, -0.62, 1.82))
        pts = [base, base + V((0.1 * mx, 0.16, 0.14)), base + V((0.17 * mx, 0.42, 0.2)), base + V((0.2 * mx, 0.68, 0.12))]
        C.tube(f"Horn{mx}", pts, [0.065, 0.05, 0.03, 0.004], "horn", "head")
        for k in range(3):
            p = V(pts[0]).lerp(V(pts[1]), 0.4) if k == 0 else V(pts[k])
            C.ellipsoid(f"HornRing{mx}{k}", tuple(p), (0.045 - 0.01 * k,) * 2 + (0.012,), "horn2", "head")
        b2 = V((0.13 * mx, -0.66, 1.72))
        C.tube(f"HornB{mx}", [b2, b2 + V((0.1 * mx, 0.12, 0.02)), b2 + V((0.14 * mx, 0.26, -0.04))], [0.03, 0.018, 0.003],
               "horn", "head")
        for k in range(3):
            C.cone(f"Frill{mx}{k}", (0.15 * mx, -0.66 + 0.04 * k, 1.63 + 0.04 * k),
                   (0.3 * mx, -0.56 + 0.06 * k, 1.6 + 0.09 * k), 0.032, "horn", "head", segs=5)
        C.cone(f"JawSpike{mx}", (0.09 * mx, -0.7, 1.56), (0.15 * mx, -0.64, 1.47), 0.022, "horn", "jaw", segs=5)
        C.cone(f"Fang{mx}", (0.055 * mx, -0.94, 1.64), (0.055 * mx, -0.95, 1.575), 0.016, "tooth", "head", segs=5)
    for k in range(6):
        y = -0.98 + 0.06 * k
        for mx in (-1, 1):
            x = (0.04 + 0.012 * k) * mx
            C.cone(f"ToothU{k}{mx}", (x, y, 1.64), (x, y - 0.005, 1.6), 0.011, "tooth", "head", segs=4)
            C.cone(f"ToothL{k}{mx}", (x * 0.92, y + 0.01, 1.615), (x * 0.92, y + 0.005, 1.645), 0.009, "tooth", "jaw", segs=4)
    # back spines from the skull to the tail, curved and shrinking
    spine_pts = [(-0.62, 1.84, 0.1), (-0.56, 1.62, 0.12), (-0.5, 1.45, 0.14), (-0.42, 1.28, 0.16), (-0.28, 1.27, 0.18),
                 (-0.1, 1.22, 0.19), (0.08, 1.16, 0.18), (0.26, 1.12, 0.16), (0.46, 1.04, 0.13), (0.7, 0.94, 0.1),
                 (0.92, 0.8, 0.08), (1.1, 0.68, 0.06)]
    for k, (y, z, h) in enumerate(spine_pts):
        bone = ("head" if y < -0.6 else "neck2" if y < -0.52 else "neck" if y < -0.38 else "chest" if y < 0.0 else
                "hips" if y < 0.5 else "tail1" if y < 0.75 else "tail2" if y < 1.0 else "tail3")
        C.tube(f"Spine{k}", [V((0, y, z - 0.03)), V((0, y + h * 0.5, z + h * 0.9)), V((0, y + h * 1.3, z + h * 1.5))],
               [h * 0.42, h * 0.22, 0.004], "horn", bone)
    for sx, side in ((-1, "L"), (1, "R")):
        for k in (-1, 0, 1):
            C.cone(f"ClawB{side}{k}", (0.3 * sx + 0.06 * k, 0.02, 0.05), (0.3 * sx + 0.07 * k, -0.06, 0.0), 0.022, "claw",
                   f"shin_b.{side}", segs=5)
            C.cone(f"ClawF{side}{k}", (0.31 * sx + 0.05 * k, -0.6, 0.04), (0.31 * sx + 0.06 * k, -0.67, 0.0), 0.018,
                   "claw", f"shin_f.{side}", segs=5)
    # wings: arm and finger bones, a scalloped membrane with a darker trailing edge
    for side, mx in (("L", -1), ("R", 1)):
        sh = V((0.22 * mx, -0.16, 1.24))
        el = V((0.62 * mx, -0.02, 1.78))
        tip = V((1.05 * mx, 0.26, 2.08))
        C.bone(f"wing.{side}", tuple(sh), tuple(el), "chest")
        C.bone(f"wing2.{side}", tuple(el), tuple(tip), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))
        C.tube(f"WingArm{side}", [sh, (sh + el) / 2 + V((0, -0.03, 0.04)), el], [0.075, 0.055, 0.045], "wingbone", None,
               allowed=[f"wing.{side}"])
        C.cone(f"WingThumb{side}", tuple(el), tuple(el + V((0.02 * mx, -0.1, 0.1))), 0.03, "horn", f"wing2.{side}", segs=5)
        fingers = [tip, el + V((0.42 * mx, 0.42, -0.05)), el + V((0.3 * mx, 0.55, -0.42)), el + V((0.12 * mx, 0.5, -0.72))]
        for k, ft in enumerate(fingers):
            C.tube(f"Finger{side}{k}", [el, (el + ft) / 2 + V((0, 0.02, 0.03)), ft], [0.035, 0.025, 0.008], "wingbone",
                   f"wing2.{side}")
        root_back = V((0.12 * mx, 0.28, 1.02))
        outline = [sh, el, fingers[0]]
        for k in range(1, len(fingers)):
            mid = (fingers[k - 1] + fingers[k]) / 2
            outline += [mid.lerp(el, 0.28), fingers[k]]
        outline += [(fingers[-1] + root_back) / 2 + V((0, 0.02, 0.08)), root_back]
        outline = [tuple(p) for p in outline]
        if mx < 0:
            outline = outline[::-1]
        C.membrane(f"Wing{side}", outline, "wing", None, thick=0.022, allowed=[f"wing.{side}", f"wing2.{side}"])
        for k in range(1, len(fingers)):
            a, b = fingers[k - 1], fingers[k]
            C.tube(f"Edge{side}{k}", [a, ((a + b) / 2).lerp(el, 0.28), b], [0.012, 0.016, 0.012], "wingdark",
                   f"wing2.{side}")
    # lower the whole dragon onto shorter, heavier legs (feet stay on the ground)
    from forge.sculpt import smoothstep as _ss
    C.warp(lambda p: V((p.x, p.y, p.z - 0.14 * _ss(0.05, 0.75, p.z))))
    # fire: tail tip, embers between the teeth, glowing seams on the chest
    props.flame(C, tail[-1], 0.2, "tail4", "fire", "hot", n=5, lean=(0.6, 0.6, 0.4), name="TailFire", m_core="glow")
    props.flame(C, (0, -0.98, 1.6), 0.05, "jaw", "fire", "hot", n=3, lean=(0, -0.4, 0.3), name="Breath")
