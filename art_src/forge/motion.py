"""Clips for forged creatures, written as poses over time t (0..1) and sampled into keys.

Conventions (world axes, in each bone's rest frame):
  +X on an upward bone leans it forward, on a downward limb swings it back, on a forward bone
  (jaw, head, quad spine) tips it down. Arms/legs must rest pointing down (A-pose).
  +Y on a downward left limb raises it out to the left (right limbs: -Y). On a sideways wing
  (L points -X) +Y lifts the left wing tip (right wing: -Y).
  +Z turns a bone to the creature's left... (yaw); tails sway with Z.
"""
import math
from collections import defaultdict
from mathutils import Vector, Quaternion

TAU = 2 * math.pi
AX = {'X': Vector((1, 0, 0)), 'Y': Vector((0, 1, 0)), 'Z': Vector((0, 0, 1))}


def env(t, pts):
    """Smooth piecewise curve through (time, value) pairs."""
    if t <= pts[0][0]:
        return pts[0][1]
    for (t0, v0), (t1, v1) in zip(pts, pts[1:]):
        if t <= t1:
            u = (t - t0) / max(t1 - t0, 1e-6)
            u = u * u * (3 - 2 * u)
            return v0 + (v1 - v0) * u
    return pts[-1][1]


class Pose:
    def __init__(self):
        self.rot = defaultdict(list)
        self.loc = defaultdict(lambda: Vector((0, 0, 0)))
        self.scl = {}

    def r(self, bone, axis, deg):
        if bone and deg:
            self.rot[bone].append((axis, deg))

    def l(self, bone, x=0, y=0, z=0):
        if bone:
            self.loc[bone] = self.loc[bone] + Vector((x, y, z))

    def s(self, bone, k):
        if bone:
            self.scl[bone] = k


def side_sign(name):
    return 1 if name.endswith(".L") else -1


