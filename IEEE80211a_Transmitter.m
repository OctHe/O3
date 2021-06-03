function [OFDM_TX_Air, N_sym_pld, PowerTX] = IEEE80211a_Transmitter(RawBits, MCS_Index, PowerTX)

global MCS_MAT;
global DEBUG

Mod = MCS_MAT(1, MCS_Index);
CodeRate = MCS_MAT(2, MCS_Index);

%% OFDM Encoder
[InterleavedDataBin, N_sym_pld] = OFDM_Encoder(RawBits, MCS_Index);

%% Modulation
[Payload_TX_t, Payload_TX_f] = OFDM_Modulation(InterleavedDataBin, MCS_Index);

Payload_TX_t = Add_CP(Payload_TX_t, true);

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