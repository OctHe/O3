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
global SCREAMBLE_POLYNOMIAL SCREAMBLE_INIT

MHz         = 1e6;          % 1MHz
Hz          = 1;

Nbits       = 5000;
MCSi        = 2;

Nbps = log2(MCS_TAB.mod(MCSi)) * N_DATA;    % Bits in each symbol

%% Modules
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

OFDM_Scrambler = comm.Scrambler( ...
                    'CalculationBase', 2, ...
                    'Polynomial', SCREAMBLE_POLYNOMIAL, ...
                    'InitialConditions', SCREAMBLE_INIT ...
                    );
OFDM_Descrambler = comm.Descrambler( ...
                    'CalculationBase', 2, ...
                    'Polynomial', SCREAMBLE_POLYNOMIAL, ...
                    'InitialConditions', SCREAMBLE_INIT ...
                    );
                    
%% Transmitter
TxBits = randi(2, [Nbits, 1]) -1;

Npad = Nbps - mod(Nbits + N_TAIL, Nbps);
TxPadBits = [TxBits; zeros(Npad + N_TAIL, 1)];

ScrambledBits = OFDM_Scrambler(TxPadBits);

[STF, LTF, DLTF] = OFDM_PreambleGenerator(1);
TxModData = qammod(ScrambledBits, MCS_TAB.mod(MCSi), 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = OFDM_Modulator(TxModData);

TxFrame = [STF; LTF; DLTF; Payload_t];

%% Backscatter
Nts = floor(Nbits / Nbps);                % Tag symbol is related to Ambient transmitter
Ntp = size(Payload_t, 1) / (N_CP + N_FFT) - Nts;    % Pad bits to each tag

if Ntp < 0
    error('The frame at a tag must be less than the frame of the ambient source');
end

TagBits = randi(2, [Nts, 1]) -1;    % Backscatter only uses BPSK modulation

TagModData = qammod([TagBits; zeros(Ntp, 1)], 2, 'InputType', 'bit', 'UnitAveragePower',true);

% Reflection STF and LTF (4 symbols)
% Channel estimation training sequence (4 symbols);
TagTrainBits = [zeros(4, 1); zeros(2, 1); 1; 1];
BTF = qammod(TagTrainBits, 2, 'InputType', 'bit', 'UnitAveragePower',true);

% Backscatter embeds one symbol for each OFDM symbol
TagFrame = kron([BTF; TagModData], ones(N_CP + N_FFT, 1));

%% Direct channel and double-fading channel
RxFrame = H(TxFrame);

% Tag shifts the frequency into another channel
IncomingFrame = H(TxFrame);
RxHybridFrame = H(IncomingFrame .* TagFrame);

%% Receiver 1: Ambient receiver
[~, AmbientIndex] = OFDM_SymbolSync(RxFrame, LTF(2*N_CP +1: end, 1));

if AmbientIndex == N_LTF * 2   % If sync is correct
    
    RxDLTF = RxFrame(AmbientIndex +1: AmbientIndex + (N_CP + N_FFT) * N_LTFN);
    RxPayload_t = RxFrame(AmbientIndex + (N_CP + N_FFT) * N_LTFN +1: end);

    CSId = OFDM_ChannelEstimator(RxDLTF, 1, 1);

    RxPayload_f = OFDM_Demodulator(RxPayload_t, CSId);

    DecodedBits = qamdemod(RxPayload_f, MCS_TAB.mod(MCSi), 'OutputType', 'bit', 'UnitAveragePower',true);
    
    RxTailBits = OFDM_Descrambler(DecodedBits);
    
    RxBits = RxTailBits(1: end - N_TAIL - Npad);

end

%% Receiver 2: Backscatter receiver
[~, TagIndex] = OFDM_SymbolSync(RxHybridFrame, LTF(2*N_CP +1: end, 1));

if TagIndex == N_LTF * 2   % If sync is correct
    
    HybridDLTF = RxHybridFrame(TagIndex +1: TagIndex + (N_CP + N_FFT) * N_LTFN);
    HybridPayload_t = RxHybridFrame(TagIndex + (N_CP + N_FFT) * N_LTFN +1: end);

    CSIr = OFDM_ChannelEstimator(HybridDLTF, 1, 1);

    HybridPayload_f = OFDM_Demodulator(HybridPayload_t, CSIr);

    HybridDedecodedBits = qamdemod(HybridPayload_f, MCS_TAB.mod(MCSi), 'OutputType', 'bit', 'UnitAveragePower',true);
    
    HybridTailBits = OFDM_Descrambler(HybridDedecodedBits);
    
    HybridBits = HybridTailBits(1: end - N_TAIL - Npad);

end

%% Codebook-based backscatter decoding
% Reference: Zhang, Pengyu, Colleen Josephson, Dinesh Bharadia, and Sachin 
% Katti. "Freerider: Backscatter communication using commodity radios." In 
% Proceedings of ACM CoNEXT, pp. 389-401. 2017.

if AmbientIndex == N_LTF * 2 && TagIndex == N_LTF * 2
    TagDecodedBits = zeros(Nts, 1);

    % If pilot is available, the frequency-shift backscatter cannot be
    % decoded
    for its = 1: Nts
        DecodedCodeword = xor(HybridBits((its -1) * Nbps +1: its * Nbps), RxBits((its -1) * Nbps +1: its * Nbps));
        TagDecodedBits(its) = sum(DecodedCodeword) >= Nbps/2;
    end
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
    scatter(1: Nts, tag_error_bits);
    ylim([0, 2]);
    title('Error bits');
    
else
    clc;
    disp(['*************************************']);
    disp(['    Ambient source time sync error !']);
    disp(['*************************************']);
end