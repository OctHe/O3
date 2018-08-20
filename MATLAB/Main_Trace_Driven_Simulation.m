clear; close all;

%% Global params
global LONG_PREAMBLE_LEN N_CP N_SC
global DEBUG
GlobalVariables;

%% Params
MOD_ORDER               = 64;           % Modulation order (2/4/16/64 = BSPK/QPSK/16-QAM/64-QAM)
DATA_NUM                = 48 * 6 * 5;       % the minimum data number is 48 * 6
Code_Rate               = 4;            % 2(1/2); 3(2/3); 4(3/4)
TxSignalPower           = 1e-4;         % signal power, (mW); 1mW = 0dBm
NoisePower              = 1e-8;         % noise power, (mW), 1e-11W = -80dBm, 1e-8mW = -80dBm
FineFrequencyOffset         = 15e3;         % unit is Hz

tic;

%% trace params
DEBUG = false;

MOD_ORDER_Map = [2, 2, 4, 4, 16, 16, 64, 64];
Code_Rate_Map = [2, 4, 2, 4, 2, 4, 3, 4];

%% Read CSI traces
% [Responses_linear, ~, SNRs_mW, TracesNums] = ReadTraces('Traces_mW.h5');

UBER = zeros(61, 1000);
CBER = zeros(61, 1000);

for freq_index = -30: 30

for trans_index = 1: 1000
FrequencyOffset = 25e3 * freq_index;      % unit is Hz

%% Transmitter pipeline
RawData = randi([0, MOD_ORDER - 1], DATA_NUM, 1); % randam raw datas
RawDataBin = Dec2BinVector(RawData, log2(MOD_ORDER));

ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2,'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RawDataBin);

CodedDataBin = OFDM_ConvolutionalCoder(ScrambledDataBin, Code_Rate, true);
% CodedDataBin = ones(size(CodedDataBin));
InterleavedDataBin = OFDM_Interleaver(CodedDataBin, log2(MOD_ORDER), true);

Payload_TX_t = OFDM_Modulation(InterleavedDataBin, MOD_ORDER);

Payload_TX_t = Add_CP(Payload_TX_t, true);
[STF, LTF] = PreambleGenerator;


OFDM_TX = [STF; LTF; Payload_TX_t];

% amplify power
OFDM_TX_Air = PowerAmplitude(OFDM_TX, TxSignalPower);
AirFrameLen = length(OFDM_TX_Air);
TxAirPower = sum(abs(OFDM_TX_Air).^2)/length(OFDM_TX_Air);

%% channel model
% pad zeros
PadZeros = 0;

Ts = 0.05e-6; % Ts = 1 / fs; sample rate = 20MHz