class Clips:
    def __init__(self, C):
        self.C = C
        self.chest = C.spine[-1] if C.spine else None
        self.hips = C.spine[0] if C.spine else None

    # ---------------- shared layers
    def tail_wave(self, P, t, amp, speed=1.0, lift=0.0):
        for i, b in enumerate(self.C.tail):
            P.r(b, 'Z', amp * (0.6 + 0.25 * i) * math.sin(TAU * t * speed - i * 0.7))
            P.r(b, 'X', lift)

    def wings_flap(self, P, t, amp, speed=1.0, base=0.0):
        for up, low, side in self.C.wings:
            sg = 1 if side == "L" else -1
            ph = TAU * t * speed
            P.r(up, 'Y', sg * (base + amp * math.sin(ph)))
            P.r(low, 'Y', sg * (amp * 0.6 * math.sin(ph - 0.9)))

    def spine_wave(self, P, t, amp, speed=1.0):
        chain = self.C.spine + self.C.tail
        for i, b in enumerate(chain):
            P.r(b, 'Z', amp * (0.3 + 0.35 * i) * math.sin(TAU * t * speed - i * 0.8))

    def floaty(self):
        return self.C.plan in ("flyer", "swimmer", "hover")

    # ---------------- clips
    def idle(self, t):
        C, P = self.C, Pose()
        s, c = math.sin(TAU * t), math.cos(TAU * t)
        if self.floaty():
            P.l("root", z=C.hover + 0.06 * s)
            P.r("root", 'X', 3 * c)
        P.l(self.hips, z=0.012 * c)
        P.r(self.chest, 'X', -2.5 * s)
        for n in C.neck:
            P.r(n, 'X', 2 * c)
        P.r(C.head, 'Z', 7 * math.sin(TAU * t + 1.2))
        P.r(C.head, 'X', 3 * math.sin(TAU * 2 * t))
        P.r(C.jaw, 'X', 4 + 4 * s)
        for up, low, side in C.arms:
            sg = 1 if side == "L" else -1
            P.r(up, 'X', 5 * s)
            P.r(up, 'Y', sg * 4)
            P.r(low, 'X', -8 - 4 * c)
        self.tail_wave(P, t, 7)
        if C.plan == "flyer":
            self.wings_flap(P, t, 32, speed=2, base=6)
        else:
            self.wings_flap(P, t, 4, speed=1)
        if C.plan == "swimmer":
            self.spine_wave(P, t, 5)
        for fn in C.extra_idle:
            fn(P, t)
        return P

    def walk(self, t):
        C, P = self.C, Pose()
        ph = TAU * t
        if self.floaty():
            P.l("root", z=C.hover + 0.08 * math.sin(2 * ph))
            P.r("root", 'X', 8)
            if C.plan == "flyer":
                self.wings_flap(P, t, 42, speed=3, base=8)
            else:
                self.spine_wave(P, t, 9, speed=2)
            self.tail_wave(P, t, 10, speed=2)
            for up, low, side in C.arms:
                P.r(up, 'X', 20)
            for fn in C.extra_idle:
                fn(P, t)
            return P
        sw = 30 * C.stride
        for up, low, phase in C.legs:
            a = TAU * (t + phase)
            P.r(up, 'X', -sw * math.sin(a))
            P.r(low, 'X', 45 * max(0.0, math.cos(a)) * C.stride)
        P.l(self.hips, z=0.04 * abs(math.cos(ph)) - 0.02)
        P.r(self.hips, 'Y', 3 * math.sin(ph))
        P.r(self.chest, 'Z', 6 * math.sin(ph))
        P.r(self.chest, 'X', 4)
        for up, low, side in C.arms:
            off = 0.0 if side == "R" else 0.5
            P.r(up, 'X', 28 * math.sin(TAU * (t + off)))
            P.r(low, 'X', -20)
        P.r(C.head, 'Z', -5 * math.sin(ph))
        P.r(C.head, 'X', 3 * math.cos(2 * ph))
        self.tail_wave(P, t, 10, speed=1)
        self.wings_flap(P, t, 6, speed=2)
        return P

    def attack(self, t):
        C, P = self.C, Pose()
        w = env(t, [(0, 0), (0.36, 1), (0.48, 0), (1, 0)])          # wind-up
        k = env(t, [(0, 0), (0.36, 0), (0.48, 1), (0.64, 1), (1, 0)])  # strike
        hov = C.hover if self.floaty() else 0.0
        st = C.attack
        P.l("root", z=hov)
        if st in ("swipe", "slam", "cast", "stab"):
            P.r(self.chest, 'X', -12 * w + 22 * k)
            P.r(C.head, 'X', -8 * w + 10 * k)
            P.l("root", y=0.08 * w - 0.32 * k)
            for up, low, side in C.arms:
                sg = 1 if side == "L" else -1
                if st == "swipe":
                    if side == "R":
                        P.r(up, 'X', -150 * w - 55 * k)
                        P.r(up, 'Y', -20 * w)
                        P.r(low, 'X', -50 * w - 10 * k)
                    else:
                        P.r(up, 'X', -30 * w + 25 * k)
                        P.r(low, 'X', -60)
                    P.r(self.chest, 'Z', 25 * w - 30 * k)
                elif st == "slam":
                    P.r(up, 'X', -160 * w - 60 * k)
                    P.r(up, 'Y', sg * 15 * w)
                    P.r(low, 'X', -40 * w - 5 * k)
                    P.l("root", z=0.12 * w)
                elif st == "stab":
                    if side == "R":
                        P.r(up, 'X', 35 * w - 85 * k)
                        P.r(low, 'X', -80 * w + 10 * k)
                    else:
                        P.r(up, 'X', -20)
                        P.r(low, 'X', -50)
                    P.r(self.chest, 'Z', -20 * w + 25 * k)
                else:  # cast
                    P.r(up, 'X', 30 * w - 95 * k)
                    P.r(up, 'Y', sg * (25 * w - 10 * k))
                    P.r(low, 'X', -70 * w + 20 * k)
            for up, low, phase in C.legs:
                P.r(up, 'X', (-10 if phase < 0.25 else 15) * k)
            self.tail_wave(P, t, 18, speed=1.5)
        elif st in ("bite", "ram"):
            P.l("root", y=0.12 * w - 0.38 * k)
            P.r(self.hips, 'X', -5 * w + 6 * k)
            P.r(self.chest, 'X', -8 * w + 6 * k)
            for n in C.neck:
                P.r(n, 'X', -16 * w + (12 if st == "bite" else 22) * k)
            P.r(C.head, 'X', -12 * w + (8 if st == "bite" else 22) * k)
            P.r(C.jaw, 'X', 40 * w + 5 * k if st == "bite" else 15 * w)
            for up, low, phase in C.legs:
                front = phase in (0.0, 0.5) and C.bones[up]["head"].y < 0
                P.r(up, 'X', (-25 * w + 20 * k) if front else (10 * w - 15 * k))
            for up, low, side in C.arms:
                P.r(up, 'X', 20 * w - 60 * k)
            self.tail_wave(P, t, 12, speed=1.5, lift=20 * w)
            self.wings_flap(P, t, 25 * (w + k), speed=2)
        elif st == "dive":
            P.l("root", y=0.25 * w - 0.55 * k, z=0.35 * w - hov * 0.7 * k)
            P.r("root", 'X', -18 * w + 35 * k)
            for up, low, side in C.wings:
                sg = 1 if side == "L" else -1
                P.r(up, 'Y', sg * (55 * w - 30 * k))
                P.r(low, 'Y', sg * (-20 * w - 10 * k))
            P.r(C.jaw, 'X', 35 * w)
            P.r(C.head, 'X', -15 * w + 20 * k)
            for up, low, side in C.arms:
                P.r(up, 'X', 30 * w - 70 * k)
            self.tail_wave(P, t, 14, speed=1.5, lift=-15 * k)
            if C.plan == "swimmer":
                self.spine_wave(P, t, 12 * (w + k), speed=2)
        elif st == "sting":
            P.l("root", y=0.1 * w - 0.3 * k)
            for i, b in enumerate(C.tail):
                P.r(b, 'X', (25 * w - 55 * k) * (1 if i else 0.6))
            P.r(self.chest, 'X', -10 * w + 15 * k)
            self.wings_flap(P, t, 35, speed=3, base=5)
        return P

    def hit(self, t):
        C, P = self.C, Pose()
        h = env(t, [(0, 0), (0.22, 1), (0.6, -0.15), (1, 0)])
        P.l("root", y=0.14 * h, z=(C.hover if self.floaty() else 0.0) - 0.05 * h)
        if self.floaty():
            P.r("root", 'X', -14 * h)
        P.r(self.chest, 'X', -16 * h)
        P.r(self.hips, 'X', -4 * h)
        P.r(C.head, 'X', -18 * h)
        P.r(C.head, 'Z', 10 * h)
        P.r(C.jaw, 'X', 20 * h)
        for up, low, side in C.arms:
            P.r(up, 'X', 25 * h)
            P.r(low, 'X', -30 * h)
        self.tail_wave(P, t, 15 * abs(h), speed=2)
        self.wings_flap(P, t, 30 * h, speed=2)
        return P

    def death(self, t):
        C, P = self.C, Pose()
        d = env(t, [(0, 0), (0.18, 0.05), (0.72, 1), (1, 1)])
        shake = math.sin(TAU * 5 * t) * env(t, [(0, 0), (0.08, 1), (0.3, 0)])
        P.r(self.chest, 'Z', 6 * shake)
        P.r(C.head, 'X', 25 * d)
        P.r(C.jaw, 'X', 25 * d)
        if self.floaty():
            hov = C.hover * (1 - env(t, [(0, 0), (0.2, 0), (0.75, 1), (1, 1)]))
            P.l("root", z=hov + 0.1 * shake)
            P.r("root", 'Y', (180 if C.plan == "swimmer" else 95) * d)
            for up, low, side in C.wings:
                sg = 1 if side == "L" else -1
                P.r(up, 'Y', sg * -25 * d)
            self.tail_wave(P, t, 6 * (1 - d))
        elif C.plan == "quad":
            P.r("root", 'Y', 82 * d)
            P.l("root", z=0.02 * d)
            for up, low, phase in C.legs:
                P.r(up, 'X', 15 * d * (1 if phase else -1))
                P.r(low, 'X', 20 * d)
            for n in C.neck:
                P.r(n, 'X', 15 * d)
            for i, b in enumerate(C.tail):
                P.r(b, 'Z', -12 * d)
        else:
            P.r("root", 'X', -84 * d)
            P.r(self.chest, 'X', 10 * d)
            for up, low, side in C.arms:
                sg = 1 if side == "L" else -1
                P.r(up, 'Y', sg * 55 * d)
                P.r(low, 'X', -10 * d)
            for up, low, phase in C.legs:
                P.r(up, 'X', -20 * d * (1 if phase < 0.25 else 0.4))
            self.tail_wave(P, t, 0)
        return P

    def roar(self, t):
        C, P = self.C, Pose()
        r = env(t, [(0, 0), (0.25, 1), (0.75, 1), (1, 0)])
        sh = math.sin(TAU * 7 * t) * r
        if self.floaty():
            P.l("root", z=C.hover + 0.15 * r)
            P.r("root", 'X', -12 * r)
            self.wings_flap(P, t, 50 * r + 10, speed=3, base=10 * r)
        P.r(self.chest, 'X', -14 * r)
        for n in C.neck:
            P.r(n, 'X', -12 * r)
        P.r(C.head, 'X', -20 * r + 3 * sh)
        P.r(C.head, 'Z', 3 * sh)
        P.r(C.jaw, 'X', 38 * r)
        for up, low, side in C.arms:
            sg = 1 if side == "L" else -1
            P.r(up, 'Y', sg * 60 * r)
            P.r(up, 'X', -25 * r)
            P.r(low, 'X', -45 * r)
        for up, low, phase in C.legs:
            if C.plan == "quad" and C.bones[up]["head"].y < 0:
                P.r(up, 'X', -12 * r)
        self.tail_wave(P, t, 14 * r + 4, speed=2, lift=15 * r)
        if C.plan != "flyer":
            self.wings_flap(P, t, 25 * r, speed=1, base=30 * r)
        return P


