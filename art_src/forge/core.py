"""Forge: builds Dream Isles creatures in Blender from short recipes.

Run inside Blender (Blender MCP or `blender -b --python`):
    import sys; sys.path.insert(0, "<repo>/art_src")
    import forge; forge.run("carrion_hound")

A recipe (forge/creatures/<id>.py) defines build(C) that adds bones, a skin body and parts to the
Creature C and sets C.plan / C.attack. Forge then weights the mesh to the bones, makes the clips the
game looks for (Idle, Walk, Punch, HitReact, Death, Yes) and exports assets/monsters/forged/<id>.glb.

Axes: Blender Z up, the creature faces -Y (glTF +Z). Bone rotations in clips are given about world
axes in the bone's rest frame: +X pitches an upward bone forward, +Z turns it to its left.
"""
import bpy, bmesh, math
from mathutils import Vector, Matrix, Quaternion

REPO = "/home/murat/Desktop/cardwars"
OUT_DIR = REPO + "/assets/monsters/forged"


def srgb(hexcol):
    hexcol = hexcol.lstrip("#")
    c = [int(hexcol[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions,
                 bpy.data.curves, bpy.data.lights):
        for d in list(coll):
            coll.remove(d)


def V(p):
    return Vector(p)


class Creature:
    def __init__(self, cid):
        clear_scene()
        self.id = cid
        self.scene = bpy.context.scene
        self.scene.render.fps = 30
        self.mats = {}
        self.parts = []          # (object, bone or None, allowed-bones or None)
        self.bones = {}          # name -> dict(head, tail, parent, deform)
        self.plan = "biped"      # biped | quad | flyer | swimmer | hover
        self.attack = "swipe"    # swipe | slam | bite | cast | dive | ram | sting
        self.legs = []           # (upper, lower, phase)
        self.arms = []           # (upper, lower, side)
        self.wings = []          # (upper, lower, side)
        self.spine = []          # hips..chest
        self.neck = []
        self.head = None
        self.jaw = None
        self.tail = []
        self.extra_idle = []     # callables(key, f, t) for special motion
        self.hover = 0.0         # flyers/swimmers float this high (m) in their clips
        self.stride = 1.0
        self.weight_power = 4.0
        self.relax = 0.4         # Laplacian smoothing on skin bodies (up to 1.0 for big round bodies)
        self.warps = []
        self.auto_weight = set()  # part names weighted by Blender's heat weighting (sculpted bodies)
        self.hexes = {}          # palette name -> hex (clay colours may name palette entries)
        self.anch = {}           # named points set by kits (brow, snout, chest, back...)

    def surf(self, x, z, part="Body", dir=(0, 1, 0), y=None, sink=0.0):
        """Point on a part's surface hit by a ray travelling along dir (default from the front, +y).
        Returns (location, normal); sink pushes the point inwards so decals sit in the skin."""
        ob = next(p[0] for p in self.parts if p[0].name == part)
        d = V(dir).normalized()
        if y is None:
            o = V((x, 0, z)) - d * 5
        else:
            o = V((x, y, z)) - d * 5
        ok, loc, nor, _ = ob.ray_cast(o, d)
        if not ok:
            return None, None
        return loc - nor * sink, nor

    def decal(self, name, x, z, size, m, bone=None, part="Body", dir=(0, 1, 0), spin=0.0, y=None, flat=0.35):
        """Flattened blob lying on a part's surface (lava cracks, scales, markings, gems)."""
        loc, nor = self.surf(x, z, part, dir, y, sink=size[2] * 0.3 if len(size) > 2 else 0.0)
        if loc is None:
            return None
        q = V((0, 0, 1)).rotation_difference(nor)
        from mathutils import Matrix
        rot = (q.to_matrix().to_4x4() @ Matrix.Rotation(math.radians(spin), 4, 'Z'))
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=1)
        sz = (size[0], size[1], size[2] if len(size) > 2 else min(size) * flat)
        bmesh.ops.transform(bm, matrix=Matrix.Translation(loc) @ rot @ Matrix.Diagonal((*sz, 1)), verts=bm.verts)
        return self._bm_obj(name, bm, m, bone, True)

    def at(self, name, dx=0.0, dy=0.0, dz=0.0, mx=1):
        """Anchor point plus an offset; mx=-1 mirrors x (for left-side parts)."""
        p = self.anch[name]
        return (p[0] + dx * mx, p[1] + dy, p[2] + dz)

    # ---------- materials
    def mat(self, name, hexcol, rough=0.75, metal=0.0):
        if name in self.mats:
            return self.mats[name]
        self.hexes[name] = hexcol
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        p = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        p.inputs["Base Color"].default_value = (*srgb(hexcol), 1)
        p.inputs["Roughness"].default_value = rough
        p.inputs["Metallic"].default_value = metal
        m.diffuse_color = (*srgb(hexcol), 1)
        self.mats[name] = m
        return m

    def palette(self, **cols):
        for k, v in cols.items():
            self.mat(k, v)

    def _m(self, m):
        return self.mats[m] if isinstance(m, str) else m

    # ---------- skeleton
    def bone(self, name, head, tail, parent=None, deform=True):
        self.bones[name] = dict(head=V(head), tail=V(tail), parent=parent, deform=deform)
        return name

    def mirror_bone(self, name, head, tail, parent=None, deform=True):
        """Makes name.L at -x and name.R at +x from a right-side (+x) definition."""
        h, t = V(head), V(tail)
        for side, sx in (("L", -1), ("R", 1)):
            p = parent
            if parent and parent.endswith(".S"):
                p = parent[:-2] + "." + side
            self.bone(name + "." + side, (h.x * sx, h.y, h.z), (t.x * sx, t.y, t.z), p, deform)
        return name

    # ---------- object helpers
    def _link(self, name, me, m, bone, smooth=True, allowed=None):
        ob = bpy.data.objects.new(name, me)
        self.scene.collection.objects.link(ob)
        if m is not None:
            me.materials.append(self._m(m))
        for f in me.polygons:
            f.use_smooth = smooth
        self.parts.append((ob, bone, allowed))
        return ob

    def _bm_obj(self, name, bm, m, bone, smooth=True, allowed=None):
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        return self._link(name, me, m, bone, smooth, allowed)

    def skin(self, name, nodes, edges, m, bone=None, subdiv=2, allowed=None, root=None, smooth=True, relax=None):
        """Organic body from a node graph. nodes: {key: (x, y, z, r) or (x, y, z, rx, ry)}, edges: [(a, b)].
        bone=None weights it smoothly over the skeleton (or over `allowed` bones)."""
        keys = list(nodes)
        me = bpy.data.meshes.new(name + "_skel")
        verts = [tuple(nodes[k][:3]) for k in keys]
        me.from_pydata(verts, [(keys.index(a), keys.index(b)) for a, b in edges], [])
        ob = bpy.data.objects.new(name + "_skel", me)
        self.scene.collection.objects.link(ob)
        sk = ob.modifiers.new("Skin", "SKIN")
        sk.use_smooth_shade = smooth
        sk.branch_smoothing = 0.6
        layer = me.skin_vertices[0].data
        for i, k in enumerate(keys):
            n = nodes[k]
            rx = n[3]
            ry = n[4] if len(n) > 4 else n[3]
            layer[i].radius = (rx, ry)
            layer[i].use_root = (k == (root or keys[0]))
        if subdiv:
            sd = ob.modifiers.new("Sub", "SUBSURF")
            sd.levels = subdiv
            sd.render_levels = subdiv
        # Skin hulls go boxy where a radius is large next to a short edge; a volume-keeping smooth rounds them.
        relax = self.relax if relax is None else relax
        if relax:
            ls = ob.modifiers.new("Relax", "LAPLACIANSMOOTH")
            ls.lambda_factor = relax
            ls.iterations = 4
            ls.use_volume_preserve = True
        dg = bpy.context.evaluated_depsgraph_get()
        me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.meshes.remove(me)
        me2.name = name
        return self._link(name, me2, m, bone, smooth, allowed)

    def ellipsoid(self, name, c, r, m, bone=None, rot=(0, 0, 0), segs=20, rings=12, smooth=True, allowed=None):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1)
        M = Matrix.Translation(V(c)) @ euler(rot).to_matrix().to_4x4() @ Matrix.Diagonal((*r, 1))
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
        return self._bm_obj(name, bm, m, bone, smooth, allowed)

    def box(self, name, c, size, m, bone=None, rot=(0, 0, 0), bevel=0.25, taper=None, smooth=False):
        """Rounded block (armour plates, crates, teeth blocks). taper=(sx, sy) shrinks the +z face."""
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        if taper:
            for v in bm.verts:
                if v.co.z > 0:
                    v.co.x *= taper[0]
                    v.co.y *= taper[1]
        bmesh.ops.scale(bm, vec=V(size), verts=bm.verts)
        if bevel:
            bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(size) * bevel * 0.5, segments=2,
                            profile=0.5, affect='EDGES')
        bmesh.ops.transform(bm, matrix=Matrix.Translation(V(c)) @ euler(rot).to_matrix().to_4x4(), verts=bm.verts)
        return self._bm_obj(name, bm, m, bone, smooth)

    def tube(self, name, pts, radii, m, bone=None, res=10, caps=True, allowed=None, smooth=True):
        """Tapered bent tube through pts (horns, tails, limbs, tentacles). radii: one per point."""
        cu = bpy.data.curves.new(name, "CURVE")
        cu.dimensions = '3D'
        cu.bevel_depth = 1.0
        cu.bevel_resolution = 3
        cu.resolution_u = res
        cu.use_fill_caps = caps
        sp = cu.splines.new('BEZIER')
        sp.bezier_points.add(len(pts) - 1)
        for bp, p, r in zip(sp.bezier_points, pts, radii):
            bp.co = V(p)
            bp.handle_left_type = bp.handle_right_type = 'AUTO'
            bp.radius = r
        ob = bpy.data.objects.new(name + "_c", cu)
        self.scene.collection.objects.link(ob)
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.curves.remove(cu)
        me.name = name
        return self._link(name, me, m, bone, smooth, allowed)

    def horn(self, name, base, tip, r, m, bone=None, bend=(0, 0, 0)):
        b, t = V(base), V(tip)
        mid = (b + t) / 2 + V(bend)
        return self.tube(name, [b, mid, t], [r, r * 0.55, 0.004], m, bone)

    def mirror_horn(self, name, base, tip, r, m, bone=None, bend=(0, 0, 0)):
        for side, sx in (("L", -1), ("R", 1)):
            b = (base[0] * sx, base[1], base[2])
            t = (tip[0] * sx, tip[1], tip[2])
            bd = (bend[0] * sx, bend[1], bend[2])
            self.horn(name + side, b, t, r, m, sided(bone, side), bd)

    def cone(self, name, base, tip, r, m, bone=None, segs=8, smooth=False):
        b, t = V(base), V(tip)
        d = t - b
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=0.0, depth=d.length)
        q = V((0, 0, 1)).rotation_difference(d.normalized())
        M = Matrix.Translation((b + t) / 2) @ q.to_matrix().to_4x4()
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
        return self._bm_obj(name, bm, m, bone, smooth)

    def spikes(self, name, pts, normal_fn, sizes, m, bone=None, segs=6):
        """A row of cones: pts bases, normal_fn(i, p) -> direction, sizes [(r, len)]."""
        for i, p in enumerate(pts):
            r, ln = sizes[i] if isinstance(sizes, list) else sizes
            d = V(normal_fn(i, p)).normalized()
            b = bone(i, p) if callable(bone) else bone
            self.cone(f"{name}{i}", p, V(p) + d * ln, r, m, b, segs)

    def lathe(self, name, prof, m, bone=None, segs=32, wave=None, allowed=None, smooth=True):
        """Surface of revolution about Z. prof: [(r, z)] bottom to top. wave=(k, amp, r0) ripples the rim."""
        bm = bmesh.new()
        rings = []
        for (r, z) in prof:
            ring = []
            for i in range(segs):
                a = 2 * math.pi * i / segs
                zz = z
                if wave and r > wave[2]:
                    zz += wave[1] * math.sin(wave[0] * a) * (r - wave[2])
                ring.append(bm.verts.new((r * math.cos(a), r * math.sin(a), zz)))
            rings.append(ring)
        for k in range(len(rings) - 1):
            for i in range(segs):
                j = (i + 1) % segs
                bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        return self._bm_obj(name, bm, m, bone, smooth, allowed)

    def membrane(self, name, outline, m, bone=None, thick=0.03, allowed=None):
        """Flat-ish skin (wings, fins, sails) from an outline loop of points, thickened."""
        bm = bmesh.new()
        vs = [bm.verts.new(V(p)) for p in outline]
        f = bm.faces.new(vs)
        bmesh.ops.triangulate(bm, faces=[f])
        bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=2, use_grid_fill=True)
        ext = bmesh.ops.extrude_face_region(bm, geom=list(bm.faces))
        n = f.normal.copy() if f.is_valid else V((0, 0, 1))
        new_verts = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
        # offset along the averaged normal of the loop
        nrm = V((0, 0, 0))
        pts = [V(p) for p in outline]
        for i in range(len(pts)):
            nrm += (pts[i] - pts[0]).cross(pts[(i + 1) % len(pts)] - pts[0])
        nrm = nrm.normalized() if nrm.length > 0 else V((0, 0, 1))
        bmesh.ops.translate(bm, vec=nrm * thick, verts=new_verts)
        return self._bm_obj(name, bm, m, bone, False, allowed)

    def mirror_ellipsoid(self, name, c, r, m, bone=None, rot=(0, 0, 0), **kw):
        for side, sx in (("L", -1), ("R", 1)):
            self.ellipsoid(name + side, (c[0] * sx, c[1], c[2]), r, m, sided(bone, side),
                           (rot[0], rot[1] * sx, rot[2] * sx), **kw)

    def eyes(self, x, y, z, r, m_eye, bone, m_pupil=None, angry=0.0, m_brow=None, slit=False):
        """Glowing/menacing eyes at (+-x, y, z), facing -y; angry tilts a brow plate over them."""
        for side, sx in (("L", -1), ("R", 1)):
            c = V((x * sx, y, z))
            self.ellipsoid("Eye" + side, c, (r, r * 0.45, r * (0.62 if angry else 0.9)), m_eye, bone,
                           rot=(0, 0, 0), segs=14, rings=8)
            if m_pupil:
                pr = (r * 0.22, r * 0.2, r * 0.6) if slit else (r * 0.45, r * 0.2, r * 0.45)
                self.ellipsoid("Pupil" + side, c + V((0, -r * 0.38, 0)), pr, m_pupil, bone, segs=10, rings=6)
            if m_brow:
                self.box("Brow" + side, c + V((0, -r * 0.25, r * 0.7)), (r * 2.6, r * 0.9, r * 0.45),
                         m_brow, bone, rot=(0, -angry * sx, 0), bevel=0.4)

    def teeth(self, name, pts, down, size, m, bone):
        for i, p in enumerate(pts):
            self.cone(f"{name}{i}", p, V(p) + V(down) * size, size * 0.35, m, bone, segs=5)

    # ---------- build
    def warp(self, fn):
        """Reshapes the whole creature (every part and bone) by fn(Vector) -> Vector before rigging, e.g. to lower
        a body and shorten its legs without touching the feet."""
        self.warps.append(fn)

    def _apply_warps(self):
        for fn in self.warps:
            for ob, _, _ in self.parts:
                for v in ob.data.vertices:
                    v.co = fn(v.co.copy())
                ob.data.update()
            for b in self.bones.values():
                b["head"], b["tail"] = fn(b["head"].copy()), fn(b["tail"].copy())

    def finish(self, export=True):
        self._apply_warps()
        rig = self._make_rig()
        body = self._join_and_weight(rig)
        from . import motion
        motion.make_clips(self, rig)
        if export:
            self.export(rig, body)
        return rig, body

    def _make_rig(self):
        arm = bpy.data.armatures.new(self.id + "_rig")
        rig = bpy.data.objects.new("Rig", arm)
        self.scene.collection.objects.link(rig)
        bpy.context.view_layer.objects.active = rig
        for o in bpy.context.selected_objects:
            o.select_set(False)
        rig.select_set(True)
        bpy.ops.object.mode_set(mode='EDIT')
        E = arm.edit_bones
        order = list(self.bones)
        made = set()
        while len(made) < len(order):
            for n in order:
                if n in made:
                    continue
                b = self.bones[n]
                if b["parent"] and b["parent"] not in made:
                    continue
                eb = E.new(n)
                eb.head, eb.tail = b["head"], b["tail"]
                eb.roll = 0
                eb.use_deform = b["deform"]
                if b["parent"]:
                    eb.parent = E[b["parent"]]
                made.add(n)
        bpy.ops.object.mode_set(mode='OBJECT')
        return rig

    def _join_and_weight(self, rig):
        deform = [n for n, b in self.bones.items() if b["deform"]]
        segs = {n: (self.bones[n]["head"], self.bones[n]["tail"]) for n in deform}
        for ob, bone, allowed in self.parts:
            if ob.name in self.auto_weight:
                self._heat_weight(ob, rig)
                continue
            for n in deform:
                ob.vertex_groups.new(name=n)
            if bone:
                ob.vertex_groups[bone].add(list(range(len(ob.data.vertices))), 1.0, 'REPLACE')
                continue
            cands = allowed or deform
            for v in ob.data.vertices:
                p = v.co
                ws = []
                for n in cands:
                    a, b = segs[n]
                    ab = b - a
                    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
                    d = (a + ab * t - p).length
                    ws.append((1.0 / max(d, 0.02) ** self.weight_power, n))
                ws.sort(reverse=True)
                ws = ws[:3]
                tot = sum(w for w, _ in ws)
                for w, n in ws:
                    if w / tot > 0.02:
                        ob.vertex_groups[n].add([v.index], w / tot, 'REPLACE')
        objs = [p[0] for p in self.parts]
        if self.auto_weight:
            # painted bodies carry vertex colours; give every other part plain white so the colours join cleanly
            for o in objs:
                if "Col" not in o.data.color_attributes:
                    a = o.data.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
                    for d in a.data:
                        d.color = (1, 1, 1, 1)
        for o in bpy.context.selected_objects:
            o.select_set(False)
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.join()
        body = bpy.context.active_object
        body.name = self.id
        body.data.name = self.id
        body.parent = rig
        mod = body.modifiers.new("Armature", 'ARMATURE')
        mod.object = rig
        return body

    def _heat_weight(self, ob, rig):
        """Blender's automatic (bone heat) weights for one sculpted part; falls back to envelope weights."""
        for o in bpy.context.selected_objects:
            o.select_set(False)
        ob.select_set(True)
        rig.select_set(True)
        bpy.context.view_layer.objects.active = rig
        try:
            bpy.ops.object.parent_set(type='ARMATURE_AUTO')
        except RuntimeError:
            bpy.ops.object.parent_set(type='ARMATURE_ENVELOPE')
        ob.modifiers.clear()
        mw = ob.matrix_world.copy()
        ob.parent = None
        ob.matrix_world = mw
        deform = [n for n, b in self.bones.items() if b["deform"]]
        for n in deform:
            if n not in ob.vertex_groups:
                ob.vertex_groups.new(name=n)
        unweighted = [v.index for v in ob.data.vertices if not v.groups]
        if unweighted:
            ob.vertex_groups[deform[0]].add(unweighted, 1.0, 'REPLACE')
        rig.select_set(False)

    def export(self, rig, body):
        import os
        os.makedirs(OUT_DIR, exist_ok=True)
        for o in bpy.context.selected_objects:
            o.select_set(False)
        body.select_set(True)
        rig.select_set(True)
        bpy.context.view_layer.objects.active = rig
        rig.animation_data.action = bpy.data.actions["Idle"]
        self.scene.frame_set(1)
        import contextlib, io
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            bpy.ops.export_scene.gltf(filepath=f"{OUT_DIR}/{self.id}.glb", export_format='GLB', use_selection=True,
                                      export_animations=True, export_animation_mode='ACTIONS', export_skins=True,
                                      export_yup=True, export_apply=False, export_force_sampling=True)


