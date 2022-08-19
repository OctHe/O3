%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Demodulation process
% Payload_t: (N_FFT * Nsym) x Ntxs matrix in time domain
% D_CSI: Estimated CSI
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
function [RxAmbientData, EqualizedTagData] = HDMIMO_Demodulator(Payload_t, D_CSI, R_CSI)

global PILOTS
global N_CP N_FFT N_DATA 
global TONE_INDEX DATA_INDEX PILOT_INDEX

Nsym = size(Payload_t, 1) / (N_CP + N_FFT);
Nrxs = size(R_CSI, 2);
Ntxs = size(R_CSI, 3);
Ntags = size(R_CSI, 4);

ED_CSI = zeros(N_FFT, Nrxs, Ntxs + Ntags);
ED_CSI(:, :, 1: Ntxs) = D_CSI;
ED_CSI(:, :, Ntxs +1: end) = reshape(R_CSI(:, :, 1, :), N_FFT, Nrxs, Ntags);

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

%% Channel Equalization for Ambient Signals
EqualizedAmbientData = zeros(N_FFT, Nsym, Ntxs + Ntags);
for fft_index = TONE_INDEX
for isym  = 1: Nsym
    EqualizedAmbientData(fft_index, isym, :) = reshape( ...
        reshape(ED_CSI(fft_index, :, :), Nrxs, Ntxs + Ntags) \ ...
        reshape(RxPayload(fft_index, isym, :), Nrxs, 1), ...
        1, 1, Ntxs + Ntags);
end
end


%% Channel Equalization for Backscatter Signals
EqualizedTagData = zeros(N_FFT, Nsym, Ntags);
for fft_index = TONE_INDEX
for isym = 1: Nsym
    Hybrid_CSI = zeros(Nrxs, Ntags);
    for itag = 1: Ntags
        Hybrid_CSI(:, itag) = reshape(R_CSI(fft_index, :, :, itag), Nrxs, Ntxs) * ...
            reshape(EqualizedAmbientData(fft_index, isym, 1: Ntxs), Ntxs, 1);
    end
    
    EqualizedTagData(fft_index, isym, :) = reshape( ...
        Hybrid_CSI \ ...
        (reshape(RxPayload(fft_index, isym, :), Nrxs, 1) - ...
        reshape(D_CSI(fft_index, :, :), Nrxs, Ntxs) * ...
        reshape(EqualizedAmbientData(fft_index, isym, 1: Ntxs), Ntxs, 1)), ...
        1, 1, Ntags);
end
end

%% Phase Tracking with Pilot
% Pilot is required for Rician channel
EqualizedPilot = EqualizedAmbientData(PILOT_INDEX, :, :);
TrackPhase = zeros(Nsym, Ntxs);
for itx = 1: Ntxs
for isym = 1: Nsym
    TrackPhase(isym, itx) = mean(angle(EqualizedPilot(:, isym, itx) ./ PILOTS{Ntxs}(:, itx)));
    EqualizedAmbientData(:, isym, itx) = EqualizedAmbientData(:, isym, itx) * exp(-1j * TrackPhase(isym, itx));
end
end

RxAmbientData = zeros(N_DATA * Nsym, Ntxs);
for itx = 1: Ntxs
    RxAmbientData(:, itx) = reshape(EqualizedAmbientData(DATA_INDEX, :, itx), N_DATA * Nsym, 1);
end