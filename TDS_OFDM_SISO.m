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
    
    %% Transmitter pipeline
    [OFDM_TX_Air, AirFrameLen] = OFDM_TX_Pipeline(RawData, Mod, CodeRate, TX_POWER); 
    AirTxPower = sum(abs(OFDM_TX_Air).^2)/length(OFDM_TX_Air);

    %% channel model: awgn channel
    OFDM_RX_Air = awgn(OFDM_TX_Air, SNR, 'measured');
    
    %% Receiver pipeline
    SNR_Measured = SNR; % signal power measurement: in practice, the SNR cannot be directly obtained
    RawDataBin_Rx = OFDM_RX_Pipeline(OFDM_RX_Air, AirFrameLen, Mod, CodeRate);
    
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
