# Builds ../matches_arabic.txt and ../mismatches_arabic.txt from pairs_ar.txt.
# requires: pip install wordfreq arabic-reshaper python-bidi
# run from this directory: python build.py
import random, re, sys
from wordfreq import zipf_frequency as z
import arabic_reshaper
from bidi.algorithm import get_display

LEN_W = 0.25      # easiness lost per letter beyond 4
TIER_PEN = 0.75   # easiness lost for a weaker (tier 2) relation

def letters(w): return len(re.sub(r'[ً-ْـ]', '', w))
# sense-specific frequency estimates for words whose wordfreq count is inflated by a
# common homograph (e.g. نحو grammar vs. نحو 'towards'); Zipf values are estimates
OVERRIDE = {'نحو': 3.6, 'صرف': 3.3, 'جزر': 3.3, 'قدر': 3.4, 'جد': 4.3, 'عم': 4.2,
            'حر': 4.2, 'سن': 3.9, 'كف': 3.8, 'شعر': 4.4, 'راع': 2.6, 'عود': 3.3,
            'ظل': 4.3, 'جراح': 3.3, 'سلم': 3.6, 'حمص': 3.3, 'تمر': 3.7, 'خيار': 3.1,
            'دين': 4.2, 'طابع': 3.4, 'عرض': 4.3, 'مهر': 2.8}
def zipf(w): return OVERRIDE.get(w, z(w, 'ar'))
def easy(w): return round(zipf(w) - LEN_W * (letters(w) - 4), 3)
def disp(w): return get_display(arabic_reshaper.reshape(w))

pairs = []; cat = {}; cur = ''
for l in open('pairs_ar.txt', encoding='utf8'):
    l = l.strip()
    if l.startswith('# '): cur = l; continue
    if not l or l.startswith('#'): continue
    p = l.split(); pairs.append((p[0], p[1], int(p[2]) if len(p) > 2 else 1))
    for w in p[:2]: cat.setdefault(w, set()).add(cur)

# relation graph from matches
adj = {}
def link(a, b):
    adj.setdefault(a, set()).add(b); adj.setdefault(b, set()).add(a)
for a, b, t in pairs: link(a, b)
def related(a, b):
    if a == b or b in adj.get(a, ()) or cat[a] & cat[b]: return True
    return bool(adj.get(a, set()) & adj.get(b, set()))  # 2 hops

m = []
for a, b, t in pairs:
    ea, eb = easy(a), easy(b)
    m.append((a, b, ea, eb, round((ea + eb) / 2 - TIER_PEN * (t - 1), 3)))
m.sort(key=lambda r: -r[4])

# mismatches: each word used once, partner chosen among nearby-easiness words
random.seed(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
words = sorted({w for r in m for w in r[:2]}, key=lambda w: (-easy(w), w))
banned = set(frozenset(l.split()[:2]) for fn in ('bad_mismatch.txt', 'bad_mismatch2.txt') for l in open(fn, encoding='utf8') if len(l.split()) >= 2)
used = set(); mm = []
for i, w in enumerate(words):
    if w in used: continue
    cands = [v for v in words[i+1:i+25] if v not in used and not related(w, v) and frozenset((w, v)) not in banned]
    if not cands: continue
    v = random.choice(cands[:8])
    used |= {w, v}
    a, b = (w, v) if random.random() < 0.5 else (v, w)
    ea, eb = easy(a), easy(b)
    mm.append((a, b, ea, eb, round((ea + eb) / 2, 3)))
# final review round: drop these pairs and re-pair the freed words among themselves
banned2 = set(frozenset(l.split()[:2]) for l in open('bad_mismatch3.txt', encoding='utf8') if len(l.split()) >= 2)
freed = sorted({w for r in mm if frozenset(r[:2]) in banned2 for w in r[:2]}, key=lambda w: (-easy(w), w))
mm = [r for r in mm if frozenset(r[:2]) not in banned2]
used = set()
for i, w in enumerate(freed):
    if w in used: continue
    cands = [v for v in freed[i+1:] if v not in used and not related(w, v) and frozenset((w, v)) not in banned | banned2]
    if not cands: continue
    v = cands[0]; used |= {w, v}
    ea, eb = easy(w), easy(v)
    mm.append((w, v, ea, eb, round((ea + eb) / 2, 3))); print('NEW', w, v)
# re-paired pairs that still failed review are simply dropped
drop = {frozenset(p) for p in [('قدم', 'حياة'), ('نظر', 'ضوء'), ('طعام', 'فساد'), ('فن', 'سوق')]}
mm = [r for r in mm if frozenset(r[:2]) not in drop]
mm.sort(key=lambda r: -r[4])

hdr = 'word1\tword2\tword1_disp\tword2_disp\tword1_easy\tword2_easy\tpair_easy\n'
for fn, rows in (('../matches_arabic.txt', m), ('../mismatches_arabic.txt', mm)):
    with open(fn, 'w', encoding='utf8', newline='\n') as f:
        f.write(hdr)
        for a, b, ea, eb, e in rows:
            f.write(f'{a}\t{b}\t{disp(a)}\t{disp(b)}\t{ea}\t{eb}\t{e}\n')
    print(fn, len(rows))