% Add frequency offset
OFDM_TX_Air = OFDM_TX_Air .* exp(1j * (- 2 * pi * Ts * FrequencyOffset) * ((0: (AirFrameLen -1)).'));

OFDM_RX_Air = [zeros(PadZeros, 1); OFDM_TX_Air; zeros(PadZeros, 1)];

% % the first method to add the channel response
% OFDM_RX_reshape = reshape(OFDM_RX_Air, N_CP + N_SC, []);
% for FrameIndex = 1: size(OFDM_RX_reshape, 2)
%     temp = [OFDM_RX_reshape(:, FrameIndex); OFDM_RX_reshape(:, FrameIndex)];
%     temp = conv(temp, Response);
%     temp = temp(N_CP + N_SC + 1: 2 * (N_CP + N_SC));
%     OFDM_RX_reshape(:, FrameIndex) = temp;
%     
% end
% OFDM_RX_Air = reshape(OFDM_RX_reshape, [], 1);

% % the second method to add the channel response
% OFDM_RX_Air = Add_CP(OFDM_RX_Air, false);
% OFDM_RX_reshape = reshape(OFDM_RX_Air, N_SC, []);
% for FrameIndex = 1: size(OFDM_RX_reshape, 2)
%     OFDM_RX_reshape(:, FrameIndex) = cconv(OFDM_RX_reshape(:, FrameIndex), Response, N_SC);
%     
% end
% OFDM_RX_Air = reshape(OFDM_RX_reshape, [], 1);
% OFDM_RX_Air = Add_CP(OFDM_RX_Air, true);

% calculate Rx power, unit is mW
RxPower = sum(abs(OFDM_RX_Air).^2)/length(OFDM_RX_Air);

% add the noise
% OFDM_RX_Air = awgn(OFDM_RX_Air, RxPower / NoisePower, 'measured', 'linear');

if DEBUG
    figure;
    plot(abs(OFDM_RX_Air));
    title('RX signal');
end

%% receiver pipeline
% FrameDetection;(to be added)


% time synchronization; the algorithm need to be optimized if CFO > 30 kHz
% in simulation
[~, PayloadIndex] = OFDM_TimeSync(OFDM_RX_Air);
PayloadIndex = 321; 

FrameIndex = PayloadIndex - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP);
PayloadIndex = 2 * (LONG_PREAMBLE_LEN + 2 * N_CP) + 1;

OFDM_RX = OFDM_RX_Air(FrameIndex: FrameIndex + AirFrameLen - 1);

% FrequencySync; the OFDM_RX and long preamble both need to be compensation
[OFDM_RX, LongPreambleRX_t, CoarseFrequencyOffset, FineFrequencyOffset] = OFDM_FreqSync(OFDM_RX);

if DEBUG
    figure;
    subplot(211); hold on; plot(abs(LongPreambleRX_t(1: N_SC)));
    subplot(211); plot(abs(LongPreambleRX_t(N_SC + 1: 2 * N_SC)));
    subplot(212); hold on; plot(abs(fft(LongPreambleRX_t(1: N_SC))));
    subplot(212); plot(abs(fft(LongPreambleRX_t(N_SC + 1: 2 * N_SC))));
    title('long preamble after compensating CFO');
end

% CSI estimation
CSI = OFDM_ChannelEstimation(LongPreambleRX_t);

if DEBUG
    figure;
    plot(abs(CSI));
    title('CSI estimation abs');
    figure;
    plot(angle(CSI));
    title('CSI estimation angle');
    figure;
    plot(abs(ifft(CSI)));
    title('response estimation');
end

% extract payload after CFO compensation
Payload_RX_t = OFDM_RX(PayloadIndex: PayloadIndex + AirFrameLen - 1 - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

% remove CP
Payload_RX_t = Add_CP(Payload_RX_t, false);

if DEBUG
    figure;
    plot(abs(fft(Payload_RX_t, N_SC, 1)));
    title('Payload Rx');
end

% chanel equalization
Payload_RX_f = OFDM_ChannelEqualization(Payload_RX_t, CSI);

if DEBUG 
    figure;
    plot(abs(Payload_RX_f));
    title('Rx Payload after equalization');
end

% phase tracking with pilot(to be added)

InterleavedDataBin_Rx = OFDM_Demodulation(Payload_RX_f, MOD_ORDER);

CodedDataBin_Rx = OFDM_Interleaver(InterleavedDataBin_Rx, log2(MOD_ORDER), false);

ScrambledDataBin_Rx = OFDM_ConvolutionalCoder(CodedDataBin_Rx, Code_Rate, false);

RawDataBin_Rx = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), ScrambledDataBin_Rx);

%% Transmission Result
ErrorOffset = 100;      % delete the last EorrorOffset numbers bits. 

BinDataNums = length(RawDataBin);
UncodedDataNums = length(InterleavedDataBin);
UncodedErrorBitsNums = sum(abs(CodedDataBin_Rx - CodedDataBin));
UncodedBER = UncodedErrorBitsNums / UncodedDataNums;
CodedErrorBitsNums = sum(abs(ScrambledDataBin_Rx(1: end - ErrorOffset) - ScrambledDataBin(1: end - ErrorOffset)));
CodedBER = CodedErrorBitsNums / (BinDataNums - ErrorOffset);

% disp(['The frame start index: ' num2str(FrameIndex)])
% disp(['The payload start index: ' num2str(PayloadIndex)])
disp(['Coarse frequency offset: ' num2str(CoarseFrequencyOffset / 1e3) ' kHz'])
disp(['Fine frequency offset: ' num2str(FineFrequencyOffset / 1e3) ' kHz'])
% disp(['transmit bits: ' num2str(BinDataNums)])
% disp(['BER without convoluational code: ' num2str(UncodedBER)])
% disp(['Error nums after covolutional decoder ' num2str(CodedErrorBitsNums)])
% disp(['BER after covolutional decoder ' num2str(CodedBER)])

%%
UBER(freq_index+31, trans_index) = UncodedBER;
CBER(freq_index+31, trans_index) = CodedBER;

if mod(trans_index, 100) == 0
    toc; % display transmission time
end

end % end trans index

end % end freq index

save UBER.txt -ascii UBER
save CBER.txt -ascii CBER

% save freqoffset.txt -ascii BER

