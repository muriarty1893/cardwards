"""Clay: sculpted bodies for forged creatures.

Instead of gluing primitives together, a body is modelled from many overlapping soft volumes (metaball
ellipsoids, like clay lumps) that melt into one surface. The surface is voxel-remeshed so it is one clean
skin, relaxed, optionally given a fine surface texture, decimated to a game budget and painted with vertex
colours: a colour per clay group blended softly where groups meet, darker underneath and in creases
(baked ambient occlusion), lighter on top.

    clay = Clay(C, "Body")
    clay.add((0, 0, 1), (0.3, 0.4, 0.3), group="hide")
    clay.add((0, -0.2, 1.2), (0.1, 0.1, 0.1), rot=(20, 0, 0), group="belly", neg=True)   # carve
    body = clay.build(colors={"hide": "8a1a14", "belly": "ffb03a"})
The body is weighted to the skeleton by Blender's heat weighting when the creature is finished.
"""
import math
import bpy
import bmesh
from mathutils import Vector as V, Euler, Matrix
from .core import srgb

FIELD_K = 1.76   # metaball size per unit of visible radius (measured: threshold 0.6, stiffness 2)


class Clay:
    _n = 0

    def __init__(self, C, name="Body", res=0.035):
        self.C = C
        self.name = name
        self.res = res
        self.els = []    # (center, radii, rot Euler, group, negative, stiffness)

    def add(self, c, r, rot=(0, 0, 0), group="base", neg=False, stiff=2.0):
        self.els.append((V(c), V(r), Euler(tuple(math.radians(a) for a in rot), 'XYZ'), group, neg, stiff))
        return self

    def mirror(self, c, r, rot=(0, 0, 0), group="base", neg=False, stiff=2.0):
        """Adds a left/right pair from a right-side (+x) element."""
        for sx in (-1, 1):
            self.add((c[0] * sx, c[1], c[2]), r, (rot[0], rot[1] * sx, rot[2] * sx), group, neg, stiff)
        return self

    def chain(self, pts, radii, group="base", rot=None, steps=3, stiff=2.0):
        """A run of lumps along points (necks, tails, limbs): radii given per point, interpolated between."""
        for i in range(len(pts) - 1):
            a, b = V(pts[i]), V(pts[i + 1])
            ra, rb = radii[i], radii[i + 1]
            ra = ra if isinstance(ra, (tuple, list)) else (ra, ra, ra)
            rb = rb if isinstance(rb, (tuple, list)) else (rb, rb, rb)
            d = b - a
            q = V((0, 0, 1)).rotation_difference(d.normalized()) if d.length > 1e-6 else None
            for s in range(steps + (1 if i == len(pts) - 2 else 0)):
                t = s / steps
                p = a.lerp(b, t)
                r = [ra[k] + (rb[k] - ra[k]) * t for k in range(3)]
                # stretch each lump a little along the run so they overlap smoothly
                seg = d.length / steps
                e = q.to_euler() if q else Euler()
                self.els.append((p, V((r[0], r[1], max(r[2], seg * 0.8))), e, group, False, stiff))
        return self

    # ------------------------------------------------------------------ build
    def build(self, colors, voxel=0.018, relax=6, budget=9000, texture=None, ao=0.55, top_light=0.18,
              under_dark=0.22, bone=None, allowed=None):
        C = self.C
        Clay._n += 1
        fam = f"Clay{Clay._n}"
        mb = bpy.data.metaballs.new(fam)
        mb.resolution = self.res
        mb.render_resolution = self.res
        mb.threshold = 0.6
        for (c, r, rot, g, neg, stiff) in self.els:
            el = mb.elements.new(type='ELLIPSOID')
            el.co = c
            el.radius = 1.0
            el.size_x, el.size_y, el.size_z = (r.x * FIELD_K, r.y * FIELD_K, r.z * FIELD_K)
            el.rotation = rot.to_quaternion()
            el.stiffness = stiff
            el.use_negative = neg
        ob = bpy.data.objects.new(fam, mb)
        C.scene.collection.objects.link(ob)
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.metaballs.remove(mb)
        tmp = bpy.data.objects.new(self.name + "_tmp", me)
        C.scene.collection.objects.link(tmp)
        rm = tmp.modifiers.new("Remesh", 'REMESH')
        rm.mode = 'VOXEL'
        rm.voxel_size = voxel
        rm.use_smooth_shade = True
        if relax:
            sm = tmp.modifiers.new("Relax", 'LAPLACIANSMOOTH')
            sm.lambda_factor = 0.6
            sm.iterations = relax
            sm.use_volume_preserve = True
        if texture:
            tex = bpy.data.textures.new(self.name + "_tex", texture.get("type", 'VORONOI'))
            if hasattr(tex, "noise_scale"):
                tex.noise_scale = texture.get("scale", 0.05)
            dp = tmp.modifiers.new("Detail", 'DISPLACE')
            dp.texture = tex
            dp.strength = texture.get("strength", 0.01)
            dp.mid_level = 0.5
        dc = tmp.modifiers.new("Budget", 'DECIMATE')
        dg = bpy.context.evaluated_depsgraph_get()
        n = len(tmp.evaluated_get(dg).data.polygons)
        dc.ratio = min(1.0, budget / max(n, 1))
        dg = bpy.context.evaluated_depsgraph_get()
        me2 = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
        bpy.data.objects.remove(tmp, do_unlink=True)
        bpy.data.meshes.remove(me)
        me2.name = self.name
        for f in me2.polygons:
            f.use_smooth = True
        body = C._link(self.name, me2, None, bone, True, allowed)
        C.auto_weight.add(self.name)
        self.paint(body, colors, ao, top_light, under_dark)
        return body

    # ------------------------------------------------------------------ colour
    def _field(self, p, el):
        c, r, rot, g, neg, stiff = el
        q = rot.to_matrix().inverted() @ (p - c)
        d = math.sqrt((q.x / r.x) ** 2 + (q.y / r.y) ** 2 + (q.z / r.z) ** 2)
        return max(0.0, 1.6 - d) ** 3

    def paint(self, ob, colors, ao, top_light, under_dark):
        """Vertex colours: blended group colours, lit from above, darkened below and in the creases."""
        me = ob.data
        lin = {g: V(srgb(h)) for g, h in colors.items()}
        default = next(iter(lin.values()))
        groups = [e for e in self.els if not e[4]]
        cols = []
        for v in me.vertices:
            acc, tot = V((0, 0, 0)), 0.0
            for el in groups:
                w = self._field(v.co, el)
                if w > 0:
                    acc += lin.get(el[3], default) * w
                    tot += w
            col = acc / tot if tot > 0 else default.copy()
            cols.append(col)
        occ = self._occlusion(ob) if ao else [1.0] * len(cols)
        attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
        shade = me.attributes.new("Shade", 'FLOAT', 'POINT')
        for i, col in enumerate(cols):
            nz = me.vertices[i].normal.z
            k = (1.0 - ao * (1.0 - occ[i])) * (1.0 + top_light * max(0.0, nz) - under_dark * max(0.0, -nz))
            shade.data[i].value = k
            attr.data[i].color = (col.x * k, col.y * k, col.z * k, 1.0)
        me.color_attributes.active_color = attr
        mat = bpy.data.materials.new(self.name + "_paint")
        mat.use_nodes = True
        nt = mat.node_tree
        p = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        ca = nt.nodes.new("ShaderNodeVertexColor")
        ca.layer_name = "Col"
        nt.links.new(ca.outputs["Color"], p.inputs["Base Color"])
        p.inputs["Roughness"].default_value = 0.7
        me.materials.clear()
        me.materials.append(mat)

    def _occlusion(self, ob, rays=14, dist=0.35):
        """Cheap ambient occlusion per vertex: fraction of short hemisphere rays that escape the body."""
        from mathutils.bvhtree import BVHTree
        bvh = BVHTree.FromObject(ob, bpy.context.evaluated_depsgraph_get())
        dirs = []
        golden = math.pi * (3 - math.sqrt(5))
        for i in range(rays):
            z = 1 - (i + 0.5) / rays
            r = math.sqrt(max(0.0, 1 - z * z))
            a = golden * i
            dirs.append(V((math.cos(a) * r, math.sin(a) * r, z)))
        out = []
        for v in ob.data.vertices:
            n = v.normal
            q = V((0, 0, 1)).rotation_difference(n)
            o = v.co + n * 0.004
            free = 0
            for d in dirs:
                hit = bvh.ray_cast(o, q @ d, dist)
                if hit[0] is None:
                    free += 1
            out.append(free / rays)
        # soften
        return out


