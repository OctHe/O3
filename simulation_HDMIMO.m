%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OFDM HD-MIMO simulation
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
global MCS_TAB DATA_INDEX
global N_CP N_LTF N_FFT N_DATA N_TAIL 

MHz     = 1e6;          % 1MHz
Hz      = 1;

Nbits   = 4200;
MCSi    = 2;

Nbps    = log2(MCS_TAB.mod(MCSi)) * N_DATA;    % Bits in each symbol

Ntxs    = 2;
Ntags   = 2;
Nrxs    = 4;
    
%% HD-MIMO Transmitter
TxBits = randi(2, [Nbits, Ntxs]) -1;

Npad = Nbps - mod(Nbits + N_TAIL, Nbps);
TxPadBits = [TxBits; zeros(Npad + N_TAIL, Ntxs)];

[STF, LTF, HDLTF, BTF] = HDMIMO_PreambleGenerator(Ntxs, Ntags);

TxModData = qammod(TxPadBits, MCS_TAB.mod(MCSi), 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = OFDM_Modulator(TxModData);

TxFrame = [STF; LTF; HDLTF; Payload_t];

%% HD-MIMO Tag
Nts = floor(Nbits / Nbps);                % Tag symbol is related to Ambient transmitter
Ntp = size(Payload_t, 1) / (N_CP + N_FFT) - Nts;    % Pad bits to each tag

TagBits = randi(2, [Nts, Ntags]) -1;    % Backscatter only uses BPSK modulation

TagModData = qammod([TagBits; zeros(Ntp, Ntags)], 2, 'InputType', 'bit', 'UnitAveragePower',true);

% Backscatter Reflection Field: it reflects STF and LTF (4 symbols)
% Training sequence always uses BPSK modulation
BRF = -ones(4, Ntags);

% Symbol-level modulation (OFDM : Tag = 80 : 1)
TagFrame = kron([BRF; BTF; TagModData], ones(N_CP + N_FFT, 1));

%% HD-MIMO model
relative_loss = 0.01;
Hd = rand(Nrxs, Ntxs) .* exp(2j * pi * rand(Nrxs, Ntxs));
Hf = rand(Ntags, Ntxs) .* exp(2j * pi * rand(Ntags, Ntxs));
Hb = rand(Nrxs, Ntags) .* exp(2j * pi * rand(Nrxs, Ntags));

Nsamp = size(TxFrame, 1);
RxFrame = zeros(Nsamp, Nrxs);
for isig = 1: Nsamp
    RxFrame(isig, :) = (Hd * TxFrame(isig, :).' + ...
        relative_loss * Hb * diag(TagFrame(isig, :)) * Hf * TxFrame(isig, :).').';
end

%% HD-MIMO receiver
[SyncResults, SyncIndex] = OFDM_SymbolSync(RxFrame, LTF(2*N_CP +1: end, 1));

if SyncIndex == N_LTF * 2   % If sync is correct
    
    RxHDLTF = RxFrame(SyncIndex +1: SyncIndex + (N_CP + N_FFT) * Ntxs * (Ntags +1), :);
    RxPayload_t = RxFrame(SyncIndex + (N_CP + N_FFT) * Ntxs * (Ntags +1) +1: end, :);

    [D_CSI, R_CSI] = HDMIMO_ChannelEstimator(RxHDLTF, Ntxs, Ntags);

    [RxAmbientPayload_f, RxTagPayload_f] = HDMIMO_Demodulator(RxPayload_t, D_CSI, R_CSI);

    RxTagCombinedPayload_f = reshape(mean(RxTagPayload_f(DATA_INDEX, :, :), 1), [], Ntags);

    RxAmbientsTailBits = qamdemod(RxAmbientPayload_f, MCS_TAB.mod(MCSi), 'OutputType', 'bit', 'UnitAveragePower',true);

    RxAmbientBits = RxAmbientsTailBits(1: end - N_TAIL - Npad, :);

    RxTagTailBits = qamdemod(RxTagCombinedPayload_f, 2, 'OutputType', 'bit', 'UnitAveragePower',true);

    RxTagBits = RxTagTailBits(1: end - Ntp, :);
    
    
end

%% Transmission result
if SyncIndex == N_LTF * 2   % If sync is correct
    
    % BER
    AmbientErrorBits = xor(RxAmbientBits, TxBits);
    TagErrorBits = xor(RxTagBits, TagBits);
    AmbientBER = sum(sum(AmbientErrorBits)) / Nbits;
    
    clc;
    disp(['*********Transmission Result*********']);
    if AmbientBER == 0
        disp(['    Frame reception successful!']);
    else
        disp(['    Frame reception failed!']);
        disp(['    BER: ' num2str(AmbientBER)]);
    end
    disp(['*************************************']);
    
    figure; hold on;
    for itx = 1: Ntxs
        scatter(real(RxAmbientPayload_f(:, itx)), imag(RxAmbientPayload_f(:, itx)));
    end
    xlim([-2, 2]); ylim([-2, 2]);
    title(['RX payload constellation']);
    
    figure; hold on;
    for itx = 1: Ntags
        scatter(real(RxTagCombinedPayload_f(:, itx)), imag(RxTagCombinedPayload_f(:, itx)));
    end
    xlim([-2, 2]); ylim([-2, 2]);
    title(['Tag payload constellation']);
    
    figure;
    stem(AmbientErrorBits);
    title('Ambient error bits');
    
    figure;
    stem(TagErrorBits);
    title('Tag error bits');
else
    clc;

    disp(['*************************************']);
    disp(['Time synchronization error: Index = ' num2str(SyncIndex)]);
    disp(['*************************************']);
    figure;
    plot(abs(sum(SyncResults, 2)));
    title(["Time synchronization results"]);
end
