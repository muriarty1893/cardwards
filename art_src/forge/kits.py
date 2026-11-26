"""Body plans: bones + a matching skin body from a few proportions. Recipes then add the details."""
from mathutils import Vector as V


def _mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def quad(C, m, *, hip=(0.38, 0.78), chest=(-0.32, 0.86), neck=(-0.62, 1.15), head=(-0.98, 1.12),
         jaw=True, leg_x=0.24, tail=((0.75, 0.95), (1.0, 1.12)), r_hip=0.30, r_chest=0.38, r_neck=0.17,
         r_head=0.2, r_snout=0.11, r_leg=0.10, r_paw=0.085, r_tail=0.08, knee=0.42, subdiv=2,
         head_drop=0.0, paw_fwd=0.04, r_waist=None, belly_drop=0.0, muscle=1.0, head_m=None, front=True):
    """Four-legged body facing -y. Points are (y, z). Returns the skin node dict (already built)."""
    C.plan = "quad"
    C.attack = C.attack if C.attack != "swipe" else "bite"
    hy, hz = hip
    cy, cz = chest
    ny, nz = neck
    ey, ez = head
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, hy, hz), (0, (hy + cy) / 2, (hz + cz) / 2), "root")
    C.bone("chest", (0, (hy + cy) / 2, (hz + cz) / 2), (0, cy, cz), "hips")
    C.bone("neck", (0, cy, cz), (0, ny, nz), "chest")
    C.bone("head", (0, ny, nz), (0, ey, ez - head_drop), "neck")
    C.spine = ["hips", "chest"]
    C.neck = ["neck"]
    C.head = "head"
    if jaw:
        C.bone("jaw", (0, ny - 0.1, nz - 0.12), (0, ey + 0.02, ez - head_drop - 0.12), "head")
        C.jaw = "jaw"
    prev = "hips"
    pp = (0, hy, hz)
    for i, (ty, tz) in enumerate(tail):
        n = f"tail{i + 1}"
        C.bone(n, pp, (0, ty, tz), prev)
        prev, pp = n, (0, ty, tz)
        C.tail.append(n)
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        for tag, (ly, lz, par, ph) in {"f": (cy + 0.02, cz - 0.1, "chest", 0.0 if side == "L" else 0.5),
                                       "b": (hy + 0.02, hz - 0.08, "hips", 0.5 if side == "L" else 0.0)}.items():
            if tag == "f" and not front:
                continue
            x = leg_x * sx
            top = (x, ly, lz)
            kn = (x * 1.02, ly + (0.05 if tag == "b" else -0.02), knee)
            paw = (x * 1.02, ly - paw_fwd, 0.0)
            up = C.bone(f"leg_{tag}.{side}", top, kn, par)
            lo = C.bone(f"shin_{tag}.{side}", kn, paw, up)
            C.legs.append((up, lo, ph))
            legs[f"{tag}{side}"] = (top, kn, paw)
    waist = r_waist if r_waist else (r_hip + r_chest) / 2
    nodes = {
        "pelvis": (0, hy, hz, r_hip, r_hip * 0.95),
        "belly": (0, (hy + cy) / 2, (hz + cz) / 2 - 0.02 + belly_drop, waist, waist * 1.1),
        "chest": (0, cy, cz - 0.03, r_chest, r_chest * 1.12),
        "neck": (0, (cy + ny) / 2, (cz + nz) / 2 + 0.02, r_neck * 1.35),
        "nb": (0, ny + 0.03, nz - 0.03, r_neck),
    }
    edges = [("pelvis", "belly"), ("belly", "chest"), ("chest", "neck"), ("neck", "nb")]
    prev = "pelvis"
    for i, (ty, tz) in enumerate(tail):
        k = f"t{i}"
        nodes[k] = (0, ty, tz, r_tail * (1 - 0.3 * i))
        edges.append((prev, k))
        prev = k
    for key, (top, kn, paw) in legs.items():
        par = "chest" if key[0] == "f" else "pelvis"
        sx = 1 if top[0] > 0 else -1
        if key[0] == "f":
            nodes[key + "top"] = (top[0] * 0.9, top[1], top[2] + 0.02, r_leg * 1.9 * muscle)
            nodes[key + "kn"] = (kn[0], kn[1] + 0.02, kn[2], r_leg * 1.05)
            nodes[key + "wr"] = (paw[0], paw[1] + 0.01, 0.16, r_leg * 0.8)
        else:
            nodes[key + "top"] = (top[0] * 0.92, top[1] - 0.02, top[2] - 0.06, r_leg * 2.1 * muscle)
            nodes[key + "kn"] = (kn[0], kn[1] - 0.06, kn[2] + 0.04, r_leg * 1.1)
            nodes[key + "wr"] = (paw[0], paw[1] + 0.12, 0.2, r_leg * 0.75)
        nodes[key + "paw"] = (paw[0], paw[1] - 0.04, 0.055, r_paw, r_paw * 0.8)
        edges += [(par, key + "top"), (key + "top", key + "kn"), (key + "kn", key + "wr"), (key + "wr", key + "paw")]
    C.skin("Body", nodes, edges, m, subdiv=subdiv, root="pelvis")
    # head: its own crisp shape, rigid on the head bone (wedge cranium -> brow -> snout -> nose)
    hm = head_m or m
    hd = {
        "cran": (0, ny - 0.02, nz + 0.02, r_head, r_head * 0.9),
        "brow": (0, ny + (ey - ny) * 0.4, nz + (ez - nz) * 0.4 - head_drop * 0.4 + 0.02, r_head * 0.78, r_head * 0.7),
        "snout": (0, ny + (ey - ny) * 0.78, nz + (ez - nz) * 0.8 - head_drop * 0.8 - 0.03, r_snout, r_snout * 0.85),
        "nose": (0, ey, ez - head_drop - 0.03, r_snout * 0.75, r_snout * 0.65),
    }
    C.skin("Head", hd, [("cran", "brow"), ("brow", "snout"), ("snout", "nose")], hm, bone="head", subdiv=subdiv)
    for k, v in list(nodes.items()) + list(hd.items()):
        C.anch[k] = tuple(v[:3])
    C.anch["back"] = (0, (hy + cy) / 2, (hz + cz) / 2 + waist)
    C.anch["withers"] = (0, cy, cz + r_chest)
    C.anch["rump"] = (0, hy, hz + r_hip)
    C.r_head = r_head
    return nodes


