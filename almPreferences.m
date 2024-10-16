% Adaptive Language Mapping preferences

% keys that will trigger paradigms to begin
% specify either a list of trigger keys, or a device name followed by a
% single trigger key, e.g. triggerKeys = {'AT Translated Set 2 keyboard', 'x'};
% device names can be obtained by calling GetKeyboardIndices
 triggerKeys = {'T','t'};

% seconds to pause after trigger during which dummy volumes are acquired
% for systems which send a trigger prior to the acquisition of dummy volumes
% initialDelay = 0;

% keys that count as a "match" response
inScanner = input('Inside the scanner (1 = yes, 0 = no)? ');
if inScanner
	matchKeys = {'a', 'A', 'b', 'B', 'c', 'C', 'd', 'D'};
else
    matchKeys = {'h', 'H', 'j', 'J', 'k', 'K', 'l', 'L'};
end
clearvars inScanner

% note that you may need to list, e.g. '1' and/or '1!', etc., depending on whether
% the key is on a numeric keypad or keyboard; also, the special value 'MOUSE' can be
% used to indicate a mouse click

% sync tests may need to be skipped if Psychtoolbox cannot launch due to timing inaccuracies
skipSyncTests = 0;

% proportional and monospaced fonts should look similar
% all symbols used should display properly in the monospaced font
% switch(computer)
%   case 'GLNXA64'
%     propFont = 'DejaVu Sans';
%     monoFont = 'DejaVu Sans Mono';
%   case 'PCWIN64'
%     propFont = 'Lucida Sans Unicode';
%     monoFont = 'Consolas';
%   case 'MACI64'
%     propFont = 'Lucida Grande';
%     monoFont = 'Menlo';
%   otherwise
%     error('Unrecognized type of computer.');
% end

% font sizes are measured approximately in terms of line height on the menu screen
% standardFontSize = 0.75;
% messageFontSize = 1.5;
% stimulusFontSize = 3;
% stimCase = 'lower';
% yLoc = 1;

% provide hint text at the bottom of the screen?
% hintText = 1;

% override audio regLatencyClass if needed
% overrideRegLatencyClass = [];

% activeParadigms = [1:4 13:16 23:24 28:30 31:34 35:41 42 43];
