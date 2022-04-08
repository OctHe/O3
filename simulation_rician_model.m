%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% IEEE 802.11n/ac simulation on the Rician channel.
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
global N_CP N_LTF N_FFT N_LTFN N_DATA

MHz         = 1e6;          % 1MHz
Hz          = 1;

Nbits       = 8192;
MCSi        = 8;

Mod = MCS_TAB.mod(MCSi);
Nbps = log2(Mod) * N_DATA;

NO_CHANNEL = true;

%% Channel model
BW          = 20;                   % Bandwidth (20 MHz)
doppler     = 500 * Hz;             % Doppler shift is around 5 Hz
path_delays = [0, 0.05, 0.1] / MHz;
avg_gains   = [0, -20, -40];        % Average path gain in dB

rician = comm.RicianChannel(...
        'SampleRate', BW * MHz,...
        'PathDelays', path_delays,...
        'AveragePathGains', avg_gains,...
        'NormalizePathGains', true,...
        'DirectPathDopplerShift', doppler,...
        'PathGainsOutputPort', true);

%% Transmitter
BitsTX = randi(2, [Nbits, 1]) -1;

Npad = Nbps - mod(Nbits, Nbps);
BitsPadTX = [BitsTX; zeros(Npad, 1)];

[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(1);
ModDataTX = qammod(BitsPadTX, Mod, 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = IEEE80211ac_Modulator(ModDataTX);

FrameTX = [STF; LTF; DLTF; Payload_t];

%% Channel model
if NO_CHANNEL
    FrameRX = FrameTX;
else
    FrameRX = rician(FrameTX);
end

%% Receiver
[sync_results, LTF_index] = IEEE80211ac_SymbolSync(FrameRX, LTF(2*N_CP +1: end, 1));

if LTF_index == N_LTF * 2   % If sync is correct
    
    LTF_RX = FrameRX(LTF_index - N_LTF +1: LTF_index);
    DLTF_RX = FrameRX(LTF_index +1: LTF_index + (N_CP + N_FFT) * N_LTFN);
    Payload_RX_t = FrameRX(LTF_index + (N_CP + N_FFT) * N_LTFN +1: end);

    CSI = IEEE80211ac_ChannelEstimator(DLTF_RX, 1, 1);

    Payload_RX_f = IEEE80211ac_Demodulator(Payload_RX_t, CSI);

    BitsRX = qamdemod(Payload_RX_f, Mod, 'OutputType', 'bit', 'UnitAveragePower',true);
    BitsRX = BitsRX(1: end - Npad);

end

%% Transmission result
figure;
plot(abs(sync_results));
title('Correlation result');

if LTF_index == N_LTF * 2
    
    error_bits = xor(BitsRX, BitsTX);
    BER = sum(error_bits) / Nbits;

    figure; hold on; 
    plot(abs(LTF_RX(N_CP *2 +1: N_CP *2 + N_FFT)));
    plot(abs(LTF_RX(N_CP *2 + N_FFT +1: end)));
    title('Long preamble in the time domain');

    figure;
    subplot(211);
    plot(abs(CSI));
    title('CSI estimation abs');
    subplot(212);
    plot(angle(CSI));
    title('CSI estimation angle');

    figure; hold on;
    scatter(real(Payload_RX_f), imag(Payload_RX_f));
    title('Constellation of RX payload');

    clc;
    disp(['*********Rician Channel Model********']);
    disp(['    Path delays: [' num2str(path_delays) '] s']);
    disp(['    Path Gains: [' num2str(avg_gains) '] dB']);
    disp(['    Maximum Doppler shift: ' num2str(doppler) ' Hz']);
    disp(['*********Transmission Result*********']);
    disp(['    Packet length: ' num2str(length(FrameRX) / BW) ' us']);
    disp(['    Time synchronization successful!']);
    if BER == 0
        disp(['    Frame reception successful!']);
    else
        disp(['    Frame reception failed!']);
        disp(['    BER: ' num2str(BER)]);
    end
    
    figure;
    stem(error_bits);
    title('Error bits');
    
else
    clc;
    disp(['*************************************']);
    disp(['    Time synchronization error !']);
end
disp(['*************************************']);