%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% BER vs SNR curve with AWGN channel
%
% Copyright (C) 2022  Shiyue He (hsy1995313@gmail.com)
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; 
close all;

%% Variables
global MCS_TAB MCS_MAX
global N_CP N_LTF N_FFT N_LTFN N_TAIL
global SCREAMBLE_POLYNOMIAL SCREAMBLE_INIT
global MIN_BITS

MHz         = 1e6;          % 1MHz
Hz          = 1;

Nbits       = 65536;

SNR_TAB = 1: 40;
BW = 20 * MHz;

BER = zeros(length(SNR_TAB), MCS_MAX);

for SNR = SNR_TAB
for MCSi = 1: MCS_MAX
    % Transmitter
    BitsTX = randi(2, [Nbits, 1]) -1;
    
    Npad = MIN_BITS - mod(size(BitsTX, 1) + N_TAIL, MIN_BITS);
    PadedBitsTX = [BitsTX; zeros(Npad + N_TAIL, 1)];

    IEEE80211_scrambler = comm.Scrambler( ...
                            'CalculationBase', 2, ...
                            'Polynomial', SCREAMBLE_POLYNOMIAL, ...
                            'InitialConditions', SCREAMBLE_INIT ...
                            );
    ScrambledBits = IEEE80211_scrambler(PadedBitsTX);

    EncodedBits = IEEE80211ac_ConvolutionalEncoder(ScrambledBits, MCS_TAB.rate(MCSi));

    ModDataTX = qammod(EncodedBits, MCS_TAB.mod(MCSi), 'InputType', 'bit', 'UnitAveragePower',true);
    Payload_t = IEEE80211ac_Modulator(ModDataTX);

    [STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(1);

    FrameTX = [STF; LTF; DLTF; Payload_t];

    % Channel model: awgn channel
    FrameRX = awgn(FrameTX, SNR, 'measured');

    % Receiver
    [sync_results, LTF_index] = OFDM_SymbolSync(FrameRX, LTF(2*N_CP +1: end, 1));

    if LTF_index == N_LTF * 2   % If sync is correct

        LTF_RX = FrameRX(LTF_index - N_LTF +1: LTF_index);
        DLTF_RX = FrameRX(LTF_index +1: LTF_index + (N_CP + N_FFT) * N_LTFN);
        Payload_RX_t = FrameRX(LTF_index + (N_CP + N_FFT) * N_LTFN +1: end);

        CSI = IEEE80211ac_ChannelEstimator(DLTF_RX, 1, 1);

        Payload_RX_f = IEEE80211ac_Demodulator(Payload_RX_t, CSI);

        DecodedBits = qamdemod(Payload_RX_f, MCS_TAB.mod(MCSi), 'OutputType', 'bit', 'UnitAveragePower',true);

        DescrambledBits = IEEE80211ac_ConvolutionalDecoder(DecodedBits, MCS_TAB.rate(MCSi));

        IEEE80211_descrambler = comm.Descrambler( ...
                            'CalculationBase', 2, ...
                            'Polynomial', SCREAMBLE_POLYNOMIAL, ...
                            'InitialConditions', SCREAMBLE_INIT ...
                            );
        TailBitsRX = IEEE80211_descrambler(DescrambledBits);

        BitsRX = TailBitsRX(1: end - N_TAIL - Npad);

        % Transmission result
        error_bits = xor(BitsRX, BitsTX);
        BER(SNR, MCSi) = sum(error_bits) / Nbits;

        clc;
        disp(['*********Frame Configuration********']);
        disp(['    MCS: ' num2str(MCSi)]);
        disp(['*********AWGN Channel Model********']);
        disp(['    SNR: ' num2str(SNR) ' dB']);
        disp(['*********Transmission Result*********']);
        disp(['    Packet length: ' num2str(length(FrameRX) / BW) ' us']);
        disp(['    Time synchronization successful!']);
        disp(['    BER: ' num2str(BER(SNR, MCSi))]);

    else
        BER(SNR, MCSi) = 1;
        clc;
        disp(['*************************************']);
        disp(['    Time synchronization error !']);
    end
    disp(['*************************************']);
    
end % End of MCS
end % End of SNR

figure;
plot(SNR_TAB, BER);
xlabel('SNR'); ylabel('BER');
title('BER at different SNRs');