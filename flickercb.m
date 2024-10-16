% flickering checkerboard visual mapping paradigm
% 420 seconds
% alternating 14-second blocks of left visual field, right visual field, rest
% press any key to start
% press any key to stop
% modified from this script:
% https://peterscarfe.com/windowedradialcheckerboarddemo.html

% Clear the workspace
close all;
clearvars;
sca;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Skip sync tests for this demo
Screen('Preference', 'SkipSyncTests', 2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open an on screen window
% [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [0 0 1024 768]);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Screen resolution in X and Y
screenXpix = windowRect(3);
screenYpix = windowRect(4);

% crosshair
csize = 50;
Screen('DrawLine', window, [255 0 0], screenXpix / 2 - csize, screenYpix / 2, ...
  screenXpix / 2 + csize + 1, screenYpix / 2, 5);
Screen('DrawLine', window, [255 0 0], screenXpix / 2, screenYpix / 2 - csize, ...
  screenXpix / 2, screenYpix / 2 + csize + 1, 5);
Screen('Flip', window);

% Number of white/black circle pairs
rcycles = 8;

% Number of white/black angular segment pairs (integer)
tcycles = 24;

% Now we make our checkerboard pattern
xylim = 2 * pi * rcycles;
[x, y] = meshgrid(-xylim: 2 * xylim / (screenYpix - 1): xylim,...
    -xylim: 2 * xylim / (screenYpix - 1): xylim);
at = atan2(y, x);
checks = ((1 + sign(sin(at * tcycles) + eps)...
    .* sign(sin(sqrt(x.^2 + y.^2)))) / 2) * (white - black) + black;
circle = x.^2 + y.^2 <= xylim^2;
checks = circle .* checks + grey * ~circle;

% Now we make this into a PTB texture
radialCheckerboardTexture(1)  = Screen('MakeTexture', window, checks);
radialCheckerboardTexture(2)  = Screen('MakeTexture', window, 1 - checks);

% The rect in which we will define our arc
arcRect = CenterRectOnPointd([0 0 screenYpix screenYpix],...
    screenXpix / 2, screenYpix / 2);

% set up keyboard
clear PsychHID;
clear KbCheck;
KbName('UnifyKeyNames');

% start a queue for every device, keyboard and non-keyboard alike
keyboardIndices = GetKeyboardIndices;
gamepadIndices = GetGamepadIndices;
devInd = [keyboardIndices(:); gamepadIndices(:)];
nDevices = length(devInd);
for i = 1:nDevices
  KbQueueCreate(devInd(i));
  KbQueueStart(devInd(i));
end

% wait for trigger
gotKey = true;
while gotKey
  gotKey = false;
  for i = 1:nDevices
    if KbQueueCheck(devInd(i))
      gotKey = true;
    end
  end
end
gotKey = false;
while ~gotKey
  for i = 1:nDevices
    if KbQueueCheck(devInd(i))
      gotKey = true;
    end
  end
end
for i = 1:nDevices
  KbEventFlush(devInd(i));
end

% main loop
startTime = GetSecs;
q = false;
for b = 1:10
  for c = 1:3
    for f = 1:112
      % draw checkerboard
      Screen('DrawTexture', window, radialCheckerboardTexture(mod(f, 2) + 1));
      
      % mask out unwwanted region
      switch c
        case 1
          startAngle = 0;
          arcAngle = 180;
        case 2
          startAngle = 180;
          arcAngle = 180;
        case 3
          startAngle = 0;
          arcAngle = 360;
      end
      Screen('FillArc', window, grey, arcRect, startAngle, arcAngle)
      
      % draw crosshair
      csize = 50;
      Screen('DrawLine', window, [255 0 0], screenXpix / 2 - csize, screenYpix / 2, ...
        screenXpix / 2 + csize + 1, screenYpix / 2, 5);
      Screen('DrawLine', window, [255 0 0], screenXpix / 2, screenYpix / 2 - csize, ...
        screenXpix / 2, screenYpix / 2 + csize + 1, 5);
      
      % wait until it's time to display it
      while GetSecs < startTime + (b - 1) * 42 + (c - 1) * 14 + (f - 1) * 0.125
        for i = 1:nDevices
          [pressed, firstPress] = KbQueueCheck(devInd(i));
          if pressed
            k = KbName(find(firstPress, 1));
            if strcmp(k, 'q') || strcmp(k, 'ESCAPE')
              q = true;
              break
            end
          end
        end
      end
      if q, break, end
      vbl = Screen('Flip', window);
    end
    if q, break, end
  end
  if q, break, end
end

% clean up
sca;
for i = 1:nDevices
  KbQueueRelease(devInd(i));
end
close all;
clear all; %#ok<CLALL>
