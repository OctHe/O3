%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Trace-driven simulation for IEEE 802.11ac rate adaptation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;

%% Waveform configuration
cfgVHT = wlanVHTConfig;
cfgVHT.ChannelBandwidth = 'CBW160';     % 160 MHz channel bandwidth
cfgVHT.MCS = 0;                         % MCS = [0, ..., 9]
cfgVHT.APEPLength = 2^13-1;             % APEP length in bytes

sampRate    = wlanSampleRate(cfgVHT);	% Sample rate in Hertz

%% Simulation parameters
traceFile   = '/home/shiyue_deep/Desktop/csi_trace.mat';
THR         = [6.2 8.7 12.4 15.3 19.6 23.2 24.7 25.8 28];
BITRATE = [58.5 117 175.5 234 351 468 526.5 585 702 780];
traceDur    = [120, 140];       % Trace duration
interval    = 500;              % Packet interval
RA_TYPE     = "ra";             % fixed | ra

BYTE2BIT    = 8;        % 1 Byte = 8 bits
S2US        = 1e6;      % 1s = 1e6 us

DEBUG = false;

%% Channel model from collected traces
disp('Loading the collected traces ...');

[SNR, tstamp] = chModelfromIntelTraces(traceFile, 'awgn', traceDur * S2US);
traceNum = size(SNR, 1);
if traceNum > 1
    DEBUG = false;
end
pktInterval = (tstamp(2: end) - tstamp(1: end-1)) * S2US;

%% Processing Chain
estimatedSNR = zeros(traceNum, 1);
ber = zeros(traceNum, 1);
throughput = zeros(traceNum, 1);
errorPktInd = zeros(traceNum, 1);
transDelay = zeros(traceNum, 1);    % Time delay of error packet is 0
DelayEachPkt = 0;              % Time delay of each packet
for pktIndex = 1: traceNum
    
    %% Generate a single packet waveform
    txPSDU = randi([0,1], BYTE2BIT*cfgVHT.PSDULength, 1 ,'int8');
    txWave = wlanWaveformGenerator(txPSDU, cfgVHT);
    
    packetLength = size(txWave,1) / sampRate * S2US; % Packet length in us
    pkt_mcs = cfgVHT.MCS;
    
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

    %% Packet detection
    pktOffset = wlanPacketDetect(rxWave, cfgVHT.ChannelBandwidth);
    
    if ~isempty(pktOffset) % If packet is detected

        %% Fine time synchronization
        LLTFSearchBuffer = rxWave(pktOffset+(fieldInd.LSTF(1): fieldInd.LSIG(2)), :);
        finePktOffset = wlanSymbolTimingEstimate(LLTFSearchBuffer, cfgVHT.ChannelBandwidth);
        pktOffset = pktOffset+finePktOffset;
        
        if pktOffset == 0
            %% Channel estimation
            VHTLTF = rxWave(pktOffset+(fieldInd.VHTLTF(1):fieldInd.VHTLTF(2)),:);
            demodVHTLTF = wlanVHTLTFDemodulate(VHTLTF, cfgVHT);
            chanEstVHTLTF = wlanVHTLTFChannelEstimate(demodVHTLTF, cfgVHT);

            %% Demodulation and decoding of the VHT data field
            vhtdata = rxWave(pktOffset+(fieldInd.VHTData(1):fieldInd.VHTData(2)), :);
            chanEstSSPilots = vhtSingleStreamChannelEstimate(demodVHTLTF,cfgVHT);
            noiseVarVHT = vhtNoiseEstimate(vhtdata,chanEstSSPilots,cfgVHT);

            [rxPSDU,~,eqDataSym] = wlanVHTDataRecover(vhtdata, chanEstVHTLTF, noiseVarVHT, cfgVHT);

            %% Transmission recording
            [~,ber(pktIndex)] = biterr(rxPSDU, txPSDU);
            if ber(pktIndex) ~= 0
                errorPktInd(pktIndex) = 1;  % Decoding error

            end
           %% Rate adaptation algorithm
            powVHTLTF = mean(VHTLTF.*conj(VHTLTF));
            estSigPower = powVHTLTF-noiseVarVHT +1;
            estimatedSNR(pktIndex) = 10*log10(mean(estSigPower./noiseVarVHT));
            if RA_TYPE == "fixed"
                cfgVHT.MCS = 3;
            elseif RA_TYPE == "ra"
                cfgVHT.MCS = sum(estimatedSNR(pktIndex) > THR);
            else
                error('Please choose a rate adatpation with RA_TYPE');
            end
            
        else
            errorPktInd(pktIndex) = 3;  % Time sync error
            
        end
        
    else
        errorPktInd(pktIndex) = 2;  % Packet is not detected
        
    end
    

   %% Transmission results
    if errorPktInd(pktIndex) == 0
        throughput(pktIndex) = BITRATE(pkt_mcs+1);
        transDelay(pktIndex) = DelayEachPkt + packetLength;
        DelayEachPkt = 0;

    else
        throughput(pktIndex) = 0;
        transDelay(pktIndex) = 0;
        if pktIndex < traceNum
            DelayEachPkt = DelayEachPkt + pktInterval(pktIndex);
        end
        
    end
    correctPkt = pktIndex - length(find(errorPktInd ~= 0));
    averageDelay = sum(transDelay) / correctPkt;
    averageTpt = sum(throughput)/pktIndex;
        
   %% Real-time display
    clc;
    disp(['*********************TX INFO*********************']);
    disp(['Bitrate:                     ' num2str(BITRATE(pkt_mcs+1)) ' Mbps']);
    disp(['Selected MCS:                ' num2str(pkt_mcs)]);
    disp(['Packet length:               ' num2str(packetLength) ' us']);
    
    disp(['*********************CH INFO*********************']);
    disp(['SNR of the model:            ' num2str(SNR(pktIndex)) ' dB']);
    disp(['Traces:                      ' num2str(pktIndex) '/' num2str(traceNum)]);
    if pktIndex < traceNum
        disp(['Next frame moment:           ' num2str(pktInterval(pktIndex)) ' us']);
    else
        disp(['Next frame moment:           ' 'NaN' ' us']);
    end
    
    disp(['*********************RX INFO*********************']);
    disp(['Estimated SNR:               ' num2str(estimatedSNR(pktIndex)) ' dB']);
    disp(['Average delay:               ' num2str(averageDelay) ' us']);
    disp(['Average throughput:          ' num2str(averageTpt) ' Mbps']);
    
    disp(['*************************************************']);
    
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
subplot(311);
plot(throughput);
xlabel('Packet index');
ylabel('Throughput (Mbps)');
title('Throughput of each packet');
subplot(312);
stem(ber);
xlabel('Packet index');
ylabel('BER');
title('BER of each packets');
subplot(313);
stem(errorPktInd);
xlabel('Packet index');
ylabel('Error packet (1)');
title('Index of error packets');