function [SyncResult, PayloadIndex] = OFDM_TimeSync(OFDM_Frame_RX)
% column vector
% column vector; long preamble w/o CP; scalar


global N_CP LONG_PREAMBLE_LEN
global DEBUG

[~,  LongPreambleTX] = PreambleGenerator; 
LongPreambleTX = LongPreambleTX(2*N_CP+1: end);

SyncSize = LONG_PREAMBLE_LEN; 
SyncResult = zeros(size(OFDM_Frame_RX));
for index = SyncSize : size(OFDM_Frame_RX, 1)
    SyncResult(index, :) = LongPreambleTX' * OFDM_Frame_RX(index - SyncSize + 1: index, :);
end
SyncResult = SyncResult ./ (LongPreambleTX' * LongPreambleTX);    % Normalized to one
[~, PayloadIndex] = max(abs(SyncResult)); 

PayloadIndex = PayloadIndex + 1;

if DEBUG
    figure;
    plot(abs(SyncResult));
    title('correlation result');
end
% lPreambleRX = OFDM_Frame_RX(PayloadIndex - LONG_PREAMBLE_LEN + 1: PayloadIndex, :); 

