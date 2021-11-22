%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Channel Estimation with zero forcing
% LongPreambleRX_t: column vector
% CSI: column vector
%
% Copyright (C) 2021.11.18  Shiyue He (hsy1995313@gmail.com)
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
function CSI = OFDM_ChannelEstimator(LongPreambleRX_t)

global N_CP N_SC GUARD_SC_INDEX

[~,  LongPreambleTX_t] = IEEE80211g_PreambleGenerator; 
LongPreambleTX_t = LongPreambleTX_t(2 * N_CP + N_SC + 1: end);

LongPreambleRX_t = reshape(LongPreambleRX_t, N_SC, 2);

LongPreambleTX_f = fft(LongPreambleTX_t, N_SC, 1);
LongPreambleRX_f = fft(LongPreambleRX_t, N_SC, 1);

CSI = LongPreambleTX_f .* (LongPreambleRX_f(:, 1) + LongPreambleRX_f(:, 2))/2;
CSI(GUARD_SC_INDEX) = zeros(size(GUARD_SC_INDEX));