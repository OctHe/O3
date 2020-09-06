%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Trace driven simulation
%   Update: awgn trace; transmit Bin signal
% 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all;

%% Global params
global LONG_PREAMBLE_LEN N_CP N_SC TAIL_LEN GUARD_SC_INDEX
global DEBUG
GlobalVariables;

DEBUG = false;

%% Local params initialization
DATA_NUM                = 48 * 6000;      % the minimum data number is 48 * 6 to compatible with the rate 2/3 and 3/4

MOD_ORDER = 16;
Code_Rate = 4;

TracesNums = 10;

SNR = 15;
BERs = zeros(TracesNums, 1);

%% Simulation Running
for trace_index = 1: TracesNums
    %% Generate raw data; Obtain SNR by channel feedback
    RawData = randi([0, 1], DATA_NUM, 1); % randam raw datas
    
    %% Encoding
    ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2,'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RawData);
    
    CodedDataBin = OFDM_ConvolutionalCoder(ScrambledDataBin, Code_Rate, true);

    InterleavedDataBin = OFDM_Interleaver(CodedDataBin, log2(MOD_ORDER), true);

    Payload_TX_t = OFDM_Modulation(InterleavedDataBin, MOD_ORDER);

    Payload_TX_t = Add_CP(Payload_TX_t, true);
    
    %% Channel model: awgn channel
    Payload_RX_t = awgn(Payload_TX_t, SNR, 'measured');
%     Payload_RX_t = Payload_TX_t;
    
    %% Remove CP
    Payload_RX_t = Add_CP(Payload_RX_t, false);
    
    Payload_RX_f = fft(Payload_RX_t, N_SC, 1);
    Payload_RX_f(GUARD_SC_INDEX, :) = zeros(length(GUARD_SC_INDEX), size(Payload_RX_f, 2));
    
%     CSI = [0; ones(26, 1); zeros(11, 1); ones(26, 1)];
%     Payload_RX_f = OFDM_ChannelEqualization(Payload_RX_t, CSI);
    
    %% Decoding
    InterleavedDataBin_Rx = OFDM_Demodulation(Payload_RX_f, MOD_ORDER);

    CodedDataBin_Rx = OFDM_Interleaver(InterleavedDataBin_Rx, log2(MOD_ORDER), false);

    ScrambledDataBin_Rx = OFDM_ConvolutionalCoder(CodedDataBin_Rx, Code_Rate, false);

    RawDataBin_Rx = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), ScrambledDataBin_Rx);

    
    %% Transmission Result
    TailBitsNums = 100;
    
    ErrorPosition = xor(RawDataBin_Rx, RawData);
    ErrorPosition = ErrorPosition(1: end - TailBitsNums); % remove tail bits (to be done)
    BinDataNums = length(ErrorPosition);
    
    BERs(trace_index) = sum(ErrorPosition) / BinDataNums;
    
    disp(['BER: ' num2str(BERs(trace_index))])
    
end % end trans index
disp(['Variance: ' num2str(var(BERs))])