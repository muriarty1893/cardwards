# Writes the Dark Moon expansion's card .tres files (spec docs/superpowers/specs/2026-11-25-dark-moon-design.md).
#   python3 tools/data/gen_dark_moon_cards.py data/cards
import os, sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "data/cards"
M, E, C, F, N, D = 0, 1, 2, 3, 4, 5      # lands (N = Neutral)
CR, BU, SP = 0, 1, 2                     # kinds
INT = ("amount", "amount2", "filter_kind", "filter_land", "need")
SN = ("when", "op", "who", "keyword", "cond", "card_id", "tribe", "need_cond")


def e(when, op, amount=0, who="own_hero", **kw):
    d = dict(when=when, op=op, amount=amount, who=who)
    d.update(kw)
    return d


def card(id, name, kind, land, cost, atk=0, hp=0, level=None, kw=(), tribe="", sp=0, field=False,
         effects=(), legendary=False, curse=False, allows_40=False, follower="", collectible=True, deck_legal=True):
    return dict(id=id, name=name, kind=kind, land=land, cost=cost, atk=atk, hp=hp,
                level=(level if level is not None else (1 if kind == CR else 0)), kw=list(kw), tribe=tribe, sp=sp,
                field=field, effects=list(effects), legendary=legendary, curse=curse, allows_40=allows_40,
                follower=follower, collectible=collectible, deck_legal=deck_legal)


def write(c):
    lines = ['[gd_resource type="Resource" script_class="CardData" format=3]', '',
             '[ext_resource type="Script" path="res://core/card_data.gd" id="1_card"]',
             '[ext_resource type="Script" path="res://core/effect_data.gd" id="2_eff"]', '']
    subs = []
    for i, ef in enumerate(c["effects"]):
        rid = "eff_%s_%d" % (c["id"], i)
        subs.append(rid)
        lines.append('[sub_resource type="Resource" id="%s"]' % rid)
        lines.append('script = ExtResource("2_eff")')
        for k in SN:
            if k in ef and ef[k] != "":
                lines.append('%s = &"%s"' % (k, ef[k]))
        for k in INT:
            if k in ef:
                lines.append('%s = %d' % (k, ef[k]))
        for k in ("combo", "gift"):
            if ef.get(k):
                lines.append('%s = true' % k)
        lines.append('')
    lines += ['[resource]', 'script = ExtResource("1_card")', 'id = &"%s"' % c["id"], 'display_name = "%s"' % c["name"],
              'kind = %d' % c["kind"], 'land = %d' % c["land"], 'level = %d' % c["level"], 'cost = %d' % c["cost"]]
    if c["kind"] == CR:
        lines += ['attack = %d' % c["atk"], 'health = %d' % c["hp"]]
    if c["kw"]:
        lines.append('keywords = Array[StringName]([%s])' % ", ".join('&"%s"' % k for k in c["kw"]))
    if c["sp"]:
        lines.append('spell_power = %d' % c["sp"])
    if c["tribe"]:
        lines.append('tribe = &"%s"' % c["tribe"])
    if c["field"]:
        lines.append('field = true')
    if subs:
        lines.append('effects = Array[ExtResource("2_eff")]([%s])' % ", ".join('SubResource("%s")' % r for r in subs))
    if not c["collectible"]:
        lines.append('collectible = false')
    for k in ("legendary", "curse", "allows_40"):
        if c[k]:
            lines.append('%s = true' % k)
    if not c["deck_legal"]:
        lines.append('deck_legal = false')
    if c["follower"]:
        lines.append('follower_id = &"%s"' % c["follower"])
    with open(os.path.join(OUT, c["id"] + ".tres"), "w") as f:
        f.write("\n".join(lines) + "\n")


CARDS = [
    # --- Dark Moon (Neutral legendary) and its two direction choices
    card("dark_moon", "Dark Moon", SP, N, 4, effects=[e("on_play", "dark_moon")], legendary=True),
    card("moon_left", "Wane Left", SP, N, 0, collectible=False, deck_legal=False),
    card("moon_right", "Wax Right", SP, N, 0, collectible=False, deck_legal=False),
]

if __name__ == "__main__":
    for c in CARDS:
        write(c)
    print("wrote", len(CARDS), "cards")
