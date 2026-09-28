# ALM, PsychoPy version

A Python/PsychoPy version of three Adaptive Language Mapping paradigms, so they can run without MATLAB:

- Adaptive semantic matching, visual (English, Spanish, Arabic): training, practice, standard scan, quick scan
- Adaptive rhyming judgment, visual (English): training, practice, standard scan, quick scan
- Word generation (English/Spanish letters, Arabic letters): practice, quick scan

It follows `AdaptiveLanguageMapping.m` closely and uses the same word lists (`../paradigms`), the same paradigm
numbers and the same `history/` and `logs/` folders and file formats, so a participant can move between the
MATLAB and Python versions and keep their difficulty levels and list of words already seen.

## Install (Ubuntu)

PsychoPy needs Python 3.10, so install it in its own environment with [uv](https://docs.astral.sh/uv/):

    cd alm_py
    uv venv --python 3.10 .venv
    VIRTUAL_ENV=.venv uv pip install -r requirements.txt

## Run

    .venv/bin/python alm.py

It asks whether you are in the scanner (this picks the match keys), then shows the menu:
type the participant ID, use Up/Down to move, Left/Right to change language, Enter to start, Esc to quit.
Pressing a match key or the trigger key in the menu flashes the title, to check the button box and trigger.

Settings (keys, fonts, sizes, initial delay) are in `preferences.py`, the equivalent of `almPreferences.m`.

### Testing without a participant

    .venv/bin/python alm.py --windowed --simulate --pid TEST --language Arabic --paradigm 4

`--simulate` triggers the run itself and presses the match key (about 85% correct), so a whole run can be
checked unattended. `--paradigm` runs one paradigm without the menu: 1-4 semantic, 13-16 rhyming,
33-34 word generation. Simulated runs write to the history file like real ones, so use a test ID.

## Files

- `alm.py`: menu and command line
- `adaptive.py`: semantic matching and rhyming (block timing, staircases, item choice, symbol strings)
- `wordgen.py`: word generation
- `common.py`: window, keyboard, waiting, logging, history file, drawing helpers
- `preferences.py`: settings

## Differences from the MATLAB version

- Only these three paradigms. The others still need MATLAB.
- Text is drawn by PsychoPy rather than Psychtoolbox, so sizes and positions are close but not pixel-identical.
  Word pairs are centred on the screen; word-generation letters are centred on their line (like the MATLAB version,
  letters that hang below the line, such as ع, sit a little low).
- Arabic uses the pre-shaped columns of the word lists, as in MATLAB, so history files match.
- Word generation uses Liberation Serif (the Linux equivalent of Times New Roman).
- Keyboard: key presses come from the window's key events, which include every keyboard (scanner trigger and
  button box), timed by checking every half millisecond. Unlike MATLAB, keys only count while the ALM window has
  focus (it always does when full screen). Psychtoolbox's keyboard queues were not used: without real-time
  priority (not set up on a normal Ubuntu install) they crashed Python intermittently.
- The low-latency kernel is not required.
