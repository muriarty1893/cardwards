"""Sculpted body kits: a skeleton plus a Clay body for the common shapes (four-legged animals, upright
walkers, floating spirits, flyers and fish). A kit sets the bones, adds the clay lumps of the basic body
and returns the open Clay, so a recipe adds its own lumps (horns, crests, armour ridges, carved eyes)
before calling build(). Everything faces -y, feet on z = 0.

    cl, at = skulpt.quad(C, length=1.2, height=0.9, ...)
    cl.add(at["head"] + V((0, -0.1, 0.1)), (0.05, 0.05, 0.05), group="horn")
    body = cl.build({...})
"""
import math
from mathutils import Vector as V
from .sculpt import Clay


def _v(p):
    return V(p) if not isinstance(p, V) else p.copy()


def quad(C, *, hip=(0.4, 0.9), chest=(-0.3, 0.95), r_chest=(0.27, 0.3, 0.3), r_belly=(0.25, 0.3, 0.25),
         r_hips=(0.25, 0.24, 0.25), leg_x=0.2, r_thigh=0.13, r_shin=0.07, r_paw=0.08, paw_len=1.2,
         neck=((-0.42, 1.1), (-0.58, 1.3)), r_neck=(0.16, 0.12), head=(-0.72, 1.32), r_head=(0.14, 0.15, 0.13),
         snout=None, r_snout=(0.08, 0.07), tail=((0.62, 0.95), (0.86, 0.8)), r_tail=(0.08, 0.03),
         digi=True, res=0.028, jaw=False, group="hide", belly_group=None, hump=None):
    """Four legs. hip/chest/head/neck as (y, z). snout: (y, z) of the nose tip (default ahead of the head).
    digi: hind legs bend back at the hock. Returns (clay, anchors)."""
    C.plan = C.plan if C.plan in ("flyer", "swimmer", "hover") else "quad"
    hy, hz = hip
    cy, cz = chest
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, hy, hz), (0, (hy + cy) / 2, (hz + cz) / 2), "root")
    C.bone("chest", (0, (hy + cy) / 2, (hz + cz) / 2), (0, cy, cz), "hips")
    pts = [V((0, cy, cz))] + [V((0, y, z)) for (y, z) in neck]
    prev = "chest"
    C.neck = []
    for i in range(len(pts) - 1):
        nm = "neck" if i == 0 else f"neck{i + 1}"
        C.bone(nm, tuple(pts[i]), tuple(pts[i + 1]), prev)
        C.neck.append(nm)
        prev = nm
    hd = V((0, head[0], head[1]))
    sn = V((0, snout[0], snout[1])) if snout else hd + V((0, -r_head[1] * 1.6, -r_head[2] * 0.4))
    C.bone("head", tuple(pts[-1]), tuple(sn), prev)
    if jaw:
        C.bone("jaw", tuple(hd + V((0, -r_head[1] * 0.3, -r_head[2] * 0.6))), tuple(sn + V((0, 0, -r_head[2] * 0.5))),
               "head")
        C.jaw = "jaw"
    C.spine, C.head = ["hips", "chest"], "head"
    tp = [V((0, hy + 0.15, hz))] + [V((0, y, z)) for (y, z) in tail]
    C.tail = []
    for i in range(len(tp) - 1):
        C.bone(f"tail{i + 1}", tuple(tp[i]), tuple(tp[i + 1]), "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        x = leg_x * sx
        fk = cz * 0.48
        bk = hz * 0.5
        f = [V((x, cy, cz - r_chest[2] * 0.4)), V((x, cy - 0.02, fk)), V((x, cy - 0.04, 0.05))]
        if digi:
            b = [V((x, hy, hz - r_hips[2] * 0.3)), V((x, hy - 0.14, bk + 0.05)), V((x, hy + 0.08, bk * 0.55)),
                 V((x, hy + 0.04, 0.05))]
        else:
            b = [V((x, hy, hz - r_hips[2] * 0.3)), V((x, hy + 0.02, bk)), V((x, hy, 0.05))]
        legs[side] = dict(f=f, b=b)
        C.bone(f"leg_f.{side}", tuple(f[0]), tuple(f[1]), "chest")
        C.bone(f"shin_f.{side}", tuple(f[1]), tuple(f[2]), f"leg_f.{side}")
        C.bone(f"leg_b.{side}", tuple(b[0]), tuple(b[1]), "hips")
        C.bone(f"shin_b.{side}", tuple(b[1]), tuple(b[-1]), f"leg_b.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    g, bg = group, belly_group or group
    cl = Clay(C, "Body", res=res)
    cl.add((0, cy, cz), r_chest, group=g)
    cl.add((0, (hy + cy) / 2, (hz + cz) / 2 - 0.02), r_belly, group=g)
    cl.add((0, hy, hz), r_hips, group=g)
    if belly_group:
        cl.add((0, (hy + cy) / 2 - 0.05, min(hz, cz) - r_belly[2] * 0.55), (r_belly[0] * 0.7, abs(hy - cy) * 0.55,
                                                                           r_belly[2] * 0.4), group=bg)
    cl.mirror((r_chest[0] * 0.7, cy - 0.02, cz - 0.02), (r_chest[0] * 0.45, r_chest[1] * 0.5, r_chest[2] * 0.6),
              group=g)                                                                     # shoulders
    cl.mirror((r_hips[0] * 0.65, hy + 0.02, hz - 0.05), (r_hips[0] * 0.5, r_hips[1] * 0.75, r_hips[2] * 0.8),
              rot=(-15, 0, 0), group=g)                                                     # haunches
    if hump:
        cl.add((0, cy + 0.05, cz + r_chest[2] * 0.75), hump, group=g)
    rn = list(r_neck) + [r_neck[-1]] * (len(pts) - len(r_neck))
    cl.chain(pts + [hd], rn[:len(pts)] + [r_neck[-1] * 0.9], group=g)
    cl.add(hd, r_head, group=g)
    cl.chain([hd + V((0, -r_head[1] * 0.5, -r_head[2] * 0.2)), sn], [r_snout[0], r_snout[1]], group=g)
    for side in ("L", "R"):
        f, b = legs[side]["f"], legs[side]["b"]
        cl.add(f[0].lerp(f[1], 0.35), (r_thigh * 1.25, r_thigh * 1.35, r_thigh * 1.7), group=g)     # upper-leg muscle
        cl.add(b[0].lerp(b[1], 0.35), (r_thigh * 1.3, r_thigh * 1.5, r_thigh * 1.8), group=g)
        cl.chain(f, [r_thigh * 0.95, r_shin, r_shin * 0.9], group=g)
        cl.add(f[-1] + V((0, -0.03 * paw_len, 0.0)), (r_paw, r_paw * paw_len, r_paw * 0.6), group=g)
        if digi:
            cl.chain(b, [r_thigh, r_shin * 1.1, r_shin, r_shin * 0.9], group=g)
        else:
            cl.chain(b, [r_thigh, r_shin, r_shin * 0.9], group=g)
        cl.add(b[-1] + V((0, -0.03 * paw_len, 0.0)), (r_paw, r_paw * paw_len, r_paw * 0.6), group=g)
    cl.chain(tp, [r_tail[0]] + [r_tail[0] + (r_tail[1] - r_tail[0]) * (i + 1) / (len(tp) - 1)
                                for i in range(len(tp) - 1)], group=g)
    at = {"hips": V((0, hy, hz)), "chest": V((0, cy, cz)), "head": hd, "snout": sn, "neck": pts,
          "tail": tp, "legs": legs, "back": V((0, (hy + cy) / 2, max(hz, cz) + r_belly[2] * 0.9))}
    return cl, at


def biped(C, *, hip=0.9, chest=1.35, head=1.68, lean=0.05, shoulder_x=0.3, hip_x=0.14,
          r_chest=(0.26, 0.18, 0.22), r_waist=(0.17, 0.14, 0.14), r_hips=(0.2, 0.15, 0.13), r_head=(0.13, 0.14, 0.15),
          r_arm=(0.08, 0.065), r_hand=0.06, r_leg=(0.11, 0.075), r_foot=(0.07, 0.11, 0.05), arm_len=0.55,
          hand_fwd=0.16, legs=True, hover=0.3, res=0.024, group="hide", jaw=False, digi=False):
    """Upright walker (or, legs=False, a floating spirit whose body tapers into a tail). Returns (clay, anchors)."""
    C.plan = "biped" if legs else "hover"
    if not legs:
        C.hover = hover
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    cy = -lean
    C.bone("hips", (0, 0, hip), (0, cy * 0.4, (hip + chest) / 2), "root")
    C.bone("chest", (0, cy * 0.4, (hip + chest) / 2), (0, cy, chest), "hips")
    nz = chest + (head - chest) * 0.45
    C.bone("neck", (0, cy, chest), (0, cy * 1.3, nz), "chest")
    hc = V((0, cy * 1.4 - 0.02, head))
    C.bone("head", (0, cy * 1.3, nz), tuple(hc + V((0, 0, r_head[2] * 1.4))), "neck")
    if jaw:
        C.bone("jaw", tuple(hc + V((0, -r_head[1] * 0.2, -r_head[2] * 0.5))),
               tuple(hc + V((0, -r_head[1] * 1.1, -r_head[2] * 0.9))), "head")
        C.jaw = "jaw"
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    sz = chest - r_chest[2] * 0.15
    at = {"head": hc, "chest": V((0, cy, chest - r_chest[2] * 0.4)), "hips": V((0, 0, hip))}
    cl = Clay(C, "Body", res=res)
    g = group
    cl.add(at["chest"], r_chest, rot=(-lean * 40, 0, 0), group=g)
    cl.mirror((shoulder_x * 0.85, cy, sz), (r_arm[0] * 1.5, r_arm[0] * 1.5, r_arm[0] * 1.3), group=g)
    cl.add((0, cy * 0.5, (hip + chest) / 2 - 0.05), r_waist, group=g)
    cl.add((0, 0, hip), r_hips, group=g)
    cl.chain([V((0, cy, chest)), V((0, cy * 1.3, nz)), hc], [r_head[0] * 0.55, r_head[0] * 0.5, r_head[0] * 0.6],
             group=g)
    cl.add(hc, r_head, group=g)
    for side, sx in (("L", -1), ("R", 1)):
        sh = V((shoulder_x * sx, cy, sz))
        el = sh + V((0.12 * sx, 0.02, -arm_len * 0.5))
        hd = sh + V((0.18 * sx, -hand_fwd, -arm_len))
        C.bone(f"arm.{side}", tuple(sh), tuple(el), "chest")
        C.bone(f"forearm.{side}", tuple(el), tuple(hd), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
        at["sh" + side], at["el" + side], at["hd" + side] = sh, el, hd
        cl.chain([sh, el, hd], [r_arm[0], r_arm[1], r_arm[1] * 0.9], group=g)
        cl.add(hd + V((0, -0.01, -r_hand * 0.6)), (r_hand, r_hand, r_hand * 1.1), group=g)
        if legs:
            ht = V((hip_x * sx, 0, hip - 0.04))
            if digi:
                kn = V((hip_x * sx * 1.1, -0.12, hip * 0.55))
                ft = V((hip_x * sx * 1.1, 0.06, 0.06))
            else:
                kn = V((hip_x * sx * 1.05, -0.04, hip * 0.5))
                ft = V((hip_x * sx * 1.05, 0.0, 0.06))
            C.bone(f"leg.{side}", tuple(ht), tuple(kn), "hips")
            C.bone(f"shin.{side}", tuple(kn), tuple(ft), f"leg.{side}")
            C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
            cl.chain([ht, kn, ft], [r_leg[0], r_leg[1], r_leg[1] * 0.85], group=g)
            cl.add(ft + V((0, -r_foot[1] * 0.4, -0.01)), r_foot, group=g)
            at["ft" + side] = ft
    if not legs:
        t1, t2 = V((0, 0.06, hip * 0.6)), V((0, 0.14, hip * 0.2))
        C.bone("tail1", (0, 0, hip), tuple(t1), "hips")
        C.bone("tail2", tuple(t1), tuple(t2), "tail1")
        C.tail = ["tail1", "tail2"]
        cl.chain([V((0, 0, hip)), t1, t2], [r_hips[0] * 0.9, r_hips[0] * 0.5, 0.03], group=g)
        at["tail"] = [V((0, 0, hip)), t1, t2]
    return cl, at


def wing_bones(C, shoulder, elbow, tip, parent="chest"):
    """Bones for a pair of wings (wing.S, wing2.S) from right-side points."""
    for side, sx in (("L", -1), ("R", 1)):
        m = lambda p: (p[0] * sx, p[1], p[2])
        C.bone(f"wing.{side}", m(shoulder), m(elbow), parent)
        C.bone(f"wing2.{side}", m(elbow), m(tip), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))


def eyes(C, pts, r, m_eye="eye", m_pupil=None, bone="head", slit=False, look=(0, -1, 0), seat=True):
    """Crisp eyes at right-side points (mirrored); a pupil a little in front if m_pupil. seat: the eye is
    moved onto the sculpted body's real surface (seen from the front), half sunk in, since overlapping
    clay swells past the lumps' nominal sizes."""
    lk = V(look).normalized()
    for k, p in enumerate(pts):
        for sx in (-1, 1):
            c = V((p[0] * sx, p[1], p[2]))
            if seat and any(q[0].name == "Body" for q in C.parts):
                hit, nor = C.surf(c.x, c.z, dir=tuple(-lk))
                if hit is not None and abs(hit.y - c.y) < 0.35:
                    c = hit + lk * (-r * 0.35)
            C.ellipsoid(f"Eye{k}{sx}", tuple(c), (r, r * 0.7, r * 0.85), m_eye, bone)
            if m_pupil:
                pr = (r * 0.25, r * 0.3, r * 0.75) if slit else (r * 0.45, r * 0.35, r * 0.45)
                C.ellipsoid(f"Pupil{k}{sx}", tuple(c + lk * r * 0.55), pr, m_pupil, bone)
