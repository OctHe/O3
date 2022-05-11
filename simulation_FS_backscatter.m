%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Frequency shift backscatter on the IEEE 802.11 channel
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
global MCS_TAB 
global N_CP N_LTF N_FFT N_DATA N_LTFN N_TAIL 
global MIN_BITS

MHz         = 1e6;          % 1MHz
Hz          = 1;

Nbits       = 8192;
MCSi        = 3;

BackMod     = 2;            % 2, 4 -> BPSK, QPSK

Nbps = log2(MCS_TAB.mod(MCSi)) * N_DATA;    % Bits in each symbol

NO_CHANNEL = true;

%% Channel model
BW          = 20 * MHz;                 % Bandwidth (20 MHz)
doppler     = 100 * Hz;                 % Doppler shift is around 5 Hz
path_delays = [0, 0.05, 0.1] / MHz;
avg_gains   = [0, -20, -40];            % Average path gain in dB

H = comm.RicianChannel(...
        'SampleRate', BW,...
        'PathDelays', path_delays,...
        'AveragePathGains', avg_gains,...
        'NormalizePathGains', true,...
        'DirectPathDopplerShift', doppler,...
        'PathGainsOutputPort', true);


%% Transmitter
TxBits = randi(2, [Nbits, 1]) -1;

Npad = MIN_BITS - mod(size(TxBits, 1) + N_TAIL, MIN_BITS);
TxPadBits = [TxBits; zeros(Npad + N_TAIL, 1)];

[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(1);
TxModData = qammod(TxPadBits, MCS_TAB.mod(MCSi), 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = IEEE80211ac_Modulator(TxModData);

TxFrame = [STF; LTF; DLTF; Payload_t];

%% Backscatter
Nts = floor(Nbits / Nbps);                % Tag symbol is related to Ambient transmitter
Ntp = size(Payload_t, 1) / (N_CP + N_FFT) - Nts;    % Pad bits to each tag

if Ntp < 0
    error('The frame at a tag must be less than the frame of the ambient source');
end

TagBits = randi(2, [Nts * log2(BackMod), 1]) -1;

TagModData = qammod([TagBits; zeros(Ntp, 1)], BackMod, 'InputType', 'bit', 'UnitAveragePower',true);

% Reflection STF and LTF (4 symbols)
% Channel estimation training sequence (4 symbols);
% Training sequence always uses BPSK modulation
TagTrainBits = [zeros(4, 1); zeros(2, 1); 1; 1];
BTF = qammod(TagTrainBits, 2, 'InputType', 'bit', 'UnitAveragePower',true);

% Backscatter embeds one symbol for each OFDM symbol
TagFrame = kron([BTF; TagModData], ones(N_CP + N_FFT, 1));

%% Direct channel and double-fading channel
RxFrame = H(TxFrame);

IncomingFrame = H(TxFrame);
RxHybridFrame = H(IncomingFrame .* TagFrame);

%% Receiver 1: Ambient receiver
[~, AmbientIndex] = OFDM_SymbolSync(RxFrame, LTF(2*N_CP +1: end, 1));

if AmbientIndex == N_LTF * 2   % If sync is correct
    
    RxDLTF = RxFrame(AmbientIndex +1: AmbientIndex + (N_CP + N_FFT) * N_LTFN);
    RxPayload_t = RxFrame(AmbientIndex + (N_CP + N_FFT) * N_LTFN +1: end);

    CSId = IEEE80211ac_ChannelEstimator(RxDLTF, 1, 1);

    RxPayload_f = IEEE80211ac_Demodulator(RxPayload_t, CSId);

    RxBits = qamdemod(RxPayload_f, MCS_TAB.mod(MCSi), 'OutputType', 'bit', 'UnitAveragePower',true);
    RxBits = RxBits(1: end - N_TAIL - Npad);

end

%% Receiver 2: Backscatter receiver
[~, TagIndex] = OFDM_SymbolSync(RxHybridFrame, LTF(2*N_CP +1: end, 1));

if TagIndex == N_LTF * 2   % If sync is correct
    
    HybridDLTF = RxHybridFrame(TagIndex +1: TagIndex + (N_CP + N_FFT) * N_LTFN);
    HybridPayload_t = RxHybridFrame(TagIndex + (N_CP + N_FFT) * N_LTFN +1: end);

    CSIr = IEEE80211ac_ChannelEstimator(HybridDLTF, 1, 1);

    HybridPayload_f = IEEE80211ac_Demodulator(HybridPayload_t, CSIr);

    RxHybridBits = qamdemod(HybridPayload_f, MCS_TAB.mod(MCSi), 'OutputType', 'bit', 'UnitAveragePower',true);
    RxHybridBits = RxHybridBits(1: end - N_TAIL - Npad);

end

%% Codebook-based backscatter decoding
% The algorithm is firstly illustrated in HitchHike (SenSys'16) and 
% Freerider (CoNEXT'17)

TagDecodedBits = zeros(Nts, 1);

for its = 1: Nts
    TagDecodedBits(its) = sum(xor(RxHybridBits((its -1) * Nbps +1: its * Nbps), RxBits((its -1) * Nbps +1: its * Nbps))) ~= 0;
end

%% Transmission result
if AmbientIndex == N_LTF * 2
    
    ambient_error_bits = xor(RxBits, TxBits);
    BER = sum(ambient_error_bits) / Nbits;

    figure;
    scatter(1: size(ambient_error_bits), ambient_error_bits);
    ylim([0, 2]);
    title('Error bits');
    
else
    clc;
    disp(['*************************************']);
    disp(['    Ambient source time sync error !']);
    disp(['*************************************']);
end

if TagIndex == N_LTF * 2
    
    tag_error_bits = xor(TagDecodedBits, TagBits);

    figure;
    scatter(1: size(tag_error_bits), tag_error_bits);
    ylim([0, 2]);
    title('Error bits');
    
else
    clc;
    disp(['*************************************']);
    disp(['    Ambient source time sync error !']);
    disp(['*************************************']);
end