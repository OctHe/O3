%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OFDM modulation and demodulation
%
% Copyright (C) 2022-2023  Shiyue He (hsy1995313@gmail.com)
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
clear;
close all;

%% Variables
Ndata = 52;
Ntxs = 1;

global MCS_TAB DATA_INDEX PILOT_INDEX N_PILOT N_FFT N_DATA N_CP

%% Modulation and demodulation
for MCS_Index = 1: 8
    Mod = MCS_TAB.mod(MCS_Index);
    CSI = zeros(N_FFT, 1);
    CSI(DATA_INDEX) = ones(N_DATA, 1);
    CSI(PILOT_INDEX) = ones(N_PILOT, 1);

    TxData = randi(Mod, [Ndata, Ntxs]) -1;

    if Mod == 2
        TxModData = pskmod(TxData, Mod).';
    else
        TxModData = qammod(TxData, Mod);
    end
    Payload_t = OFDM_Modulator(TxModData);
    Payload_f_a = fftshift(fft(Payload_t(N_CP +1: end)) / sqrt(N_FFT), 1);
    Payload_f_a = Payload_f_a(DATA_INDEX, :);
    Payload_f = OFDM_Demodulator(Payload_t, CSI);
    if Mod == 2
        RxData = pskdemod(Payload_f, Mod);
    else
        RxData = qamdemod(Payload_f, Mod);
    end

    %% Error symbol
    SE = sum(RxData ~= TxData);

    disp(['Symbol Errors:' num2str(SE) ' (MCS == ' num2str(MCS_Index) ')']);
end
