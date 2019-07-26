function RawDataBin_Rx = OFDM_RX_Pipeline(OFDM_RX_Air, AirFrameLen, MOD_ORDER, Code_Rate)
%   In real system, the AirFrameLen, MOD_ORDER, Code_Rate must be contained
%   in the Header
%   We have not implement Header 

%% Paras
global LONG_PREAMBLE_LEN N_CP N_SC TAIL_LEN
global DEBUG

%% FrameDetection;(to be added)


%% Time synchronization; the algorithm need to be optimized if CFO > 30 kHz
[~, PayloadIndex] = OFDM_TimeSync(OFDM_RX_Air);

FrameIndex = PayloadIndex - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP);
% PayloadIndex = 2 * (LONG_PREAMBLE_LEN + 2 * N_CP) + 1;

OFDM_RX = OFDM_RX_Air(FrameIndex: FrameIndex + AirFrameLen - 1);

%% FrequencySync; the OFDM_RX and long preamble both need to be compensation
% [OFDM_RX, LongPreambleRX_t, ~, ~] = OFDM_FreqSync(OFDM_RX);
LongPreambleRX_t = OFDM_RX(2 * (N_CP + N_SC) + 2 * N_CP + 1: 4 * (N_CP + N_SC));

if DEBUG
    disp(['The frame start index: ' num2str(FrameIndex)])
    disp(['The payload start index: ' num2str(PayloadIndex)])
    
    figure;
    subplot(211); hold on; plot(abs(LongPreambleRX_t(1: N_SC)));
    subplot(211); plot(abs(LongPreambleRX_t(N_SC + 1: 2 * N_SC)));
    subplot(212); hold on; plot(abs(fft(LongPreambleRX_t(1: N_SC))));
    subplot(212); plot(abs(fft(LongPreambleRX_t(N_SC + 1: 2 * N_SC))));
    title('Long preamble after compensating CFO');
end

%% CSI estimation
CSI = OFDM_ChannelEstimation(LongPreambleRX_t);
% CSI = 8.8735 * [0; ones(26, 1); zeros(11, 1); ones(26, 1)];

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

%% Extract payload after CFO compensation
Payload_RX_t = OFDM_RX(PayloadIndex: PayloadIndex + AirFrameLen - 1 - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

%% Remove CP
Payload_RX_t = Add_CP(Payload_RX_t, false);

%% Chanel equalization
Payload_RX_f = OFDM_ChannelEqualization(Payload_RX_t, CSI);

%% Phase tracking with pilot(to be added)

%% Decoding
InterleavedDataBin_Rx = OFDM_Demodulation(Payload_RX_f, MOD_ORDER);

CodedDataBin_Rx = OFDM_Interleaver(InterleavedDataBin_Rx, log2(MOD_ORDER), false);

ScrambledDataBin_Rx = OFDM_ConvolutionalCoder(CodedDataBin_Rx, Code_Rate, false);

RawDataBin_Rx = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), ScrambledDataBin_Rx);

%% Remove tail and pad bits
% RawDataBin_Rx = RawDataBin_Rx(1: end - 6);
