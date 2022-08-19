%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Channel Estimation with zero forcing
% DLTFrx: column vector
% Ntxs: TX antennas
% Nrxs: RX antennas
% CSI: (FFT x Ntxs x Nrxs)
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
function CSI = OFDM_ChannelEstimator(RxDLTF, Ntxs, Nrxs)

global N_CP N_FFT N_TONE TONE_INDEX

CSI = zeros(N_FFT, Nrxs, Ntxs);

Nsym = Ntxs;

%% RX preambles
RxLongPreamble = zeros(N_FFT, Nrxs, Nsym);
for rx = 1: Nrxs
for iltf = 1: Ntxs
    RxLongPreamble(:, rx, iltf) = ...
        RxDLTF((iltf -1) * (N_CP + N_FFT) + N_CP +1: iltf * (N_CP + N_FFT), rx);
    RxLongPreamble(:, rx, iltf) = ...
        fftshift(sqrt(N_TONE) / N_FFT * fft(RxLongPreamble(:, rx, iltf), N_FFT, 1), 1);
end
end

%% TX preambles
TxLongPreamble = zeros(N_FFT, Ntxs, Nsym);
[~,  ~, TxDLTF] = OFDM_PreambleGenerator(Ntxs); 
TxDLTF = TxDLTF(1: (N_CP + N_FFT) * Nsym, :);  % Not all DLTFs are needed
for tx = 1: Ntxs
for iltf = 1: Nsym
    TxLongPreamble(:, tx, iltf) = ...
        TxDLTF((iltf -1) * (N_CP + N_FFT) + N_CP +1: iltf * (N_CP + N_FFT), tx);
    TxLongPreamble(:, tx, iltf) = ...
        fftshift(sqrt(N_TONE) / N_FFT * fft(TxLongPreamble(:, tx, iltf), N_FFT, 1), 1);
end
end

%% Channel estimation
for fft_index = TONE_INDEX
    CSI(fft_index, :, :) = reshape( ...
        reshape(RxLongPreamble(fft_index, :, :), Nrxs, Nsym) / ...
        reshape(TxLongPreamble(fft_index, :, :), Ntxs, Nsym), ...
        1, Nrxs, Ntxs);
end