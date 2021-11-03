%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% IEEE 802.11g simulation on the AWGN channel.
%
% Copyright (C) 2021.11.03  Shiyue He (hsy1995313@gmail.com)
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
clear; close all;

%% Simualtion variables
Nbytes      = 4096;         % The number of bits (max: 4096 Bytes)
BW          = 20;           % Bandwidth (MHz)
MCS         = 1;
SNR         = 30;
Nbits       = Nbytes * 8;

IEEE80211g_GlobalVariables;
global MCS_MAT N_SC N_CP TAIL_LEN SC_DATA_NUM CODE_RATE;
global LONG_PREAMBLE_LEN GUARD_SC_INDEX SCREAMBLE_POLYNOMIAL SCREAMBLE_INIT;

%% Raw data generation
Mod = MCS_MAT(1, MCS);
CodeRate = MCS_MAT(2, MCS);
RawBits = randi([0, 1], Nbits, 1); % randam bits

%% Add TAIL bits and PAD bits
Ndbs = SC_DATA_NUM * log2(Mod) * CODE_RATE(MCS);    % Number of coded bits per symbol
RawBits_tail = [RawBits; zeros(TAIL_LEN, 1)];

N_PAD = Ndbs - mod(length(RawBits_tail), Ndbs);
RawBits_pad = [RawBits_tail; zeros(N_PAD, 1)];

N_sym_pd = length(RawBits_pad) / Ndbs;

%% Encoding
ScrambledDataBin = step(comm.Scrambler('CalculationBase', 2, ...
                        'Polynomial', SCREAMBLE_POLYNOMIAL, ...
                        'InitialConditions', SCREAMBLE_INIT), ...
                        RawBits_pad);
CodedDataBin = IEEE80211g_ConvolutionalCode(ScrambledDataBin, CodeRate, true);
InterleavedDataBin = IEEE80211g_Interleaver(CodedDataBin, log2(Mod), true);

%% Modulation
[Payload_TX_t, Payload_TX_f] = IEEE80211g_Modulation(InterleavedDataBin, MCS);

%% Add CP
SymbolNum = length(Payload_TX_t) / N_SC;

Payload_TX_t = reshape(Payload_TX_t, N_SC, SymbolNum);
Payload_TX_t = [Payload_TX_t(N_SC - N_CP +1: N_SC, :); Payload_TX_t];
Payload_TX_t = reshape(Payload_TX_t, [], 1);

%% Preamble generation
[STF, LTF] = PreambleGenerator;
OFDM_TX = [STF; LTF; Payload_TX_t];

FrameLen = length(OFDM_TX);

%% Channel model: awgn channel
OFDM_TX_Air = OFDM_TX;
OFDM_RX_Air = awgn(OFDM_TX_Air, SNR, 'measured');

%% Time synchronization
[SyncResult, PayloadIndex] = OFDM_TimeSync(OFDM_RX_Air);
FrameIndex = PayloadIndex - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP);

OFDM_RX = OFDM_RX_Air(FrameIndex +1: FrameIndex + FrameLen);
LongPreambleRX_t = OFDM_RX(2 * (N_CP + N_SC) + 2 * N_CP + 1: 4 * (N_CP + N_SC));
Payload_RX_t = OFDM_RX(PayloadIndex +1: PayloadIndex + FrameLen - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

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

%% OFDM demodulation
InterleavedDataBin_Rx = IEEE80211g_Demodulation(Payload_RX_f, MCS);

%% Decoding
CodedDataBin_Rx = IEEE80211g_Interleaver(InterleavedDataBin_Rx, log2(Mod), false);
ScrambledDataBin_Rx = IEEE80211g_ConvolutionalCode(CodedDataBin_Rx, CodeRate, false);
RawDataBin_Rx = step(comm.Descrambler('CalculationBase', 2, ...
                                        'Polynomial', SCREAMBLE_POLYNOMIAL, ...
                                        'InitialConditions', SCREAMBLE_INIT), ...
                                        ScrambledDataBin_Rx);

%% Remove tail and pad bits
RawDataBin_Rx = RawDataBin_Rx(1: Nbits);

%% Transmission result
ErrorPosition = xor(RawDataBin_Rx, RawBits);
BER = sum(ErrorPosition) / Nbits;

clc;

figure();
plot(abs(Payload_TX_f));
title('Payload Tx');

figure;
plot(abs(SyncResult));
title('Correlation result');

disp(['The frame start index: ' num2str(FrameIndex)])
disp(['The payload start index: ' num2str(PayloadIndex)])

figure; hold on; 
plot(abs(LongPreambleRX_t(1: N_SC)));
plot(abs(LongPreambleRX_t(N_SC + 1: 2 * N_SC)));
title('Long preamble in the time domain');

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

disp(['***************TX INFO***************']);
disp(['    The number of payload symbols: ' num2str(N_sym_pd)]);
disp(['    Transmission time: ' num2str(length(OFDM_TX_Air) / BW) ' us']);

disp(['**********AWGN Channel Model*********']);
disp(['    SNR: ' num2str(SNR) ' dB']);

disp(['***************Res INFO**************']);
if BER == 0
    disp(['    Frame reception successful!']);
else
    disp(['    Frame reception failed!']);
    disp(['    BER: ' num2str(BER)]);
end
disp(['*************************************']);