def biped(C, m, *, hip=0.85, chest=1.35, neck=1.62, head_top=2.05, shoulder_x=0.36, hip_x=0.17,
          hand=(0.52, -0.05, 0.78), foot_y=-0.04, r_hip=0.26, r_waist=0.24, r_chest=0.36, r_neck=0.12,
          r_head=0.24, r_arm=0.10, r_hand=0.09, r_leg=0.13, r_foot=0.11, elbow_back=0.1, knee_fwd=-0.06,
          skin_head=True, subdiv=2, jaw=None, lean=0.0, legs=True, hover=0.3):
    """Upright body facing -y, arms in A-pose. lean pushes the chest/head forward (hunch)."""
    C.plan = "biped"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, hip), (0, -lean * 0.3, (hip + chest) / 2), "root")
    C.bone("chest", (0, -lean * 0.3, (hip + chest) / 2), (0, -lean, chest), "hips")
    C.bone("neck", (0, -lean, chest), (0, -lean * 1.2, neck), "chest")
    C.bone("head", (0, -lean * 1.2, neck), (0, -lean * 1.2, head_top), "neck")
    C.spine = ["hips", "chest"]
    C.neck = ["neck"]
    C.head = "head"
    if jaw:
        C.bone("jaw", jaw[0], jaw[1], "head")
        C.jaw = "jaw"
    sh_z = chest - 0.06
    for side, sx in (("L", -1), ("R", 1)):
        sh = (shoulder_x * sx, -lean, sh_z)
        hd = (hand[0] * sx, hand[1] - lean * 0.6, hand[2])
        el = (_mid(sh, hd)[0] + 0.03 * sx, _mid(sh, hd)[1] + elbow_back, _mid(sh, hd)[2])
        up = C.bone(f"arm.{side}", sh, el, "chest")
        lo = C.bone(f"forearm.{side}", el, hd, up)
        C.arms.append((up, lo, side))
        if not legs:
            continue
        ht = (hip_x * sx, 0, hip - 0.05)
        ft = (hip_x * 1.1 * sx, foot_y, 0.05)
        kn = (hip_x * 1.05 * sx, knee_fwd, (hip - 0.05) * 0.5)
        lu = C.bone(f"leg.{side}", ht, kn, "hips")
        ll = C.bone(f"shin.{side}", kn, ft, lu)
        C.legs.append((lu, ll, 0.0 if side == "L" else 0.5))
    nodes = {
        "pelvis": (0, 0, hip, r_hip),
        "waist": (0, -lean * 0.3, (hip + chest) / 2, r_waist),
        "chest": (0, -lean, chest - 0.05, r_chest),
        "neck": (0, -lean * 1.1, neck, r_neck),
    }
    edges = [("pelvis", "waist"), ("waist", "chest"), ("chest", "neck")]
    if skin_head:
        nodes["head"] = (0, -lean * 1.2 - 0.02, (neck + head_top) / 2 + 0.04, r_head)
        edges.append(("neck", "head"))
    if not legs:
        C.plan = "hover"
        C.hover = hover
        w1 = (0, 0.06, hip * 0.55)
        w2 = (0, 0.16, hip * 0.12)
        C.bone("tail1", (0, 0, hip), w1, "hips")
        C.bone("tail2", w1, w2, "tail1")
        C.tail = ["tail1", "tail2"]
        nodes["w1"] = (*w1, r_hip * 0.75)
        nodes["w2"] = (*w2, 0.03)
        edges += [("pelvis", "w1"), ("w1", "w2")]
    for side, sx in (("L", -1), ("R", 1)):
        a = C.bones[f"arm.{side}"]
        f = C.bones[f"forearm.{side}"]
        nodes[f"sh{side}"] = (*a["head"], r_arm * 1.25)
        nodes[f"el{side}"] = (*f["head"], r_arm)
        nodes[f"hd{side}"] = (*f["tail"], r_hand)
        edges += [("chest", f"sh{side}"), (f"sh{side}", f"el{side}"), (f"el{side}", f"hd{side}")]
        if legs:
            l = C.bones[f"leg.{side}"]
            s = C.bones[f"shin.{side}"]
            nodes[f"hp{side}"] = (*l["head"], r_leg * 1.2)
            nodes[f"kn{side}"] = (*s["head"], r_leg)
            nodes[f"ft{side}"] = (s["tail"][0], s["tail"][1] - 0.06, 0.06, r_foot)
            edges += [("pelvis", f"hp{side}"), (f"hp{side}", f"kn{side}"), (f"kn{side}", f"ft{side}")]
    C.skin("Body", nodes, edges, m, subdiv=subdiv, root="pelvis")
    for k, v in nodes.items():
        C.anch[k] = tuple(v[:3])
    C.anch["face"] = (0, -lean * 1.2 - 0.02 - r_head, (neck + head_top) / 2 + 0.04)
    C.anch["crown"] = (0, -lean * 1.2, (neck + head_top) / 2 + 0.04 + r_head)
    return nodes


