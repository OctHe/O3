%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% IEEE 802.11g simulation on the Rician channel.
%
% Copyright (C) 2021.11.18  Shiyue He (hsy1995313@gmail.com)
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
MHz         = 1e6;          % 1MHz

Nbytes      = 4096;         % The number of bits (max: 4096 Bytes)
BW          = 20 * MHz;     % Bandwidth (20 MHz)
MCS         = 7;
Nbits       = Nbytes * 8;
Nzeros      = 100;
path_delays = [0, 0.05] / MHz;
avg_gains   = [10, 1];
doppler     = 5;            % Doppler shift is around 5 Hz

IEEE80211g_GlobalVariables;
global MCS_MAT N_SC N_CP TAIL_LEN SC_DATA_NUM CODE_RATE SC_IND_DATA;
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

%% Channel model: Rician channel
OFDM_TX_Air = [zeros(Nzeros, 1); OFDM_TX; zeros(Nzeros, 1)];

ricianchan = comm.RicianChannel(...
            'SampleRate', BW,...
            'PathDelays', path_delays,...
            'AveragePathGains', avg_gains,...
            'NormalizePathGains', false,...
            'DirectPathDopplerShift', doppler,...
            'MaximumDopplerShift', 50,...
            'PathGainsOutputPort', true);

[OFDM_RX_Air, path_gains] = ricianchan(OFDM_TX_Air);

%% Time synchronization
[SyncResult, PayloadIndex] = OFDM_TimeSync(OFDM_RX_Air);
FrameIndex = PayloadIndex - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP);

LongPreambleRX_t = OFDM_RX_Air(FrameIndex + 2 * (N_CP + N_SC) + 2 * N_CP + 1: FrameIndex + 4 * (N_CP + N_SC));
Payload_RX_t = OFDM_RX_Air(PayloadIndex +1: PayloadIndex + FrameLen - 2 * (LONG_PREAMBLE_LEN + 2 * N_CP));

%% CSI estimation
[~,  LongPreambleTX_t] = PreambleGenerator; 
LongPreambleTX_t = LongPreambleTX_t(2 * N_CP + N_SC + 1: end);

LongPreambleRX_t = reshape(LongPreambleRX_t, N_SC, 2);

LongPreambleTX_f = fft(LongPreambleTX_t, N_SC, 1);
LongPreambleRX_f = fft(LongPreambleRX_t, N_SC, 1);

CSI = LongPreambleTX_f .* (LongPreambleRX_f(:, 1) + LongPreambleRX_f(:, 2))/2;
CSI(GUARD_SC_INDEX) = zeros(size(GUARD_SC_INDEX));

%% Remove CP
SymbolNum = size(Payload_RX_t, 1) / (N_CP + N_SC);
Payload_RX_t = reshape(Payload_RX_t, N_CP + N_SC, SymbolNum);
Payload_RX_t = Payload_RX_t(N_CP + 1: end, :);

%% Channel equalization
[Payload_RX_f, PhaseOffset] = IEEE80211g_ChannelEqualizer(Payload_RX_t, CSI);

%% OFDM demodulation
InterleavedDataBin_Rx = IEEE80211g_Demodulation(Payload_RX_f, MCS);

Payload_RX_f = reshape(Payload_RX_f(SC_IND_DATA, :), [], 1);

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

figure;
plot((0: FrameLen+2*Nzeros-1) / BW / MHz, abs(path_gains));
ylim([0, 10]);
title('Gains of each path in the Rician channel');

figure;
plot(abs(SyncResult));
title('Correlation result');

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

figure;
plot(angle(PhaseOffset.'));
title('Phase offest of each symbol at pilots');

figure; hold on;
scatter(real(Payload_RX_f), imag(Payload_RX_f));
xlim([-3, 3]); ylim([-3, 3]);
title('Constellation of RX payload');

clc;
disp(['***************TX INFO***************']);
disp(['    The number of payload symbols: ' num2str(N_sym_pd)]);
disp(['    Transmission time: ' num2str(FrameLen / BW / MHz) ' us']);

disp(['*********Rician Channel Model********']);
disp(['    Path delays: [' num2str(path_delays) '] s']);
disp(['    Path Gains: [' num2str(avg_gains) '] dB']);
disp(['    Maximum Doppler shift: ' num2str(doppler) ' Hz']);

disp(['***************Res INFO**************']);
disp(['    The frame start index: ' num2str(FrameIndex)]);
if FrameIndex == Nzeros
    disp(['    Time synchronization successful!']);
else
    disp(['    Time synchronization error: ' num2str(FrameIndex - Nzeros)]);
end

if BER == 0
    disp(['    Frame reception successful!']);
else
    disp(['    Frame reception failed!']);
    disp(['    BER: ' num2str(BER)]);
end
disp(['*************************************']);