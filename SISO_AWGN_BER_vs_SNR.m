%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   OFDM simulation on the AWGN channel.
%   It can plot the BER vs SNR and PER vs SNR of different MCSs in IEEE 
%   802.11 standard.
%   BER is obtained by the Monto Carlo simultion. 
%   PER is calculated based on the BER and the expected frame length (FL).
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

%% Global params
global DEBUG
GlobalVariables;

DEBUG = false;

%% Simualtion variables
Nbits       = 1e5;	% The number of bits (default: 1500 Bytes)
Npack       = 1;        % The number of packet in each round
FL          = 800;      % Expected frame length. 
                        % PER is related to FL and BER
SNR_MAX     = 30;       % The maximum SNR in the simulation
BW          = 20;       % Bandwidth (MHz)

FRAME_COUNT = 0;
MCS         = 1: 8;
SNR_Res     = 0.1;      % Resolution of SNR
SNR_Range   = SNR_Res: SNR_Res: SNR_MAX;

BER_METRICS = zeros(length(SNR_Range), length(MCS));
PER_METRICS = zeros(length(SNR_Range), length(MCS));

if length(SNR_Range) > 1
    DEBUG = false;
end

%% Simulation process
for SNR_Index = SNR_Range
for MCS_Index = MCS
        
    %% Raw data generation
    RawBits = randi([0, 1], Nbits, 1); % randam bits

    %% OFDM Transmitter
    [OFDM_TX_Air, N_sym_pld, PowerTX] = IEEE80211a_Transmitter(RawBits, MCS_Index, 'Normalized');

    %% Channel model: awgn channel
    OFDM_RX_Air = awgn(OFDM_TX_Air, SNR_Index, 'measured');
    
    %% OFDM receiver
    RawDataBin_Rx = IEEE80211a_Receiver(OFDM_RX_Air, MCS_Index, Nbits);

    %% Transmission result
    FRAME_COUNT = FRAME_COUNT + 1;
    
    ErrorPosition = xor(RawDataBin_Rx, RawBits);
    BER = sum(ErrorPosition) / Nbits;
    BER_METRICS(round(SNR_Index / SNR_Res), MCS_Index) = BER;
    PER_METRICS(round(SNR_Index / SNR_Res), MCS_Index) = 1 - (1-BER)^FL;
    
    %% Display the transmission details
    clc;
    disp(['***************TX INFO***************']);
    disp(['    Simulated frame: ' num2str(FRAME_COUNT)]);
    disp(['    The number of payload symbols: ' num2str(N_sym_pld)]);
    disp(['    Transmission time: ' num2str(length(OFDM_TX_Air) / BW) ' us']);
    if PowerTX == "Normalized"
        disp(['    TX power: Normalized']);
    else
        disp(['    TX power: ' num2str(PowerTX) ' dBm']);
    end
        
    disp(['**********AWGN Channel Model*********']);
    disp(['    SNR: ' num2str(SNR_Index) ' dB']);

    disp(['***************Res INFO**************']);
    if BER == 0
        disp(['    Frame reception successful!']);
    else
        disp(['    Frame reception failed!']);
        disp(['    BER: ' num2str(BER)]);
    end

end % end MCS
end % end SNR

figure;
plot(SNR_Range, BER_METRICS);
title('BER at different SNR');
figure;
plot(SNR_Range, PER_METRICS);
title('PER at different SNR');