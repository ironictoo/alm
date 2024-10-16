function AdaptiveLanguageMapping(pid)

% Adaptive Language Mapping
% Version 7.71; September 1, 2022
% Copyright 2010-2022 Stephen M. Wilson
% Language Neuroscience Laboratory
% Vanderbilt University Medical Center
% 
% version and launch time
almVersion = '7.71; September 1, 2022';
launchTime = now;

% preferences
triggerKeys = {'T','t'};
initialDelay = 0;
matchKeys = {'a', 'A', 'b', 'B', 'c', 'C', 'd', 'D'};
skipSyncTests = 0;
switch(computer)
  case 'GLNXA64'
    propFont = 'DejaVu Sans';
    monoFont = 'DejaVu Sans Mono';
  case 'PCWIN64'
    propFont = 'Lucida Sans Unicode';
    monoFont = 'Consolas';
  case 'MACI64'
    propFont = 'Lucida Grande';
    monoFont = 'Menlo';
  otherwise
    error('Unrecognized type of computer.');
end
standardFontSize = 0.75;
messageFontSize = 1.65;
stimulusFontSize = 3.3;
stimCase = 'lower';
yLoc = 1;
hintText = 1;
overrideRegLatencyClass = [];

activeParadigms = [1:4 13:16 23:24 28:30 31:34 35:41 42 43];

almPreferences; % overrides these defaults

language = 1;
languageName = {'English', 'Spanish'};
nLanguages = numel(languageName);

% argument processing
if nargin < 1
  pid = [];
end

% cd to own directory
myPath = which(mfilename);
myDir = fileparts(myPath);
oldWd = cd(myDir);
c1 = onCleanup(@()cd(oldWd));

% log command window
logFname = ['logs/log_' datestr(launchTime, 'yyyymmdd.HHMMSS')];
diary(logFname);
c2_diary = onCleanup(@()diary('off'));

% splash to command window
fprintf('Adaptive Language Mapping\n');
fprintf('Version %s\n', almVersion);
fprintf('Copyright 2010-2022 Stephen M. Wilson\n');
fprintf('Language Neuroscience Laboratory\n');
fprintf('Vanderbilt University Medical Center\n\n');

% environment information
fprintf('Environment information:\n');
fprintf('%s Session initiated.\n', datestr(launchTime, 31));
fprintf('Experiment script = %s\n', myPath);
fprintf('Log file = %s\n', fullfile(myDir, logFname));
fprintf('OS = %s\n', computer('arch'));
fprintf('MATLAB version = %s\n', version);
if exist('Screen', 'file') ~= 3
  error('Psychtoolbox does not seem to be installed correctly.');
end
[~, ptbVer] = PsychtoolboxVersion;
fprintf('Psychtoolbox version = %d.%d.%d\n', ptbVer.major, ptbVer.minor, ptbVer.point);

type('almPreferences.m');
fprintf('\n');

ver
fprintf('\nPsychtoolbox version = %s\n\n', ptbVer.string);

% psychtoolbox
fprintf('%s Initializing psychtoolbox.\n', datestr(now, 31));
Screen('Preference', 'SkipSyncTests', skipSyncTests);
Screen('Preference', 'DefaultTextYPositionIsBaseline', 1);

% set java classpath if necessary
jvm = usejava('jvm');
if jvm
  jcp = javaclasspath('-all');
  psychJavaOnPath = false;
  for i = 1:numel(jcp)
    if ~isempty(strfind(jcp{i}, 'PsychJava'))
      psychJavaOnPath = true;
    end
  end
  if ~psychJavaOnPath
    fprintf('Warning: java classpath is not set correctly for Psychtoolbox.\n');
    fprintf('Type ''help PsychJavaTrouble'' for information as to how to resolve this.\n');
    fprintf('Will now try to dynamically add classpath as workaround.\n');
    fprintf('Beware that this has the side effect of clearing all global variables.\n');
    PsychJavaTrouble;
  end
end

% set up screen
fprintf('%s Setting up screen.\n', datestr(now, 31));
[w, wRect] = Screen('OpenWindow', max(Screen('Screens')));
wOffscreen = Screen('OpenOffscreenWindow', max(Screen('Screens')));
c3 = onCleanup(@()Screen('CloseAll'));

xDim = wRect(3);
x = round(xDim / 2);
xGrid = xDim / 100;

yDim = wRect(4);
y = round(yDim / 2 * yLoc);
verticalLines = 45;
yGrid = yDim / verticalLines;
lineWidth = ceil(yDim / 400);

HideCursor;
c4 = onCleanup(@()ShowCursor);
fprintf('\n');

highlightColor = [50 150 150];
hintColor = [128 128 128];

% set up fonts
fprintf('%s Setting up fonts.\n', datestr(now, 31));
Screen('TextFont', w, propFont);
Screen('DrawText', w, 'test');
actualPropFont = Screen('TextFont', w);
fprintf('Intended proportional font: %s\n', propFont);
fprintf('Actual proportional font: %s\n', actualPropFont);
Screen('TextFont', w, monoFont);
Screen('DrawText', w, 'test');
actualMonoFont = Screen('TextFont', w);
fprintf('Intended monospaced font: %s\n', monoFont);
fprintf('Actual monospaced font: %s\n', actualMonoFont);

Screen('TextFont', w, propFont);

% set up sound
fprintf('%s Initializing psychtoolbox sound.\n', datestr(now, 31));
InitializePsychSound;
PsychPortAudio('Close'); % in case anything is already open
deviceId = []; % system default
mode = 1 + 8; % sound playback only (1) + master device (8)
if ~isempty(overrideRegLatencyClass)
  regLatencyClass = overrideRegLatencyClass;
elseif ispc % Windows
  regLatencyClass = 0; % don't care about latency
else
  regLatencyClass = 2; % take full control of audio device
end
fs = []; % get sample rate from sound device
nchan = 1;
master_pahandle = PsychPortAudio('Open', deviceId, mode, regLatencyClass, fs, nchan);
c5 = onCleanup(@()PsychPortAudio('Close', master_pahandle));
% start the device
PsychPortAudio('Start', master_pahandle, 0, 0, 1);
% find the frequency of the sound card
status = PsychPortAudio('GetStatus', master_pahandle);
fs = status.SampleRate;
fprintf('%s PsychPortAudio device sample rate = %d Hz.\n', datestr(now, 31), fs);
% create a virtual channel
virtual_mode = 1; % sound playback only
pahandle = PsychPortAudio('OpenSlave', master_pahandle, virtual_mode);
% play a dummy sound in order to speed up the first sound later
PsychPortAudio('FillBuffer', pahandle, zeros(nchan, 10));
PsychPortAudio('Start', pahandle, 1, 0, 1);
% rms to normalize
rms = 0.20; % 0.06

% set up keyboard
fprintf('%s Setting up keyboard.\n', datestr(now, 31));
clear PsychHID; % new 7.36
clear KbCheck; % new 7.36
KbName('UnifyKeyNames');
% don't clutter command window with key presses
if jvm
  ListenChar(2);
  c6 = onCleanup(@()ListenChar(0));
end

% start a queue for every device, keyboard and non-keyboard alike
keyboardIndices = GetKeyboardIndices;
gamepadIndices = GetGamepadIndices;
global devInd;
global nDevices;
devInd = [keyboardIndices(:); gamepadIndices(:)];
nDevices = length(devInd);
for i = 1:nDevices
  KbQueueCreate(devInd(i));
  KbQueueStart(devInd(i));
  c7(i) = onCleanup(@()KbQueueRelease(devInd(i))); %#ok<AGROW,NASGU>
end

paradigmName = { ...
  'Adaptive semantic matching -- visual -- training', ... % 1
  'Adaptive semantic matching -- visual -- practice', ... % 2
  'Adaptive semantic matching -- visual -- standard scan (6:40)', ... % 3
  'Adaptive semantic matching -- visual -- quick scan (4:00)', ... % 4
  'Adaptive semantic matching -- auditory -- training', ... % 5
  'Adaptive semantic matching -- auditory -- practice', ... % 6
  'Adaptive semantic matching -- auditory -- standard scan (6:40)', ... % 7
  'Adaptive semantic matching -- auditory -- quick scan (4:00)', ... % 8
  'Adaptive syllable matching -- visual -- training', ... % 9
  'Adaptive syllable matching -- visual -- practice', ... % 10
  'Adaptive syllable matching -- visual -- standard scan (6:40)', ... % 11
  'Adaptive syllable matching -- visual -- quick scan (4:00)', ... % 12
  'Adaptive rhyming judgment -- visual -- training', ... % 13
  'Adaptive rhyming judgment -- visual -- practice', ... % 14
  'Adaptive rhyming judgment -- visual -- standard scan (6:40)', ... % 15
  'Adaptive rhyming judgment -- visual -- quick scan (4:00)', ... % 16
  'Narrative comprehension -- training', ... % 17
  'Narrative comprehension -- paradigm 1 (Einstein) (6:40)', ... % 18
  'Narrative comprehension -- paradigm 2 (Beatles) (6:40)', ... % 19
  'Picture naming -- training', ... % 20
  'Picture naming -- paradigm 1 (6:40)', ... % 21
  'Picture naming -- paradigm 2 (6:40)', ... % 22
  'Breath holding -- training', ... % 23
  'Breath holding -- scan (4:54)', ... % 24
  'Fixed semantic matching -- visual -- practice', ... % 25
  'Fixed semantic matching -- visual -- paradigm 1 (8:00)', ... % 26
  'Fixed semantic matching -- visual -- paradigm 2 (8:00)', ... % 27
  'Fixed semantic matching -- auditory -- practice', ... % 28
  'Fixed semantic matching -- auditory -- paradigm 1 (8:00)', ... % 29
  'Fixed semantic matching -- auditory -- paradigm 2 (8:00)', ... % 30
  'Sentence completion -- practice', ... % 31
  'Sentence completion -- quick scan (4:00)', ... % 32
  'Word generation -- practice', ... % 33
  'Word generation -- quick scan (4:00)', ... % 34
  'Motor -- tongue -- Wilson', ... % 35
  'Motor -- fingers -- Wilson', ... % 36
  'Motor -- foot -- Wilson', ... % 37
  'Motor -- face -- Morgan', ... % 38
  'Motor -- tap -- Morgan', ... % 39
  'Motor -- arm -- Morgan', ... % 40
  'Motor -- foot -- Morgan', ... % 41
  'Check fonts', ... % 42
  'Quit'}; % 43
nParadigms = numel(paradigmName);
loaded = zeros(nParadigms, 1);

