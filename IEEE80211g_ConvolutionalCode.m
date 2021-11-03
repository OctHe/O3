%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function integrates convolutional encode/decode with multiple rates
% Input: column vector, true or false; Output: column vector;
% 
% Copyright (C) 2021.11.03  Shiyue He (hsy1995313@gmail.com)
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
function [OutputData] = IEEE80211g_ConvolutionalCode(InputData, CodeRate, sign)

global CONV_TRELLIS

TRACEBACK = 4;     % The trace back is a parameter of the convolutional decoder

if sign == true
    
    switch CodeRate % OutputData is bit stolen data
        case 2 % CodeRate = 1/2
            handle_Conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS);
            OutputData = step(handle_Conv, InputData); % MiddleData is convolutional bits
            
        case 3 % CodeRate = 2/3; Punctured Coding
            handle_Conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS, 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0]);
            OutputData = step(handle_Conv, InputData); % MiddleData is convolutional bits
            
        case 4  % CodeRate = 3/4; Punctured Coding
            handle_Conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS, 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0; 0; 1]);
            OutputData = step(handle_Conv, InputData); % MiddleData is convolutional bits
            
        otherwise
            error('ERROR: CodeRate must be 2/3/4');
    end

else % if sign == false
    
    switch CodeRate     % MiddleData includes inserted dummy bits
        case 2 % CodeRate = 1/2
            OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)]; % OutputData is deconvolutional bits
            handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard');
            OutputData = step(handle_viterbi, OutputData);
            OutputData = OutputData(TRACEBACK + 1: end);
            
        case 3 % CodeRate = 2/3; Punctured Coding
            OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)]; % OutputData is deconvolutional bits
            handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard', 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0]);
            OutputData = step(handle_viterbi, OutputData);
            OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK);
            
        case 4  % CodeRate = 3/4; Punctured Coding
            OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)]; % OutputData is deconvolutional bits
            handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard', 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0; 0; 1]);
            OutputData = step(handle_viterbi, OutputData);
            OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK * 2);
            
        otherwise
            error('ERROR: CodeRate must be 2/3/4');
    end
    

end % end sign
