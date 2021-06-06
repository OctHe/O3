function [OFDM_TX_Air, N_sym_pld, PowerTX] = IEEE80211a_Transmitter(RawBits, MCS_Index, PowerTX)

global MCS_MAT N_SC N_CP TAIL_LEN SC_DATA_NUM CODE_RATE;
global DEBUG

Mod = MCS_MAT(1, MCS_Index);
CodeRate = MCS_MAT(2, MCS_Index);

%% Add TAIL bits and PAD bits
Ndbs = SC_DATA_NUM * log2(Mod) * CODE_RATE(MCS_Index);    % Number of coded bits per symbol
RawBits = [RawBits; zeros(TAIL_LEN, 1)];

N_PAD = Ndbs - mod(length(RawBits), Ndbs);
RawBits = [RawBits; zeros(N_PAD, 1)];

N_sym_pld = length(RawBits) / Ndbs;

%% Encoding
ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2, 'Polynomial', [1 0 0 0 1 0 0 1], 'InitialConditions', [0 1 0 0 1 0 1]), RawBits);
CodedDataBin = OFDM_ConvolutionalCode(ScrambledDataBin, CodeRate, true);
InterleavedDataBin = OFDM_Interleaver(CodedDataBin, log2(Mod), true);

%% Modulation
[Payload_TX_t, Payload_TX_f] = OFDM_Modulation(InterleavedDataBin, MCS_Index);

%% Add CP
SymbolNum = length(Payload_TX_t) / N_SC;

Payload_TX_t = reshape(Payload_TX_t, N_SC, SymbolNum);
Payload_TX_t = [Payload_TX_t(N_SC - N_CP +1: N_SC, :); Payload_TX_t];
Payload_TX_t = reshape(Payload_TX_t, [], 1);

%% Preamble generation
[STF, LTF] = PreambleGenerator;

OFDM_TX = [STF; LTF; Payload_TX_t];

%% Amplify the power
if PowerTX == "Normalized"
    OFDM_TX_Air = OFDM_TX;
else
    OFDM_TX_Air = PowerAmplifier(OFDM_TX, PowerTX);
end

%% Debug
if DEBUG
    figure();
    plot(abs(Payload_TX_f));
    title('Payload Tx');
end