% main menu
paradigm = -1;
while true
  fprintf('%s Entering main menu.\n', datestr(now, 31));
  
  readHistory = true;  
  go = false;

  backgroundColor = [64 64 64];
  textColor = [255 255 255];
  
  while ~go
    Screen('FillRect', w, backgroundColor);
    Screen('TextSize', w, round(standardFontSize * yGrid));
    Screen('TextStyle', w, 1); % bold
    Screen('DrawText', w, 'ADAPTIVE LANGUAGE MAPPING', 3 * xGrid, 2 * yGrid, textColor);    
    Screen('TextStyle', w, 0); % normal
    Screen('DrawText', w, ['Version ' almVersion], 3 * xGrid, 3 * yGrid, hintColor);    

    % pid
    if paradigm == -1
      fgColor = [0 0 0];
      [~, offsetBoundsRect] = Screen('TextBounds', w, ['Participant ID: ' pid], 3 * xGrid, 5 * yGrid);
      highlightRect = GrowRect(offsetBoundsRect, round(yGrid / 10), round(yGrid / 10));
      highlightRect(3) = max(highlightRect(3), xDim / 3);
      Screen('FillRect', w, highlightColor, highlightRect);
    else
      fgColor = textColor;
    end
    [newX, newY] = Screen('DrawText', w, 'Participant ID: ', 3 * xGrid, 5 * yGrid, fgColor);
    Screen('DrawText', w, sprintf('%s', pid), newX, newY, [255 255 0]);

    % language
    if paradigm == 0
      fgColor = [0 0 0];
      [~, offsetBoundsRect] = Screen('TextBounds', w, ['Language: ' languageName{language}], 3 * xGrid, 6 * yGrid);
      highlightRect = GrowRect(offsetBoundsRect, round(yGrid / 10), round(yGrid / 10));
      highlightRect(3) = max(highlightRect(3), xDim / 3);
      Screen('FillRect', w, highlightColor, highlightRect);
    else
      fgColor = textColor;
    end
    [newX, newY] = Screen('DrawText', w, 'Language: ', 3 * xGrid, 6 * yGrid, fgColor);
    Screen('DrawText', w, languageName{language}, newX, newY, [255 255 0]);
    
    % history
    if readHistory
      historyFname = sprintf('history/history_%s.txt', pid);
      if exist(historyFname, 'file')
        history = txtread(historyFname, [], [], 'utf8');
        nHistory = length(history.when);
        if nHistory == 1
          plural = '';
        else
          plural = 's';
        end
        historyStr = sprintf('History file contains %d item%s', nHistory, plural);
      else
        history = [];
        nHistory = -1;
        historyStr = 'History file not created yet';
      end
      if isempty(pid)
        pidOrNull = '[null]';
      else
        pidOrNull = pid;
      end
      fprintf('%s pid = %s, %s.\n', datestr(now, 31), pidOrNull, historyStr);
      readHistory = false;
    end    
    Screen('DrawText', w, historyStr, 3 * xGrid, 7 * yGrid, hintColor);

    % paradigms
    for i = 1:nParadigms
      if any(activeParadigms == i)
        % highlight selected item
        if paradigm == i
          fgColor = [0 0 0];
          [~, offsetBoundsRect] = Screen('TextBounds', w, paradigmName{i}, 3 * xGrid, (find(activeParadigms == i) + 8) * yGrid);
          highlightRect = GrowRect(offsetBoundsRect, round(yGrid / 10), round(yGrid / 10));
          Screen('FillRect', w, highlightColor, highlightRect);
        else
          fgColor = textColor;
        end
        if language == 2 && i > 4 && i < nParadigms - 1
          fgColor = [128 128 128];
        end
        % draw menu item
        Screen('DrawText', w, paradigmName{i}, 3 * xGrid, (find(activeParadigms == i) + 8) * yGrid, fgColor);    
      end
    end
    
    Screen('Flip', w, 0, 1);

    % wait for next key
    [q, key] = waitUntil([cellstr(char(double('abcdefghijklmnopqrstuvwxyz1234567890')'))' ...
      {'1!', '2@', '3#', '4$', '5%', '6^', '7&', '8*', '9(', '0)', '-_', ...
      'BackSpace', 'Delete', 'DELETE', 'Return', 'tab', ...
      'UpArrow', 'DownArrow', 'LeftArrow', 'RightArrow'} ...
      matchKeys triggerKeys]);  
    if q
      go = true;
      paradigm = nParadigms;
    else   
      switch key
        case 'UpArrow'
          if paradigm == -1
            readHistory = true;
          else
            if paradigm == -1
              ;
            elseif paradigm == 0
              paradigm = -1;
            elseif paradigm == activeParadigms(1)
              paradigm = 0;
            else
              paradigm = activeParadigms(find(activeParadigms == paradigm) - 1);
            end
          end
        case {'DownArrow', 'tab'}
          if paradigm == -1 && isempty(pid)
            Screen('DrawText', w, 'Participant ID:', 3 * xGrid, 5 * yGrid, [255 0 0]);
            Screen('Flip', w, 0, 1);
            pause(0.25);
            Screen('DrawText', w, 'Participant ID:', 3 * xGrid, 5 * yGrid, [0 0 0]);
            Screen('Flip', w, 0, 1);            
          elseif paradigm == -1
            readHistory = true;
            paradigm = 0;
          elseif paradigm == 0
            paradigm = activeParadigms(1);
          elseif paradigm == activeParadigms(end)
            ;
          else
            paradigm = activeParadigms(find(activeParadigms == paradigm) + 1);
          end
        case 'LeftArrow'
          if paradigm == 0
            language = language - 1;
            if language < 1
              language = nLanguages;
            end
          end
        case 'RightArrow'
          if paradigm == 0
            language = language + 1;
            if language > nLanguages
              language = 1;
            end
          end
        case {'BackSpace', 'Delete', 'DELETE'}
          if paradigm == -1 && ~isempty(pid)
            pid = pid(1:end - 1);
          end
        case 'Return'
          if paradigm == -1 && isempty(pid)
            Screen('DrawText', w, 'Participant ID:', 3 * xGrid, 5 * yGrid, [255 0 0]);
            Screen('Flip', w, 0, 1);
            pause(0.25);
            Screen('DrawText', w, 'Participant ID:', 3 * xGrid, 5 * yGrid, [0 0 0]);
            Screen('Flip', w, 0, 1);            
          elseif paradigm == -1
            readHistory = true;
            paradigm = 0;
          elseif paradigm == 0
            paradigm = activeParadigms(1);
          else         
            go = true;
            choiceTime = now;
          end
        case matchKeys
          if paradigm == -1
            pid = [pid upper(key(1))]; %#ok<AGROW>
          else % visual indication to check button press detected
            Screen('TextStyle', w, 1); % bold
            Screen('DrawText', w, 'ADAPTIVE LANGUAGE MAPPING', 3 * xGrid, 2 * yGrid, [255 255 0]);    
            Screen('Flip', w, 0, 1);
            pause(0.25);            
            Screen('DrawText', w, 'ADAPTIVE LANGUAGE MAPPING', 3 * xGrid, 2 * yGrid, textColor);    
            Screen('TextStyle', w, 0); % normal
            Screen('Flip', w, 0, 1);
          end
        case triggerKeys
          if paradigm == -1
            pid = [pid upper(key(1))]; %#ok<AGROW>
          else % visual indication to check trigger detected
            Screen('TextStyle', w, 1); % bold
            Screen('DrawText', w, 'ADAPTIVE LANGUAGE MAPPING', 3 * xGrid, 2 * yGrid, highlightColor);    
            Screen('Flip', w, 0, 1);
            pause(0.25);            
            Screen('DrawText', w, 'ADAPTIVE LANGUAGE MAPPING', 3 * xGrid, 2 * yGrid, textColor);    
            Screen('TextStyle', w, 0); % normal
            Screen('Flip', w, 0, 1);
          end
        otherwise
          if paradigm == -1
            pid = [pid upper(key(1))]; %#ok<AGROW>
          elseif key == 'q'
            go = true;
            paradigm = nParadigms;            
          end
      end
    end
  end
  
  % quit
  if paradigm == nParadigms
    fprintf('%s Quit from main menu.\n', datestr(now, 31));
    break;
  end

  % font check
  if paradigm == nParadigms - 1
    fprintf('%s Checking fonts.\n', datestr(choiceTime, 31));    
    fid = fopen('paradigms/symbols.txt', 'r', 'native', 'utf8');
    symbols = fgetl(fid);
    symbols = double(symbols); % unicode
    fclose(fid);

    backgroundColor = [64 64 64];
    textColor = [255 255 255];
    crossColor = [];

    Screen('FillRect', w, backgroundColor);
  
    Screen('DrawText', w, 'Checking fonts', 3 * xGrid, 4 * yGrid, textColor);    

    Screen('DrawText', w, sprintf('Intended proportional font: %s', propFont), 3 * xGrid, 6 * yGrid, textColor);    
    Screen('DrawText', w, sprintf('Actual proportional font: %s', actualPropFont), 3 * xGrid, 7 * yGrid, textColor);
    Screen('DrawText', w, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 3 * xGrid, 8 * yGrid, textColor);

    Screen('DrawText', w, sprintf('Intended monospaced font: %s', monoFont), 3 * xGrid, 10 * yGrid, textColor);    
    Screen('DrawText', w, sprintf('Actual monospaced font: %s', actualMonoFont), 3 * xGrid, 11 * yGrid, textColor);
    Screen('TextFont', w, monoFont);  
    Screen('DrawText', w, symbols, 3 * xGrid, 12 * yGrid, textColor);
    Screen('TextFont', w, propFont);

    Screen('DrawText', w, 'Press [Q] or [Esc] to quit', 3 * xGrid, 14 * yGrid, textColor);    
    
    Screen('Flip', w);
    waitUntil([]);
    continue;
  end  
  
  % start paradigm
  fprintf('%s Starting paradigm %s.\n', datestr(choiceTime, 31), paradigmName{paradigm});
  runId = datestr(choiceTime, 'yyyymmdd.HHMMSS');
  runId = str2double(runId);
  fprintf('runId %.6f assigned\n', runId);

  fprintf('%s Loading and preparing stimuli.\n', datestr(now, 31));
  Screen('FillRect', w, backgroundColor);
  drawCrossHair(w, [255 0 0]);
  if hintText
    Screen('TextSize', w, round(standardFontSize * yGrid));
    DrawFormattedText(w, 'Loading and preparing stimuli...', 'center', (verticalLines - 2) * yGrid, hintColor);
  end
  Screen('Flip', w);
    
  % load and prepare stimuli
  switch paradigm
    case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 25, 26, 27, 28, 29, 30} % adaptive or fixed matching
      if ~loaded(paradigm) && any(paradigm == 1:16)
        loaded([1:4 9:16]) = 1;
        
        fid = fopen('paradigms/matches.txt', 'r');
        c = textscan(fid, '%f%s%s%f%f%f', 'HeaderLines', 1);
        matches.word1 = c{2};
        matches.word2	= c{3};
        fclose(fid);

        fid = fopen('paradigms/mismatches.txt', 'r');
        c = textscan(fid, '%s%f%s%f%f', 'HeaderLines', 0);
        mismatches.word1 = c{1};
        mismatches.word2 = c{3};
        fclose(fid);

        fid = fopen('paradigms/matches_spanish.txt', 'r');
        c = textscan(fid, '%s%s', 'HeaderLines', 0, 'Whitespace', '\t');
        sp_matches.word1 = c{1};
        sp_matches.word2	= c{2};
        fclose(fid);

        fid = fopen('paradigms/mismatches_spanish.txt', 'r');
        c = textscan(fid, '%s%s', 'HeaderLines', 0, 'Whitespace', '\t');
        sp_mismatches.word1 = c{1};
        sp_mismatches.word2 = c{2};
        fclose(fid);
            
        fid = fopen('paradigms/aud_matches.txt', 'r');
        c = textscan(fid, '%s%s%f%f%f%f%f%f%f%f%f%f', 'HeaderLines', 1);
        aud_matches.word1 = c{1};
        aud_matches.word2	= c{2};
        fclose(fid);

        fid = fopen('paradigms/aud_mismatches.txt', 'r');
        c = textscan(fid, '%s%s%f', 'HeaderLines', 1);
        aud_mismatches.word1 = c{1};
        aud_mismatches.word2 = c{2};
        fclose(fid);        
        
        % pseudowords = txtread('paradigms/syl_pseudowords.txt');
        fid = fopen('paradigms/syl_pseudowords.txt', 'r');
        c = textscan(fid, '%s%f%f', 'HeaderLines', 1);
        pseudowords.word = c{1};
        pseudowords.syllables	= c{2};
        pseudowords.letters = c{3};
        fclose(fid);
        
        % rhyme = txtread('paradigms/rhyme.txt');
        fid = fopen('paradigms/rhyme.txt', 'r');
        c = textscan(fid, '%s%s%f%f', 'HeaderLines', 1);
        rhyme.word1 = c{1};
        rhyme.word2 = c{2};
        rhyme.match	= c{3};
        rhyme.difficulty = c{4};
        fclose(fid);

        fid = fopen('paradigms/symbols.txt', 'r', 'native', 'utf8');
        symbols = fgetl(fid);
        symbols = double(symbols); % unicode
        fclose(fid);
      end

      if ~loaded(paradigm) && any(paradigm == 5:8)
        loaded(5:8) = 1;
        d = dir('paradigms/words/*.wav');
        for i = 1:length(d)
          almWav.(d(i).name(1:end - 4)) = ptbWavRead(['paradigms/words/' d(i).name], fs, rms);
        end
        ding = ptbWavRead('paradigms/ding.wav', fs, rms);
        da = load_da(fs, rms * 1.13);
      end
      
      if ~loaded(paradigm) && any(paradigm == 25:30)
        loaded(25:27) = 1;
        fixed_order = mod(double(pid(end)) + 2, 10); % order is based on last digit of pid
        fixed_events{25} = txtread(sprintf('paradigms/fixed/fixed_%d.p.txt', fixed_order), [], [], 'utf8');
        fixed_events{26} = txtread(sprintf('paradigms/fixed/fixed_%d.1.txt', fixed_order), [], [], 'utf8');
        fixed_events{27} = txtread(sprintf('paradigms/fixed/fixed_%d.2.txt', fixed_order), [], [], 'utf8');
      end
      
      if ~loaded(paradigm) && any(paradigm == 28:30)
        loaded(28:30) = 1;
        fixed_events{28} = fixed_events{25};
        fixed_events{29} = fixed_events{26};
        fixed_events{30} = fixed_events{27};

        d = dir('paradigms/fixed_words/*_.wav');
        for i = 1:length(d)
          fixedWav.(d(i).name(1:end - 5)) = ptbWavRead(['paradigms/fixed_words/' d(i).name], fs, rms);
        end
        ding = ptbWavRead('paradigms/ding.wav', fs, rms);
        da = load_da(fs, rms * 1.13);

        extra_pahandle(1) = PsychPortAudio('OpenSlave', master_pahandle, 1);
        extra_pahandle(2) = PsychPortAudio('OpenSlave', master_pahandle, 1);
      end
      
      % history file
      % if the log file does not exist, create it and write a header row
      if nHistory == -1
        fprintf('%s Creating history file %s.\n', datestr(now, 31), historyFname);
        historyFid = fopen(historyFname, 'a+', 'native', 'utf8');
        fprintf(historyFid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
          'when', 'runId', 'paradigm', 'intendedOnset', 'onset', 'cond', 'difficulty', 'match', ...
          'item', 'item1', 'item2', 'rtWindow', 'response', 'rt', 'correct', 'newDifficulty');
        history = txtread(historyFname, [], [], 'utf8'); % read the column headings
        history.item1 = {}; % strings
        history.item2 = {}; % strings
        nHistory = 0;
      else % otherwise open it for writing
        fprintf('%s Opening history file %s with %d existing trials to append new trials.\n', datestr(now, 31), historyFname, nHistory);
        historyFid = fopen(historyFname, 'a+', 'native', 'utf8');
      end
      
      if paradigm <= 16 % adaptive
        % blocks and trials within blocks
        blockLength = 20;
        if paradigm == 4 || paradigm == 8 || paradigm == 12 || paradigm == 16
          nBlocks = 12; % quick scan
        else       
          nBlocks = 20; % standard scan
        end
        if paradigm <= 4 % written
          % TODO this might be where we can adjust the minimum timing
          maxStimsPerBlock = 10;
          minStimsPerBlock = 4;
          ignoreWindow = 0.3;
        elseif paradigm >= 5 && paradigm <= 8 % auditory
          maxStimsPerBlock = 7;
          minStimsPerBlock = 4;
          ignoreWindow = 0.83;       
        elseif paradigm >= 9 && paradigm <= 12 % syl
          maxStimsPerBlock = 10;
          minStimsPerBlock = 4;
          ignoreWindow = 0.3;
        elseif paradigm >= 13 % rhyme
          % TODO this might be where we can adjust the minimum timing
          maxStimsPerBlock = 10;
          minStimsPerBlock = 4;
          ignoreWindow = 0.3;
        end
        nDifficultyLevels = 7;
        if ~exist('trainingDifficulty', 'var')
          % TODO: adjust here to have it start not on min difficulty 
          trainingDifficulty = 1;
        end
        stepHarder = 1;
        stepEasier = 2;

        nWords = length(matches.word1);
        nVeryEasyItems = 100;
        diffRanges{1} = 1:nVeryEasyItems;
        for i = 2:nDifficultyLevels
          diffRanges{i} = (diffRanges{i - 1}(end) + 1):(nVeryEasyItems + ceil((i - 1) / (nDifficultyLevels - 1) * (nWords - nVeryEasyItems))); %#ok<AGROW>
        end
        
        sp_diffRanges{1} = 1:nVeryEasyItems;
        for i = 2:nDifficultyLevels
          sp_diffRanges{i} = (sp_diffRanges{i - 1}(end) + 1):(nVeryEasyItems + ceil((i - 1) / (nDifficultyLevels - 1) * (length(sp_matches.word1) - nVeryEasyItems))); %#ok<AGROW>
        end
        sp_diffRanges_mismatch{1} = 1:nVeryEasyItems;
        for i = 2:nDifficultyLevels
          sp_diffRanges_mismatch{i} = (sp_diffRanges_mismatch{i - 1}(end) + 1):(nVeryEasyItems + ceil((i - 1) / (nDifficultyLevels - 1) * (length(sp_mismatches.word1) - nVeryEasyItems))); %#ok<AGROW>
        end
        
        aud_nWords = length(aud_matches.word1);
        aud_nVeryEasyItems = 50;
        aud_diffRanges{1} = 1:aud_nVeryEasyItems;
        for i = 2:nDifficultyLevels
          aud_diffRanges{i} = (aud_diffRanges{i - 1}(end) + 1):(aud_nVeryEasyItems + ceil((i - 1) / (nDifficultyLevels - 1) * (aud_nWords - aud_nVeryEasyItems))); %#ok<AGROW>
        end
        iti = 0.1;
        intendedOnset = -1;
        nLetters = [];
        bufferKey = [];

        switch paradigm
          case {1, 5, 9, 13}
            nTrials = 10000;
            expDuration = inf;

          case {2, 6, 10, 14}
            nTrials = nBlocks * 6;
            upcomingCond = repmat([ones(1, 6), 2 * ones(1, 6)], 1, 10);
            upcomingMatch = [];
            for i = 1:nBlocks
              r = rand;
              if r < 0.1
                nextMatches = [1 1 1 1 0 0];
              elseif r < 0.2
                nextMatches = [1 1 0 0 0 0];
              else
                nextMatches = [1 1 1 0 0 0];
              end
              % no three in a row same
              while ~all(diff(diff(nextMatches)))
                nextMatches = nextMatches(randperm(6));
              end
              upcomingMatch = [upcomingMatch nextMatches]; %#ok<AGROW>
            end
            expDuration = inf;

          case {3, 4, 7, 8, 11, 12, 15, 16}
            nTrials = 10000;
            upcomingCond = [];
            upcomingMatch = [];
            upcomingOnset = [];
            nextBlockPairOnset = 0;
            expDuration = nBlocks * blockLength;
        end
      
      else % fixed
        expDuration = 480;
        if paradigm >= 28 % auditory
          expDuration = expDuration + 1; % allow for post-scan response to last trial
        end
        ignoreWindow = 0.3;
        iti = 0.1;
        showDuration = 1.3;
      end
      
      switch paradigm
        case {1, 2, 3, 4, 25, 26, 27, 28, 29, 30}
          backgroundColor = [64 64 64];
          textColor = [255 255 255];
          crossColor = [];
        case {5, 6, 7, 8}
          backgroundColor = [64 64 64];
          textColor = [255 255 255];
          crossColor = textColor;
        case {9, 10, 11, 12}
          backgroundColor = [0 0 128];
          textColor = [255 255 0];
          crossColor = [];
        case {13, 14, 15, 16}
          backgroundColor = [0 64 0];
          textColor = [192 192 192];
          crossColor = [];
      end
      
    case {17, 18, 19} % narrative comprehension
      if ~loaded(paradigm)
        loaded(17:19) = 1;
        narrwav = cell(20, 2);
          for seg = 1:20
            narrwav{seg, 1} = ptbWavRead(sprintf('paradigms/narr/whowas%02d.wav', seg), fs) * rms / 0.0871; % mean RMS of all segments
            narrwav{seg, 2} = fliplr(narrwav{seg, 1}); % reverse
          end
        narrPic{1} = imread('paradigms/narr/narr_1_picture.jpg');
        narrPic{2} = imread('paradigms/narr/narr_2_picture.jpg');
      end
      
      expDuration = 400;
      switch paradigm
        case 17 % practice
          events = dlmread('paradigms/narr/narr_practice_timing.txt');
        case 18 % paradigm 1 (Einstein)
          events = dlmread('paradigms/narr/narr_1_timing.txt');
        case 19 % paradigm 2 (Beatles)
          events = dlmread('paradigms/narr/narr_2_timing.txt');
      end

      backgroundColor = [64 64 64];
      textColor = [255 255 255];
      crossColor = [];
      
    case {20, 21, 22} % picture naming
      if ~loaded(paradigm)
        loaded(20:22) = 1;

        picnamePic = cell(260, 1);
        for i = 1:260
          picnamePic{i} = imread(sprintf('paradigms/picname/pics/%03d.jpg', i));
        end

        scramblePic = cell(260, 1);
        for i = 1:260
          scramblePic{i} = imread(sprintf('paradigms/picname/scrambled_pics/%03d.jpg', i));
        end
      end
      
      expDuration = 400;
      switch paradigm
        case 20 % practice
          events = dlmread('paradigms/picname/picname_practice_timing.txt');
        case 21 % paradigm 1
          events = dlmread('paradigms/picname/picname_1_timing.txt');
        case 22 % paradigm 2
          events = dlmread('paradigms/picname/picname_2_timing.txt');
      end
      
      backgroundColor = [255 255 255];
      textColor = [0 0 0];
      crossColor = textColor;
      
    case {23, 24} % breath holding
      expDuration = 294.4;

      window = 30;
      curPosWithinWindow = 1 / 4;
      ballRadius = ceil(wRect(4) / 100);
      skip = ceil(wRect(4) / 500);

      % breathe
      normalBreath = 4.6;
      microTime = 0.01;
      t = (0:microTime:(normalBreath - microTime))';
      b = sin(t / normalBreath * 2 * pi - (pi / 2));
      b0 = -ones(size(b));

      switch paradigm
        case 23 % practice
          parad = [repmat(b, [22 1]); repmat([repmat(b0, [3 1]); repmat(b, [4 1])], [6 1]); repmat(b, [30 1])];
        case 24 % real
          parad = [repmat(b, [25 1]); repmat([repmat(b0, [3 1]); repmat(b, [6 1])], [6 1]); repmat(b, [30 1])];
      end
      % extra 15 normal breaths at the start to allow for "already done" part of waveform
      
      backgroundColor = [64 64 64];
      textColor = [255 255 255];
      crossColor = [];

    case {31, 32, 33, 34} % sentence completion and word generation (standard clinical paradigms)
      if ~loaded(paradigm)
        loaded(31:34) = 1;

        sentComp = txtread('paradigms/black/sentence-completion.txt', false);
        sentComp = sentComp.Column1;
        sentCompPractice = txtread('paradigms/black/sentence-completion-practice.txt', false);
        sentCompPractice = sentCompPractice.Column1;
        wordGen = txtread('paradigms/black/word-generation.txt', false);
        wordGen = wordGen.Column1;
        wordGenPractice = txtread('paradigms/black/word-generation-practice.txt', false);
        wordGenPractice = wordGenPractice.Column1;
        wordGenSymbol = cell(12, 1);
        for i = 1:12
          wordGenSymbol{i} = 255 - imread(sprintf('paradigms/black/symbol%02d.jpg', i));
        end
      end
      
      switch paradigm
        case 31 % practice
          expDuration = 60;          
          events = [(1:12)', (0:5:55)', 4.9 * ones(12, 1)];
        case 32 % sentence completion
          expDuration = 240;
          events = [(1:48)', (0:5:235)', 4.9 * ones(48, 1)];
        case 33 % practice
          expDuration = 60;          
          events = [(1:6)', (0:10:50)', 9.9 * ones(6, 1)];
        case 34 % word generation
          expDuration = 240;
          events = [(1:24)', (0:10:230)', 9.9 * ones(24, 1)];
      end
      
      backgroundColor = [255 255 255];
      textColor = [0 0 0];
      crossColor = textColor;

    case {35, 36, 37} % motor -- Wilson
      expDuration = 240;
      events = [[1 2 1 2 1 2 1 2 1 2 1 2]', (0:20:220)', 19.9 * ones(12, 1)];

      switch paradigm
        case 35
          activeInstruction = 'Move your tongue';
        case 36
          activeInstruction = 'Move your fingers';
        case 37
          activeInstruction = 'Move your foot';
        end
        controlInstruction = 'Rest now';

      backgroundColor = [64 64 64];
      textColor = [255 255 255];
      crossColor = [];      

    case {38, 39, 40, 41} % motor -- Morgan
      expDuration = 200;
      events = [[2 1 2 1 2 1 2 1 2 1]', (0:20:180)', 19.9 * ones(10, 1)];

      switch paradigm
        case 38
          activeInstruction = 'FACE';
        case 39
          activeInstruction = 'TAP';
        case 40
          activeInstruction = 'ARM'; % Spanish = MOVERE
        case 41
          activeInstruction = 'FOOT';
        end
        controlInstruction = 'REST'; % Spanish = DESCANSAR

      backgroundColor = [64 64 64];
      textColor = [255 255 255];
      crossColor = [];      
  end
  
  % set up screen for waiting for trigger
  Screen('FillRect', w, backgroundColor);
  if paradigm == 17 || paradigm == 18 % einstein
    Screen('PutImage', w, narrPic{1});
  elseif paradigm == 19
    Screen('PutImage', w, narrPic{2});
  end
  drawCrossHair(w, [255 255 0]);
  if hintText
    Screen('TextSize', w, round(standardFontSize * yGrid));
    DrawFormattedText(w, sprintf('[%s] = start; [Q]/[Esc] = quit', triggerKeys{1}(1)), 'center', (verticalLines - 2) * yGrid, hintColor);
  end
  Screen('Flip', w);
  fprintf('%s Finished loading and preparing stimuli.\n', datestr(now, 31));
  fprintf('%s Waiting for trigger to start...\n', datestr(now, 31));

  % set up screen for after trigger
  Screen('FillRect', w, backgroundColor);
  if paradigm == 17 || paradigm == 18 % einstein
    Screen('PutImage', w, narrPic{1});
  elseif paradigm == 19
    Screen('PutImage', w, narrPic{2});
  end
  drawCrossHair(w, crossColor);
  if hintText && (paradigm == 17 || paradigm == 20)
    Screen('TextSize', w, round(standardFontSize * yGrid));
    DrawFormattedText(w, '[6] = present next item; [Q]/[Esc] = quit', 'center', (verticalLines - 2) * yGrid, hintColor);
  end
  
  % wait for trigger
  [q, ~, expStartTime] = waitUntil(triggerKeys);
  if q
    fprintf('%s Did not start paradigm, quit instead.', datestr(now, 31));
    continue
  end
  
  % trigger
  fprintf('%s Experiment triggered.\n', datestr(now, 31));
  fprintf('runId %.6f internal clock start time = %f\n', runId, expStartTime);
  if initialDelay && any(paradigm == [3 4 7 8 11 12 15 16 18 19 21 22 24 26 27 29 30 32 34 35:41])
    expStartTime = expStartTime + initialDelay;
    fprintf('runId %.6f delaying start until %f\n', runId, expStartTime);
    q = waitUntil([], expStartTime);
    if q
      fprintf('%s Did not start paradigm, quit instead.', datestr(now, 31));
      continue
    end    
  end
  Screen('Flip', w);

  % start the experiment
  switch paradigm
    case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16} % adaptive matching      
      for trial = 1:nTrials
        fprintf('runId %.6f time %.3f starting trial %d\n', runId, GetSecs - expStartTime, trial);
        Screen('FillRect', w, backgroundColor);
        drawCrossHair(w, crossColor);
        if hintText && (paradigm == 1 || paradigm == 5 || paradigm == 9 || paradigm == 13)
          writeInstructions(w, standardFontSize, yGrid, verticalLines, hintColor, trainingDifficulty)
        end
        Screen('Flip', w);
        switch paradigm
          case {1, 5, 9, 13}
            if ~isempty(bufferKey)
              key = bufferKey;
              q = false;
              fprintf('runId %.6f time %.3f processing buffered key %s\n', runId, GetSecs - expStartTime, key);
              bufferKey = [];
            else
              [q, key] = waitUntil({'w', 'e', 'r', 't', 'y', 'u', 'i', 'a', 's', 'd', 'f'}, inf, expStartTime, runId, pahandle); 
            end
            if q, break; end
            switch key
              case {'w', 'e', 'r', 't', 'y', 'u', 'i'}
                switch key
                  case 'w'
                    trainingDifficulty = 1;
                  case 'e'
                    trainingDifficulty = 2;
                  case 'r'
                    trainingDifficulty = 3;
                  case 't'
                    trainingDifficulty = 4;
                  case 'y'
                    trainingDifficulty = 5;
                  case 'u'
                    trainingDifficulty = 6;
                  case 'i'
                    trainingDifficulty = 7;
                end
                fprintf('runId %.6f time %.3f setting trainingDifficulty = %d\n', runId, GetSecs - expStartTime, trainingDifficulty);
                continue
              case 'a' % words match
                cond = 1;
                match = 1;
              case 's' % words mismatch
                cond = 1;
                match = 0;
              case 'd' % symbols/tones match
                cond = 2;
                match = 1;
              case 'f' % symbols/tones mismatch
                cond = 2;
                match = 0;
            end
            difficulty = trainingDifficulty;
            intendedOnset = -1;
            rtWindow = 600;
            
          case {2, 6, 10, 14}
            if isempty(upcomingCond) % finished
              expDuration = GetSecs - expStartTime;
              break;
            end
            
            cond = upcomingCond(trial);
            match = upcomingMatch(trial);
            
            % words
            wordsNewDifficulty = history.newDifficulty(history.paradigm == paradigm & history.cond == 1);
            if isempty(wordsNewDifficulty)
              wordsDifficulty = trainingDifficulty;
            else
              wordsDifficulty = wordsNewDifficulty(end);
            end
            % control
            ctrlNewDifficulty = history.newDifficulty(history.paradigm == paradigm & history.cond == 2);
            if isempty(ctrlNewDifficulty)
              ctrlDifficulty = trainingDifficulty;
            else
              ctrlDifficulty = ctrlNewDifficulty(end);
            end
            
            if cond == 1
              difficulty = wordsDifficulty;
            else
              difficulty = ctrlDifficulty;
            end
            
            rtWindow = blockLength / (minStimsPerBlock + ...
              ((wordsDifficulty + ctrlDifficulty) / 2 - 1) / ...
              (nDifficultyLevels - 1) * (maxStimsPerBlock - minStimsPerBlock));            
          
            intendedOnset = GetSecs - expStartTime + iti;

          case {3, 4, 7, 8, 11, 12, 15, 16}
            % words
            wordsNewDifficulty = history.newDifficulty((history.paradigm == paradigm | history.paradigm == ceil(paradigm / 4) * 4 - 2) & history.cond == 1);
            if isempty(wordsNewDifficulty)
              wordsDifficulty = trainingDifficulty;
            else
              wordsDifficulty = wordsNewDifficulty(end);
            end
            % tones
            ctrlNewDifficulty = history.newDifficulty((history.paradigm == paradigm | history.paradigm == ceil(paradigm / 4) * 4 - 2) & history.cond == 2);
            if isempty(ctrlNewDifficulty)
              ctrlDifficulty = trainingDifficulty;
            else
              ctrlDifficulty = ctrlNewDifficulty(end);
            end
            
            if isempty(upcomingCond) % start of block pair
              if nextBlockPairOnset == blockLength * nBlocks % end of block design
                break;
              end
              
              possibleRtWindows = blockLength ./ (minStimsPerBlock:maxStimsPerBlock);
              idealRtWindow = blockLength / (minStimsPerBlock + ...
                ((wordsDifficulty + ctrlDifficulty) / 2 - 1) / ...
                (nDifficultyLevels - 1) * (maxStimsPerBlock - minStimsPerBlock));          
              blockPairRtWindow = min([blockLength / minStimsPerBlock, possibleRtWindows(possibleRtWindows >= idealRtWindow)]);
              trialsPerBlock = round(blockLength / blockPairRtWindow);
              
              upcomingCond = [ones(1, trialsPerBlock), 2 * ones(1, trialsPerBlock)];
              r = rand;
              if mod(trialsPerBlock, 2) == 1 % odd
                if r < 0.5
                  nMatches = (trialsPerBlock - 1) / 2;
                else
                  nMatches = (trialsPerBlock + 1) / 2;
                end
              else
                if r < 0.1
                  nMatches = trialsPerBlock / 2 + 1;
                elseif r < 0.2
                  nMatches = trialsPerBlock / 2 - 1;
                else
                  nMatches = trialsPerBlock / 2;
                end
              end
              for b = 1:2
                nextMatches = [ones(1, nMatches), zeros(1, trialsPerBlock - nMatches)];
                nextMatches = nextMatches(randperm(trialsPerBlock));
                while ~all(diff(diff(nextMatches)))
                  nextMatches = nextMatches(randperm(trialsPerBlock));
                  % occasionally allow weird long strings
                  if rand < 0.02
                    break;
                  end
                end
                upcomingMatch = [upcomingMatch nextMatches]; %#ok<AGROW>
              end
              upcomingOnset = nextBlockPairOnset + (0:blockPairRtWindow:((2 * trialsPerBlock - 1) * blockPairRtWindow));
              nextBlockPairOnset = nextBlockPairOnset + 2 * blockLength;
            end
            
            cond = upcomingCond(1);
            upcomingCond = upcomingCond(2:end);
            match = upcomingMatch(1);
            upcomingMatch = upcomingMatch(2:end);
            intendedOnset = upcomingOnset(1);
            upcomingOnset = upcomingOnset(2:end);
            rtWindow = blockPairRtWindow;
            
            if cond == 1
              difficulty = wordsDifficulty;
            else
              difficulty = ctrlDifficulty;
            end
        end

        switch cond
          case 1 % words
            if paradigm <= 4 % written semantic task
              % find an item of the right difficulty range that has not been presented previously
              switch language
                case 1
                  diffRange = diffRanges{difficulty};
                case 2
                  if match
                    diffRange = sp_diffRanges{difficulty};
                  else
                    diffRange = sp_diffRanges_mismatch{difficulty};
                  end
              end
              if ~match
                diffRange = -diffRange;
              end
              
              alreadyPresented = history.item(history.paradigm <= 4 & history.cond == 1);
              validItems = diffRange(~ismember(diffRange, alreadyPresented));
              if isempty(validItems)
                % consider only items presented today
                alreadyPresented = history.item(history.paradigm <= 4 & history.cond == 1 & floor(history.when) == floor(runId));
                validItems = diffRange(~ismember(diffRange, alreadyPresented));
                if isempty(validItems)
                  % give up, present anything in range
                  validItems = diffRange;
                end
              end
              item = validItems(randi(length(validItems)));

              switch language
                case 1
                  if match
                    item1 = matches.word1{item};
                    item2 = matches.word2{item};
                  else
                    item1 = mismatches.word1{-item};
                    item2 = mismatches.word2{-item};
                  end
                case 2
                  if match
                    item1 = sp_matches.word1{item};
                    item2 = sp_matches.word2{item};
                  else
                    item1 = sp_mismatches.word1{-item};
                    item2 = sp_mismatches.word2{-item};
                  end
              end
              item1 = convertCase(item1, stimCase);
              item2 = convertCase(item2, stimCase);
              nLetters = [nLetters; length(item1) + length(item2)]; %#ok<AGROW>
                          
            elseif paradigm <= 8 % auditory semantic task
              % find an item of the right difficulty range that has not been presented previously
              diffRange = aud_diffRanges{difficulty};
              if ~match
                diffRange = -diffRange;
              end
              alreadyPresented = history.item(history.paradigm >= 5 & history.paradigm <= 8 & history.cond == 1);
              validItems = diffRange(~ismember(diffRange, alreadyPresented));
              if isempty(validItems)
                % consider only items presented today
                alreadyPresented = history.item(history.paradigm >= 5 & history.paradigm <= 8 & history.cond == 1 & floor(history.when) == floor(runId));
                validItems = diffRange(~ismember(diffRange, alreadyPresented));
                if isempty(validItems)
                  % give up, present anything in range
                  validItems = diffRange;
                end
              end
              item = validItems(randi(length(validItems)));

              if match
                item1 = aud_matches.word1{item};
                item2 = aud_matches.word2{item};
              else
                item1 = aud_mismatches.word1{-item};
                item2 = aud_mismatches.word2{-item};
              end
              item1 = convertCase(item1, stimCase);
              item2 = convertCase(item2, stimCase);
              nLetters = [nLetters; length(item1) + length(item2)]; %#ok<AGROW>
            
              if match
                wav1 = almWav.(aud_matches.word1{item});
                wav2 = almWav.(aud_matches.word2{item});
              else
                wav1 = almWav.(aud_mismatches.word1{-item});
                wav2 = almWav.(aud_mismatches.word2{-item});
              end
              gapInPair = 0.5 - difficulty * 0.07;
              stimulus = [wav1, zeros(nchan, round(gapInPair * fs)), wav2];
              
            elseif paradigm <= 12 % syllables task
              r = rand;
              switch difficulty
                case 1
                  if match
                    if r < 0.2
                      lettersAndSyllables = [3 1 3 1];
                    elseif r < 0.7
                      lettersAndSyllables = [4 1 4 1];
                    else
                      lettersAndSyllables = [3 1 4 1];
                    end
                  else
                    if r < 0.7
                      lettersAndSyllables = [4 1 4 2];
                    else
                      lettersAndSyllables = [3 1 4 2];
                    end
                  end
                case 2
                  if match
                    if r < 0.2
                      lettersAndSyllables = [3 1 3 1];
                    elseif r < 0.45
                      lettersAndSyllables = [4 1 4 1];
                    elseif r < 0.7
                      lettersAndSyllables = [4 2 4 2];
                    elseif r < 0.85
                      lettersAndSyllables = [3 1 4 1];
                    else
                      lettersAndSyllables = [3 2 4 2];
                    end
                  else
                    if r < 0.2
                      lettersAndSyllables = [3 1 3 2];
                    elseif r < 0.7
                      lettersAndSyllables = [4 1 4 2];
                    elseif r < 0.9
                      lettersAndSyllables = [3 1 4 2];
                    else
                      lettersAndSyllables = [4 1 3 2];
                    end
                  end
                case 3
                  if match
                    if r < 0.2
                      lettersAndSyllables = [4 1 4 1];
                    elseif r < 0.35
                      lettersAndSyllables = [5 1 5 1];
                    elseif r < 0.5
                      lettersAndSyllables = [4 2 4 2];
                    elseif r < 0.7
                      lettersAndSyllables = [5 2 5 2];
                    elseif r < 0.85
                      lettersAndSyllables = [4 1 5 1];
                    else
                      lettersAndSyllables = [4 2 5 2];
                    end
                  else
                    if r < 0.35
                      lettersAndSyllables = [4 1 4 2];
                    elseif r < 0.7
                      lettersAndSyllables = [5 1 5 2];
                    elseif r < 0.9
                      lettersAndSyllables = [4 1 5 2];
                    else
                      lettersAndSyllables = [5 1 4 2];
                    end
                  end
                case 4
                  if match
                    if r < 0.2
                      lettersAndSyllables = [5 1 5 1];
                    elseif r < 0.35
                      lettersAndSyllables = [6 1 6 1];
                    elseif r < 0.5
                      lettersAndSyllables = [5 2 5 2];
                    elseif r < 0.7
                      lettersAndSyllables = [6 2 6 2];
                    elseif r < 0.85
                      lettersAndSyllables = [5 1 6 1];
                    else
                      lettersAndSyllables = [5 2 6 2];
                    end
                  else
                    if r < 0.35
                      lettersAndSyllables = [5 1 5 2];
                    elseif r < 0.7
                      lettersAndSyllables = [6 1 6 2];
                    elseif r < 0.9
                      lettersAndSyllables = [5 1 6 2];
                    else
                      lettersAndSyllables = [6 1 5 2];
                    end
                  end
                case 5
                  if match
                    if r < 0.2
                      lettersAndSyllables = [6 2 6 2];
                    elseif r < 0.35
                      lettersAndSyllables = [7 2 7 2];
                    elseif r < 0.5
                      lettersAndSyllables = [6 3 6 3];
                    elseif r < 0.7
                      lettersAndSyllables = [7 3 7 3];
                    elseif r < 0.85
                      lettersAndSyllables = [6 2 7 2];
                    else
                      lettersAndSyllables = [6 3 7 3];
                    end
                  else
                    if r < 0.35
                      lettersAndSyllables = [6 2 6 3];
                    elseif r < 0.7
                      lettersAndSyllables = [7 2 7 3];
                    elseif r < 0.9
                      lettersAndSyllables = [6 2 7 3];
                    else
                      lettersAndSyllables = [7 2 6 3];
                    end
                  end
                case 6
                  if match
                    if r < 0.2
                      lettersAndSyllables = [7 2 7 2];
                    elseif r < 0.35
                      lettersAndSyllables = [8 2 8 2];
                    elseif r < 0.5
                      lettersAndSyllables = [7 3 7 3];
                    elseif r < 0.7
                      lettersAndSyllables = [8 3 8 3];
                    elseif r < 0.85
                      lettersAndSyllables = [7 2 8 2];
                    else
                      lettersAndSyllables = [7 3 8 3];
                    end
                  else
                    if r < 0.35
                      lettersAndSyllables = [7 2 7 3];
                    elseif r < 0.7
                      lettersAndSyllables = [8 2 8 3];
                    elseif r < 0.9
                      lettersAndSyllables = [7 2 8 3];
                    else
                      lettersAndSyllables = [8 2 7 3];
                    end
                  end
                case 7
                  if match
                    if r < 0.2
                      lettersAndSyllables = [8 3 8 3];
                    elseif r < 0.35
                      lettersAndSyllables = [9 3 9 3];
                    elseif r < 0.5
                      lettersAndSyllables = [8 4 8 4];
                    elseif r < 0.7
                      lettersAndSyllables = [9 4 9 4];
                    elseif r < 0.85
                      lettersAndSyllables = [8 3 9 3];
                    else
                      lettersAndSyllables = [8 4 9 4];
                    end
                  else
                    if r < 0.35
                      lettersAndSyllables = [8 3 8 4];
                    elseif r < 0.7
                      lettersAndSyllables = [9 3 9 4];
                    elseif r < 0.9
                      lettersAndSyllables = [8 3 9 4];
                    else
                      lettersAndSyllables = [9 3 8 4];
                    end
                  end
              end

              widx1 = 0;
              widx2 = 0;
              while widx1 == widx2
                widx1 = find(pseudowords.syllables == lettersAndSyllables(2) & pseudowords.letters == lettersAndSyllables(1));
                widx1 = widx1(randi(length(widx1)));
                widx2 = find(pseudowords.syllables == lettersAndSyllables(4) & pseudowords.letters == lettersAndSyllables(3));
                widx2 = widx2(randi(length(widx2)));
              end
              
              if rand < 0.5
                tempwidx = widx1;
                widx1 = widx2;
                widx2 = tempwidx;
              end
              
              item1 = convertCase(pseudowords.word{widx1}, stimCase);
              item2 = convertCase(pseudowords.word{widx2}, stimCase);
              
              nLetters = [nLetters; length(item1) + length(item2)]; %#ok<AGROW>
              
              item = widx1 + widx2 / 10000;
              
            else % rhyme judgment
              % find an item of the right difficulty range that has not been presented previously
              alreadyPresented = history.item(history.paradigm >= 13 & history.cond == 1);
              validItems = find((rhyme.match == match) & (rhyme.difficulty == difficulty));
              validItems = validItems(~ismember(validItems, alreadyPresented));
              if isempty(validItems)
                % consider only items presented today
                alreadyPresented = history.item(history.paradigm >= 13 & history.cond == 1 & floor(history.when) == floor(runId));
                validItems = find((rhyme.match == match) & (rhyme.difficulty == difficulty));
                validItems = validItems(~ismember(validItems, alreadyPresented));
                if isempty(validItems)
                  % give up, present anything in range
                  validItems = find((rhyme.match == match) & (rhyme.difficulty == difficulty));
                end
              end
              item = validItems(randi(length(validItems)));

              if rand < 0.5
                item1 = rhyme.word1{item};
                item2 = rhyme.word2{item};
              else
                item1 = rhyme.word2{item};
                item2 = rhyme.word1{item};
              end
              
              item1 = convertCase(item1, stimCase);
              item2 = convertCase(item2, stimCase);
              nLetters = [nLetters; length(item1) + length(item2)]; %#ok<AGROW>
            end
            
          case 2 % symbols or tones
            if paradigm <= 4 || paradigm >= 9 % symbols
              % how many letters to use?
              if paradigm == 1 || paradigm == 9 || paradigm == 13
                letters = 10;
              elseif isempty(nLetters)
                letters = 10;
              else
                lastNLetters = length(nLetters);  
                if paradigm == 2 || paradigm == 10 || paradigm == 14
                  firstNLetters = lastNLetters - 5;
                else
                  firstNLetters = lastNLetters - trialsPerBlock + 1;
                end
                if firstNLetters < 1
                  firstNLetters = 1;
                end
                letters = max(round(mean(nLetters(firstNLetters:lastNLetters)) - 1 + rand * 2), 6); % ensure at least 3 letters per word
              end
              if match
                if mod(letters, 2) == 1
                  letters = letters + round(rand) * 2 - 1;
                end
                letters = letters / 2;
                item1 = symbols(randi(length(symbols), letters, 1));
                item2 = item1;
                
              else
                switch difficulty
                  case 1
                    if mod(letters, 2) == 0
                      letters = letters + round(rand) * 2 - 1;
                    end
                    if rand < 0.5
                      letters1 = letters / 2 + 0.5;
                      letters2 = letters / 2 - 0.5;
                    else
                      letters1 = letters / 2 - 0.5;
                      letters2 = letters / 2 + 0.5;
                    end
                    item1 = symbols(randi(length(symbols), letters1, 1));
                    item2 = symbols(randi(length(symbols), letters2, 1));
                  case 2
                    if mod(letters, 2) == 1
                      letters = letters + round(rand) * 2 - 1;
                    end
                    letters = letters / 2;
                    item1 = symbols(randi(length(symbols), letters, 1));
                    item2 = symbols(randi(length(symbols), letters, 1));
                  otherwise
                    if mod(letters, 2) == 1
                      letters = letters + round(rand) * 2 - 1;
                    end
                    letters = letters / 2;
                    item1 = symbols(randi(length(symbols), letters, 1));
                    item2 = item1;
                    switch difficulty
                      case 3 % swap first letter, last letter, and one from middle
                        swap = [1, randi(letters - 2) + 1, letters];
                      case 4
                        if rand < 0.5
                          swap = [1, randi(letters - 2) + 1];
                        else
                          swap = [randi(letters - 2) + 1, letters];
                        end
                      case 5
                        if rand < 0.5
                          swap = 1;
                        else
                          swap = letters;
                        end
                      case 6 % swap two letters at random
                        swap = randperm(letters);
                        swap = swap(1:2);
                      case 7 % swap one letter at random
                        swap = randi(letters);
                    end
                    for i = 1:length(swap)
                      while item1(swap(i)) == item2(swap(i))
                        item2(swap(i)) = symbols(randi(length(symbols)));
                      end
                    end
                end
              end
              item = 0;
              
            else % tones
              switch difficulty
                case 1
                  nTones = 1;
                  nflip = 1;
                  daLength = 1;
                case 2
                  nTones = 2;
                  nflip = 1;
                  daLength = 2;
                case 3
                  nTones = 3;
                  nflip = 2;
                  daLength = 3;
                case 4
                  nTones = 4;
                  nflip = 3;
                  daLength = 4;
                case 5
                  nTones = 4;
                  nflip = 1;
                  daLength = 4;
                case 6
                  nTones = 5;
                  nflip = 2;
                  daLength = 5;
                case 7
                  nTones = 5;
                  nflip = 1;
                  daLength = 5;
              end
              item = repmat(floor(rand(1, nTones) * 3), 2, 1);
              if ~match
                flip = randperm(size(item, 2));
                flip = flip(1:nflip);

                for i = 1:nflip
                  switch item(2, flip(i))
                    case 0
                      item(2, flip(i)) = 1;
                    case 1
                      item(2, flip(i)) = round(rand) * 2; % 0 or 2
                    case 2
                      item(2, flip(i)) = 0;
                  end
                end
              end
                            
              gapInPair = 0.8 - difficulty * 0.07;
              bigGap = zeros(1, round(gapInPair * fs));
              stimulus = [];
              for i = 1:2
                for j = 1:size(item, 2)
                  if item(i, j) == 0
                    stimulus = [stimulus da{1, daLength}(1, :)]; %#ok<AGROW>
                  elseif item(i, j) == 1
                    stimulus = [stimulus da{2, daLength}(1, :)]; %#ok<AGROW>
                  else
                    stimulus = [stimulus da{3, daLength}(1, :)]; %#ok<AGROW>
                  end
                end
                if i == 1
                  stimulus = [stimulus bigGap]; %#ok<AGROW>
                end
              end
              item1 = ['da' sprintf('%d', item(1, :) + 1)];
              item2 = ['da' sprintf('%d', item(2, :) + 1)];
              item = 0;
            end
        end

        % present the trial
        if paradigm <= 4 || paradigm >= 9 % visual paradigms
          Screen('FillRect', w, backgroundColor);
          if cond == 2
            Screen('TextFont', w, monoFont);
          end
          
          Screen('TextSize', w, round(stimulusFontSize * yGrid));
          DrawFormattedText(w, item1, 'center', y - round(2/3 * stimulusFontSize * yGrid), textColor);
          DrawFormattedText(w, item2, 'center', y + round(4/3 * stimulusFontSize * yGrid), textColor);
          Screen('TextFont', w, propFont);
          if hintText && (paradigm == 1 || paradigm == 5 || paradigm == 9 || paradigm == 13)
            writeInstructions(w, standardFontSize, yGrid, verticalLines, hintColor, trainingDifficulty)
          end
          Screen('CopyWindow', w, wOffscreen); % "backup" to continue drawing over later, because Screen('Flip', w, 0, true) throws an error for no apparent reason
          fprintf('runId %.6f time %.3f finished preparing trial %d for intended presentation time %.3f\n', runId, GetSecs - expStartTime, trial, intendedOnset);
          q = waitUntil([], expStartTime + intendedOnset, expStartTime, runId, pahandle);
          if q, break; end
          t = Screen('Flip', w);

        else % auditory paradigms
          PsychPortAudio('FillBuffer', pahandle, stimulus);
          fprintf('runId %.6f time %.3f finished preparing trial %d for intended presentation time %.3f\n', runId, GetSecs - expStartTime, trial, intendedOnset);
          q = waitUntil([], expStartTime + intendedOnset, expStartTime, runId, pahandle);
          if q, break; end
          PsychPortAudio('Stop', pahandle, 2);
          t = PsychPortAudio('Start', pahandle, 1, 0, 1);
        end

        onset = t - expStartTime;
        when = str2double(datestr(now, 'yyyymmdd.HHMMSSFFF'));
        fprintf('runId %.6f time %.3f presented trial %d\n', runId, onset, trial);
          
        if paradigm <= 4 || paradigm >= 9 % visual paradigms
          Screen('CopyWindow', wOffscreen, w); % restore from backup        
        end
        
        if intendedOnset == -1
          intendedOnset = onset;
        end
        
        % don't accept responses too early because they probably belong to the previous trial
        q = waitUntil([], expStartTime + onset + ignoreWindow, expStartTime, runId, pahandle);
        if q, break; end
        fprintf('runId %.6f time %.3f ignore window over, now waiting for response\n', runId, GetSecs - expStartTime);
        
        % now wait for a response
        if paradigm == 1 || paradigm == 5 || paradigm == 9 || paradigm == 13
          keysAllowed = [matchKeys, 'z', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'a', 's', 'd', 'f'];
        else
          keysAllowed = matchKeys;
        end
        [q, key, keyTime] = waitUntil(keysAllowed, expStartTime + intendedOnset + rtWindow - iti, expStartTime, runId, pahandle);
        if q, break; end
        if isempty(key)
          key = '-';
        end
        
        switch key
          case matchKeys % button press
            response = true;
            rt = keyTime - expStartTime - onset;
            
            % feedback that button was pressed
            if paradigm <= 4 || paradigm >= 9
              Screen('DrawLine', w, textColor, x * 2/5, y * 1/2, x * 8/5, y * 1/2, lineWidth);
              Screen('DrawLine', w, textColor, x * 2/5, y * 3/2, x * 8/5, y * 3/2, lineWidth);
              Screen('DrawLine', w, textColor, x * 2/5, y * 1/2, x * 2/5, y * 3/2, lineWidth);
              Screen('DrawLine', w, textColor, x * 8/5, y * 1/2, x * 8/5, y * 3/2, lineWidth);
              Screen('Flip', w);
            else
              PsychPortAudio('FillBuffer', pahandle, ding);
              PsychPortAudio('Stop', pahandle, 2);
              PsychPortAudio('Start', pahandle, 1, 0, 1);
            end
            fprintf('runId %.6f time %.3f match response received\n', runId, keyTime - expStartTime);            
          case {'z', '-', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'a', 's', 'd', 'f'} % no response
            response = false;
            rt = 0;
            if key ~= 'z' && key ~= '-'
              bufferKey = key; % loop around and treat this as in instruction for the next trial
            end
            fprintf('runId %.6f time %.3f no response received in window\n', runId, GetSecs - expStartTime);
          otherwise
            error('Unexpected key.');
        end

        % 2-up-1-down staircase
        correct = response == match;
        if correct
          prevCorrect = history.correct(history.runId == runId & history.cond == cond);
          prevDifficulty = history.difficulty(history.runId == runId & history.cond == cond);
          if ~isempty(prevCorrect) && prevCorrect(end) == 1 && prevDifficulty(end) == difficulty
            newDifficulty = min(difficulty + stepHarder, nDifficultyLevels);
          else
            newDifficulty = difficulty;
          end
        else
          newDifficulty = max(difficulty - stepEasier, 1);
        end

        % update history structure and log file
        nHistory = nHistory + 1;
        history.when(nHistory) = when;
        history.runId(nHistory) = runId;
        history.paradigm(nHistory) = paradigm;
        history.intendedOnset(nHistory) = intendedOnset;
        history.onset(nHistory) = onset;
        history.cond(nHistory) = cond;
        history.difficulty(nHistory) = difficulty;
        history.match(nHistory) = match;
        history.item(nHistory) = item;
        history.item1{nHistory} = item1;
        history.item2{nHistory} = item2;
        history.rtWindow(nHistory) = rtWindow;
        history.response(nHistory) = response;
        history.rt(nHistory) = rt;
        history.correct(nHistory) = correct;
        history.newDifficulty(nHistory) = newDifficulty;
        
        logLine = sprintf('%.9f\t%.6f\t%d\t%.3f\t%.3f\t%d\t%d\t%d\t%.4f\t%s\t%s\t%.3f\t%d\t%.3f\t%d\t%d\n', ...
          history.when(nHistory), ...
          history.runId(nHistory), ...
          history.paradigm(nHistory), ...
          history.intendedOnset(nHistory), ...
          history.onset(nHistory), ...
          history.cond(nHistory), ...
          history.difficulty(nHistory), ...
          history.match(nHistory), ...
          history.item(nHistory), ...
          history.item1{nHistory}, ...
          history.item2{nHistory}, ...          
          history.rtWindow(nHistory), ...
          history.response(nHistory), ...
          history.rt(nHistory), ...
          history.correct(nHistory), ...
          history.newDifficulty(nHistory));
        
        fprintf(historyFid, logLine);
        fprintf('runId %.6f time %.3f logging: %s', runId, GetSecs - expStartTime, logLine);
        
        % wait before moving on if necessary
        if paradigm == 1 || paradigm == 5 || paradigm == 9 || paradigm == 13 % practice
          if response
            q = waitUntil([], GetSecs + 1, expStartTime, runId, pahandle);
            if q, break; end
          end
        else
          q = waitUntil([], expStartTime + intendedOnset + rtWindow - iti, expStartTime, runId, pahandle);
          if q, break; end
        end        
        fprintf('runId %.6f time %.3f trial complete\n', runId, GetSecs - expStartTime);            
      end
      fclose(historyFid);

    case {25, 26, 27} % fixed matching
      events = fixed_events{paradigm};
      nTrials = length(events.cond);
      for trial = 1:nTrials
        fprintf('runId %.6f time %.3f starting trial %d\n', runId, GetSecs - expStartTime, trial);
        Screen('FillRect', w, backgroundColor);
        drawCrossHair(w, crossColor);
        Screen('Flip', w);

        % set up the trial
        switch floor(events.cond(trial))
          case 1
            cond = 1;
            difficulty = 1;
            rtWindow = 2;
            itemTextColor = [128 255 128];
          case 2
            cond = 1;
            difficulty = 2;
            rtWindow = 2;
            itemTextColor = [255 128 128];
          case 3
            cond = 2;
            difficulty = 1;
            rtWindow = 2;
            itemTextColor = [128 255 128];
          case 4
            cond = 2;
            difficulty = 2;
            rtWindow = 2;
            itemTextColor = [255 128 128];
          case 5
            cond = 3;
            difficulty = 0;
            rtWindow = 16;
        end
        match = round(rem(events.cond(trial), 1) * 10);
        intendedOnset = events.onset(trial);
        item = trial;
        item1 = upper(events.word1{trial});
        item2 = upper(events.word2{trial});
        
        % slightly adaptive difficult semantic condition
        if cond == 1 && difficulty == 2
          options1 = textscan(item1, '%s', 'delimiter', '|'); options1 = options1{1}; % options1 = split(item1, '|');
          options2 = textscan(item2, '%s', 'delimiter', '|'); options2 = options2{1}; % options2 = split(item2, '|');
          semDiffAcc  = mean(history.correct(history.runId == runId & history.cond == 1 & history.difficulty == 2)) * 100;
          percDiffAcc = mean(history.correct(history.runId == runId & history.cond == 2 & history.difficulty == 2)) * 100;
          if isnan(semDiffAcc) || isnan(percDiffAcc)
            level = 2;
          elseif semDiffAcc < percDiffAcc - 5
            level = 1;
          elseif semDiffAcc > percDiffAcc + 5
            level = 3;
          else
            level = 2;
          end
          item1 = options1{level};
          item2 = options2{level};
        end
        
        % present the trial
        if cond == 1 || cond == 2
          Screen('FillRect', w, backgroundColor);
          if cond == 2
            Screen('TextFont', w, monoFont);
          end

          Screen('TextSize', w, round(stimulusFontSize * yGrid));
          DrawFormattedText(w, double(item1), 'center', y - round(2/3 * stimulusFontSize * yGrid), itemTextColor); % cast to double needed for unicode
          DrawFormattedText(w, double(item2), 'center', y + round(4/3 * stimulusFontSize * yGrid), itemTextColor);
          Screen('TextFont', w, propFont);
          Screen('CopyWindow', w, wOffscreen); % "backup" to continue drawing over later, because Screen('Flip', w, 0, true) throws an error for no apparent reason
          fprintf('runId %.6f time %.3f finished preparing trial %d for intended presentation time %.3f\n', runId, GetSecs - expStartTime, trial, intendedOnset);
          q = waitUntil([], expStartTime + intendedOnset, expStartTime, runId, pahandle);
          if q, break; end
          t = Screen('Flip', w);
          stimOn = true;
          onset = t - expStartTime;
          when = str2double(datestr(now, 'yyyymmdd.HHMMSSFFF'));
          fprintf('runId %.6f time %.3f presented trial %d\n', runId, onset, trial);

          Screen('CopyWindow', wOffscreen, w); % restore from backup        

          % don't accept responses too early because they probably belong to the previous trial
          q = waitUntil([], expStartTime + onset + ignoreWindow, expStartTime, runId, pahandle);
          if q, break; end
          fprintf('runId %.6f time %.3f ignore window over, now waiting for response\n', runId, GetSecs - expStartTime);

          % now wait for a response
          keysAllowed = matchKeys;
          [q, key, keyTime] = waitUntil(keysAllowed, expStartTime + intendedOnset + showDuration, expStartTime, runId, pahandle);
          if q, break; end
          if isempty(key) % finished showing the stimulus but no key yet
            Screen('FillRect', w, backgroundColor);
            drawCrossHair(w, textColor);
            Screen('Flip', w);
            stimOn = false;
            Screen('FillRect', w, backgroundColor); % restore in case we need to draw box later
            drawCrossHair(w, textColor);
            [q, key, keyTime] = waitUntil(keysAllowed, expStartTime + intendedOnset + rtWindow - iti, expStartTime, runId, pahandle);          
            if q, break; end
            if isempty(key)
              key = '-';
            end
          end

          switch key
            case matchKeys % button press
              response = true;
              rt = keyTime - expStartTime - onset;

              % feedback that button was pressed
              Screen('DrawLine', w, textColor, x * 2/5, y * 1/2, x * 8/5, y * 1/2, lineWidth);
              Screen('DrawLine', w, textColor, x * 2/5, y * 3/2, x * 8/5, y * 3/2, lineWidth);
              Screen('DrawLine', w, textColor, x * 2/5, y * 1/2, x * 2/5, y * 3/2, lineWidth);
              Screen('DrawLine', w, textColor, x * 8/5, y * 1/2, x * 8/5, y * 3/2, lineWidth);
              Screen('Flip', w);
              fprintf('runId %.6f time %.3f match response received\n', runId, keyTime - expStartTime);
              
              if stimOn
                q = waitUntil([], expStartTime + intendedOnset + showDuration, expStartTime, runId, pahandle);          
                if q, break; end
                Screen('FillRect', w, backgroundColor);
                drawCrossHair(w, textColor);
                Screen('DrawLine', w, textColor, x * 2/5, y * 1/2, x * 8/5, y * 1/2, lineWidth);
                Screen('DrawLine', w, textColor, x * 2/5, y * 3/2, x * 8/5, y * 3/2, lineWidth);
                Screen('DrawLine', w, textColor, x * 2/5, y * 1/2, x * 2/5, y * 3/2, lineWidth);
                Screen('DrawLine', w, textColor, x * 8/5, y * 1/2, x * 8/5, y * 3/2, lineWidth);
                Screen('Flip', w);
              end
              
            case {'-'} % no response
              response = false;
              rt = 0;
              fprintf('runId %.6f time %.3f no response received in window\n', runId, GetSecs - expStartTime);
            otherwise
              error('Unexpected key.');
          end

          % accuracy
          correct = response == match;
          
        else % rest
          Screen('FillRect', w, backgroundColor);
          drawCrossHair(w, textColor);
          Screen('Flip', w);
          rtWindow = 16;
        end

        % update history structure and log file
        nHistory = nHistory + 1;
        history.when(nHistory) = when;
        history.runId(nHistory) = runId;
        history.paradigm(nHistory) = paradigm;
        history.intendedOnset(nHistory) = intendedOnset;
        history.onset(nHistory) = onset;
        history.cond(nHistory) = cond;
        history.difficulty(nHistory) = difficulty;
        history.match(nHistory) = match;
        history.item(nHistory) = item;
        history.item1{nHistory} = item1;
        history.item2{nHistory} = item2;
        history.rtWindow(nHistory) = rtWindow;
        history.response(nHistory) = response;
        history.rt(nHistory) = rt;
        history.correct(nHistory) = correct;
        history.newDifficulty(nHistory) = 0; % not applicable for fixed
        
        logLine = sprintf('%.9f\t%.6f\t%d\t%.3f\t%.3f\t%d\t%d\t%d\t%.4f\t%s\t%s\t%.3f\t%d\t%.3f\t%d\t%d\n', ...
          history.when(nHistory), ...
          history.runId(nHistory), ...
          history.paradigm(nHistory), ...
          history.intendedOnset(nHistory), ...
          history.onset(nHistory), ...
          history.cond(nHistory), ...
          history.difficulty(nHistory), ...
          history.match(nHistory), ...
          history.item(nHistory), ...
          history.item1{nHistory}, ...
          history.item2{nHistory}, ...          
          history.rtWindow(nHistory), ...
          history.response(nHistory), ...
          history.rt(nHistory), ...
          history.correct(nHistory), ...
          history.newDifficulty(nHistory));
        
        fprintf(historyFid, logLine);
        fprintf('runId %.6f time %.3f logging: %s', runId, GetSecs - expStartTime, logLine);
        
        % wait before moving on if necessary
        q = waitUntil([], expStartTime + intendedOnset + rtWindow - iti, expStartTime, runId, pahandle);
        if q, break; end
        fprintf('runId %.6f time %.3f trial complete\n', runId, GetSecs - expStartTime);            
      end
      fclose(historyFid);      
      
    case {28, 29, 30} % fixed matching -- auditory
      events = fixed_events{paradigm};
      nTrials = length(events.cond);
      % these variables need to be stored in arrays because of the overlap
      % between trials being planned and trials being presented
      % n.b. tr = trial being prepared
      %      trial = trial being presented
      when_array = cell(nTrials, 1);
      intendedOnset_array = zeros(nTrials, 1);
      cond_array = zeros(nTrials, 1);
      difficulty_array = zeros(nTrials, 1);
      match_array = zeros(nTrials, 1);
      item1_array = cell(nTrials, 1);
      item2_array = cell(nTrials, 1);
      % three different audio channels are used:
      % - extra_pahandle(1)  odd-numbered trials
      % - extra_pahandle(2)  even-numbered trials
      % - pahandle           "ding" match response
      visualCues = [floor(events.cond(mod(events.onset, 16) == 0)), expStartTime + events.onset(mod(events.onset, 16) == 0)];
      for trial = 1:nTrials
        fprintf('runId %.6f time %.3f starting trial %d\n', runId, GetSecs - expStartTime, trial);
        
        % if trial 1, schedule trials 1 and 2, if last trial, schedule nothing, otherwise schedule the *following* trial
        if trial == 1
          trials = [1 2];
        elseif trial == nTrials
          trials = [];
        else
          trials = trial + 1;
        end
        for tr = trials
          switch floor(events.cond(tr))
            case 1
              cond_array(tr) = 1;
              difficulty_array(tr) = 1;
            case 2
              cond_array(tr) = 1;
              difficulty_array(tr) = 2;
            case 3
              cond_array(tr) = 2;
              difficulty_array(tr) = 1;
            case 4
              cond_array(tr) = 2;
              difficulty_array(tr) = 2;
            case 5
              cond_array(tr) = 3;
              difficulty_array(tr) = 0;
          end
          
          if cond_array(tr) ~= 3
            match_array(tr) = round(rem(events.cond(tr), 1) * 10);
            intendedOnset_array(tr) = events.onset(tr);
            item1_array{tr} = upper(events.word1{tr});
            item2_array{tr} = upper(events.word2{tr});
          end
          
          % slightly adaptive difficult semantic condition
          if cond_array(tr) == 1 && difficulty_array(tr) == 2
            options1 = textscan(item1_array{tr}, '%s', 'delimiter', '|'); options1 = options1{1}; % options1 = split(item1, '|');
            options2 = textscan(item2_array{tr}, '%s', 'delimiter', '|'); options2 = options2{1}; % options2 = split(item2, '|');
            semDiffAcc  = mean(history.correct(history.runId == runId & history.cond == 1 & history.difficulty == 2)) * 100;
            percDiffAcc = mean(history.correct(history.runId == runId & history.cond == 2 & history.difficulty == 2)) * 100;
            if isnan(semDiffAcc) || isnan(percDiffAcc)
              level = 2;
            elseif semDiffAcc < percDiffAcc - 5
              level = 1;
            elseif semDiffAcc > percDiffAcc + 5
              level = 3;
            else
              level = 2;
            end
            level = 2; % zzz just for testing TAKE THIS OUT
            item1_array{tr} = options1{level};
            item2_array{tr} = options2{level};
          end

          switch cond_array(tr)
            case 1 % words
              wav1 = fixedWav.(lower(item1_array{tr}));
              wav2 = fixedWav.(lower(item2_array{tr}));
              switch difficulty_array(tr)
                case 1
                  gapInPair = 0.20;
                case 2
                  gapInPair = 0.25;
              end
              % stimulus = [wav1, zeros(nchan, round(gapInPair * fs)), wav2];
              stimulus = [wav1, zeros(1, length(wav2) - round(gapInPair * fs))] + [zeros(1, length(wav1) - round(gapInPair * fs)), wav2];
              stimulus(stimulus < -1) = -1;
              stimulus(stimulus > 1) = 1;
              events.midpoint(tr) = events.onset(tr) + length(wav1) / fs; % maybe should consider gap
            case 2 % tones
              switch difficulty_array(tr)
                case 1
                  nTones = 2;
                  nflip = 1;
                  daLength = 3;
                  gapInPair = 0.12;
                case 2
                  nTones = 5;
                  nflip = 1;
                  daLength = 7;
                  gapInPair = 0.05;
              end
              item = repmat(floor(rand(1, nTones) * 3), 2, 1);
              if ~match_array(tr)
                flip = randperm(size(item, 2));
                flip = flip(1:nflip);

                for i = 1:nflip
                  switch item(2, flip(i))
                    case 0
                      item(2, flip(i)) = 1;
                    case 1
                      item(2, flip(i)) = round(rand) * 2; % 0 or 2
                    case 2
                      item(2, flip(i)) = 1;
                  end
                end
              end
                            
              bigGap = zeros(1, round(gapInPair * fs));
              stimulus = [];
              for i = 1:2
                for j = 1:nTones
                  if item(i, j) == 0
                    stimulus = [stimulus da{1, daLength}(1, :)]; %#ok<AGROW>
                  elseif item(i, j) == 1
                    stimulus = [stimulus da{2, daLength}(1, :)]; %#ok<AGROW>
                  else
                    stimulus = [stimulus da{3, daLength}(1, :)]; %#ok<AGROW>
                  end
                end
                if i == 1
                  events.midpoint(tr) = events.onset(tr) + length(stimulus) / fs;
                  stimulus = [stimulus bigGap]; %#ok<AGROW>
                end
              end
              item1_array{tr} = ['da' sprintf('%d', item(1, :) + 1)];
              item2_array{tr} = ['da' sprintf('%d', item(2, :) + 1)];
             
            case 3 % rest
              stimulus = [];
              events.midpoint(tr) = events.onset(tr) + 1;            
          end

          if cond_array(tr) ~= 3
            % schedule the sound
            PsychPortAudio('FillBuffer', extra_pahandle(mod(tr, 2) + 1), stimulus);
            PsychPortAudio('Start', extra_pahandle(mod(tr, 2) + 1), 1, expStartTime + intendedOnset_array(tr), 0);
            fprintf('runId %.6f time %.3f scheduled trial %d for intended presentation time %.3f\n', runId, GetSecs - expStartTime, tr, intendedOnset_array(tr));
            when_array{tr} = str2double(datestr(expStartTime + intendedOnset_array(tr), 'yyyymmdd.HHMMSSFFF'));
            fprintf('_tr\t%d\tcond\t%d\tdifficulty\t%d\tlength\t%.4f\trms\t%.4f\n', tr, cond_array(tr), difficulty_array(tr), length(stimulus) / fs, sqrt(mean(stimulus .^ 2)));
          end
        end
        
        % now wait for a response to actual current trial
        if cond_array(trial) ~= 3
          if trial < nTrials
            untilTime = expStartTime + events.midpoint(trial + 1);
          else
            untilTime = expStartTime + expDuration;
          end
          rtWindow = untilTime - GetSecs;
          onset = events.onset(trial);
          keysAllowed = matchKeys;
          fprintf('runId %.6f time %.3f waiting for response to trial %d until %.3f\n', runId, GetSecs - expStartTime, trial, untilTime - expStartTime);
          key = [];
          if ~isempty(visualCues) && untilTime > visualCues(1, 2)
            Screen('FillRect', w, backgroundColor);
            switch visualCues(1, 1)
              case {1, 3}
                crossColor = [128 255 128];
              case {2, 4}
                crossColor = [255 128 128];
              case 5
                crossColor = [255 255 255];
            end
            drawCrossHair(w, crossColor);
            [q, key, keyTime] = waitUntil(keysAllowed, visualCues(1, 2), expStartTime, runId);
            if q, break; end
            if isempty(key)
              Screen('Flip', w, 1);
              fprintf('runId %.6f time %.3f crossColor = %s\n', runId, GetSecs - expStartTime, sprintf('%d ', crossColor));
              visualCues = visualCues(2:end, :);
            end
          end
          if isempty(key)
            [q, key, keyTime] = waitUntil(keysAllowed, untilTime, expStartTime, runId);
            if q, break; end
          end
          if isempty(key)
            key = '-';
          end

          switch key
            case matchKeys % button press
              response = true;
              rt = keyTime - expStartTime - onset;

              % feedback that button was pressed
              PsychPortAudio('FillBuffer', pahandle, ding .* 0.2); % quiet ding
              PsychPortAudio('Stop', pahandle);
              PsychPortAudio('Start', pahandle, 1, 0, 0);

              fprintf('runId %.6f time %.3f match response received\n', runId, keyTime - expStartTime);
            case {'-'} % no response
              response = false;
              rt = 0;
              fprintf('runId %.6f time %.3f no response received in window\n', runId, GetSecs - expStartTime);
            otherwise
              error('Unexpected key.');
          end

          % accuracy
          correct = response == match_array(trial);

          % update history structure and log file
          nHistory = nHistory + 1;
          history.when(nHistory) = when_array{trial};
          history.runId(nHistory) = runId;
          history.paradigm(nHistory) = paradigm;
          history.intendedOnset(nHistory) = intendedOnset_array(trial);
          history.onset(nHistory) = onset;
          history.cond(nHistory) = cond_array(trial);
          history.difficulty(nHistory) = difficulty_array(trial);
          history.match(nHistory) = match_array(trial);
          history.item(nHistory) = trial;
          history.item1{nHistory} = item1_array{trial};
          history.item2{nHistory} = item2_array{trial};
          history.rtWindow(nHistory) = rtWindow; % N/A
          history.response(nHistory) = response;
          history.rt(nHistory) = rt;
          history.correct(nHistory) = correct;
          history.newDifficulty(nHistory) = 0; % N/A

          logLine = sprintf('%.9f\t%.6f\t%d\t%.3f\t%.3f\t%d\t%d\t%d\t%.4f\t%s\t%s\t%.3f\t%d\t%.3f\t%d\t%d\n', ...
            history.when(nHistory), ...
            history.runId(nHistory), ...
            history.paradigm(nHistory), ...
            history.intendedOnset(nHistory), ...
            history.onset(nHistory), ...
            history.cond(nHistory), ...
            history.difficulty(nHistory), ...
            history.match(nHistory), ...
            history.item(nHistory), ...
            history.item1{nHistory}, ...
            history.item2{nHistory}, ...          
            history.rtWindow(nHistory), ...
            history.response(nHistory), ...
            history.rt(nHistory), ...
            history.correct(nHistory), ...
            history.newDifficulty(nHistory));

          fprintf(historyFid, logLine);
          fprintf('runId %.6f time %.3f logging: %s', runId, GetSecs - expStartTime, logLine);        

          % wait before moving on if necessary
          if ~isempty(visualCues) && untilTime > visualCues(1, 2)
            q = waitUntil([], visualCues(1, 2), expStartTime, runId);
            if q, break; end
            Screen('Flip', w, 1);
            fprintf('runId %.6f time %.3f crossColor = %s\n', runId, GetSecs - expStartTime, sprintf('%d ', crossColor));
            visualCues = visualCues(2:end, :);
          end
          q = waitUntil([], untilTime, expStartTime, runId);
          if q, break; end
          fprintf('runId %.6f time %.3f trial complete\n', runId, GetSecs - expStartTime);    
          
        else % rest
          if trial < nTrials
            untilTime = expStartTime + events.midpoint(trial + 1);
          else
            untilTime = expStartTime + expDuration;
          end
          if ~isempty(visualCues) && untilTime > visualCues(1, 2)
            Screen('FillRect', w, backgroundColor);
            switch visualCues(1, 1)
              case {1, 3}
                crossColor = [128 255 128];
              case {2, 4}
                crossColor = [255 128 128];
              case 5
                crossColor = [255 255 255];
            end
            drawCrossHair(w, crossColor);
            q = waitUntil([], visualCues(1, 2), expStartTime, runId);
            if q, break; end
            Screen('Flip', w, 1);
            fprintf('runId %.6f time %.3f crossColor = %s\n', runId, GetSecs - expStartTime, sprintf('%d ', crossColor));
            visualCues = visualCues(2:end, :);
          end
          q = waitUntil([], untilTime, expStartTime, runId);
          if q, break; end
        end
      end
      fclose(historyFid);
            
    case {17, 18, 19, 20, 21, 22, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41} % narrative, picname, or standard clinical paradigms
      % loop through events
      for i = 1:size(events, 1)
        trialtype = events(i, 1);
        onset = events(i, 2);

        % wait till it's time for next trial
        if onset == -1 % practice
          q = waitUntil({'6', '6^'}, inf, expStartTime, runId, pahandle);
        else
          q = waitUntil([], expStartTime + onset, expStartTime, runId, pahandle);
        end
        if q, break; end
        
        switch paradigm
          case {17, 18, 19}
            seg = round(mod(trialtype, 1) * 1000);
            PsychPortAudio('FillBuffer', pahandle, narrwav{seg, floor(trialtype)});
            dur = size(narrwav{seg, floor(trialtype)}, 2) / fs;
            t = PsychPortAudio('Start', pahandle, 1, 0, 1);
            fprintf('runId %.6f time %.3f presented event %d item %f (intended onset %.3f, intended duration %.3f)\n', ...
              runId, t - expStartTime, i, trialtype, onset, dur);
          
          case {20, 21, 22}
            item = round(rem(trialtype, 1) * 10000);
            Screen('FillRect', w, backgroundColor);
            [ysize, xsize, ~] = size(picnamePic{item});
            scaling = yDim / 500;
            picrect = round([x - xsize / 2 * scaling, y - ysize / 2 * scaling, x + xsize / 2 * scaling, y + ysize / 2 * scaling]);
            if floor(trialtype) == 2
              Screen('PutImage', w, scramblePic{item}, picrect);
            else
              Screen('PutImage', w, picnamePic{item}, picrect);
            end
            t = Screen('Flip', w);
            fprintf('runId %.6f time %.3f presented event %d item %f (intended onset %.3f)\n', ...
              runId, t - expStartTime, i, trialtype, onset);
            
            q = waitUntil([], GetSecs + 3, expStartTime, runId, pahandle);
            if q, break; end
            Screen('FillRect', w, backgroundColor);
            drawCrossHair(w, crossColor);
            if hintText && paradigm == 20
              Screen('TextSize', w, round(standardFontSize * yGrid));
              DrawFormattedText(w, '[6] = present next trial; [Q]/[Esc] = quit', 'center', (verticalLines - 2) * yGrid, hintColor);
            end
            Screen('Flip', w);

          case {31, 32, 33, 34}
            Screen('TextFont', w, 'Times New Roman');
            switch paradigm
              case 31
                item = sentCompPractice{trialtype};
              case 32
                item = sentComp{trialtype};
              case 33
                item = wordGenPractice{trialtype};
              case 34
                item = wordGen{trialtype};
            end
            Screen('FillRect', w, backgroundColor);
            if item(1) == '_' % symbol
              symbolImg = wordGenSymbol{str2double(item(end - 1:end))};
              [xSize, ySize, ~] = size(symbolImg);
              maxSize = max(xSize, ySize);
              Screen('TextSize', w, round(5 * stimulusFontSize * yGrid));
              normBoundsRect = Screen('TextBounds', w, item);
              textHeight = normBoundsRect(4);
              scale = textHeight * 1.3 / maxSize;
              imgRect = round([x - xSize / 2 * scale, y - ySize / 2 * scale, x + xSize / 2 * scale, y + ySize / 2 * scale]);
              Screen('PutImage', w, symbolImg, imgRect);
            else % word
              if paradigm == 33 || paradigm == 34
                Screen('TextSize', w, round(5 * stimulusFontSize * yGrid));
                DrawFormattedText(w, item, 'center', y + round(1/3 * 5 * stimulusFontSize * yGrid), textColor);
              else
                % split the sentence at the middle space
                spaces = find(item == ' ');
                [~, middleSpace] = min(abs(spaces - length(item) / 2));
                middleSpace = spaces(middleSpace);
                item1 = item(1:(middleSpace - 1));
                item2 = item((middleSpace + 1):end);
                Screen('TextSize', w, round(stimulusFontSize * yGrid));
                DrawFormattedText(w, item1, 'center', y - round(2/3 * stimulusFontSize * yGrid), textColor);
                DrawFormattedText(w, item2, 'center', y + round(4/3 * stimulusFontSize * yGrid), textColor);
              end
            end
            Screen('TextFont', w, propFont);
            t = Screen('Flip', w);
            fprintf('runId %.6f time %.3f presented event %d item %f (intended onset %.3f)\n', ...
              runId, t - expStartTime, i, trialtype, onset);

            Screen('TextFont', w, propFont);
            q = waitUntil([], GetSecs + events(i, 3), expStartTime, runId, pahandle);
            if q, break; end
            Screen('FillRect', w, backgroundColor);
            Screen('Flip', w);

          case {35, 36, 37, 38, 39, 40, 41}
            if trialtype == 1
              trialText = activeInstruction;
            else
              trialText = controlInstruction;
            end
            Screen('FillRect', w, backgroundColor);
            if paradigm >= 38
              multiplier = 3;
            else
              multiplier = 1;
            end
            Screen('TextSize', w, round(multiplier * stimulusFontSize * yGrid));
            DrawFormattedText(w, trialText, 'center', 'center', textColor);
            t = Screen('Flip', w);
            fprintf('runId %.6f time %.3f presented event %d item %f (intended onset %.3f)\n', ...
              runId, t - expStartTime, i, trialtype, onset);

            q = waitUntil([], GetSecs + events(i, 3), expStartTime, runId, pahandle);
            if q, break; end
            Screen('FillRect', w, backgroundColor);
            Screen('Flip', w);
        end
      end
      
    case {23, 24} % breath holding
      fprintf('runId %.6f time %.3f starting breath holding waveform\n', runId, GetSecs - expStartTime);
      while GetSecs < expStartTime + expDuration
        curtime = GetSecs - expStartTime;
        wavey = zeros(xDim, 1);
        for i = 1:(xDim + skip)
          wavey(i) = parad(round((curtime - (curPosWithinWindow * window) + i / xDim * window) * 100 + normalBreath * 15 / microTime));
        end
        curpoint = round(xDim * curPosWithinWindow);
        Screen('FillRect', w, backgroundColor);
        for i = 1:skip:(xDim - 1)
          if i < curpoint - 1
            linecolor = 75;
          else
            linecolor = 255;
          end
          if i < 100
            linecolor = (i / 100) * linecolor + (100 - i) / 100 * backgroundColor(1);
          end
          if i > (xDim - 1) - 100
            linecolor = ((xDim - 1 - i) / 100) * linecolor + (100 - (xDim - 1 - i)) / 100 * backgroundColor(1);
          end
          Screen('DrawLine', w, repmat(linecolor, 1, 3), i, y - 100 * wavey(i), i + skip, ...
            y - 100 * wavey(i + skip), lineWidth);
        end
        rect = [curpoint - ballRadius, y - 100 * wavey(curpoint) - ballRadius, ...
          curpoint + ballRadius, y - 100 * wavey(curpoint) + ballRadius];

        Screen('FillOval', w, [255 255 0], rect);
        Screen('FrameOval', w, [75 75 75], rect);  
        Screen('Flip', w);

        q = waitUntil([], GetSecs + 0.001, expStartTime, runId, pahandle);
        if q, break; end
      end    
  end

  % if not quitting, wait for end of run
  if ~q
    q = waitUntil([], expStartTime + expDuration, expStartTime, runId, pahandle);
  end
    
  if q % quit key was pressed
    fprintf('runId %.6f time %.3f paradigm aborted\n', runId, GetSecs - expStartTime);            
    fprintf('%s Paradigm aborted.\n', datestr(now, 31));
    PsychPortAudio('Stop', pahandle, 2);

  else % experiment is complete
    fprintf('runId %.6f time %.3f paradigm complete\n', runId, GetSecs - expStartTime);            
    fprintf('%s Paradigm complete.\n', datestr(now, 31));

    %calculate average difficulty
    difficulty_task = history.difficulty(history.runId==runId & history.cond == 1);
    difficulty_base = history.difficulty(history.runId==runId & history.cond == 2);
    fprintf('Average difficult of task: %.3f \n',mean(difficulty_task));
    fprintf('Average difficult of baseline: %.3f \n',mean(difficulty_base));
            
    % inform subject that task is complete
    Screen('FillRect', w, backgroundColor);
    Screen('TextSize', w, round(messageFontSize * yGrid));
    DrawFormattedText(w, 'Thanks, you''ve finished this task.', 'center', 'center', textColor);
    Screen('Flip', w);
    waitUntil([], GetSecs + 2, expStartTime, runId, pahandle);
  end  
