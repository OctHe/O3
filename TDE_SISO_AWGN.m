%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Trace driven simulation
%   Update: awgn trace; transmit Bin signal
% 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all;

%% Global params
global LONG_PREAMBLE_LEN N_CP N_SC TAIL_LEN
global DEBUG
GlobalVariables;

DEBUG = false;

%% Local params initialization
DATA_NUM                = 48 * 6 * 36;      % the minimum data number is 48 * 6 to compatible with the rate 2/3 and 3/4
TX_POWER                = 1;                % signal power, (mW); 1mW = 0dBm
NOISE_FLOOR             = 10;               % dB
ReceptionSign           = 0;                % reception sign: 1(true), 0(false)
SNR_Measured            = 30; 
Throughput_for_Packets = 0; 

Mod_Map = [2; 2; 4; 4; 16; 16; 64; 64];
CodeRate_Map = [2; 4; 2; 4; 2; 4; 3; 4];
BitRate_Map = [6; 9; 12; 18; 24; 36; 48; 54]; % Mbps
    
%% Read CSI traces (TBD: add trace files)
[SNRs_dB, CSI, TracesNums, Timestamps] = ReadTracesFromMat('../CSITraces_low_velocity.mat');

TracesNums = 1000;
SNRs_dB = SNRs_dB(1: TracesNums);

%% Simulation Running
for trace_index = 1: TracesNums
    %% Generate raw data; Obtain SNR by channel feedback
    RawData = randi([0, 1], DATA_NUM, 1); % randam raw datas
    SNR = SNRs_dB(trace_index);
    
    %% Rate adaptation algorithm at TX
    SNR_Threshold = [5; 7; 8.6; 11.3; 15.5; 22.8; 22.6; 25]; % dB
    MCS_Index = sum(SNR_Measured > SNR_Threshold);
    
    Mod = Mod_Map(MCS_Index);                % Modulation order (2/4/16/64 = BSPK/QPSK/16-QAM/64-QAM)
    CodeRate = CodeRate_Map(MCS_Index);           % 2(1/2); 3(2/3); 4(3/4)
    BitRate = BitRate_Map(MCS_Index);
    
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

    %% Amplify the power
    OFDM_TX_Air = PowerAmplifier(OFDM_TX, TxSignalPower);
    AirFrameLen = length(OFDM_TX_Air);

    AirTxPower = sum(abs(OFDM_TX_Air).^2)/length(OFDM_TX_Air);

    %% channel model: awgn channel
    OFDM_RX_Air = awgn(OFDM_TX_Air, SNR, 'measured');
    
    %% FrameDetection;(to be added)
    SNR_Measured = SNR; % signal power measurement: in practice, the SNR cannot be directly obtained
    
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
    
    %% Transmission Result
    TailBitsNums = 100;
    
    ErrorPosition = xor(RawDataBin_Rx, RawData);
    ErrorPosition = ErrorPosition(1: end - TailBitsNums); % remove tail bits (to be done)
    BinDataNums = length(ErrorPosition);
    
    BER = sum(ErrorPosition) / BinDataNums;
    
    if BER == 0
        ReceptionSign = 1;  % successful reception
        % disp(['SNR: ' num2str(SNR)  ' dB'  '; MCS Index: ' num2str(MCS_Index) '; Throughput: ' num2str(BitRate) ' Mbps']);
        Throughput_for_Packets = Throughput_for_Packets + BitRate;
    else
        ReceptionSign = 0;  % fail reception
        % disp(['SNR: ' num2str(SNR)  ' dB'  '; MCS Index: ' num2str(MCS_Index) '; BER: ' num2str(BER)]);
    end
end % end trans index

disp(['Throughput for all traces: ' num2str(Throughput_for_Packets) ' Mbps']);