def wings(C, m_bone, m_skin, *, shoulder=(0.25, 0.1, 1.2), span=1.2, parent="chest", up=0.25, sweep=0.25,
          r=0.05, membrane=True, fingers=3, droop=0.35, thick=0.025):
    """Bat/dragon wings on both sides (bones wing.S, wing2.S). span = half wingspan from the shoulder."""
    for side, sx in (("L", -1), ("R", 1)):
        sh = V((shoulder[0] * sx, shoulder[1], shoulder[2]))
        el = sh + V((span * 0.45 * sx, sweep * 0.4, up))
        tip = sh + V((span * sx, sweep, up * 0.6))
        u = C.bone(f"wing.{side}", tuple(sh), tuple(el), parent)
        lo = C.bone(f"wing2.{side}", tuple(el), tuple(tip), u)
        C.wings.append((u, lo, side))
        C.tube(f"WingArm{side}", [sh, (sh + el) / 2 + V((0, 0, 0.03)), el], [r * 1.3, r, r * 0.8], m_bone, None,
               allowed=[u])
        C.tube(f"WingHand{side}", [el, (el + tip) / 2, tip], [r * 0.8, r * 0.6, 0.012], m_bone, lo)
        tips = [tip]
        for k in range(1, fingers):
            a = k / fingers
            ft = el + V((span * (0.55 - 0.12 * k) * sx, sweep + 0.25 * k, -droop * (0.6 + 0.5 * a)))
            C.tube(f"WingFinger{side}{k}", [el, (el + ft) / 2, ft], [r * 0.6, r * 0.45, 0.01], m_bone, lo)
            tips.append(ft)
        if membrane:
            outline = [tuple(sh), tuple(el)] + [tuple(p) for p in tips] + [
                tuple(sh + V((0.05 * sx, sweep + 0.35, -droop * 0.6)))]
            if sx < 0:
                outline = outline[::-1]
            C.membrane(f"Wing{side}", outline, m_skin, None, thick=thick, allowed=[u, lo])


def fish(C, m, nodes, mid=3, hover=0.5, jaw=True, subdiv=2):
    """Swimming body along -y. nodes: [(y, z, r) or (y, z, rx, rz)] from nose to tail tip; mid = index where the
    tail chain starts. Bones: head (front), chest, hips (pointing forward), tail1..n (pointing back)."""
    C.plan, C.hover = "swimmer", hover
    C.attack = C.attack if C.attack != "swipe" else "bite"
    P = [V((0, n[0], n[1])) for n in nodes]
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", tuple(P[mid]), tuple(P[mid - 1]), "root")
    C.bone("chest", tuple(P[mid - 1]), tuple(P[1]), "hips")
    C.bone("head", tuple(P[1]), tuple(P[0]), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    if jaw:
        C.bone("jaw", tuple(P[1] + V((0, 0, -0.08))), tuple(P[0] + V((0, 0.05, -0.12))), "head")
        C.jaw = "jaw"
    prev = "hips"
    for i in range(mid, len(P) - 1):
        n = f"tail{i - mid + 1}"
        C.bone(n, tuple(P[i]), tuple(P[i + 1]), prev)
        C.tail.append(n)
        prev = n
    radii = []
    for i, n in enumerate(nodes):
        radii.append((n[2] + (n[3] if len(n) > 3 else n[2])) / 2)
        C.anch[f"n{i}"] = (0, n[0], n[1])
    C.tube("Body", P, radii, m, None, res=12)
    # rounded nose and tail caps (tubes end flat)
    C.ellipsoid("Nose", tuple(P[0]), (radii[0],) * 3, m, "head")
    C.ellipsoid("TailCap", tuple(P[-1]), (radii[-1],) * 3, m, C.tail[-1] if C.tail else "hips")
    return P
