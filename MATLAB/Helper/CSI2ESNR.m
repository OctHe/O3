function [ESNR, SNR_dB, CSI_dB] = CSI2ESNR(CSI_linear, NoisePower)
% CSI: mW, N_SC * Nums; NoisePower, mW, scalar
% ESNR 4 * Nums

GlobalVariables;
global N_SC
global TONES_INDEX
global DEBUG

CSINums = size(CSI_linear, 2);

CSI_dB = zeros(size(CSI_linear));
CSI_dB(TONES_INDEX, :) = 10 * log10(abs(CSI_linear(TONES_INDEX, :)) .^ 2 / NoisePower);

SNR_dB = mean(CSI_dB(TONES_INDEX, :), 1);

% CSI_dB must > 0 before input the Q function
for SubIndex = 1: N_SC
    FindIndex = find(CSI_dB(SubIndex, :) < 0);
    CSI_dB(SubIndex, FindIndex) = zeros([1, length( FindIndex )]);
end

SubBER = zeros(size(CSI_dB));
ESNR = zeros(CSINums, 4);

% BPSK
SubBER = qfunc(sqrt(2 * CSI_dB(TONES_INDEX, :)));
ESNR(1: CSINums, 1) = qfuncinv(mean(SubBER, 1)).^2 / 2;

% QPSK
SubBER = qfunc(sqrt( CSI_dB(TONES_INDEX, :) ));
ESNR(1: CSINums, 2) = qfuncinv(mean(SubBER, 1)).^2;

% 16QAM
SubBER = (3/4) * qfunc(sqrt(CSI_dB(TONES_INDEX, :) / 5));
ESNR(1: CSINums, 3) = qfuncinv(mean(SubBER, 1) * 4 / 3).^2 * 5;

% 64QAM
SubBER = (7/12) * qfunc(sqrt(CSI_dB(TONES_INDEX, :) / 21));
ESNR(1: CSINums, 4) = qfuncinv(mean(SubBER, 1) * 12 / 7).^2 * 21;  