end

fprintf('%s Renaming log file to %s\n', datestr(now, 31), fullfile(myDir, [logFname '_' pid]));
clear c2_diary % close the diary
movefile(logFname, [logFname '_' pid]);

% other onCleanup functions will be executed here


function da = load_da(fs, rms)

da = cell(3, 6);
da{1, 1} = ptbWavRead('paradigms/da/da1_830.wav', fs, rms);
da{1, 2} = ptbWavRead('paradigms/da/da1_415.wav', fs, rms);
da{1, 3} = ptbWavRead('paradigms/da/da1_276.wav', fs, rms);
da{1, 4} = ptbWavRead('paradigms/da/da1_208.wav', fs, rms);
da{1, 5} = ptbWavRead('paradigms/da/da1_166.wav', fs, rms);
da{1, 6} = ptbWavRead('paradigms/da/da1_138.wav', fs, rms);
da{1, 7} = ptbWavRead('paradigms/da/da1_119.wav', fs, rms);
da{2, 1} = ptbWavRead('paradigms/da/da2_830.wav', fs, rms);
da{2, 2} = ptbWavRead('paradigms/da/da2_415.wav', fs, rms);
da{2, 3} = ptbWavRead('paradigms/da/da2_276.wav', fs, rms);
da{2, 4} = ptbWavRead('paradigms/da/da2_208.wav', fs, rms);
da{2, 5} = ptbWavRead('paradigms/da/da2_166.wav', fs, rms);
da{2, 6} = ptbWavRead('paradigms/da/da2_138.wav', fs, rms);
da{2, 7} = ptbWavRead('paradigms/da/da2_119.wav', fs, rms);
da{3, 1} = ptbWavRead('paradigms/da/da3_830.wav', fs, rms);
da{3, 2} = ptbWavRead('paradigms/da/da3_415.wav', fs, rms);
da{3, 3} = ptbWavRead('paradigms/da/da3_276.wav', fs, rms);
da{3, 4} = ptbWavRead('paradigms/da/da3_208.wav', fs, rms);
da{3, 5} = ptbWavRead('paradigms/da/da3_166.wav', fs, rms);
da{3, 6} = ptbWavRead('paradigms/da/da3_138.wav', fs, rms);
da{3, 7} = ptbWavRead('paradigms/da/da3_119.wav', fs, rms);


