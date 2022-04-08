%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Demodulation process
% Payload_t: (N_FFT * Nsym) x Ntxs matrix in time domain
% CSI: Estimated CSI
% ModDataRX: Demodulated data (column vector)
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
function ModDataRX = IEEE80211ac_Demodulator(Payload_t, CSI)

global N_CP N_FFT N_DATA N_PILOT PILOT_INDEX
global SC_INDEX DATA_INDEX

Nsym = size(Payload_t, 1) / (N_CP + N_FFT);
Ntxs = size(CSI, 2);
Nrxs = size(CSI, 3);

PayloadRX = zeros(N_FFT, Nrxs, Nsym);
EqualizedData = zeros(N_FFT, Ntxs, Nsym);

%% OFDM demodulator
for irx = 1: Nrxs
for isym = 1: Nsym
    PayloadRX(:, irx, isym) = ...
        Payload_t((isym -1) * (N_CP + N_FFT) + N_CP +1: isym * (N_CP + N_FFT), irx);
    PayloadRX(:, irx, isym) = ...
        fftshift(1 / sqrt(N_FFT) * fft(PayloadRX(:, irx, isym)));
end
end

% Channel equalization
for fft_index = SC_INDEX
for isym  = 1: Nsym
    EqualizedData(fft_index, :, isym) = reshape( ...
        reshape(CSI(fft_index, :, :), Ntxs, Nrxs) \ ...
        reshape(PayloadRX(fft_index, :, isym), Nrxs, 1), ...
        1, 1, Ntxs);
end
end

%% Pilot


%% Reshape
PilotRX = zeros(N_PILOT * Nsym, Ntxs);
ModDataRX = zeros(N_DATA * Nsym, Ntxs);
for itx = 1: Ntxs
    PilotRX(:, itx) = reshape(EqualizedData(PILOT_INDEX, itx, :), N_PILOT * Nsym, 1);
    ModDataRX(:, itx) = reshape(EqualizedData(DATA_INDEX, itx, :), N_DATA * Nsym, 1);
end
