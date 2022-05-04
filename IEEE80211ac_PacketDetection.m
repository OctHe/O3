%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% coarse time synchronization with auto-correlation
% rx_frame: RX Frame (column vector)
% threshold: Threshold for auto-correlation result (column vector)
% M: auto-correlation results of RX_frame (column vector) 
% pkt_index: estimated packet index, it must be before LTF
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
function [M, pkt_index] = IEEE80211ac_PacketDetection(rx_frame, threshold)

global N_CP

Nsamp = size(rx_frame, 1);
index_vec = 1: Nsamp;

%% Auto correlation
% Tzi-Dar Chiueh, Pei-Yun Tsai. OFDM Baseband Receiver Design for Wireless
% Communications.
% Algorithm: M = C / P

M = zeros(size(rx_frame));
rx = rx_frame(1: end - N_CP);
delayed_rx = rx_frame(N_CP +1: end);

C = zeros(Nsamp, 1);
P = zeros(Nsamp, 1);
for isamp = 1 : Nsamp - 2 * N_CP
    C(isamp) = rx(isamp: isamp + N_CP -1)' * delayed_rx(isamp: isamp + N_CP -1);
    P(isamp) = ...
        (rx(isamp: isamp + N_CP -1)' * rx(isamp: isamp + N_CP -1) + ...
        delayed_rx(isamp: isamp + N_CP -1)' * delayed_rx(isamp: isamp + N_CP -1)) / 2;
end

M = abs(C).^2 ./ P.^2;

M = sum(M, 2);

%% Packet detection
detect_index = M > threshold;
if sum(detect_index) >= 1.5 * N_CP
    pkt_index_vec = index_vec(detect_index);
    pkt_index = pkt_index_vec(1);
end