function y = ptbWavRead(fname, fs, rms)

% read wav with readwav which is faster than built-in functions
[y, actual_fs] = readwav(fname);

% ensure row vector(s)
if size(y, 1) > 2
  y = y';
end

% resample if necessary
if actual_fs ~= fs
  y = resample(y, fs, actual_fs);
end

% covert to single precision to save memory
y = single(y);

% rms-normalize if requested
if nargin >= 3
  y = y .* (rms / sqrt(mean(y .^ 2)));
end

% clip to (-1, 1)
y(y > 1) = 1;
y(y < -1) = -1;


function m = txtread(fname, headerrow, delim, encoding, maxrows)

% M = TXTREAD(FNAME) reads the text file FNAME, which is assumed to have
% column names in the first row, followed by numbers and/or text. M is a
% structure with a field named for each column. If a column is entirely
% numeric (or empty), then its field in M is an array, otherwise its field in M
% is a cell array.

if nargin < 2 || isempty(headerrow), headerrow = true; end
if nargin < 3 || isempty(delim), delim = '\t'; end
if nargin < 4 || isempty(encoding), encoding = ''; end
if nargin < 5 || isempty(maxrows), maxrows = inf; end

warning off MATLAB:iofun:UnsupportedEncoding;

fid = fopen(fname, 'r', 'n', encoding);
if fid == -1
  error('Could not open file.');
