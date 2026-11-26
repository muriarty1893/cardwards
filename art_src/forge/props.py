"""Gear for forged creatures: robes, hoods, capes, weapons, crowns. All take anchor-based positions."""
import math
from mathutils import Vector as V, Matrix


def _orient(ob, origin, direction):
    """Moves a part built around +Z at the origin so its +Z runs along direction from origin."""
    d = V(direction).normalized()
    ob.data.transform(Matrix.Translation(V(origin)) @ V((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4())


def robe(C, m, top_z, bottom_r=0.5, top_r=0.28, hem=0.06, wave=7, front_open=False, length=None):
    """Long skirt/robe from the waist (top_z) to the floor, weighted to hips + legs."""
    bot = 0.02 if length is None else top_z - length
    prof = [(bottom_r, bot), (bottom_r * 0.92, bot + (top_z - bot) * 0.3), (top_r * 1.15, top_z - 0.12),
            (top_r, top_z)]
    allowed = ["hips"] + [l for l in ("leg.L", "leg.R", "shin.L", "shin.R") if l in C.bones]
    return C.lathe("Robe", prof, m, None, segs=28, wave=(wave, hem, bottom_r * 0.85), allowed=allowed)


def hooded_face(C, m_hood, m_dark, m_eye, head, r=0.25, eye_gap=0.07, eye_size=0.035, bone="head", horns=None):
    """Deep hood over a shadowed face with two glowing eyes. head = centre of the head."""
    h = V(head)
    C.ellipsoid("Hood", h + V((0, 0.05, 0.04)), (r * 1.05, r * 1.1, r * 1.15), m_hood, bone)
    C.cone("HoodTip", h + V((0, 0.16, r * 0.7)), h + V((0, 0.42, r * 0.95)), r * 0.45, m_hood, bone, segs=10,
           smooth=True)
    C.ellipsoid("Face", h + V((0, -r * 0.62, -0.02)), (r * 0.72, r * 0.35, r * 0.8), m_dark, bone)
    for mx in (-1, 1):
        C.ellipsoid(f"HoodEye{mx}", h + V((eye_gap * mx, -r * 0.92, 0.02)), (eye_size, eye_size * 0.5, eye_size * 0.6),
                    m_eye, bone, rot=(0, 15 * mx, 0))


def cape(C, m, shoulder_z, width=0.42, length=None, back_y=0.22, flare=0.25, thick=0.03):
    """Cape hanging behind the shoulders to near the floor, weighted to chest/hips."""
    bot = 0.08 if length is None else shoulder_z - length
    pts = [(-width, back_y, shoulder_z), (width, back_y, shoulder_z),
           (width + flare, back_y + 0.12, bot + 0.1), (width * 0.4, back_y + 0.16, bot),
           (0, back_y + 0.12, bot + 0.08), (-width * 0.4, back_y + 0.16, bot), (-width - flare, back_y + 0.12, bot + 0.1)]
    return C.membrane("Cape", pts, m, None, thick=thick, allowed=["chest", "hips"])


def staff(C, hand, m_wood, bone, length=1.7, up=0.9, top=None, m_top=None, top_r=0.1):
    """Staff held upright in a hand: runs from hand - (length-up) to hand + up. top: orb|crystal|skull|hook."""
    h = V(hand)
    a, b = h - V((0, 0, length - up)), h + V((0, 0, up))
    C.tube("Staff", [a, (a + b) / 2 + V((0.02, 0, 0)), b], [0.035, 0.035, 0.04], m_wood, bone)
    if top == "orb":
        C.ellipsoid("StaffOrb", b + V((0, 0, top_r)), (top_r,) * 3, m_top, bone)
        for k in range(3):
            ang = 2 * math.pi * k / 3
            C.horn(f"StaffClaw{k}", b, b + V((math.cos(ang) * top_r * 1.1, math.sin(ang) * top_r * 1.1, top_r * 2.1)),
                   0.022, m_wood, bone)
    elif top == "crystal":
        C.cone("StaffCrystal", b, b + V((0, 0, top_r * 3.2)), top_r, m_top, bone, segs=6)
        C.cone("StaffCrystal2", b + V((0, 0, top_r * 0.6)), b + V((0, 0, -top_r * 1.2)), top_r * 0.8, m_top, bone, segs=6)
    elif top == "hook":
        C.tube("StaffHook", [b, b + V((0, -0.12, 0.2)), b + V((0, -0.28, 0.12)), b + V((0, -0.26, -0.02))],
               [0.04, 0.035, 0.03, 0.02], m_wood, bone)
        if m_top:
            C.ellipsoid("StaffLantern", b + V((0, -0.26, -0.12)), (0.07, 0.07, 0.1), m_top, bone)
    elif top == "skull":
        C.ellipsoid("StaffSkull", b + V((0, 0, top_r)), (top_r, top_r * 1.1, top_r), m_top, bone)
    return b


def blade(C, hand, m_blade, m_hilt, bone, length=0.9, width=0.09, direction=(0, -0.25, -1), curve=0.0, guard=0.18):
    """Sword/scimitar/dagger held in a hand, pointing along direction (default down and a bit forward)."""
    h = V(hand)
    d = V(direction).normalized()
    side = d.cross(V((1, 0, 0))).normalized()
    C.tube("Grip", [h - d * 0.1, h, h + d * 0.08], [0.03, 0.03, 0.03], m_hilt, bone)
    C.box("Guard", tuple(h + d * 0.1), (guard, 0.06, 0.04), m_hilt, bone, bevel=0.4,
          rot=(math.degrees(math.atan2(d.y, -d.z)), 0, 0))
    tip = h + d * (0.12 + length)
    mid = h + d * (0.12 + length * 0.5) + side * curve
    pts = [h + d * 0.12 + V((width, 0, 0)), mid + V((width * 1.1, 0, 0)), tip, mid - V((width * 0.8, 0, 0)),
           h + d * 0.12 - V((width, 0, 0))]
    ob = C.membrane("Blade", [tuple(p) for p in pts], m_blade, bone, thick=0.025)
    return tip


def shield(C, center, r, m_face, m_rim, bone, facing=(0, -1, 0), boss=None, kite=False):
    c = V(center)
    if kite:
        pts = [(-r, 0, r * 0.7), (r, 0, r * 0.7), (r * 0.95, 0, -r * 0.2), (0, 0, -r * 1.4), (-r * 0.95, 0, -r * 0.2)]
        ob = C.membrane("Shield", pts, m_face, bone, thick=0.08)
        ob.data.transform(Matrix.Translation(c))
    else:
        ob = C.lathe("Shield", [(0.001, 0.05), (r * 0.6, 0.04), (r, 0.0), (r * 0.98, -0.03), (0.001, -0.02)],
                     m_face, bone, segs=24)
        _orient(ob, c, V(facing) * -1)
        rim = C.lathe("ShieldRim", [(r * 0.94, 0.0), (r * 1.04, 0.02), (r * 1.06, -0.01), (r * 0.96, -0.03)],
                      m_rim, bone, segs=24)
        _orient(rim, c, V(facing) * -1)
    if boss:
        C.ellipsoid("ShieldBoss", c + V(facing) * 0.07, (r * 0.25,) * 3, boss, bone)


def crown(C, center, r, m, bone, points=5, height=0.14, m_gem=None, tilt=0.0):
    c = V(center)
    C.lathe("Crown", [(r, 0), (r * 1.04, height * 0.45), (r * 1.02, height * 0.5)], m, bone, segs=24)
    ob = C.parts[-1][0]
    ob.data.transform(Matrix.Translation(c) @ Matrix.Rotation(math.radians(tilt), 4, 'X'))
    for k in range(points):
        a = 2 * math.pi * k / points + math.pi / 2
        b = c + V((math.cos(a) * r, math.sin(a) * r, height * 0.4))
        C.cone(f"CrownPt{k}", b, b + V((math.cos(a) * 0.02, math.sin(a) * 0.02, height)), r * 0.22, m, bone, segs=4)
        if m_gem:
            C.ellipsoid(f"CrownGem{k}", b + V((math.cos(a) * 0.01, math.sin(a) * 0.01, 0.0)), (r * 0.1,) * 3, m_gem, bone)


def bow(C, hand, m_wood, m_string, bone, size=0.75):
    h = V(hand)
    top, bot = h + V((0, -0.08, size)), h + V((0, -0.08, -size))
    C.tube("Bow", [bot, h + V((0, -0.32, -size * 0.5)), h + V((0, -0.2, 0)), h + V((0, -0.32, size * 0.5)), top],
           [0.015, 0.03, 0.04, 0.03, 0.015], m_wood, bone)
    C.tube("BowString", [bot, h + V((0, 0.05, 0)), top], [0.006, 0.006, 0.006], m_string, bone)


def pauldrons(C, m, spikes=None, size=0.2, spike_n=3):
    for side, mx in (("L", -1), ("R", 1)):
        sh = V(C.anch["sh" + side])
        C.ellipsoid(f"Pauldron{side}", sh + V((0.03 * mx, 0, 0.08)), (size * 1.1, size * 1.1, size * 0.65), m,
                    f"arm.{side}", rot=(0, 25 * mx, 0))
        if spikes:
            for k in range(spike_n):
                b = sh + V(((0.02 + 0.07 * k) * mx, -0.05 + 0.06 * k, size * 0.85))
                C.cone(f"PSpike{side}{k}", b, b + V((0.06 * mx, 0.02, size)), size * 0.22, spikes, f"arm.{side}")


def flame(C, base, size, bone, m_outer, m_inner, n=5, lean=(0, 0.15, 0), name="Flame", spread=0.6, m_core=None):
    """A tongue of fire: a ring of tall cones around a taller inner core, leaning back (lean)."""
    b = V(base)
    ln = V(lean)
    for k in range(n):
        a = 2 * math.pi * k / n
        off = V((math.cos(a), math.sin(a), 0)) * size * spread * 0.5
        h = size * (1.0 + 0.35 * ((k * 7) % 3) / 2)
        C.cone(f"{name}O{k}", b + off, b + off * 1.6 + V((0, 0, h)) + ln * h, size * 0.32, m_outer, bone, segs=6,
               smooth=True)
    C.cone(f"{name}I", b, b + V((0, 0, size * 1.5)) + ln * size * 1.5, size * 0.34, m_inner, bone, segs=8, smooth=True)
    if m_core:
        C.ellipsoid(f"{name}C", b + V((0, 0, size * 0.2)), (size * 0.3,) * 3, m_core, bone)


def mane_of_fire(C, pts, size, bone_fn, m_outer, m_inner, name="Mane", lean=(0, 0.6, 0.6)):
    for i, p in enumerate(pts):
        flame(C, p, size * (1 - 0.06 * i), bone_fn(i), m_outer, m_inner, n=3, lean=lean, name=f"{name}{i}", spread=0.5)