CLIPS = [("Idle", 60, "idle", True), ("Walk", 24, "walk", True), ("Punch", 27, "attack", False),
         ("HitReact", 18, "hit", False), ("Death", 42, "death", False), ("Yes", 45, "roar", False)]


def make_clips(C, rig):
    import bpy
    cl = Clips(C)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='POSE')
    PB = rig.pose.bones
    for pb in PB:
        pb.rotation_mode = 'QUATERNION'
    rig.animation_data_create()
    rest = {pb.name: pb.bone.matrix_local.to_3x3() for pb in PB}
    for name, frames, fn, loop in CLIPS:
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        step = 2
        fr = list(range(0, frames + 1, step))
        if fr[-1] != frames:
            fr.append(frames)
        for f in fr:
            t = f / frames
            if loop and f == frames:
                t = 0.0
            P = getattr(cl, fn)(t)
            for pb in PB:
                R = rest[pb.name]
                q = Quaternion()
                for ax, deg in P.rot.get(pb.name, []):
                    q = Quaternion(AX[ax], math.radians(deg)) @ q
                pb.rotation_quaternion = (R.inverted() @ q.to_matrix() @ R).to_quaternion()
                pb.location = R.inverted() @ P.loc.get(pb.name, Vector((0, 0, 0)))
                k = P.scl.get(pb.name, 1.0)
                pb.scale = (k, k, k)
                for path in ("rotation_quaternion", "location", "scale"):
                    pb.keyframe_insert(path, frame=f + 1)
    rig.animation_data.action = bpy.data.actions["Idle"]
    bpy.ops.object.mode_set(mode='OBJECT')
