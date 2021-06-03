function RawDataBin_Rx = IEEE80211a_Receiver(OFDM_RX_Air, MCS_Index, Nbits)

global LONG_PREAMBLE_LEN N_CP N_SC MCS_MAT
global DEBUG

Mod = MCS_MAT(1, MCS_Index);

Frame_RX_Air_Len = length(OFDM_RX_Air);

%% Time synchronization
[SyncResult, PayloadIndex] = OFDM_TimeSync(OFDM_RX_Air);

FrameIndex = PayloadIndex - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP);

OFDM_RX = OFDM_RX_Air(FrameIndex: FrameIndex + Frame_RX_Air_Len - 1);

LongPreambleRX_t = OFDM_RX(2 * (N_CP + N_SC) + 2 * N_CP + 1: 4 * (N_CP + N_SC));

%% CSI estimation
CSI = OFDM_ChannelEstimation(LongPreambleRX_t);

%% Extract payload after CFO compensation
Payload_RX_t = OFDM_RX(PayloadIndex: PayloadIndex + Frame_RX_Air_Len - 1 - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

%% Remove CP
Payload_RX_t = Add_CP(Payload_RX_t, false);

%% Chanel equalization
Payload_RX_f = OFDM_ChannelEqualization(Payload_RX_t, CSI);

%% Phase tracking with pilot(to be added)

%% OFDM demodulation
InterleavedDataBin_Rx = OFDM_Demodulation(Payload_RX_f, MCS_Index);

%% OFDM decoding
RawDataBin_Rx = OFDM_Decoder(InterleavedDataBin_Rx, Nbits, MCS_Index);

%% Debug
if DEBUG
    figure;
    plot(abs(SyncResult));
    title('Correlation result');
    
    disp(['The frame start index: ' num2str(FrameIndex)])
    disp(['The payload start index: ' num2str(PayloadIndex)])
    
    figure; hold on; 
    plot(abs(LongPreambleRX_t(1: N_SC)));
    plot(abs(LongPreambleRX_t(N_SC + 1: 2 * N_SC)));
    title('Long preamble in the time domain');
    
    if DEBUG
        figure;
        subplot(311);
        plot(abs(CSI));
        title('CSI estimation abs');
        subplot(312);
        plot(angle(CSI));
        title('CSI estimation angle');
        subplot(313);
        plot(abs(ifft(CSI)));
        title('Channel response');
    end

end