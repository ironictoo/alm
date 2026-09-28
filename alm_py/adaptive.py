"""Adaptive semantic matching (paradigms 1-4) and adaptive rhyming judgment (paradigms 13-16).

Follows AdaptiveLanguageMapping.m. Paradigm numbers match the MATLAB version so history files are shared.
Paradigm n: (n - 1) % 4 == 0 training, 1 practice, 2 standard scan (6:40), 3 quick scan (4:00).
"""
import math
import random

from psychopy import visual
from psychtoolbox import GetSecs

from common import append_history, mround, path, read_history, rgb, stamp

N_LEVELS = 7
BLOCK_LENGTH = 20
MIN_STIMS, MAX_STIMS = 4, 10  # trials per block at the easiest / hardest level
IGNORE_WINDOW = 0.3  # presses this soon after onset belong to the previous trial
ITI = 0.1
STEP_HARDER, STEP_EASIER = 1, 2
N_VERY_EASY = 100
TRAINING_KEYS = {'w': 1, 'e': 2, 'r': 3, 't': 4, 'y': 5, 'u': 6, 'i': 7}  # set difficulty
COMMAND_KEYS = {'s': (1, 1), 'd': (1, 0), 'f': (2, 1), 'g': (2, 0)}  # present (cond, match)


def read_rows(fname, header=True):
    with open(path('paradigms', fname), encoding='utf8') as f:
        rows = [line.split() for line in f.read().splitlines()]
    return [r for r in (rows[1:] if header else rows) if r]


def diff_ranges(n):
    """Item numbers (1-based) at each difficulty level: 100 very easy items, then the rest split evenly."""
    ranges = [list(range(1, N_VERY_EASY + 1))]
    for i in range(2, N_LEVELS + 1):
        end = N_VERY_EASY + math.ceil((i - 1) / (N_LEVELS - 1) * (n - N_VERY_EASY))
        ranges.append(list(range(ranges[-1][-1] + 1, end + 1)))
    return ranges


def load_semantic():
    """{language: (matches, mismatches, match ranges, mismatch ranges)}; lists are easiest first."""
    lists = {}
    for language, mfile, mmfile, mm_header, cols, mm_cols in [
            ('English', 'matches.txt', 'mismatches.txt', False, (1, 2), (0, 2)),
            ('Spanish', 'matches_spanish.txt', 'mismatches_spanish.txt', True, (0, 1), (0, 1)),
            ('Arabic', 'matches_arabic.txt', 'mismatches_arabic.txt', True, (2, 3), (2, 3))]:  # pre-shaped Arabic
        matches = [(r[cols[0]], r[cols[1]]) for r in read_rows(mfile)]
        mismatches = [(r[mm_cols[0]], r[mm_cols[1]]) for r in read_rows(mmfile, mm_header)]
        # English mismatches use the match ranges, as in the MATLAB version
        mm_n = len(matches) if language == 'English' else len(mismatches)
        lists[language] = (matches, mismatches, diff_ranges(len(matches)), diff_ranges(mm_n))
    return lists


def last_new_difficulty(history, paradigms, cond, default):
    values = [h['newDifficulty'] for h in history if h['paradigm'] in paradigms and h['cond'] == cond]
    return int(values[-1]) if values else default


def no_three_in_a_row(matches):
    return all(not (a == b == c) for a, b, c in zip(matches, matches[1:], matches[2:]))


def practice_schedule(n_blocks):
    """Blocks of 6 word trials then 6 symbol trials; 2, 3 or 4 matches per block."""
    conds = ([1] * 6 + [2] * 6) * 10
    matches = []
    for _ in range(n_blocks):
        r = random.random()
        block = [1, 1, 1, 1, 0, 0] if r < 0.1 else [1, 1, 0, 0, 0, 0] if r < 0.2 else [1, 1, 1, 0, 0, 0]
        while not no_three_in_a_row(block):
            random.shuffle(block)
        matches += block
    return conds, matches