end
s = fscanf(fid, '%c');
s = s(s ~= 13); % get rid of CR
rows = textscan(s, '%s', 'delimiter', char(10)); %#ok<CHARTEN> % split on LF
rows = rows{1};
nrows = length(rows);
if maxrows < inf
  rows = rows(1:maxrows);
  nrows = maxrows;
end
if headerrow
  n = nrows - 1;
  offset = 1;
else
  n = nrows;
  offset = 0;
end

colnames = textscan(rows{1}, '%s', 'delimiter', delim);
colnames = colnames{1};
ncols = length(colnames);
cells = cell(n, ncols);

if ~headerrow
  for i = 1:ncols
    colnames{i} = sprintf('Column%d', i);
  end
end

for r = 1:n
  nextcells = textscan(rows{r + offset}, '%s', 'delimiter', delim)';
  nextcells = nextcells{1};
  cells(r, 1:length(nextcells)) = nextcells;
end

m = [];
for c = 1:ncols
  colname = colnames{c};
  if strcmp(colname, '')
    colname = 'Untitled';
  end
  if isfield(m, colname)
    dup = 2;
    while isfield(m, sprintf('%s%d', colname, dup))
      dup = dup + 1;
    end
    colname = sprintf('%s%d', colname, dup);
  end
  s2d = str2double(cells(:, c));
  len = cellfun('length', cells(:, c));
  if any(isnan(s2d) & len > 0)
    m.(colname) = cells(:, c);
  else
    m.(colname) = s2d;
  end
