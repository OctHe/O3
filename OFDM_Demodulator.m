%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Demodulation process
% Payload_t: (N_FFT * Nsym) x Ntxs matrix in time domain
% CSI: Estimated CSI
% RxAmbientData: Demodulated data for ambient source
% TrackPhase: Phase caused by CFO
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
function [RxAmbientData, TrackPhase] = OFDM_Demodulator(Payload_t, CSI)

global N_CP N_FFT N_DATA PILOT_INDEX
global TONE_INDEX DATA_INDEX
global PILOTS

Nsym = size(Payload_t, 1) / (N_CP + N_FFT);
Nrxs = size(CSI, 2);
Ntxs = size(CSI, 3);

%% Reshape
RxPayload = zeros(N_FFT, Nsym, Nrxs);
for irx = 1: Nrxs
for isym = 1: Nsym
    RxPayload(:, isym, irx) = ...
        Payload_t((isym -1) * (N_CP + N_FFT) + N_CP +1: isym * (N_CP + N_FFT), irx);
    RxPayload(:, isym, irx) = ...
        fftshift(1 / sqrt(N_FFT) * fft(RxPayload(:, isym, irx)));
end
end

%% Channel Equalization
EqualizedData = zeros(N_FFT, Nsym, Ntxs);
for fft_index = TONE_INDEX
for isym  = 1: Nsym
    EqualizedData(fft_index, isym, :) = reshape( ...
        reshape(CSI(fft_index, :, :), Nrxs, Ntxs) \ ...
        reshape(RxPayload(fft_index, isym, :), Nrxs, 1), ...
        1, 1, Ntxs);
end
end

%% Phase Tracking with Pilot
% Pilot is required for Rician channel
EqualizedPilot = EqualizedData(PILOT_INDEX, :, :);
TrackPhase = zeros(Nsym, Ntxs);
for itx = 1: Ntxs
for isym = 1: Nsym
    TrackPhase(isym, itx) = mean(angle(EqualizedPilot(:, isym, itx) ./ PILOTS{Ntxs}(:, itx)));
    EqualizedData(:, isym, itx) = EqualizedData(:, isym, itx) * exp(-1j * TrackPhase(isym, itx));
end
end

%% Reshape
RxAmbientData = zeros(N_DATA * Nsym, Ntxs);
for itx = 1: Ntxs
    RxAmbientData(:, itx) = reshape(EqualizedData(DATA_INDEX, :, itx), N_DATA * Nsym, 1);
end