def block_pair(start, words_difficulty):
    """Schedule a 20 s word block then a 20 s symbol block; faster trials at higher difficulty.

    Returns (trials, rt_window, trials_per_block), where trials is a list of (cond, match, onset).
    """
    possible = [BLOCK_LENGTH / n for n in range(MIN_STIMS, MAX_STIMS + 1)]
    ideal = BLOCK_LENGTH / (MIN_STIMS + (words_difficulty - 1) / (N_LEVELS - 1) * (MAX_STIMS - MIN_STIMS))
    rt_window = min([BLOCK_LENGTH / MIN_STIMS] + [p for p in possible if p >= ideal])
    per_block = mround(BLOCK_LENGTH / rt_window)
    r = random.random()
    if per_block % 2 == 1:
        n_matches = (per_block - 1) // 2 if r < 0.5 else (per_block + 1) // 2
    else:
        n_matches = per_block // 2 + 1 if r < 0.1 else per_block // 2 - 1 if r < 0.2 else per_block // 2
    matches = []
    for _ in range(2):
        block = [1] * n_matches + [0] * (per_block - n_matches)
        random.shuffle(block)
        while not no_three_in_a_row(block):
            random.shuffle(block)
            if random.random() < 0.02:  # occasionally allow long runs
                break
        matches += block
    conds = [1] * per_block + [2] * per_block
    onsets = [start + k * rt_window for k in range(2 * per_block)]
    return list(zip(conds, matches, onsets)), rt_window, per_block


