%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Trace-driven simulation for IEEE 802.11ac rate adaptation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% Waveform configuration
cfgVHT = wlanVHTConfig;
cfgVHT.ChannelBandwidth = 'CBW160';     % 160 MHz channel bandwidth
cfgVHT.MCS = 0;                         % MCS = [0, ..., 9]
cfgVHT.APEPLength = 32767;              % APEP length in bytes

%% Simulation parameters
byte2Bits = 8;
s2us = 1e6;
sampRate = wlanSampleRate(cfgVHT);      % Sample rate in Hertz

traceFile = '/home/shiyue_deep/Desktop/csi.mat';

BITRATE = [58.5 117 175.5 234 351 468 526.5 585 702 780];
THR = [6.2 8.7 12.4 15.3 19.6 23.2 24.7 25.8 28];
RA_TYPE = "ra";  % fixed | ra

DEBUG = false;

traceDur = [20, 90];    % Trace duration

interval = 500; % Packet interval

%% Channel model from collected traces
[SNR, tstamp] = chModelfromTraces(traceFile, 'awgn', traceDur * s2us, 8);
traceNum = length(SNR);
if traceNum > 1
    DEBUG = false;
end

%% Processing Chain
estimatedSNR = zeros(traceNum, 1);
throughput = zeros(traceNum, 1);
errorPktInd = zeros(traceNum, 1);
for pktIndex = 1: traceNum
    
    %% Generate a single packet waveform
    
    txPSDU = randi([0,1], byte2Bits*cfgVHT.PSDULength, 1 ,'int8');
    
    txWave = wlanWaveformGenerator(txPSDU, cfgVHT);
    
    packetLength = size(txWave,1) / sampRate; % Length of the packet in seconds
    
    if DEBUG
        figure;
        plot(abs(txWave));
        xlabel('Sample Index')
        ylabel('Abs')
        title('TX wave')
    end
    
    %% Channel model: Trace-driven model
    % Pass the waveform through the fading channel model
    rxWave = awgn(txWave, SNR(pktIndex), 'measured');

    %% Get the OFDM info
    ofdmInfo = wlanVHTOFDMInfo('VHT-Data', cfgVHT);
    rxWaveformLength = size(rxWave,1); % Length of the received waveform
    
    fieldInd = wlanFieldIndices(cfgVHT); % Get field indices

    %% Packet detecgtion
    pktOffset = wlanPacketDetect(rxWave, cfgVHT.ChannelBandwidth);

    if ~isempty(pktOffset) % If packet detected

        %% Fine time synchronization
        LLTFSearchBuffer = rxWave(pktOffset+(fieldInd.LSTF(1): fieldInd.LSIG(2)), :);
        
        finePktOffset = wlanSymbolTimingEstimate(LLTFSearchBuffer, cfgVHT.ChannelBandwidth);

        pktOffset = pktOffset+finePktOffset;

        %% Channel estimation
        VHTLTF = rxWave(pktOffset+(fieldInd.VHTLTF(1):fieldInd.VHTLTF(2)),:);
        demodVHTLTF = wlanVHTLTFDemodulate(VHTLTF, cfgVHT);
        chanEstVHTLTF = wlanVHTLTFChannelEstimate(demodVHTLTF, cfgVHT);

        %% Demodulation and decoding of the VHT data field
        vhtdata = rxWave(pktOffset+(fieldInd.VHTData(1):fieldInd.VHTData(2)), :);
        chanEstSSPilots = vhtSingleStreamChannelEstimate(demodVHTLTF,cfgVHT);
        noiseVarVHT = vhtNoiseEstimate(vhtdata,chanEstSSPilots,cfgVHT);

        [rxPSDU,~,eqDataSym] = wlanVHTDataRecover(vhtdata, chanEstVHTLTF, noiseVarVHT, cfgVHT);
        
        %% Transmission result
        pkt_mcs = cfgVHT.MCS;
        [~,ber] = biterr(rxPSDU, txPSDU);
        if ber == 0
            throughput(pktIndex) = BITRATE(pkt_mcs+1);

        else
            throughput(pktIndex) = 0;
            errorPktInd(pktIndex) = 1;

        end
        
        %% Rate adaptation algorithm
        powVHTLTF = mean(VHTLTF.*conj(VHTLTF));
        estSigPower = powVHTLTF-noiseVarVHT +1;
        estimatedSNR(pktIndex) = 10*log10(mean(estSigPower./noiseVarVHT));
                
        if RA_TYPE == "fixed"
            cfgVHT.MCS = 6;
        elseif RA_TYPE == "ra"
            cfgVHT.MCS = sum(estimatedSNR(pktIndex) > THR);
        else
            error('Please choose a rate adatpation with RA_TYPE');
        end
        
    end
    
   %% Real-time display
    clc;
    disp(['*******************TX INFO*******************']);
    disp(['Packet index:            ' num2str(pktIndex)]);
    disp(['Bitrate:                 ' num2str(BITRATE(pkt_mcs+1)) ' Mbps']);
    disp(['Selected MCS:            ' num2str(pkt_mcs)]);
    disp(['Packet length:           ' num2str(s2us * packetLength) ' us']);
    
    disp(['*******************CH INFO*******************']);
    disp(['SNR of the model:        ' num2str(SNR(pktIndex)) ' dB']);
    
    disp(['*******************RX INFO*******************']);
    disp(['BER of this packet:      ' num2str(ber)]);
    disp(['Estimated SNR:           ' num2str(estimatedSNR(pktIndex)) ' dB']);
    disp(['Number of error packets: ' num2str(sum(errorPktInd))]);
    disp(['Average throughput:      ' num2str(sum(throughput)/pktIndex) ' Mbps']);
    
    disp(['*********************************************']);
end % Processing chain

%% Simulation results
figure; hold on;
plot(tstamp, SNR);
plot(tstamp, estimatedSNR);
xlabel('Time (s)');
ylabel('SNR (dB)');
legend('SNR for the trace', 'Estimated SNR');
title('SNR');

figure;
subplot(211);
plot(throughput);
xlabel('Packet index');
ylabel('Throughput (Mbps)');
title('Throughput for each packet');
subplot(212);
stem(errorPktInd);
xlabel('Packet index');
ylabel('Error packet (1)');
title('Index of error packets');