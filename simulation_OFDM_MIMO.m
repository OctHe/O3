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
MCSi        = 4;
Ntxs        = 1;
Nrxs        = Ntxs;

Mod = MCS_TAB.mod(MCSi);
Nbps = log2(Mod) * N_DATA;

NO_CHANNEL = false;

%% Channel model
BW          = 20;                   % Bandwidth (20 MHz)
doppler     = 90 * Hz;              % Doppler shift is around 5 Hz
path_delays = [0] / MHz;
avg_gains   = [0];        % Average path gain in dB

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
TxBits = randi(2, [Nbits, Ntxs]) -1;

Npad = Nbps - mod(Nbits, Nbps);
TxPadBits = [TxBits; zeros(Npad, Ntxs)];

[STF, LTF, DLTF] = OFDM_PreambleGenerator(Ntxs);
TxModData = qammod(TxPadBits, Mod, 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = OFDM_Modulator(TxModData);

TxFrame = [STF; LTF; DLTF; Payload_t];

%% Channel model
if NO_CHANNEL
    RxFrame = TxFrame;
else
    RxFrame = mimochannel(TxFrame);
end

%% Receiver
if NO_CHANNEL
    LTF_index = N_LTF * 2;
else
    [sync_results, LTF_index] = OFDM_SymbolSync(RxFrame, LTF(2*N_CP +1: end, Nrxs), true);
end

if LTF_index == N_LTF * 2   % If sync is correct

    RxDLTF = RxFrame(LTF_index +1: LTF_index + (N_CP + N_FFT) * N_LTFN, :);
    RxPayload_t = RxFrame(LTF_index + (N_CP + N_FFT) * N_LTFN +1: end, :);

    CSI = OFDM_ChannelEstimator(RxDLTF, Ntxs, Nrxs);

    RxModData = OFDM_Demodulator(RxPayload_t, CSI);

    RxPadBits = qamdemod(RxModData, Mod, 'OutputType', 'bit', 'UnitAveragePower',true);
    RxBits = RxPadBits(1: end - Npad, :);
    
end

%% Transmission result
if LTF_index == N_LTF * 2   % If sync is correct
    
    % BER
    error_bits = xor(RxBits, TxBits);
    BER = sum(sum(error_bits)) / Nbits;
    
    clc;
    disp(['*********MIMO Channel Model********']);
    disp(['    Path delays: [' num2str(path_delays) '] s']);
    disp(['    Path Gains: [' num2str(avg_gains) '] dB']);
    disp(['    Maximum Doppler shift: ' num2str(doppler) ' Hz']);
    disp(['*********Transmission Result*********']);
    disp(['    Packet length: ' num2str(size(RxFrame, 1) / BW) ' us']);
    if BER == 0
        disp(['    Frame reception successful!']);
    else
        disp(['    Frame reception failed!']);
        disp(['    BER: ' num2str(BER)]);
    end
    disp(['*************************************']);

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
    
    
    for itx = 1: Ntxs
        figure;
        scatter(real(RxModData(:, itx)), imag(RxModData(:, itx)));
        xlim([-2, 2]); ylim([-2, 2]);
        title(['RX payload constellation (TX antenna ' num2str(itx) ')']);
    end
    
    figure;
    stem(error_bits);
    title('Error bits');
    
else
    clc;

    disp(['*************************************']);
    disp(['Time synchronization error: Index = ' num2str(LTF_index)]);
    disp(['*************************************']);
    figure;
    plot(abs(sum(sync_results, 2)));
    title(["Time synchronization results"]);
end