end

fclose(fid);


function drawCrossHair(w, color)

if ~isempty(color)
  wRect = Screen('Rect', w);

  csize = round(wRect(4) / 30);
  lineWidth = ceil(wRect(4) / 400);
  Screen('DrawLine', w, color, wRect(3) / 2 - csize, wRect(4) / 2, ...
    wRect(3) / 2 + csize + 1, wRect(4) / 2, lineWidth);
  Screen('DrawLine', w, color, wRect(3) / 2, wRect(4) / 2 - csize, ...
    wRect(3) / 2, wRect(4) / 2 + csize + 1, lineWidth);
end


function [q, key, keyTime] = waitUntil(keysAllowed, untilTime, expStartTime, runId, pahandle)

% if called with one argument, waits for specified key(s)
% if called with 5 arguments, logs all key events and audio on/off events
% returns when either untilTime is reached, one of the keysAllowed is
% pressed, or [Q] or [Esc] is pressed.

persistent lastIsPlaying;
global devInd;
global nDevices;

if nargin < 2, untilTime = inf; end
if nargin < 3, expStartTime = []; end
if nargin < 4, runId = []; end
if nargin < 5, pahandle = []; end

q = false;
q_is_quit = true;
for i = 1:numel(keysAllowed)
  if strcmp(keysAllowed{i}, 'q')
    q_is_quit = false;
  end
