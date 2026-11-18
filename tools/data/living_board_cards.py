#!/usr/bin/env python3
"""One-off data edit for the living board (spec section 10): tribes, new effect steps, new cards
and deck swaps. Idempotent: re-running leaves files unchanged."""
import re, os, sys, random, string

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
CARDS = os.path.join(ROOT, 'data', 'cards')
DECKS = os.path.join(ROOT, 'data', 'decks')
EFF_SCRIPT = 'res://core/effect_data.gd'
CARD_SCRIPT = 'res://core/card_data.gd'

TRIBES = {
    'beast': ['cinderpup', 'blazehorn', 'frostfang', 'snowmite', 'blizzard_titan', 'glacier_tortoise', 'bonbon_behemoth'],
    'flyer': ['ashmite', 'flarebeak', 'inferno_drake', 'rimewing', 'lollibat'],
    'blob': ['gumdrop', 'taffy_snail', 'jellywobble', 'mossback'],
    'sprout': ['sporeling', 'puffcap', 'glimmer_morel', 'rootstalker', 'elder_shroomhulk'],
    'spirit': ['sugar_sprite', 'iceling', 'magmaw'],
}

# card -> list of effect dicts to append (each gets a stable sub_resource id).
ADD = {
    'mossback': [dict(when='on_play', op='armour', amount=2, who='own_hero')],
    'glacier_tortoise': [dict(when='on_play', op='armour', amount=3, who='own_hero')],
    'cinderpup': [dict(when='on_play', op='buff', amount=1, amount2=1, who='self', tribe='beast', need=1),
                  dict(when='on_level_up', op='give_keyword', keyword='flurry', who='self')],
    'rimewing': [dict(when='on_play', op='draw', amount=1, who='own_hero', tribe='flyer', need=1)],
    'taffy_snail': [dict(when='on_play', op='gain_magic', amount=1, who='own_hero', tribe='blob', need=2)],
    'glimmer_morel': [dict(when='on_play', op='armour', amount=3, who='own_hero', tribe='sprout', need=1)],
    'sugar_sprite': [dict(when='on_level_up', op='draw', amount=1, who='own_hero')],
    'flarebeak': [dict(when='on_level_up', op='damage', amount=1, who='enemy_hero')],
    'iceling': [dict(when='on_level_up', op='give_keyword', keyword='bubble', who='self')],
    'sporeling': [dict(when='on_level_up', op='heal', amount=2, who='own_hero')],
    'snowmite': [dict(when='on_level_up', op='freeze', who='opposing')],
}

M, E, K, F = 0, 1, 2, 3
NEW = {
    'volcano': dict(name='Volcano', land=E, cost=4, field=True, effects=[
        dict(when='field_aura', op='on_land_atk', amount=1, who='own_hero', filter_land=E),
        dict(when='field_end', op='damage', amount=1, who='own_on_land', filter_land=F)]),
    'snowstorm': dict(name='Snowstorm', land=F, cost=4, field=True, effects=[
        dict(when='field_aura', op='off_land_atk', amount=-1, who='own_hero', filter_land=F),
        dict(when='field_aura', op='no_quirk', who='own_hero', filter_land=E)]),
    'spore_bloom': dict(name='Spore Bloom', land=M, cost=3, field=True, effects=[
        dict(when='field_start', op='sprout_meadow', who='own_hero'),
        dict(when='field_aura', op='on_land_hp', amount=1, who='own_hero', filter_land=M)]),
    'sugar_rain': dict(name='Sugar Rain', land=K, cost=3, field=True, effects=[
        dict(when='field_start', op='land_draw', amount=1, who='own_hero', filter_land=K)]),
    'bark_shield': dict(name='Bark Shield', land=M, cost=1, effects=[
        dict(when='on_play', op='armour', amount=4, who='own_hero')]),
    'candy_shell': dict(name='Candy Shell', land=K, cost=2, effects=[
        dict(when='on_play', op='armour', amount=3, who='own_hero'),
        dict(when='on_play', op='draw', amount=1, who='own_hero')]),
}

DECK_SWAPS = {
    'blaze_rush': ({'sugar_rush': 2}, {'volcano': 1, 'candy_shell': 1}),
    'deep_freeze': ({'ashmite': 2}, {'snowstorm': 1, 'bark_shield': 1}),
    'grove_guard': ({'regrowth': 2}, {'spore_bloom': 1, 'bark_shield': 1}),
    'sugar_storm': ({'swap_trick': 1, 'spore_hut': 1}, {'sugar_rain': 1, 'candy_shell': 1}),
}


def sub_id(card, i):
    return 'Resource_lb_%s_%d' % (card[:10], i)


def eff_block(sid, eff_ext, e):
    lines = ['[sub_resource type="Resource" id="%s"]' % sid, 'script = ExtResource("%s")' % eff_ext]
    lines.append('when = &"%s"' % e['when'])
    lines.append('op = &"%s"' % e['op'])
    for k in ('amount', 'amount2'):
        if k in e:
            lines.append('%s = %d' % (k, e[k]))
    lines.append('who = &"%s"' % e.get('who', 'own_hero'))
    if 'keyword' in e:
        lines.append('keyword = &"%s"' % e['keyword'])
    if 'filter_land' in e:
        lines.append('filter_land = %d' % e['filter_land'])
    if 'tribe' in e:
        lines.append('tribe = &"%s"' % e['tribe'])
        lines.append('need = %d' % e['need'])
    return '\n'.join(lines) + '\n'


