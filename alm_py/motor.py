"""Wilson motor paradigms (35 tongue, 36 fingers, 37 foot).

Twelve 20 s blocks alternating between the movement instruction and rest. Follows AdaptiveLanguageMapping.m.
"""
from psychtoolbox import GetSecs

BACKGROUND = (64, 64, 64)
COLOR = (255, 255, 255)
BLOCK_LENGTH = 20
EVENT_DURATION = 19.9
N_BLOCKS = 12

# Arabic uses verbal nouns ("moving the tongue") because the imperative differs for men and women
INSTRUCTIONS = {
    'English': {35: 'Move your tongue', 36: 'Move your fingers', 37: 'Move your foot', 'rest': 'Rest now'},
    'Spanish': {35: 'Mueva la lengua', 36: 'Mueva los dedos', 37: 'Mueva el pie', 'rest': 'Descanse ahora'},
    'Arabic': {35: 'تحريك اللسان', 36: 'تحريك الأصابع', 37: 'تحريك القدم', 'rest': 'راحة'},
}


def run(s, paradigm, name, language):
    p = s.prefs
    arabic = language == 'Arabic'
    size = p.stimulus_font_size * s.ygrid * (p.arabic_font_scale if arabic else 1)
    font = p.arabic_font if arabic else p.prop_font

    quit = s.start_run(name, BACKGROUND, None, scan=True)
    for i in range(N_BLOCKS):
        if quit:
            break
        onset = i * BLOCK_LENGTH
        quit, _, _ = s.wait_until(s.exp_start + onset)
        if quit:
            break
        text = INSTRUCTIONS[language][paradigm if i % 2 == 0 else 'rest']
        s.text(text, size=size, font=font, color=COLOR, arabic=arabic).draw()
        t = s.flip()
        s.run_log('presented event %d item %s (intended onset %.3f)' % (i + 1, text, onset), t)
        quit, _, _ = s.wait_until(GetSecs() + EVENT_DURATION)
        s.flip()  # blank

    if s.finish_run(quit, N_BLOCKS * BLOCK_LENGTH):
        s.thanks(COLOR)
