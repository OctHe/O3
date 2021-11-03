%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Modulation for BPSK/QPSK/QAM and OFDM
% Payload_RX_f: Matrix (N_SC, SymbolNum)
% MCS_Index: scalar
% RawDataRX_Bin: column vector
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
function RawDataRX_Bin = IEEE80211g_Demodulation(Payload_RX_f, MCS_Index)

%% Params
global SC_IND_DATA MCS_MAT

Mod = MCS_MAT(1, MCS_Index);

%% OFDM Demod
Demod_Data = Payload_RX_f(SC_IND_DATA, :);

Demod_Data = reshape(Demod_Data, [], 1);

%% BPSK, QPSK, 16QAM, 64QAM demod
switch Mod
    case 2
        RawDataRX = step(comm.BPSKDemodulator, Demod_Data);
    case 4
        RawDataRX = step(comm.QPSKDemodulator, Demod_Data);
    case 16
        RawDataRX = step(comm.RectangularQAMDemodulator, sqrt(10) * Demod_Data);
    case 64
        RawDataRX = step(comm.RectangularQAMDemodulator(64), sqrt(43) * Demod_Data);
    otherwise
        error('Invalid modulation!  Must be in [2, 4, 16, 64]\n');
end

RawDataRX_Bin = Dec2BinVector(RawDataRX, log2(Mod));