def symbol_pair(symbols, match, difficulty, n_letters):
    """Two strings of symbols; the total length follows the recent words (at least 6)."""
    if n_letters:
        letters = max(mround(sum(n_letters) / len(n_letters) - 1 + random.random() * 2), 6)
    else:
        letters = 10

    def rand_str(n):
        return ''.join(random.choice(symbols) for _ in range(n))

    def plus_minus_one(n):
        return n + random.choice((-1, 1))

    if match:
        half = (plus_minus_one(letters) if letters % 2 == 1 else letters) // 2
        item1 = rand_str(half)
        return item1, item1
    if difficulty == 1:  # different lengths
        if letters % 2 == 0:
            letters = plus_minus_one(letters)
        lengths = [letters // 2 + 1, letters // 2]
        random.shuffle(lengths)
        return rand_str(lengths[0]), rand_str(lengths[1])
    half = (plus_minus_one(letters) if letters % 2 == 1 else letters) // 2
    if difficulty == 2:  # unrelated strings of the same length
        return rand_str(half), rand_str(half)
    # difficulty 3-7: change some positions of an identical string
    middle = random.randrange(1, half - 1)
    swap = {3: [0, middle, half - 1],
            4: random.choice([[0, middle], [middle, half - 1]]),
            5: [random.choice([0, half - 1])],
            6: random.sample(range(half), 2),
            7: [random.randrange(half)]}[difficulty]
    item1 = rand_str(half)
    item2 = list(item1)
    for pos in swap:
        while item2[pos] == item1[pos]:
            item2[pos] = random.choice(symbols)
    return item1, ''.join(item2)


def choose_item(candidates, history, is_mine, run_id):
    """Pick an item not presented before; failing that, not presented today; failing that, any."""
    seen = {h['item'] for h in history if is_mine(h)}
    valid = [c for c in candidates if c not in seen]
    if not valid:
        seen = {h['item'] for h in history if is_mine(h) and math.floor(h['when']) == math.floor(run_id)}
        valid = [c for c in candidates if c not in seen] or candidates
    return random.choice(valid)


def convert_case(word, stim_case):
    return word.lower() if stim_case == 'lower' else word.upper() if stim_case == 'upper' else word


def run(s, paradigm, name, language, pid):
    p = s.prefs
    rhyme = paradigm >= 13
    kind = (paradigm - 1) % 4  # 0 training, 1 practice, 2 standard scan, 3 quick scan
    n_blocks = 12 if kind == 3 else 20
    background, color = ((0, 64, 0), (192, 192, 192)) if rhyme else ((64, 64, 64), (255, 255, 255))

    s.log('Loading and preparing stimuli.')
    if rhyme:
        rhymes = read_rows('rhyme.txt')
    else:
        matches, mismatches, match_ranges, mismatch_ranges = load_semantic()[language]
    with open(path('paradigms', 'symbols.txt'), encoding='utf8') as f:
        symbols = f.readline().strip()
    history = read_history(pid)
    s.log('History file contains %d items.' % len(history))

    if kind == 1:
        practice_conds, practice_matches = practice_schedule(n_blocks)
    duration = n_blocks * BLOCK_LENGTH if kind >= 2 else math.inf
    upcoming = []  # scans: (cond, match, onset) for the rest of the current block pair
    next_pair_onset = 0
    per_block = None
    n_letters = []  # letters in each word pair shown, to size the symbol strings
    buffer_key = None
    size = p.stimulus_font_size * s.ygrid
    box = visual.Rect(s.win, width=0.6 * s.xdim, height=0.5 * s.ydim, lineColor=rgb(color), fillColor=None,
                      lineWidth=math.ceil(s.ydim / 400))

    def training_hints():
        if p.hint_text and kind == 0:
            s.hint('[S]/[D] = present match/mismatch language item', 39)
            s.hint('[F]/[G] = present match/mismatch control item', 40)
            s.hint('[%s] = respond "match"' % ']/['.join(k.upper() for k in p.match_keys), 41)
            s.hint('[W]/[E]/[R]/[T]/[Y]/[U]/[I] = set difficulty level 1/2/3/4/5/6/7; currently %d'
                   % s.training_difficulty, 42)
            s.hint('[Z] = clear item; [Q]/[Esc] = quit', 43)

    quit = s.start_run(name, background, None, scan=kind >= 2)
    trial = 0
    while not quit:
        trial += 1
        if kind == 1 and trial > len(practice_conds):
            break
        s.run_log('starting trial %d' % trial)
        training_hints()
        s.flip()

        # decide what to present, and when
        if kind == 0:  # training: the operator chooses each item
            key = buffer_key
            buffer_key = None
            if key is None:
                quit, key, _ = s.wait_until(allowed=list(TRAINING_KEYS) + list(COMMAND_KEYS))
                if quit:
                    break
            if key in TRAINING_KEYS:
                s.training_difficulty = TRAINING_KEYS[key]
                s.run_log('setting trainingDifficulty = %d' % s.training_difficulty)
                continue
            cond, match = COMMAND_KEYS[key]
            difficulty = s.training_difficulty
            intended_onset = -1
            rt_window = 600
        elif kind == 1:  # practice: self-paced, speed follows the word difficulty
            cond = practice_conds[trial - 1]
            match = practice_matches[trial - 1]
            words_difficulty = last_new_difficulty(history, [paradigm], 1, s.training_difficulty)
            ctrl_difficulty = last_new_difficulty(history, [paradigm], 2, s.training_difficulty)
            difficulty = words_difficulty if cond == 1 else ctrl_difficulty
            rt_window = BLOCK_LENGTH / (MIN_STIMS + (words_difficulty - 1) / (N_LEVELS - 1) * (MAX_STIMS - MIN_STIMS))
            intended_onset = GetSecs() - s.exp_start + ITI
        else:  # scan: fixed 20 s blocks, starting from where the practice (or last scan) left off
            practice = math.ceil(paradigm / 4) * 4 - 2
            words_difficulty = last_new_difficulty(history, [paradigm, practice], 1, s.training_difficulty)
            ctrl_difficulty = last_new_difficulty(history, [paradigm, practice], 2, s.training_difficulty)
            if not upcoming:
                if next_pair_onset == BLOCK_LENGTH * n_blocks:
                    break
                upcoming, pair_rt_window, per_block = block_pair(next_pair_onset, words_difficulty)
                next_pair_onset += 2 * BLOCK_LENGTH
            cond, match, intended_onset = upcoming.pop(0)
            rt_window = pair_rt_window
            difficulty = words_difficulty if cond == 1 else ctrl_difficulty

        # choose the item
        if cond == 1 and not rhyme:
            ranges = match_ranges if match else mismatch_ranges
            candidates = ranges[difficulty - 1] if match else [-i for i in ranges[difficulty - 1]]
            item = choose_item(candidates, history, lambda h: h['paradigm'] <= 4 and h['cond'] == 1, s.run_id)
            item1, item2 = matches[item - 1] if match else mismatches[-item - 1]
        elif cond == 1:
            candidates = [i + 1 for i, r in enumerate(rhymes) if int(r[2]) == match and int(r[3]) == difficulty]
            item = choose_item(candidates, history, lambda h: h['paradigm'] >= 13 and h['cond'] == 1, s.run_id)
            item1, item2 = rhymes[item - 1][:2]
            if random.random() >= 0.5:
                item1, item2 = item2, item1
        if cond == 1:
            item1, item2 = convert_case(item1, p.stim_case), convert_case(item2, p.stim_case)
            n_letters.append(len(item1) + len(item2))
        else:
            recent = None if kind == 0 else n_letters[-(6 if kind == 1 else per_block):]
            item1, item2 = symbol_pair(symbols, match, difficulty, recent)
            item = 0

        # draw the pair
        font, height = p.prop_font, size
        if cond == 2:
            font = p.mono_font
        elif language == 'Arabic' and not rhyme:
            font, height = p.arabic_font, p.arabic_font_scale * size
        stims = [s.text(item1, y=size, size=height, font=font, color=color),
                 s.text(item2, y=-size, size=height, font=font, color=color)]

        def draw_trial():
            for stim in stims:
                stim.draw()
            training_hints()

        draw_trial()
        s.run_log('finished preparing trial %d for intended presentation time %.3f' % (trial, intended_onset))
        quit, _, _ = s.wait_until(s.exp_start + intended_onset)
        if quit:
            break
        t = s.flip()
        onset = t - s.exp_start
        when = float(stamp('%Y%m%d.%H%M%S%f')[:-3])
        s.run_log('presented trial %d' % trial, t)
        if intended_onset == -1:
            intended_onset = onset
        if s.simulate and random.random() < (0.85 if match else 0.15):
            s.sim_press(p.match_keys[0], t + random.uniform(0.5, 1.0))

        # response
        quit, _, _ = s.wait_until(s.exp_start + onset + IGNORE_WINDOW)
        if quit:
            break
        allowed = list(p.match_keys)
        if kind == 0:
            allowed += ['z'] + list(TRAINING_KEYS) + list(COMMAND_KEYS)
        quit, key, key_time = s.wait_until(s.exp_start + intended_onset + rt_window - ITI, allowed)
        if quit:
            break
        response = key in p.match_keys
        if response:
            rt = key_time - s.exp_start - onset
            draw_trial()
            box.draw()
            s.flip()
            s.run_log('match response received', key_time)
        else:
            rt = 0
            if key is not None and key != 'z':
                buffer_key = key  # training: treat it as the instruction for the next trial
            s.run_log('no response received in window')

        # 2-up-1-down staircase (within this run and condition)
        correct = response == bool(match)
        previous = [h for h in history if h['runId'] == s.run_id and h['cond'] == cond]
        if not correct:
            new_difficulty = max(difficulty - STEP_EASIER, 1)
        elif previous and previous[-1]['correct'] == 1 and previous[-1]['difficulty'] == difficulty:
            new_difficulty = min(difficulty + STEP_HARDER, N_LEVELS)
        else:
            new_difficulty = difficulty

        row = dict(when=when, runId=s.run_id, paradigm=paradigm, intendedOnset=intended_onset, onset=onset,
                   cond=cond, difficulty=difficulty, match=match, item=item, item1=item1, item2=item2,
                   rtWindow=rt_window, response=response, rt=rt, correct=correct, newDifficulty=new_difficulty)
        history.append(row)
        s.run_log('logging: ' + append_history(pid, row))

        # wait before moving on
        if kind == 0:
            if response:
                quit, _, _ = s.wait_until(GetSecs() + 1)
        else:
            quit, _, _ = s.wait_until(s.exp_start + intended_onset + rt_window - ITI)
        s.run_log('trial complete')

    if s.finish_run(quit, duration):
        for cond, label in ((1, 'task'), (2, 'baseline')):
            levels = [h['difficulty'] for h in history if h['runId'] == s.run_id and h['cond'] == cond]
            if levels:
                s.log('Average difficulty of %s: %.3f' % (label, sum(levels) / len(levels)))
        s.thanks(color)
