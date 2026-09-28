"""Word generation (paradigms 33 practice and 34 quick scan).

A letter is shown for 10 s and the participant silently thinks of words starting with it;
rest blocks show abstract symbols. Follows AdaptiveLanguageMapping.m.
"""
from PIL import Image, ImageOps
from psychopy import visual
from psychtoolbox import GetSecs

from common import path

BACKGROUND = (255, 255, 255)
COLOR = (0, 0, 0)
EVENT_SPACING = 10  # seconds from one letter or symbol to the next
EVENT_DURATION = 9.9


def run(s, paradigm, name, language):
    p = s.prefs
    arabic = language == 'Arabic'
    fname = 'word-generation%s%s.txt' % ('-practice' if paradigm == 33 else '', '-arabic' if arabic else '')
    with open(path('paradigms', 'black', fname), encoding='utf8') as f:
        items = [line.strip() for line in f if line.strip()]
    duration = 60 if paradigm == 33 else 240
    size = 5 * p.stimulus_font_size * s.ygrid
    # the symbol images are white on black, so invert them
    symbols = {i: ImageOps.invert(Image.open(path('paradigms', 'black', 'symbol%02d.jpg' % i)).convert('RGB'))
               for i in range(1, 13)}

    quit = s.start_run(name, BACKGROUND, COLOR, scan=paradigm == 34)
    for i, item in enumerate(items):
        if quit:
            break
        onset = i * EVENT_SPACING
        quit, _, _ = s.wait_until(s.exp_start + onset)
        if quit:
            break
        if item.startswith('_'):  # e.g. _symbol03
            symbol_size = 1.3 * 1.15 * size  # about the height of the letters
            visual.ImageStim(s.win, image=symbols[int(item[-2:])], size=(symbol_size, symbol_size)).draw()
        else:
            s.text(item, size=size, font=p.arabic_font if arabic else p.word_gen_font, color=COLOR).draw()
        t = s.flip()
        s.run_log('presented event %d item %s (intended onset %.3f)' % (i + 1, item, onset), t)
        quit, _, _ = s.wait_until(GetSecs() + EVENT_DURATION)
        s.flip()  # blank

    if s.finish_run(quit, duration):
        s.thanks(COLOR)
