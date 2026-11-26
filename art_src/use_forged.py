"""Points VisualDB entries at forged models: python3 art_src/use_forged.py id [id...]"""
import re, sys
p = "view/visual_db.gd"
s = open(p).read()
for cid in sys.argv[1:]:
    pat = re.compile(r'(\t&"%s": )\{[^}\n]*\}' % re.escape(cid))
    new = r'\1{"model": "forged/%s.glb", "tint": &"none"}' % cid
    s, n = pat.subn(new, s, count=1)
    print(cid, "ok" if n else "NOT FOUND")
open(p, "w").write(s)
