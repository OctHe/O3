%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Channel equalization for IEEE 802.11a/g
% Payload_RX_f: matrix
% CSI: column vector
% PhaseOffset: matrix
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
function [Payload_RX_f, PhaseOffset] = IEEE80211g_ChannelEqualizer(Payload_RX_t, CSI)

global N_SC TONES_INDEX GUARD_SC_INDEX SC_IND_PILOTS
global PILOTS

SymbolNum = size(Payload_RX_t, 2);
PhaseOffset = zeros(4, SymbolNum);

Payload_RX_f = fft(Payload_RX_t, N_SC, 1);
Payload_RX_f(TONES_INDEX, :) = Payload_RX_f(TONES_INDEX, :) ./ ...
                                repmat(CSI(TONES_INDEX), 1, SymbolNum);
Payload_RX_f(GUARD_SC_INDEX, :) = zeros(length(GUARD_SC_INDEX), SymbolNum);

for sym_ind = 1: SymbolNum
    PhaseOffset(:, sym_ind) = Payload_RX_f(SC_IND_PILOTS, sym_ind) .* PILOTS;
    phase = mean(angle(Payload_RX_f(SC_IND_PILOTS, sym_ind) .* PILOTS));
    Payload_RX_f(TONES_INDEX, sym_ind) = ...
        Payload_RX_f(TONES_INDEX, sym_ind) * exp(-1j * phase);
    
end