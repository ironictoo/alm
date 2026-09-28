"""Shared pieces: window, keyboard, timing, logging, history file and drawing helpers.

All times are Psychtoolbox GetSecs() times (the same clock the key presses are stamped with).
"""
import datetime
import math
import os
import time

from psychopy import event, visual
from psychtoolbox import GetSecs

# repo root: paradigms/, history/ and logs/ are shared with the MATLAB version
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HINT_COLOR = (128, 128, 128)
HISTORY_COLUMNS = ['when', 'runId', 'paradigm', 'intendedOnset', 'onset', 'cond', 'difficulty', 'match',
                   'item', 'item1', 'item2', 'rtWindow', 'response', 'rt', 'correct', 'newDifficulty']
HISTORY_FORMATS = ['%.9f', '%.6f', '%d', '%.3f', '%.3f', '%d', '%d', '%d',
                   '%.4f', '%s', '%s', '%.3f', '%d', '%.3f', '%d', '%d']


def rgb(color):
    """0-255 colour (as in the MATLAB version) to PsychoPy's -1..1 colour scale."""
    return [c / 127.5 - 1 for c in color]


def path(*parts):
    return os.path.join(ROOT, *parts)


def mround(x):
    """Round half away from zero, like MATLAB (Python's round() rounds half to even)."""
    return math.floor(x + 0.5) if x >= 0 else -math.floor(-x + 0.5)


def stamp(fmt):
    return datetime.datetime.now().strftime(fmt)


def history_fname(pid):
    return path('history', 'history_%s.txt' % pid)


def read_history(pid):
    """Read the participant's history file (written by either version) as a list of dicts."""
    rows = []
    if not os.path.exists(history_fname(pid)):
        return rows
    with open(history_fname(pid), encoding='utf8') as f:
        lines = f.read().replace('\r', '').split('\n')
    header = lines[0].split('\t')
    for line in lines[1:]:
        if not line:
            continue
        row = dict(zip(header, line.split('\t')))
        for col in header:
            if col not in ('item1', 'item2'):
                try:
                    row[col] = float(row.get(col, 'nan'))
                except ValueError:
                    row[col] = float('nan')
        rows.append(row)
    return rows


def append_history(pid, row):
    """Append one trial to the history file, creating it with a header row if needed."""
    new = not os.path.exists(history_fname(pid))
    line = '\t'.join(fmt % row[col] for fmt, col in zip(HISTORY_FORMATS, HISTORY_COLUMNS))
    with open(history_fname(pid), 'a', encoding='utf8') as f:
        if new:
            f.write('\t'.join(HISTORY_COLUMNS) + '\n')
        f.write(line + '\n')
    return line


