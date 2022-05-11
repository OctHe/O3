%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function integrates convolutional encoder
% InputData: Column vector of unencoded bits
% CodeRate: scalar, 2 -> code rate of 1/2, 3 -> 2/3, 4 -> 3/4, 6 -> 5/6 
% OutputData: Column vector of encoded bits;
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
function [OutputData] = IEEE80211ac_ConvolutionalEncoder(InputData, CodeRate)

global CONV_TRELLIS
    
switch CodeRate
    case 2 % CodeRate = 1/2
        encoder = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS);

    case 3 % CodeRate = 2/3; Punctured Coding
        encoder = comm.ConvolutionalEncoder( ...
            'TrellisStructure',  CONV_TRELLIS, ...
            'PuncturePatternSource', 'Property', ...
            'PuncturePattern', [1; 1; 1; 0] ...
            );

    case 4  % CodeRate = 3/4; Punctured Coding
        encoder = comm.ConvolutionalEncoder(...
            'TrellisStructure',  CONV_TRELLIS, ...
            'PuncturePatternSource', 'Property', ...
            'PuncturePattern', [1; 1; 1; 0; 0; 1] ...
            );
        
    case 6 % CodeRate = 5/6; Punctured Coding
        encoder = comm.ConvolutionalEncoder(...
            'TrellisStructure',  CONV_TRELLIS, ...
            'PuncturePatternSource', 'Property', ...
            'PuncturePattern', [1; 1; 1; 0; 0; 1; 1; 0; 0; 1] ...
            );
    otherwise
        error('ERROR: CodeRate must be 2/3/4/6');
end

OutputData = encoder(InputData);