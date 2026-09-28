# ALM (PsychoPy version) preferences; the equivalent of almPreferences.m

# keys that start a paradigm (scanner trigger), as PsychoPy key names
trigger_keys = ['t']

# keys that count as a "match" response; asked at startup unless in_scanner is set to True or False
in_scanner = None
match_keys_scanner = ['a', 'b', 'c', 'd']
match_keys_desk = ['h', 'j', 'k', 'l']

# seconds to wait after the trigger before starting scans (for scanners that trigger before dummy volumes)
initial_delay = 0

screen = 0
hint_text = True  # show operator hints at the bottom of the screen

# font sizes are in "lines" (1/45 of the screen height)
standard_font_size = 0.75
message_font_size = 1.65
stimulus_font_size = 3.3
stim_case = 'lower'

prop_font = 'DejaVu Sans'
mono_font = 'DejaVu Sans Mono'
arabic_font = 'DejaVu Sans'
arabic_font_scale = 1.4  # Arabic words look small at the same size
word_gen_font = 'Liberation Serif'  # same letter shapes and sizes as Times New Roman
