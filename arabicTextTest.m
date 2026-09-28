function arabicTextTest(fontName)
% Quick check that Arabic stimuli render correctly with Psychtoolbox.
% Shows three word pairs two ways; press any key to exit.
%   top    = pre-shaped (arabicPreShaped = 1, the default)
%   bottom = raw        (arabicPreShaped = 0)
% Whichever looks like normal, connected, right-to-left Arabic is the one to use.
% Optional argument: font name to try (default is the same as AdaptiveLanguageMapping).

if nargin < 1
  switch(computer)
    case 'PCWIN64'
      fontName = 'Arial';
    case 'MACI64'
      fontName = 'Geeza Pro';
    otherwise
      fontName = 'DejaVu Sans';
  end
end

oldWd = cd(fileparts(which(mfilename)));
c1 = onCleanup(@()cd(oldWd));

fid = fopen('paradigms/matches_arabic.txt', 'r', 'native', 'UTF-8');
c = textscan(fid, '%s%s%s%s%f%f%f', 'HeaderLines', 1, 'Whitespace', '\t');
fclose(fid);
fprintf('Loaded %d Arabic match pairs.\n', length(c{1}));

Screen('Preference', 'SkipSyncTests', 1);
w = Screen('OpenWindow', max(Screen('Screens')), [0 0 0]);
c2 = onCleanup(@()sca);
[xDim, yDim] = Screen('WindowSize', w);

Screen('TextFont', w, fontName);
Screen('TextSize', w, round(yDim / 30));
DrawFormattedText(w, sprintf('Font: %s  (actual: %s)', fontName, Screen('TextFont', w)), 'center', round(yDim * 0.05), [128 128 128]);
DrawFormattedText(w, 'Pre-shaped (arabicPreShaped = 1)', 'center', round(yDim * 0.12), [128 128 128]);
DrawFormattedText(w, 'Raw (arabicPreShaped = 0)', 'center', round(yDim * 0.57), [128 128 128]);

items = [1 200 500];
Screen('TextSize', w, round(yDim / 14));
for i = 1:3
  x = round(xDim * (4 - i) / 4); % right to left, as Arabic is read
  for row = 1:2
    if row == 1
      cols = [3 4];
      y0 = 0.25;
    else
      cols = [1 2];
      y0 = 0.70;
    end
    for k = 1:2
      str = double(c{cols(k)}{items(i)});
      bounds = Screen('TextBounds', w, str);
      Screen('DrawText', w, str, x - round(bounds(3) / 2), round(yDim * (y0 + 0.12 * (k - 1))), [255 255 255]);
    end
  end
end
Screen('Flip', w);
KbStrokeWait;
