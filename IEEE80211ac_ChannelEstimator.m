%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Channel Estimation with zero forcing
% DLTFrx: column vector
% Ntxs: TX antennas
% Nrxs: RX antennas
% CSI: column vector
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
function CSI = IEEE80211ac_ChannelEstimator(DLTFrx, Ntxs, Nrxs)

global N_CP N_FFT N_SC SC_INDEX

CSI = zeros(N_FFT, Ntxs, Nrxs);

%% RX preambles
LongPreambleRX = zeros(N_FFT, Nrxs, Nrxs);
for rx = 1: Nrxs
for iltf = 1: Nrxs
    LongPreambleRX(:, rx, iltf) = ...
        DLTFrx((iltf -1) * (N_CP + N_FFT) + N_CP +1: iltf * (N_CP + N_FFT), rx);
    LongPreambleRX(:, rx, iltf) = ...
        fftshift(sqrt(N_SC) / N_FFT * fft(LongPreambleRX(:, rx, iltf), N_FFT, 1), 1);
end
end

%% TX preambles
LongPreambleTX = zeros(N_FFT, Ntxs, Ntxs);
[~,  ~, DLTFtx] = IEEE80211ac_PreambleGenerator(Ntxs); 
DLTFtx = DLTFtx(1: (N_CP + N_FFT) * Ntxs, :);  % Not all DLTFs are needed
for tx = 1: Ntxs
for iltf = 1: Ntxs
    LongPreambleTX(:, tx, iltf) = ...
        DLTFtx((iltf -1) * (N_CP + N_FFT) + N_CP +1: iltf * (N_CP + N_FFT), tx);
    LongPreambleTX(:, tx, iltf) = ...
        fftshift(sqrt(N_SC) / N_FFT * fft(LongPreambleTX(:, tx, iltf), N_FFT, 1), 1);
end
end

%% Channel estimation
for fft_index = SC_INDEX
    CSI(fft_index, :, :) = reshape( ...
        reshape(LongPreambleRX(fft_index, :, :), Nrxs, Nrxs) / ...
        reshape(LongPreambleTX(fft_index, :, :), Ntxs, Ntxs), ...
        1, Ntxs, Nrxs);
end