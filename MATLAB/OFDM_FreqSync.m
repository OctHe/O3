function [OFDM_RX, LongPreambleRX_t, CoarseFrequencyOffset, FineFrequencyOffset] = OFDM_FreqSync(OFDM_RX)
% Inputs: vector
% Outputs: vector; scalar

global N_SC N_CP STF_LEN
global DEBUG

% GlobalVariables;

Ts = 0.05e-6; % sample interval(s); 0.05us = 0.05e-6s = 50ns = 50e-9s
N_STF_SYMBOL = 16; % the OFDM symbol in short preamble length

RX_Len = length(OFDM_RX);

%% Coarse frequency sync
% Estimation
ShortPreambleTX_t = OFDM_RX(1: 2 * (N_CP + N_SC));
ShortPreambleTX_t_reshape = reshape(ShortPreambleTX_t, N_STF_SYMBOL, 10);   % 10 short symbols
CoarsePhaseOffset = mean(diag(angle(ShortPreambleTX_t_reshape(:, 1: 9)' * ShortPreambleTX_t_reshape(:, 2: 10))));
CoarseFrequencyOffset = - 1 / (2 * pi * N_STF_SYMBOL * Ts) * CoarsePhaseOffset;

% Compensation
OFDM_RX = OFDM_RX .* exp(1j * - CoarsePhaseOffset / N_STF_SYMBOL * ((0: (RX_Len -1)).'));

%% Fine frequency sync
% Estimation
LongPreambleRX_t = OFDM_RX(2 * (N_CP + N_SC) + 2 * N_CP + 1: 4 * (N_CP + N_SC));
FinePhaseOffset = angle(LongPreambleRX_t(1: N_SC)' * LongPreambleRX_t(N_SC+1: 2*N_SC));
FineFrequencyOffset = - 1 / (2 * pi * N_SC * Ts) * FinePhaseOffset;

% Compensation
OFDM_RX = OFDM_RX .* exp(1j * - FinePhaseOffset / N_SC * ((0: (RX_Len -1)).'));

%% The preamble after compensation
LongPreambleRX_t = OFDM_RX(STF_LEN + 2 * N_CP + 1: STF_LEN + 2 * (N_CP + N_SC));

if DEBUG
    disp(['Coarse frequency offset: ' num2str(CoarseFrequencyOffset / 1e3) ' kHz'])
    disp(['Fine frequency offset: ' num2str(FineFrequencyOffset / 1e3) ' kHz'])
end