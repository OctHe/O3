%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OFDM modulation and demodulation
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
clear all;  % clear all for global variables
close all;

%% Variables
Ndata = 52;
Ntxs = 2;
MCS_Index = 8;
IEEE80211ac_GlobalVariables;

global MCS_TAB

%% Modulation and demodulation
Mod = MCS_TAB.mod(MCS_Index);

DataTX = randi(Mod, [Ndata, Ntxs]) -1;

ModDataTX = qammod(DataTX, Mod);
Payload_t = IEEE80211ac_Modulator(ModDataTX);
Payload_f = IEEE80211ac_Demodulator(Payload_t);
DataRX = qamdemod(Payload_f, Mod);

%% Error symbol
ErrorSym = DataRX - DataTX;