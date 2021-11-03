%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function integrates interleaver/deinterleaver with multiple rates
% Input: InputData: column vector; 
%       Nbpsc: number of coded bits per subcarrier;
%       sign = true means add cp, sign = false means remove cp;
% Output: column vector with cp;
% 
% Copyright (C) 2021.11.2  Shiyue He (hsy1995313@gmail.com)
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
function OutputData = IEEE80211g_Interleaver(InputData, Nbpsc, sign)

global SC_DATA_NUM

%% First step
Ncbps = SC_DATA_NUM * Nbpsc;
SymbolNum = length(InputData) / Ncbps;
InputData = reshape(InputData, Ncbps, SymbolNum);

OutputData = zeros(size(InputData));

%% Second step
InputIndex = (0: Ncbps - 1).';
s = max(Nbpsc / 2, 1);

if sign == true
    MiddleIndex = floor(Ncbps / 16) * mod(InputIndex, 16) + floor(InputIndex / 16);
    OutputIndex = s * floor(MiddleIndex / s) + mod(MiddleIndex + Ncbps - floor(16 * MiddleIndex / Ncbps), s);
elseif sign == false
    MiddleIndex = s * floor(InputIndex / s) + mod(InputIndex + floor(16 * InputIndex / Ncbps), s);
    OutputIndex = 16 * MiddleIndex - (Ncbps - 1) * floor(16 * MiddleIndex / Ncbps);
else
    error('ERROR: sign must be true or false!');
end
for index = 1: Ncbps
    OutputData(OutputIndex(index) + 1, :) = InputData(InputIndex(index) + 1, :);
end
OutputData = reshape(OutputData, [], 1);