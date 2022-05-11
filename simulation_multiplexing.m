%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MIMO (multiplexer) IEEE 802.11n/ac simulation
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
clear; close all;

%% Variables

global MCS_TAB
global N_CP N_LTF N_FFT N_LTFN N_DATA

MHz         = 1e6;          % 1MHz
Hz          = 1;

Nbits       = 8192;
MCSi        = 7;
Ntxs        = 4;
Nrxs        = Ntxs;

Mod = MCS_TAB.mod(MCSi);
Nbps = log2(Mod) * N_DATA;

NO_CHANNEL = false;

%% Channel model
BW          = 20;                   % Bandwidth (20 MHz)
doppler     = 50 * Hz;              % Doppler shift is around 5 Hz
path_delays = [0, 0.05, 0.1] / MHz;
avg_gains   = [0, -20, -40];        % Average path gain in dB

mimochannel = comm.MIMOChannel(...
        'SampleRate', BW * MHz,...
        'PathDelays', path_delays,...
        'AveragePathGains', avg_gains,...
        'NormalizePathGains', true,...
        'MaximumDopplerShift', doppler,...
        'SpatialCorrelationSpecification','None', ...
        'NumTransmitAntennas',Ntxs, ...
        'NumReceiveAntennas',Nrxs);

%% Transmitter
BitsTX = randi(2, [Nbits, Ntxs]) -1;

Npad = Nbps - mod(Nbits, Nbps);
BitsPadTX = [BitsTX; zeros(Npad, Ntxs)];

[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Ntxs);
ModDataTX = qammod(BitsPadTX, Mod, 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = IEEE80211ac_Modulator(ModDataTX);

FrameTX = [STF; LTF; DLTF; Payload_t];

%% Channel model
if NO_CHANNEL
    FrameRX = FrameTX;
else
    FrameRX = mimochannel(FrameTX);
end
%% Receiver
if NO_CHANNEL
    LTF_index = N_LTF * 2;
else
    [sync_results, LTF_index] = OFDM_SymbolSync(FrameRX, LTF(2*N_CP +1: end, 1), true);
end

if LTF_index == N_LTF * 2   % If sync is correct

    LTF_RX = FrameRX(LTF_index - N_LTF +1: LTF_index, :);
    DLTF_RX = FrameRX(LTF_index +1: LTF_index + (N_CP + N_FFT) * N_LTFN, :);
    Payload_RX_t = FrameRX(LTF_index + (N_CP + N_FFT) * N_LTFN +1: end, :);

    CSI = IEEE80211ac_ChannelEstimator(DLTF_RX, Ntxs, Nrxs);

    ModDataRX = IEEE80211ac_Demodulator(Payload_RX_t, CSI);

    BitsRX = qamdemod(ModDataRX, Mod, 'OutputType', 'bit', 'UnitAveragePower',true);
    BitsRX = BitsRX(1: end - Npad, :);
    
end

%% Transmission result
if LTF_index == N_LTF * 2   % If sync is correct
    
    % BER
    error_bits = xor(BitsRX, BitsTX);
    BER = sum(sum(error_bits)) / Nbits;
    
    clc;
    disp(['*********MIMO Channel Model********']);
    disp(['    Path delays: [' num2str(path_delays) '] s']);
    disp(['    Path Gains: [' num2str(avg_gains) '] dB']);
    disp(['    Maximum Doppler shift: ' num2str(doppler) ' Hz']);
    disp(['*********Transmission Result*********']);
    disp(['    Packet length: ' num2str(size(FrameRX, 1) / BW) ' us']);
    if BER == 0
        disp(['    Frame reception successful!']);
    else
        disp(['    Frame reception failed!']);
        disp(['    BER: ' num2str(BER)]);
    end
    disp(['*************************************']);

    figure;
    stem(error_bits);
    title('Error bits');
    
    % Channel
    figure;
    for itx = 1: Ntxs
    for irx = 1: Nrxs
        subplot(Ntxs , Nrxs, (itx -1) * Nrxs + irx);
        plot(abs(CSI(:, itx, irx)));
        title(['Amp (TX: ' num2str(itx) '; RX: ' num2str(irx) ')']);
    end
    end
    
    figure;
    for itx = 1: Ntxs
    for irx = 1: Nrxs
        subplot(Ntxs , Nrxs, (itx -1) * Nrxs + irx);
        plot(angle(CSI(:, irx, itx)));
        title(['Phase (TX: ' num2str(itx) '; RX: ' num2str(irx) ')']);
    end
    end
    
    figure;
    for itx = 1: Ntxs
        scatter(real(ModDataRX(:, itx)), imag(ModDataRX(:, itx)));
        title(['RX payload constellation (TX antenna ' num2str(itx) ')']);
    end
    
else
    clc;

    disp(['*************************************']);
    disp(['Time synchronization error: Index = ' num2str(LTF_index)]);
    disp(['*************************************']);
    figure;
    plot(abs(sum(sync_results, 2)));
    title(["Time synchronization results"]);
end