end
if q_is_quit
  keysAllowed = [keysAllowed {'q'}];
end
keysAllowed = [keysAllowed {'ESCAPE'}];

if isempty(lastIsPlaying)
  lastIsPlaying = false;
end

gotKey = false;
while GetSecs < untilTime && ~gotKey
  for i = 1:nDevices
    [pressed, firstPress] = KbQueueCheck(devInd(i));
    if pressed
      for j = 1:length(firstPress)
        if firstPress(j)
          if j == 1 || j == 2 || j == 3
            k = 'MOUSE';
          else
            k = KbName(j);
          end
          if nargin >= 4
            fprintf('runId %.6f time %.3f keyDown %s\n', runId, firstPress(j) - expStartTime, k);
          end
          for l = 1:numel(keysAllowed)
            if strcmp(k, keysAllowed{l})
              gotKey = true;
              key = k;
              keyTime = firstPress(j);
              if (q_is_quit && strcmp(key, 'q')) || strcmp(key, 'ESCAPE')
                q = true;
              end
            end              
          end
        end
      end
    end
  end  
    
  if nargin >= 5 && ~isempty(pahandle)
    status = PsychPortAudio('GetStatus', pahandle);
    isPlaying = status.Active;
    if isPlaying ~= lastIsPlaying
      fprintf('runId %.6f time %.3f soundIsPlaying %d\n', runId, GetSecs - expStartTime, isPlaying);
      lastIsPlaying = isPlaying;
    end
  end
end

if ~gotKey
  key = [];
  keyTime = [];
end


function writeInstructions(w, standardFontSize, yGrid, verticalLines, hintColor, trainingDifficulty)

Screen('TextSize', w, round(standardFontSize * yGrid));
DrawFormattedText(w, '[A]/[S] = present match/mismatch language item', 'center', (verticalLines - 6) * yGrid, hintColor);
DrawFormattedText(w, '[D]/[F] = present match/mismatch control item', 'center', (verticalLines - 5) * yGrid, hintColor);
DrawFormattedText(w, '[H]/[J]/[K]/[L] = respond "match"', 'center', (verticalLines - 4) * yGrid, hintColor);
DrawFormattedText(w, sprintf('[W]/[E]/[R]/[T]/[Y]/[U]/[I] = set difficulty level 1/2/3/4/5/6/7; currently %d', trainingDifficulty), 'center', (verticalLines - 3) * yGrid, hintColor);
DrawFormattedText(w, '[Z] = clear item; [Q]/[Esc] = quit', 'center', (verticalLines - 2) * yGrid, hintColor);


function word = convertCase(word, stimCase)

switch stimCase
  case 'upper'
    word = upper(word);
  case 'lower'
    word = lower(word);
end