class Session:
    def __init__(self, prefs, windowed=False, simulate=False):
        self.prefs = prefs
        self.simulate = simulate
        self.sim_keys = []  # (name, time) key presses scheduled by --simulate
        self.run_id = None
        self.exp_start = None
        self.training_difficulty = 2  # kept between runs, like the MATLAB version

        os.makedirs(path('logs'), exist_ok=True)
        os.makedirs(path('history'), exist_ok=True)
        self.log_fname = path('logs', 'log_' + stamp('%Y%m%d.%H%M%S'))
        self.log_file = open(self.log_fname, 'a', encoding='utf8')

        self.win = visual.Window(fullscr=not windowed, size=(1280, 800), screen=prefs.screen, units='pix',
                                 color=rgb((64, 64, 64)), allowGUI=windowed)
        self.win.mouseVisible = False
        self.xdim, self.ydim = self.win.size
        self.ygrid = self.ydim / 45  # font sizes are in units of these "lines", as in the MATLAB version

    # ---- logging ----

    def log(self, msg):
        line = '%s %s' % (stamp('%Y-%m-%d %H:%M:%S'), msg)
        print(line)
        self.log_file.write(line + '\n')
        self.log_file.flush()

    def run_log(self, msg, t=None):
        t = GetSecs() if t is None else t
        self.log('runId %.6f time %.3f %s' % (self.run_id, t - self.exp_start, msg))

    # ---- keyboard and waiting ----

    def poll_keys(self):
        """Return [(name, time)] for key presses since the last call.

        Uses the window's key events: the X server merges every keyboard (including the scanner trigger and
        button box) into them. Checking every half millisecond makes the timestamps accurate enough.
        """
        keys = [(name, GetSecs()) for name in event.getKeys()]
        if self.simulate:
            keys = []  # simulated runs ignore the real keyboard (stop them with Ctrl-C)
        now = GetSecs()
        keys += [k for k in self.sim_keys if k[1] <= now]
        self.sim_keys = [k for k in self.sim_keys if k[1] > now]
        return keys

    def sim_press(self, name, t):
        self.sim_keys.append((name, t))

    def wait_until(self, until=math.inf, allowed=()):
        """Wait until time `until` or until one of the `allowed` keys is pressed.

        Returns (quit, key, key_time). Esc always quits, and so does Q unless it is an allowed key.
        Other keys are ignored (but logged during a run).
        """
        quit_keys = ['escape'] + ([] if 'q' in allowed else ['q'])
        while GetSecs() < until:
            for name, t in self.poll_keys():
                if self.exp_start is not None:
                    self.run_log('keyDown %s' % name, t)
                if name in quit_keys:
                    return True, name, t
                if name in allowed:
                    return False, name, t
            time.sleep(0.0005)
        return False, None, None

    # ---- drawing ----

    def flip(self):
        """Show what has been drawn; return the time it appeared."""
        self.win.flip()
        return GetSecs()

    def text(self, s, y=0, size=None, font=None, color=(255, 255, 255), x=0, left=False, bold=False, arabic=False):
        """Text centred on (x, y), or left-aligned at x if left=True. Coordinates are pixels from the centre.

        arabic=True joins the letters and writes right to left (not needed for the pre-shaped word lists).
        """
        return visual.TextStim(self.win, text=s, pos=(x, y), height=size or self.prefs.standard_font_size * self.ygrid,
                               font=font or self.prefs.prop_font, color=rgb(color), bold=bold,
                               wrapWidth=2 * self.xdim, anchorHoriz='left' if left else 'center',
                               alignText='left' if left else 'center', languageStyle='Arabic' if arabic else 'LTR')

    def row(self, n):
        """y coordinate of text row n counted from the top (45 rows per screen)."""
        return self.ydim / 2 - n * self.ygrid

    def hint(self, s, row=43):
        self.text(s, y=self.row(row), color=HINT_COLOR).draw()

    def cross(self, color):
        if color is None:
            return
        size = self.ydim / 30
        width = math.ceil(self.ydim / 400)
        for start, end in (((-size, 0), (size, 0)), ((0, -size), (0, size))):
            visual.Line(self.win, start=start, end=end, lineWidth=width, lineColor=rgb(color)).draw()

    # ---- start and end of a run ----

    def start_run(self, name, background, cross_color, scan):
        """Show the 'waiting for trigger' screen and wait for the trigger. Returns True if quit instead."""
        self.run_id = float(stamp('%Y%m%d.%H%M%S'))
        self.log('Starting paradigm %s.' % name)
        self.log('runId %.6f assigned' % self.run_id)
        self.win.color = rgb(background)
        self.win.clearBuffer()  # so the new background applies to this frame
        self.cross((255, 255, 0))
        if self.prefs.hint_text:
            self.hint('[%s] = start; [Q]/[Esc] = quit' % self.prefs.trigger_keys[0].upper())
        self.flip()
        self.log('Waiting for trigger to start...')
        if self.simulate:
            self.sim_press(self.prefs.trigger_keys[0], GetSecs() + 1)
        quit, _, self.exp_start = self.wait_until(allowed=self.prefs.trigger_keys)
        if quit:
            self.log('Did not start paradigm, quit instead.')
            self.exp_start = None
            return True
        self.log('Experiment triggered.')
        if self.prefs.initial_delay and scan:
            self.exp_start += self.prefs.initial_delay
            self.log('runId %.6f delaying start until %f' % (self.run_id, self.exp_start))
            quit, _, _ = self.wait_until(self.exp_start)
            if quit:
                self.exp_start = None
                return True
        self.cross(cross_color)
        self.flip()
        return False

    def finish_run(self, quit, duration):
        """Wait for the end of the run (unless quitting). Returns True if the run completed."""
        if not quit:
            if self.simulate and duration == math.inf:
                self.sim_press('escape', GetSecs() + 1)  # practice runs otherwise wait for the operator
            quit, _, _ = self.wait_until(self.exp_start + duration)
        if quit:
            self.run_log('paradigm aborted')
        else:
            self.run_log('paradigm complete')
        self.exp_start = None
        return not quit

    def thanks(self, color):
        self.text("Thanks, you've finished this task.", size=self.prefs.message_font_size * self.ygrid,
                  color=color).draw()
        self.flip()
        self.wait_until(GetSecs() + 2)

    def close(self, pid):
        self.win.close()
        self.log_file.close()
        if pid:
            os.rename(self.log_fname, self.log_fname + '_' + pid)
