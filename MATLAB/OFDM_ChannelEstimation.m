function ChannelStateInfo = OFDM_ChannelEstimation(LongPreambleRX_t)
% vector,(LONG_PREAMBLE_LEN, 1); 
% CSI, (N_SC, 1)


global N_CP N_SC
GlobalVariables;

[~,  LongPreambleTX_t] = PreambleGenerator; 
LongPreambleTX_t = LongPreambleTX_t(2 * N_CP + N_SC + 1: end);

LongPreambleRX_t = reshape(LongPreambleRX_t, N_SC, 2);

LongPreambleTX_f = fft(LongPreambleTX_t, N_SC, 1);
LongPreambleRX_f = fft(LongPreambleRX_t, N_SC, 1);

ChannelStateInfo = LongPreambleTX_f .* (LongPreambleRX_f(:, 1) + LongPreambleRX_f(:, 2))/2;

ChannelStateInfo = LongPreambleTX_f .* (LongPreambleRX_f(:, 2));

