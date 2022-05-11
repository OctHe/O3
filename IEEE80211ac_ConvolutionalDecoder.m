%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function integrates convolutional encoder
% InputData: Column vector of encoded bits
% CodeRate: scalar, 2 -> code rate of 1/2, 3 -> 2/3, 4 -> 3/4, 6 -> 5/6 
% OutputData: Column vector of decoded bits;
% 
% Copyright (C) 2022  Shiyue He (hsy1995313@gmail.com)
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [OutputData] = IEEE80211ac_ConvolutionalDecoder(InputData, CodeRate)

global CONV_TRELLIS

TRACEBACK = 4;     % The trace back is a parameter of the convolutional decoder

OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)];

switch CodeRate     % MiddleData includes inserted dummy bits
    case 2 % CodeRate = 1/2
        
        decoder = comm.ViterbiDecoder( ...
            'TrellisStructure', CONV_TRELLIS, ...
            'TracebackDepth', TRACEBACK, ...
            'InputFormat', 'Hard' ...
            );
        OutputData = decoder(OutputData);
        OutputData = OutputData(TRACEBACK + 1: end);

    case 3 % CodeRate = 2/3; Punctured Coding

        decoder = comm.ViterbiDecoder( ...
            'TrellisStructure', CONV_TRELLIS, ...
            'TracebackDepth', TRACEBACK, ...
            'InputFormat', 'Hard', ...
            'PuncturePatternSource', 'Property', ...
            'PuncturePattern', [1; 1; 1; 0] ...
            );
        OutputData = decoder(OutputData);
        OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK);

    case 4  % CodeRate = 3/4; Punctured Coding
        decoder = comm.ViterbiDecoder( ...
            'TrellisStructure', CONV_TRELLIS, ...
            'TracebackDepth', TRACEBACK, ...
            'InputFormat', 'Hard', ...
            'PuncturePatternSource', 'Property', ...
            'PuncturePattern', [1; 1; 1; 0; 0; 1] ...
            );
        OutputData = decoder(OutputData);
        OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK *2);

    case 6  % CodeRate = 5/6; Punctured Coding
        decoder = comm.ViterbiDecoder( ...
            'TrellisStructure', CONV_TRELLIS, ...
            'TracebackDepth', TRACEBACK, ...
            'InputFormat', 'Hard', ...
            'PuncturePatternSource', 'Property', ...
            'PuncturePattern', [1; 1; 1; 0; 0; 1; 1; 0; 0; 1] ...
            );
        OutputData = decoder(OutputData);
        OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK *4);
    otherwise
        error('ERROR: CodeRate must be 2/3/4/6');
end