def recolor(ob, fn, hexcol, soft=True):
    """Blends a colour into a painted body where fn(position, normal) gives a weight 0..1 (bellies, stripes,
    markings), keeping the body's baked light and occlusion."""
    me = ob.data
    attr = me.color_attributes["Col"]
    shade = me.attributes["Shade"]
    c = V(srgb(hexcol))
    for i, v in enumerate(me.vertices):
        w = max(0.0, min(1.0, fn(v.co, v.normal)))
        if w <= 0:
            continue
        old = V(attr.data[i].color[:3])
        mix = old.lerp(c * shade.data[i].value, w)
        attr.data[i].color = (mix.x, mix.y, mix.z, 1.0)


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def _h3(i, j, k, s):
    n = (i * 73856093) ^ (j * 19349663) ^ (k * 83492791) ^ (s * 2654435761)
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return (n & 0xFFFF) / 65535.0


def cracks(p, scale=0.12, width=0.18, seed=1):
    """0..1 weight along a web of thin cracks (cell borders of 3D Voronoi cells about `scale` across): magma
    veins, ice fractures, stone seams. width is the crack thickness as a fraction of a cell."""
    q = V((p.x / scale, p.y / scale, p.z / scale))
    ci, cj, ck = math.floor(q.x), math.floor(q.y), math.floor(q.z)
    d1 = d2 = 9.0
    for i in range(ci - 1, ci + 2):
        for j in range(cj - 1, cj + 2):
            for k in range(ck - 1, ck + 2):
                f = V((i + _h3(i, j, k, seed), j + _h3(i, j, k, seed + 7), k + _h3(i, j, k, seed + 13)))
                d = (f - q).length
                if d < d1:
                    d1, d2 = d, d1
                elif d < d2:
                    d2 = d
    return smoothstep(width, 0.0, d2 - d1)