def euler(rot):
    from mathutils import Euler
    return Euler(tuple(math.radians(a) for a in rot), 'XYZ')


def sided(bone, side):
    if bone and bone.endswith(".S"):
        return bone[:-2] + "." + side
    return bone


def preview_setup(rig):
    """Light and sky for look() renders (not exported: export takes the selection only)."""
    scn = bpy.context.scene
    w = bpy.data.worlds[0] if bpy.data.worlds else bpy.data.worlds.new("W")
    scn.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.45, 0.5, 0.6, 1)
    bg.inputs[1].default_value = 1.0
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.0
    o = bpy.data.objects.new("Sun", sun)
    scn.collection.objects.link(o)
    o.rotation_euler = (math.radians(50), 0, math.radians(-30))
    rig.hide_set(True)


def run(cid, export=True):
    import importlib
    mod = importlib.import_module("forge.creatures." + cid)
    importlib.reload(mod)
    C = Creature(cid)
    # Legends keep full sculpt detail; everyone else is smaller on the board and gets 60% of the polygons
    # (keeps the web download in check).
    C.budget_scale = 1.0 if "legend)" in (mod.__doc__ or "") else 0.6
    if hasattr(mod, "DRESS"):
        from . import dress
        rig, meshes, D = dress.build(C, mod)
        if export:
            dress.export(C, rig, meshes)
        lo, hi = D.bounds()
        dims = hi - lo
        fit = game_fit(cid, dims)
        flag = "  <-- SHRUNK" if fit < 0.75 else ""
        return f"{cid}: dressed {mod.DRESS['src']}, {dims.x:.2f} x {dims.y:.2f} x {dims.z:.2f}, in-game size {fit:.2f}{flag}"
    mod.build(C)
    rig, body = C.finish(export)
    preview_setup(rig)
    v = len(body.data.vertices)
    dims = body.dimensions
    fit = game_fit(cid, dims)
    flag = "  <-- SHRUNK" if fit < 0.75 else ""
    return f"{cid}: {v} verts, {dims.x:.2f} x {dims.y:.2f} x {dims.z:.2f}, in-game size {fit:.2f}{flag}"


def game_fit(cid, dims):
    """How much of its intended standing height the creature keeps in game (CreatureView scales by height,
    then caps the larger of width/length at MAX_WIDTH 1.05)."""
    import re
    level = 1
    try:
        txt = open(f"{REPO}/data/cards/{cid}.tres").read()
        m = re.search(r"^level = (\d+)", txt, re.M)
        level = int(m.group(1)) if m else 1
    except OSError:
        pass
    h = [0.55, 0.55, 0.72, 0.95][max(0, min(3, level))]
    return min(1.0, 1.05 * dims.z / (max(dims.x, dims.y) * h))


def run_all(ids, export=True):
    """Builds several creatures in turn; one line per creature, errors included."""
    import traceback
    out = []
    for cid in ids:
        try:
            out.append(run(cid, export))
        except Exception:
            out.append(f"{cid}: FAILED\n" + traceback.format_exc(limit=3))
    return "\n".join(out)
