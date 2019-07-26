function [OFDM_TX_Air, AirFrameLen] = OFDM_TX_Pipeline(RawDataBin, MOD_ORDER, Code_Rate, TxSignalPower)
%   In real system, the AirFrameLen, MOD_ORDER, Code_Rate must be contained
%   in the Header

global TAIL_LEN SC_DATA_NUM

%% Add Tail bits (to be done)
% RawDataBin = [RawDataBin; zeros(TAIL_LEN, 1)];

%% Add pad bits (to be done)
% CodedBitsNums = length(RawDataBin);
% PadNums = mod(RawDataBin, SC_DATA_NUM);

%% Encoding
ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2,'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RawDataBin);

CodedDataBin = OFDM_ConvolutionalCoder(ScrambledDataBin, Code_Rate, true);

InterleavedDataBin = OFDM_Interleaver(CodedDataBin, log2(MOD_ORDER), true);

Payload_TX_t = OFDM_Modulation(InterleavedDataBin, MOD_ORDER);

Payload_TX_t = Add_CP(Payload_TX_t, true);
[STF, LTF] = PreambleGenerator;


OFDM_TX = [STF; LTF; Payload_TX_t];

% Amplify the power
OFDM_TX_Air = PowerAmplifier(OFDM_TX, TxSignalPower);
AirFrameLen = length(OFDM_TX_Air);