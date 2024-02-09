%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Coarse time synchronization with auto-correlation
% Tzi-Dar Chiueh, Pei-Yun Tsai. OFDM Baseband Receiver Design for Wireless Communication.
% Algorithm: M = C / P
%
% rx_frame: RX Frame (column vector)
% threshold: Threshold for auto-correlation result (scale)
% M: auto-correlation results of RX_frame (column vector) 
% pkt_index: estimated packet index, it must be before LTF
%
% Copyright (C) 2022-2024 OctHe 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [M, pkt_index] = PacketDetection(rx_frame, threshold)

global N_CP

Nsamp = size(rx_frame, 1);
index_vec = 1: Nsamp;

M = zeros(size(rx_frame));
Nrxs = size(rx_frame, 2);

for irx = 1: Nrxs
    
    rx = rx_frame(1: end - N_CP, irx);
    delayed_rx = rx_frame(N_CP +1: end, irx);

    C = zeros(Nsamp, 1);
    P = ones(Nsamp, 1);
    for isamp = 1 : Nsamp - 2 * N_CP
        C(isamp) = rx(isamp: isamp + N_CP -1)' * delayed_rx(isamp: isamp + N_CP -1);
        P(isamp) = ...
            (rx(isamp: isamp + N_CP -1)' * rx(isamp: isamp + N_CP -1) + ...
            delayed_rx(isamp: isamp + N_CP -1)' * delayed_rx(isamp: isamp + N_CP -1)) / 2;
    end

    M(:, irx) = abs(C).^2 ./ P.^2;
end

% Packet detection
pkt_index = zeros(1, Nrxs);
detect_index = M > threshold;
for irx = 1: Nrxs
    if sum(detect_index(:, irx)) >= 1.5 * N_CP
        pkt_index_vec = index_vec(detect_index(:, irx));
        pkt_index(irx) = pkt_index_vec(1);
    else
        pkt_index(irx) = -1;
    end
end
