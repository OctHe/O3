%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% BFi Encoder
% In BFi (BLE) transmitter, one BFi bit is related to four BLE symbols,
% which is equal to the Wi-Fi symbol duration.
% Symbol 1: 1010; Symbol 0: 0000
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
function EncodedBits = BFi_Encoder(UncodedBits)

Nbits = size(UncodedBits, 1);
CodeRate = 4;
CodeWord{1} = [0; 0; 0; 0];
CodeWord{2} = [1; 0; 1; 0];

EncodedBits = zeros(Nbits * CodeRate, 1);
for ib = 1: Nbits
    EncodedBits((ib -1) * CodeRate +1: ib * CodeRate) = CodeWord{UncodedBits(ib) +1};
end