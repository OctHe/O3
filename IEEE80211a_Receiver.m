function RawDataBin_Rx = IEEE80211a_Receiver(OFDM_RX_Air, MCS_Index, Nbits)

global LONG_PREAMBLE_LEN N_CP N_SC MCS_MAT GUARD_SC_INDEX
global DEBUG

Mod = MCS_MAT(1, MCS_Index);
CodeRate = MCS_MAT(2, MCS_Index);

%% Time synchronization
Frame_RX_Air_Len = length(OFDM_RX_Air);

[SyncResult, PayloadIndex] = OFDM_TimeSync(OFDM_RX_Air);
FrameIndex = PayloadIndex - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP);

OFDM_RX = OFDM_RX_Air(FrameIndex: FrameIndex + Frame_RX_Air_Len - 1);
LongPreambleRX_t = OFDM_RX(2 * (N_CP + N_SC) + 2 * N_CP + 1: 4 * (N_CP + N_SC));
Payload_RX_t = OFDM_RX(PayloadIndex: PayloadIndex + Frame_RX_Air_Len - 1 - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

%% CSI estimation
[~,  LongPreambleTX_t] = PreambleGenerator; 
LongPreambleTX_t = LongPreambleTX_t(2 * N_CP + N_SC + 1: end);

LongPreambleRX_t = reshape(LongPreambleRX_t, N_SC, 2);

LongPreambleTX_f = fft(LongPreambleTX_t, N_SC, 1);
LongPreambleRX_f = fft(LongPreambleRX_t, N_SC, 1);

CSI = LongPreambleTX_f .* (LongPreambleRX_f(:, 1) + LongPreambleRX_f(:, 2))/2;

%% Remove CP
SymbolNum = size(Payload_RX_t, 1) / (N_CP + N_SC);
Payload_RX_t = reshape(Payload_RX_t, N_CP + N_SC, SymbolNum);
Payload_RX_t = Payload_RX_t(N_CP + 1: end, :);
    
%% Chanel equalization
Payload_RX_f = fft(Payload_RX_t, N_SC, 1) ./ repmat(CSI, 1, SymbolNum);
Payload_RX_f(GUARD_SC_INDEX, :) = zeros(length(GUARD_SC_INDEX), SymbolNum);

%% Phase tracking with pilot(to be added)


%% OFDM demodulation
InterleavedDataBin_Rx = OFDM_Demodulation(Payload_RX_f, MCS_Index);

%% Decoding
CodedDataBin_Rx = OFDM_Interleaver(InterleavedDataBin_Rx, log2(Mod), false);
ScrambledDataBin_Rx = OFDM_ConvolutionalCode(CodedDataBin_Rx, CodeRate, false);
RawDataBin_Rx = step(comm.Descrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), ScrambledDataBin_Rx);

%% Remove tail and pad bits
RawDataBin_Rx = RawDataBin_Rx(1: Nbits);

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