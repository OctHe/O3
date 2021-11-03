%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Modulation for BPSK/QPSK/QAM and OFDM
% BinData: column vector
% MCS_Index: scalar
% Payload_t: column vector
% Payload_f: column vector
% 
% Copyright (C) 2021.11.02  Shiyue He (hsy1995313@gmail.com)
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
function [Payload_t, Payload_f] = IEEE80211g_Modulation(BinData, MCS_Index)

%% Params
global SC_IND_PILOTS SC_IND_DATA N_SC PILOTS SC_DATA_NUM MCS_MAT

Mod = MCS_MAT(1, MCS_Index);

%% BPSK, QPSK, 16QAM, and 64QAM modulator
switch Mod
    case 2
        ModDataTX = step(comm.BPSKModulator, BinData);
    case 4
        ModDataTX = step(comm.QPSKModulator('BitInput', true), BinData);
    case 16
        ModDataTX = (1/sqrt(10)) * step(comm.RectangularQAMModulator('BitInput', true), BinData);
    case 64
        ModDataTX = (1/sqrt(43)) * step(comm.RectangularQAMModulator('ModulationOrder', 64, 'BitInput', true) , BinData);
    otherwise
        error('Invalid MOD_ORDER!  Must be in [2, 4, 16, 64]\n');
end

%% OFDM modulator
DataNum = length(BinData) / log2(Mod);
SymbolNum = DataNum / SC_DATA_NUM;

ModDataTX = reshape(ModDataTX, SC_DATA_NUM, SymbolNum);
Payload_f = zeros(N_SC, SymbolNum);

Payload_f(SC_IND_PILOTS, :) = repmat(PILOTS, 1, SymbolNum);
Payload_f(SC_IND_DATA, :) = ModDataTX;

Payload_t = ifft(Payload_f, N_SC, 1);
Payload_t = reshape(Payload_t, [], 1);