def ensure_eff_ext(t):
    m = re.search(r'\[ext_resource type="Script" path="%s" id="([^"]+)"\]' % re.escape(EFF_SCRIPT), t)
    if m:
        return t, m.group(1)
    card_ext = re.search(r'(\[ext_resource type="Script" path="%s" id="[^"]+"\]\n)' % re.escape(CARD_SCRIPT), t)
    line = '[ext_resource type="Script" path="%s" id="1_effect"]\n' % EFF_SCRIPT
    t = t.replace(card_ext.group(1), card_ext.group(1) + line, 1)
    return t, '1_effect'


def edit_card(cid):
    path = os.path.join(CARDS, cid + '.tres')
    t = open(path).read()
    head, res = t.split('[resource]\n', 1)
    tribe = next((tr for tr, ids in TRIBES.items() if cid in ids), None)
    if tribe and 'tribe = ' not in res:
        res = res.replace('\nkeywords = ', '\ntribe = &"%s"\nkeywords = ' % tribe, 1) if '\nkeywords = ' in res else res.rstrip('\n') + '\ntribe = &"%s"\n' % tribe
    if cid in ADD and sub_id(cid, 0) not in head:
        t2, eff_ext = ensure_eff_ext(head)
        head = t2
        blocks = ''
        refs = []
        for i, e in enumerate(ADD[cid]):
            sid = sub_id(cid, i)
            blocks += eff_block(sid, eff_ext, e) + '\n'
            refs.append('SubResource("%s")' % sid)
        head = head.rstrip('\n') + '\n\n' + blocks
        m = re.search(r'^effects = Array\[ExtResource\("[^"]+"\)\]\(\[(.*)\]\)$', res, re.M)
        if m:
            res = res.replace(m.group(0), 'effects = Array[ExtResource("%s")]([%s, %s])' % (eff_ext, m.group(1), ', '.join(refs)))
        else:
            res = res.rstrip('\n') + '\neffects = Array[ExtResource("%s")]([%s])\n' % (eff_ext, ', '.join(refs))
    out = head + '[resource]\n' + res
    if out != t:
        open(path, 'w').write(out)
        print('edited', cid)


def new_card(cid, d):
    path = os.path.join(CARDS, cid + '.tres')
    if os.path.exists(path):
        return
    lines = ['[gd_resource type="Resource" script_class="CardData" format=3]', '',
             '[ext_resource type="Script" path="%s" id="1_card"]' % CARD_SCRIPT,
             '[ext_resource type="Script" path="%s" id="1_effect"]' % EFF_SCRIPT, '']
    refs = []
    for i, e in enumerate(d['effects']):
        sid = sub_id(cid, i)
        lines.append(eff_block(sid, '1_effect', e))
        refs.append('SubResource("%s")' % sid)
    lines += ['[resource]', 'script = ExtResource("1_card")', 'id = &"%s"' % cid,
              'display_name = "%s"' % d['name'], 'kind = 2', 'land = %d' % d['land'], 'cost = %d' % d['cost']]
    if d.get('field'):
        lines.append('field = true')
    lines.append('effects = Array[ExtResource("1_effect")]([%s])' % ', '.join(refs))
    open(path, 'w').write('\n'.join(lines) + '\n')
    print('created', cid)


def edit_deck(did, remove, add):
    path = os.path.join(DECKS, did + '.tres')
    t = open(path).read()
    ids = {m.group(2): m.group(1) for m in re.finditer(r'\[ext_resource type="Resource"[^\]]*path="res://data/cards/([a-z_]+)\.tres" id="([^"]+)"\]', t)}
    rev = {v: k for k, v in ids.items()}
    if any(c in rev for c in add):
        return
    m = re.search(r'^cards = Array\[Resource\]\(\[(.*)\]\)$', t, re.M)
    refs = re.findall(r'ExtResource\("([^"]+)"\)', m.group(1))
    for cid, n in remove.items():
        for _ in range(n):
            refs.remove(rev[cid])
    ext_lines = ''
    for cid, n in add.items():
        eid = 'lb_' + cid
        ext_lines += '[ext_resource type="Resource" path="res://data/cards/%s.tres" id="%s"]\n' % (cid, eid)
        refs += [eid] * n
    last_ext = list(re.finditer(r'\[ext_resource [^\]]*\]\n', t))[-1]
    t = t[:last_ext.end()] + ext_lines + t[last_ext.end():]
    t = t.replace(m.group(0), 'cards = Array[Resource]([%s])' % ', '.join('ExtResource("%s")' % r for r in refs))
    open(path, 'w').write(t)
    print('deck', did, len(refs))


for cid in sorted(set(sum(TRIBES.values(), [])) | set(ADD)):
    edit_card(cid)
for cid, d in NEW.items():
    new_card(cid, d)
for did, (rm, ad) in DECK_SWAPS.items():
    edit_deck(did, rm, ad)
