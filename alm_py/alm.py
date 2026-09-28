"""Adaptive Language Mapping, PsychoPy version (semantic matching, rhyming and word generation).

Run:  .venv/bin/python alm.py            (menu)
      .venv/bin/python alm.py --windowed --simulate --pid TEST --language Arabic --paradigm 4
"""
import argparse

from psychopy import visual

import preferences as prefs
from common import HINT_COLOR, Session, read_history, rgb
import adaptive
import motor
import wordgen

PARADIGMS = {
    1: 'Adaptive semantic matching -- visual -- training',
    2: 'Adaptive semantic matching -- visual -- practice',
    3: 'Adaptive semantic matching -- visual -- standard scan (6:40)',
    4: 'Adaptive semantic matching -- visual -- quick scan (4:00)',
    13: 'Adaptive rhyming judgment -- visual -- training',
    14: 'Adaptive rhyming judgment -- visual -- practice',
    15: 'Adaptive rhyming judgment -- visual -- standard scan (6:40)',
    16: 'Adaptive rhyming judgment -- visual -- quick scan (4:00)',
    33: 'Word generation -- practice',
    34: 'Word generation -- quick scan (4:00)',
    35: 'Motor -- tongue -- Wilson (4:00)',
    36: 'Motor -- fingers -- Wilson (4:00)',
    37: 'Motor -- foot -- Wilson (4:00)',
}
LANGUAGES = ['English', 'Spanish', 'Arabic']


def run_paradigm(s, paradigm, language, pid):
    if paradigm >= 35:
        motor.run(s, paradigm, PARADIGMS[paradigm], language)
    elif paradigm >= 33:
        wordgen.run(s, paradigm, PARADIGMS[paradigm], language)
    else:
        adaptive.run(s, paradigm, PARADIGMS[paradigm], language, pid)


def menu(s):
    """Main menu. Returns when the operator quits."""
    pid, language = '', 0
    numbers = list(PARADIGMS)
    selected = -1  # -1 participant ID, 0 language, 1.. paradigms
    x = -s.xdim / 2 + 3 * s.xdim / 100
    white, yellow, highlight = (255, 255, 255), (255, 255, 0), (50, 150, 150)
    title_color = white
    while True:
        s.win.color = rgb((64, 64, 64))
        s.win.clearBuffer()
        s.text('ADAPTIVE LANGUAGE MAPPING', y=s.row(2), x=x, left=True, bold=True, color=title_color).draw()
        title_color = white
        n_history = len(read_history(pid)) if pid else 0
        lines = [('Participant ID: ' + pid, -1), ('Language: ' + LANGUAGES[language], 0),
                 ('History file contains %d items' % n_history, None)]
        lines += [(PARADIGMS[n], i + 1) for i, n in enumerate(numbers)]
        for row, (label, index) in enumerate(lines):
            color = white
            if index is None or (index > 0 and 13 <= numbers[index - 1] <= 16 and LANGUAGES[language] == 'Arabic'):
                color = HINT_COLOR  # information line, or rhyming (no Arabic rhyming list)
            y = s.row(5 + row + (1 if row >= 3 else 0))
            stim = s.text(label, y=y, x=x, left=True, color=color)
            if index == selected:
                w, h = stim.boundingBox
                width = max(w, s.xdim / 3) + 10
                visual.Rect(s.win, width=width, height=h + 6, pos=(x - 5 + width / 2, y), fillColor=rgb(highlight),
                            lineColor=None).draw()
                stim.color = rgb((0, 0, 0))
            stim.draw()
        s.hint('[Up]/[Down] = select; [Left]/[Right] = language; [Enter] = start; [Esc] = quit')
        s.flip()

        quit, key, _ = s.wait_until(allowed=ALL_KEYS)
        if quit:
            return pid
        if selected == -1 and key in ('backspace', 'delete'):
            pid = pid[:-1]
        elif selected == -1 and len(key) == 1:
            pid += key.upper()
        elif key == 'q':
            return pid
        elif key in prefs.match_keys or key in prefs.trigger_keys:
            title_color = yellow if key in prefs.match_keys else highlight  # button box / trigger check
        elif key == 'up':
            selected = max(selected - 1, -1)
        elif key in ('down', 'tab', 'return') and selected < 1:
            if pid:
                selected += 1
        elif key == 'down':
            selected = min(selected + 1, len(numbers))
        elif key in ('left', 'right') and selected == 0:
            language = (language + (1 if key == 'right' else -1)) % len(LANGUAGES)
        elif key == 'return':
            run_paradigm(s, numbers[selected - 1], LANGUAGES[language], pid)


ALL_KEYS = list('abcdefghijklmnopqrstuvwxyz0123456789') + [
    'backspace', 'delete', 'return', 'tab', 'up', 'down', 'left', 'right']


def main():
    parser = argparse.ArgumentParser(description='Adaptive Language Mapping (PsychoPy version)')
    parser.add_argument('--windowed', action='store_true', help='run in a window instead of full screen')
    parser.add_argument('--simulate', action='store_true', help='auto-trigger and auto-respond (for testing)')
    parser.add_argument('--pid', help='participant ID (skip the menu)')
    parser.add_argument('--language', default='English', choices=LANGUAGES)
    parser.add_argument('--paradigm', type=int, choices=list(PARADIGMS), help='run one paradigm (skip the menu)')
    args = parser.parse_args()

    in_scanner = prefs.in_scanner
    if in_scanner is None:
        in_scanner = args.simulate or input('Inside the scanner (1 = yes, 0 = no)? ').strip() == '1'
    prefs.match_keys = prefs.match_keys_scanner if in_scanner else prefs.match_keys_desk

    s = Session(prefs, windowed=args.windowed, simulate=args.simulate)
    s.log('Adaptive Language Mapping (PsychoPy version); match keys %s, trigger keys %s'
          % (prefs.match_keys, prefs.trigger_keys))
    pid = args.pid or ''
    try:
        if args.paradigm:
            run_paradigm(s, args.paradigm, args.language, pid)
        else:
            pid = menu(s)
    finally:
        s.close(pid)


if __name__ == '__main__':
    main()
