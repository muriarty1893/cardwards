"""Dressing free models: for cards that really are an animal (a wolf, a fox, a raptor), a professionally made
CC0 model with proper anatomy and animation (Quaternius, from Poly Pizza; sources in art_src/models/) is
dressed for its card instead of being sculpted: recoloured by material name, given card props parented to its
bones (built with the forge's own primitives), its clips renamed to the game's (Idle, Walk, Punch, HitReact,
Death, Yes) and the rest dropped. A dressed recipe sets DRESS and defines dress(C, D):

    DRESS = dict(src="wolf", colors={"Main": "d8843a"}, anims={"Idle": "Idle", "Walk": "Walk", ...})
    def dress(C, D):
        C.palette(shard="ff6aa0")
        C.cone("Shard", D.at("Neck", 0.5) + V((0, 0, 0.1)), ..., 0.04, "shard", "Neck")   # bone = model bone

Models face -y with feet on z = 0 and are scaled to `height` metres, like forge creatures.
"""
import os
import re
import bpy
from mathutils import Vector as V, Matrix
from .core import srgb

SRC_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models")


class Dressed:
    def __init__(self, arm, meshes):
        self.arm = arm
        self.meshes = meshes

    def at(self, bone, t=0.0):
        """World point along a model bone in its rest pose (t = 0 head, 1 tail)."""
        b = self.arm.data.bones[bone]
        mw = self.arm.matrix_world
        return (mw @ b.head_local).lerp(mw @ b.tail_local, t)

    def last(self, prefix):
        """The highest-numbered bone whose name starts with prefix (Tail -> Tail3)."""
        names = sorted((b.name for b in self.arm.data.bones if b.name.startswith(prefix)),
                       key=lambda n: (len(n), n))
        return names[-1]

    def top(self, bone, t=0.5, up=(0, 0, 1)):
        """Point on the model's skin above a bone point (ray cast down onto it), for props that sit on the
        surface (crests, saddles, horns). Falls back to the bone point."""
        p = self.at(bone, t)
        d = V(up).normalized()
        dg = bpy.context.evaluated_depsgraph_get()
        ok, loc, nor, idx, ob, mx = bpy.context.scene.ray_cast(dg, p + d * 3.0, -d)
        return loc if ok and ob in self.meshes else p

    def bounds(self):
        pts = [m.matrix_world @ V(c) for m in self.meshes for c in m.bound_box]
        lo = V((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = V((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        return lo, hi


def _base(name):
    return re.sub(r"\.\d+$", "", name)


def build(C, mod):
    spec = mod.DRESS
    path = os.path.join(SRC_DIR, spec["src"] + ".glb")
    for a in list(bpy.data.actions):                     # no stale clips from an earlier model
        bpy.data.actions.remove(a)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next(o for o in new if o.type == 'ARMATURE')
    def skinned(o):
        return any(m.type == 'ARMATURE' and m.object == arm for m in o.modifiers) or o.parent == arm
    meshes = [o for o in new if o.type == 'MESH' and skinned(o)]
    drop = [o for o in new if (o.type == 'MESH' and o not in meshes) or o.type in ('CAMERA', 'LIGHT')]
    for o in drop:                                         # stray helpers some model files carry
        bpy.data.objects.remove(o, do_unlink=True)
    new = [o for o in bpy.data.objects if o not in before]
    root = arm
    while root.parent:
        root = root.parent
    arm.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    D = Dressed(arm, meshes)
    # face -y: point the head away from the hips along -y
    head = spec.get("head_bone", "Head")
    tail_end = spec.get("rear_bone")
    hb = D.at(head, 1.0)
    rb = D.at(tail_end) if tail_end else (D.bounds()[0] + D.bounds()[1]) / 2
    d = hb - rb
    import math
    ang = math.atan2(d.x, -d.y)            # rotation needed about z so that d points to -y
    root.rotation_mode = 'XYZ'
    root.rotation_euler.z += ang + math.radians(spec.get("turn", 0.0))
    bpy.context.view_layer.update()
    lo, hi = D.bounds()
    s = spec.get("height", 1.0) / max(hi.z - lo.z, 1e-4)
    root.scale = root.scale * s
    bpy.context.view_layer.update()
    lo, hi = D.bounds()
    root.location += V((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
    bpy.context.view_layer.update()
    # recolour by material name
    cols = spec.get("colors", {})
    for m in meshes:
        for mat in m.data.materials:
            if mat is None:
                continue
            h = cols.get(_base(mat.name))
            if h is None:
                continue
            p = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            if p:
                p.inputs["Base Color"].default_value = (*srgb(h), 1)
            mat.diffuse_color = (*srgb(h), 1)
    # card props, parented to the model's bones in its rest pose
    C.parts = []
    mod.dress(C, D)
    for ob, bone, allowed in C.parts:
        mw = ob.matrix_world.copy()
        ob.parent = arm
        if bone and bone in arm.data.bones:
            ob.parent_type = 'BONE'
            ob.parent_bone = bone
        bpy.context.view_layer.update()
        ob.matrix_world = mw
    arm.data.pose_position = 'POSE'
    # clips: rename the ones we use, drop the rest
    keep = {}
    acts = list(bpy.data.actions)
    for ours, theirs in spec["anims"].items():
        a = next((a for a in acts if a.name == theirs), None) or \
            next((a for a in acts if a.name.endswith("|" + theirs) or a.name.endswith("_" + theirs)), None)
        if a is None:
            raise RuntimeError(f"{C.id}: no clip {theirs} in {[x.name for x in acts]}")
        keep[ours] = a
    for a in acts:
        if a not in keep.values():
            bpy.data.actions.remove(a)
    used = set()
    for ours, a in list(keep.items()):
        if a in used:                      # one clip under two names (e.g. no hit clip: reuse idle)
            a = a.copy()
            keep[ours] = a
        used.add(a)
    for ours, a in keep.items():
        a.name = ours
        a.use_fake_user = True
    if arm.animation_data is None:
        arm.animation_data_create()
    for tr in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(tr)
    arm.animation_data.action = bpy.data.actions["Idle"]
    return arm, meshes, D


def export(C, arm, meshes):
    from .core import OUT_DIR
    os.makedirs(OUT_DIR, exist_ok=True)
    for o in bpy.context.selected_objects:
        o.select_set(False)
    objs = [arm] + meshes + [p[0] for p in C.parts]
    for o in objs:
        o.select_set(True)
    root = arm
    while root.parent:
        root = root.parent
        root.select_set(True)
    for o in bpy.context.scene.objects:            # empties in the model's hierarchy
        if o.type == 'EMPTY':
            o.select_set(True)
    bpy.context.view_layer.objects.active = arm
    arm.animation_data.action = bpy.data.actions["Idle"]
    C.scene.frame_set(1)
    import contextlib, io
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        bpy.ops.export_scene.gltf(filepath=f"{OUT_DIR}/{C.id}.glb", export_format='GLB', use_selection=True,
                                  export_animations=True, export_animation_mode='ACTIONS', export_skins=True,
                                  export_yup=True, export_apply=False, export_force_sampling=True)
