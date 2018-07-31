clear; close all;

%% Global params
global LONG_PREAMBLE_LEN N_CP N_SC
global DEBUG
GlobalVariables;

%% Params
MOD_ORDER               = 64;           % Modulation order (2/4/16/64 = BSPK/QPSK/16-QAM/64-QAM)
DATA_NUM                = 48 * 6 * 5;       % the minimum data number
Code_Rate               = 4;            % 2(1/2); 3(2/3); 4(3/4)
TailNums = 48 * 3;
TxSignalPower           =  1;           % signal power, (mW)
NoisePower              = 1e-8;         % noise power, (mW), 1e-11W = -80dBm, 1e-8mW = -80dBm
tic;

%% trace params
DEBUG = false;

MOD_ORDER_Map = [2, 2, 4, 4, 16, 16, 64, 64];
Code_Rate_Map = [2, 4, 2, 4, 2, 4, 3, 4];

%% Read CSI traces
[Responses_linear, ~, SNRs_mW, TracesNums] = ReadTraces('Traces_mW.h5');
TracesNums

BER = -ones(TracesNums, 8);
UnBER = -ones(TracesNums, 8);
RxCSIs = zeros(N_SC, TracesNums);

for trans_index = 1: 18000
Response = Responses_linear(:, trans_index);
SNR_dB = 10 * log10(SNRs_mW(trans_index) / NoisePower);

for mod_index = 8: -1: 1
    MOD_ORDER = MOD_ORDER_Map(mod_index);
    Code_Rate = Code_Rate_Map(mod_index);
    
%% transmitter
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
AirFrameLen = length(OFDM_TX);

% amplify power
OFDM_TX_Air = PowerAmplitude(OFDM_TX, TxSignalPower);
TxAirPower = sum(abs(OFDM_TX_Air).^2)/length(OFDM_TX_Air);

%% channel model
% pad zeros
PadZeros = 80;
OFDM_RX = [zeros(PadZeros, 1); OFDM_TX_Air; zeros(PadZeros, 1)];

% % add the channel response
% OFDM_RX_reshape = reshape(OFDM_RX, N_CP + N_SC, []);
% for FrameIndex = 1: size(OFDM_RX_reshape, 2)
%     temp = [OFDM_RX_reshape(:, FrameIndex); OFDM_RX_reshape(:, FrameIndex)];
%     temp = conv(temp, Response);
%     temp = temp(N_CP + N_SC + 1: 2 * (N_CP + N_SC));
%     OFDM_RX_reshape(:, FrameIndex) = temp;
%     
% end
% OFDM_RX = reshape(OFDM_RX_reshape, [], 1);

% the third method to add the channel response
OFDM_RX = Add_CP(OFDM_RX, false);
OFDM_RX_reshape = reshape(OFDM_RX, N_SC, []);
for FrameIndex = 1: size(OFDM_RX_reshape, 2)
    OFDM_RX_reshape(:, FrameIndex) = cconv(OFDM_RX_reshape(:, FrameIndex), Response, N_SC);
    
end
OFDM_RX = reshape(OFDM_RX_reshape, [], 1);
OFDM_RX = Add_CP(OFDM_RX, true);

% % the second method to add channel. the response length must less than N_CP
% OFDM_RX = conv(OFDM_RX, Response);
% OFDM_RX = OFDM_RX(1: end - length(Response) + 1);

% calculate Rx power, unit is mW
RxPower = sum(abs(OFDM_RX).^2)/length(OFDM_RX);

% % add the noise
OFDM_RX = awgn(OFDM_RX, RxPower / NoisePower, 'measured', 'linear');
% OFDM_RX = awgn(OFDM_RX, SNR_dB, 'measured');

if DEBUG
    figure;
    plot(abs(OFDM_RX));
    title('RX signal');
end

%% receiver pipeline
% FrameDetection;(to be added)

[lts_corr, LongPreambleRX_t, PayloadIndex] = OFDM_TimeSync(OFDM_RX);    % time sync

% FrequencySync(to be added)

CSI = OFDM_ChannelEstimation(LongPreambleRX_t);

if DEBUG
    PayloadIndex
    figure;
    plot(abs(lts_corr));
    title('correlation result');
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

Payload_RX_t = OFDM_RX(PayloadIndex: PayloadIndex + AirFrameLen - 1 - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

% remove CP
Payload_RX_t = Add_CP(Payload_RX_t, false);
if DEBUG
    figure;
    plot(abs(fft(Payload_RX_t, N_SC, 1)));
    title('Payload Rx');
end

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
ErrorOffset = 100;

BinDataNums = length(RawDataBin);
UncodedDataNums = length(InterleavedDataBin);
UncodedErrorBitsNums = sum(abs(CodedDataBin_Rx - CodedDataBin));
UncodedBER = UncodedErrorBitsNums / UncodedDataNums;
CodedErrorBitsNums = sum(abs(ScrambledDataBin_Rx(1: end - ErrorOffset) - ScrambledDataBin(1: end - ErrorOffset)));
CodedBER = CodedErrorBitsNums / (BinDataNums - ErrorOffset);

% disp(['transmit bits: ' num2str(BinDataNums)])
% disp(['BER without convoluational code: ' num2str(UncodedBER)])
% disp(['Error nums after covolutional decoder ' num2str(CodedErrorBitsNums)])
% disp(['BER after covolutional decoder ' num2str(CodedBER)])


%%
UnBER(trans_index, mod_index) = UncodedBER;
BER(trans_index, mod_index) = CodedBER;
RxCSIs(:, trans_index) = CSI;

if BER(trans_index, mod_index) == 0
    break;
end

if DEBUG
    figure; 
    plot(abs(fft(Response)) / norm(fft(Response))); hold on;
    plot(abs(CSI) / norm(CSI));
    legend('ground truth', 'estimation');
    title('the ground truth and the estimation of normallized CSI');
end

end % end mod index
if mod(trans_index, 100) == 0
    toc; % display transmission time
end


end % end trans index

real_CSIs = real(RxCSIs);
imag_CSIs = imag(RxCSIs);

% save ber5.txt -ascii BER
% save noiseCSI_real5.txt -ascii real_CSIs
% save noiseCSI_imag5.txt -ascii imag_CSIs

