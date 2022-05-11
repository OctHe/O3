%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Channel Estimation with zero forcing
% DLTFrx: column vector
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
function CSI = IEEE80211g_ChannelEstimator(LTF_rx)

global N_CP N_FFT GUARD_INDEX

[~,  LTF_tx] = IEEE80211g_PreambleGenerator; 
LTF_tx = LTF_tx(2 * N_CP + N_FFT + 1: end);

LTF_rx = reshape(LTF_rx, N_FFT, 2);

LTS_TX_f = fftshift(fft(LTF_rx, N_FFT, 1), 1);
LTS_RX_f = fftshift(fft(LTF_tx, N_FFT, 1), 1);

CSI = LTS_TX_f .* (LTS_RX_f(:, 1) + LTS_RX_f(:, 2))/2;

CSI(GUARD_INDEX) = zeros(size(GUARD_INDEX));