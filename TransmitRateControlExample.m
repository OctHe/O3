%% 802.11 Dynamic Rate Control Simulation
%
% This example shows dynamic rate control by varying the Modulation and
% Coding scheme (MCS) of successive packets transmitted over a frequency
% selective multipath fading channel.

% Copyright 2016-2019 The MathWorks, Inc.

%% Introduction
% The IEEE(R) 802.11(TM) standard supports dynamic rate control by
% adjusting the MCS value of each transmitted packet based on the
% underlying radio propagation channel. Maximizing link throughput, in a
% propagation channel that is time varying due to multipath fading or
% movement of the surrounding objects, requires dynamic variation of MCS.
% The IEEE 802.11 standard does not define any standardized rate control
% algorithm (RCA) for dynamically varying the modulation rate. The
% implementation of RCA is left open to the WLAN device manufacturers. This
% example uses a closed-loop rate control scheme. A recommended MCS for
% transmitting a packet is calculated at the receiver and is available at
% the transmitter without any feedback latency. In a real system this
% information would be conveyed through a control frame exchange. The MCS
% is adjusted for each subsequent packet in response to an evolving channel
% condition with noise power varying over time.
%
% In this example, an IEEE 802.11ac(TM) [ <#11 1> ] waveform consisting of
% a single VHT format packet is generated using
% <matlab:doc('wlanWaveformGenerator') wlanWaveformGenerator>. The waveform
% is passed through a TGac channel and noise is added. The packet is
% synchronized and decoded to recover the PSDU. The SNR is estimated and
% compared against thresholds to determine which MCS is suitable for
% transmission of the next packet. This figure shows the processing for
% each packet.
%
% <<../RCAschematic.png>>
%
%% Waveform Configuration
% An IEEE 802.11ac VHT transmission is simulated in this example. The VHT
% waveform properties are specified in a <matlab:doc('wlanVHTConfig')
% wlanVHTConfig> configuration object. In this example the object is
% initially configured for a 40 MHz channel bandwidth, single transmit
% antenna and QPSK rate-1/2 (MCS 1). The MCS for the subsequent packets
% is changed by the algorithm throughout the simulation.

cfgVHT = wlanVHTConfig;         
cfgVHT.ChannelBandwidth = 'CBW160'; % 40 MHz channel bandwidth
cfgVHT.MCS = 1;                    % QPSK rate-1/2
cfgVHT.APEPLength = 4096;          % APEP length in bytes

% Set random stream for repeatability of results
s = rng(21);

%% Channel Configuration
% In this example a TGac N-LOS channel model is used with delay profile
% Model-D. For Model-D when the distance between the transmitter and
% receiver is greater than or equal to 10 meters, the model is NLOS. This
% is described further in <matlab:doc('wlanTGacChannel') wlanTGacChannel>.

tgacChannel = wlanTGacChannel;
tgacChannel.DelayProfile = 'Model-D';
tgacChannel.ChannelBandwidth = cfgVHT.ChannelBandwidth;
tgacChannel.NumTransmitAntennas = 1;
tgacChannel.NumReceiveAntennas = 1;
tgacChannel.TransmitReceiveDistance = 20; % Distance in meters for NLOS
tgacChannel.RandomStream = 'mt19937ar with seed';
tgacChannel.Seed = 0;

% Set the sampling rate for the channel
sr = wlanSampleRate(cfgVHT);
tgacChannel.SampleRate = sr;

%% Rate Control Algorithm Parameters
% Typically RCAs use channel quality or link performance metrics, such as
% SNR or packet error rate, for rate selection. The RCA presented in this
% example estimates the SNR of a received packet. On reception, the
% estimated SNR is compared against a predefined threshold. If the SNR
% exceeds the predefined threshold then a new MCS is selected for
% transmitting the next packet. The |rcaAttack| and |rcaRelease| controls
% smooth rate changes to avoid changing rates prematurely. The SNR must
% exceed the |threshold| + |rcaAttack| value to increase the MCS and must
% be under the |threshold| - |rcaRelease| value to decrease the MCS. In
% this simulation |rcaAttack| and |rcaRelease| are set to conservatively
% increase the MCS and aggressively reduce it. For the |threshold| values
% selected for the scenario simulated in this example, a small number of
% packet errors are expected. These settings may not be suitable for other
% scenarios.

rcaAttack = 1;  % Control the sensitivity when MCS is increasing
rcaRelease = 0; % Control the sensitivity when MCS is decreasing
threshold = [11 14 19 20 25 28 30 31 35]; 
snrUp = [threshold inf]+rcaAttack;
snrDown = [-inf threshold]-rcaRelease;
snrInd = cfgVHT.MCS; % Store the start MCS value

%% Simulation Parameters
% In this simulation |numPackets| packets are transmitted through a TGac
% channel, separated by a fixed idle time. The channel state is maintained
% throughout the simulation, therefore the channel evolves slowly over
% time. This evolution slowly changes the resulting SNR measured at the
% receiver. Since the TGac channel changes very slowly over time, here an
% SNR variation at the receiver visible over a short simulation can be
% forced using the |walkSNR| parameter to modify the noise power:
%
% # Setting |walkSNR| to true generates a varying SNR by randomly setting
% the noise power per packet during transmission. The SNR walks between
% 14-33 dB (using the |amplitude| and |meanSNR| variables).
% # Setting |walkSNR| to false fixes the noise power applied to the
% received waveform, so that channel variations are the main source of SNR
% changes at the receiver.

numPackets = 100; % Number of packets transmitted during the simulation 
walkSNR = true; 

% Select SNR for the simulation
if walkSNR
    meanSNR = 22;   % Mean SNR
    amplitude = 14; % Variation in SNR around the average mean SNR value
    % Generate varying SNR values for each transmitted packet
    baseSNR = sin(linspace(1,10,numPackets))*amplitude+meanSNR;
    snrWalk = baseSNR(1); % Set the initial SNR value
    % The maxJump controls the maximum SNR difference between one
    % packet and the next 
    maxJump = 0.5;
else
    % Fixed mean SNR value for each transmitted packet. All the variability
    % in SNR comes from a time varying radio channel
    snrWalk = 22; %#ok<UNRCH>
end

% To plot the equalized constellation for each spatial stream set
% displayConstellation to true
displayConstellation = false;
if displayConstellation
    ConstellationDiagram = comm.ConstellationDiagram; %#ok<UNRCH>
    ConstellationDiagram.ShowGrid = true;
    ConstellationDiagram.Name = 'Equalized data symbols';
end

% Define simulation variables
snrMeasured = zeros(1,numPackets);
MCS = zeros(1,numPackets);
ber = zeros(1,numPackets);
packetLength = zeros(1,numPackets);

%% Processing Chain
% The following processing steps occur for each packet:
%
% # A PSDU is created and encoded to create a single packet waveform.
% # A fixed idle time is added between successive packets.
% # The waveform is passed through an evolving TGac channel.
% # AWGN is added to the transmitted waveform to create the desired average
% SNR per subcarrier.
% # This local function |processPacket| passes the transmitted waveform
% through the TGac channel, performs receiver processing, and SNR
% estimation.
% # The VHT-LTF is extracted from the received waveform. The VHT-LTF is
% OFDM demodulated and channel estimation is performed.
% # The VHT Data field is extracted from the synchronized received
% waveform.
% # Noise estimation is performed using the demodulated data field pilots
% and single-stream channel estimate at pilot subcarriers.
% # The estimated SNR for each packet is compared against the threshold,
% the comparison is used to adjust the MCS for the next packet.
% # The PSDU is recovered using the extracted VHT-Data field.

%%
% For simplicity, this example assumes:
%
% # Fixed bandwidth and antenna configuration for each transmitted packet.
% # There is no explicit feedback packet to inform the transmitter about
% the suggested MCS setting for the next packet. The example assumes that
% this information is known to the transmitter before transmitting the
% subsequent packet.
% # Fixed idle time of 0.5 milliseconds between packets.

for numPkt = 1:numPackets 
    if walkSNR
        % Generate SNR value per packet using random walk algorithm biased
        % towards the mean SNR
        snrWalk = 0.9*snrWalk+0.1*baseSNR(numPkt)+rand(1)*maxJump*2-maxJump;
    end
    
    % Generate a single packet waveform
    txPSDU = randi([0,1],8*cfgVHT.PSDULength,1,'int8');
    txWave = wlanWaveformGenerator(txPSDU,cfgVHT,'IdleTime',5e-4);
    
    % Receive processing, including SNR estimation
    y = processPacket(txWave,snrWalk,tgacChannel,cfgVHT);
    
    % Plot equalized symbols of data carrying subcarriers
    if displayConstellation && ~isempty(y.EstimatedSNR)
        release(ConstellationDiagram);
        ConstellationDiagram.ReferenceConstellation = wlanReferenceSymbols(cfgVHT);
        ConstellationDiagram.Title = ['Packet ' int2str(numPkt)];
        ConstellationDiagram(y.EqDataSym(:));
        drawnow 
    end
    
    % Store estimated SNR value for each packet
    if isempty(y.EstimatedSNR) 
        snrMeasured(1,numPkt) = NaN;
    else
        snrMeasured(1,numPkt) = y.EstimatedSNR;
    end
    
    % Determine the length of the packet in seconds including idle time
    packetLength(numPkt) = y.RxWaveformLength/sr;
    
    % Calculate packet error rate (PER)
    if isempty(y.RxPSDU)
        % Set the PER of an undetected packet to NaN
        ber(numPkt) = NaN;
    else
        [~,ber(numPkt)] = biterr(y.RxPSDU,txPSDU);
    end

    % Compare the estimated SNR to the threshold, and adjust the MCS value
    % used for the next packet
    MCS(numPkt) = cfgVHT.MCS; % Store current MCS value
    increaseMCS = (mean(y.EstimatedSNR) > snrUp((snrInd==0)+snrInd));
    decreaseMCS = (mean(y.EstimatedSNR) <= snrDown((snrInd==0)+snrInd));
    snrInd = snrInd+increaseMCS-decreaseMCS;
    cfgVHT.MCS = snrInd-1;
end

%% Display and Plot Simulation Results
% This example plots the variation of MCS, SNR, BER, and data throughput
% over the duration of the simulation.
% 
% # The MCS used to transmit each packet is plotted. When compared to the
% estimated SNR, you can see the MCS selection is dependent on the
% estimated SNR.
% # The bit error rate per packet depends on the channel conditions, SNR,
% and MCS used for transmission.
% # The throughput is maximized by varying the MCS according to the channel
% conditions. The throughput is calculated using a sliding window of three
% packets. For each point plotted, the throughput is the number of data
% bits, successfully recovered over the duration of three packets. The
% length of the sliding window can be increased to further smooth the
% throughput. You can see drops in the throughput either when the MCS
% decreases or when a packet error occurs.

% Display and plot simulation results
disp(['Overall data rate: ' num2str(8*cfgVHT.APEPLength*(numPackets-numel(find(ber)))/sum(packetLength)/1e6) ' Mbps']);
disp(['Overall packet error rate: ' num2str(numel(find(ber))/numPackets)]);

plotResults(ber,packetLength,snrMeasured,MCS,cfgVHT);

% Restore default stream
rng(s);

%% Conclusion and Further Exploration
% This example uses a closed-loop rate control scheme where knowledge of
% the MCS used for subsequent packet transmission is assumed to be
% available to the transmitter.
%
% In this example the variation in MCS over time due to the received SNR is
% controlled by the |threshold|, |rcaAttack| and |rcaRelease| parameters.
% The |rcaAttack| and |rcaRelease| are used as controls to smooth the rate
% changes, this is to avoid changing rates prematurely. Try changing the
% |rcaRelease| control to two. In this case, the decrease in MCS is slower
% to react when channel conditions are not good, resulting in higher BER.
%
% Try setting the |displayConstellation| to true in order to plot the
% equalized symbols per received packet, you can see the modulation scheme
% changing over time. Also try setting |walkSNR| to false in order to
% visualize the MCS change per packet. Here the variability in SNR is only
% caused by the radio channel, rather than the combination of channel and
% random walk.
%
% Further exploration includes using an alternate RCA scheme, more
% realistic MCS variation including changing number of space time streams,
% packet size and enabling STBC for subsequent transmitted packets.

%% Appendix
% This example uses the following helper functions:
%
% * <matlab:edit('vhtNoiseEstimate.m') vhtNoiseEstimate.m>
% * <matlab:edit('vhtSingleStreamChannelEstimate.m') vhtSingleStreamChannelEstimate.m>

%% Selected Bibliography
% # IEEE Std 802.11ac(TM)-2013 IEEE Standard for Information technology -
% Telecommunications and information exchange between systems - Local and
% metropolitan area networks - Specific requirements - Part 11: Wireless
% LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications -
% Amendment 4: Enhancements for Very High Throughput for Operation in Bands
% below 6 GHz.

%% Local Functions
% The following local functions are used in this example:
%
% * |processPacket|: Add channel impairments and decode receive packet
% * |plotResults|: Plot the simulation results



function Y = processPacket(txWave,snrWalk,tgacChannel,cfgVHT)
    % Pass the transmitted waveform through the channel, perform
    % receiver processing, and SNR estimation.
    
    chanBW = cfgVHT.ChannelBandwidth; % Channel bandwidth
    % Set the following parameters to empty for an undetected packet
    estimatedSNR = [];
    eqDataSym = [];
    noiseVarVHT = [];
    rxPSDU = [];
    
    % Get the OFDM info
    ofdmInfo = wlanVHTOFDMInfo('VHT-Data',cfgVHT);
    
    % Pass the waveform through the fading channel model
    rxWave = tgacChannel(txWave);
    
    % Create an instance of the AWGN channel for each transmitted packet
    awgnChannel = comm.AWGNChannel;
    awgnChannel.NoiseMethod = 'Signal to noise ratio (SNR)';
    % Normalization
    awgnChannel.SignalPower = 1/tgacChannel.NumReceiveAntennas;
    % Account for energy in nulls
    awgnChannel.SNR = snrWalk-10*log10(ofdmInfo.FFTLength/ofdmInfo.NumTones);
    
    % Add noise
    rxWave = awgnChannel(rxWave);
    rxWaveformLength = size(rxWave,1); % Length of the received waveform
    
    % Recover packet
    ind = wlanFieldIndices(cfgVHT); % Get field indices
    pktOffset = wlanPacketDetect(rxWave,chanBW); % Detect packet
    
    if ~isempty(pktOffset) % If packet detected
        % Extract the L-LTF field for fine timing synchronization
        LLTFSearchBuffer = rxWave(pktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
    
        % Start index of L-LTF field
        finePktOffset = wlanSymbolTimingEstimate(LLTFSearchBuffer,chanBW);
     
        % Determine final packet offset
        pktOffset = pktOffset+finePktOffset;
        
        if pktOffset<15 % If synchronization successful
            % Extract VHT-LTF samples from the waveform, demodulate and
            % perform channel estimation
            VHTLTF = rxWave(pktOffset+(ind.VHTLTF(1):ind.VHTLTF(2)),:);
            demodVHTLTF = wlanVHTLTFDemodulate(VHTLTF,cfgVHT);
            chanEstVHTLTF = wlanVHTLTFChannelEstimate(demodVHTLTF,cfgVHT);
            
            % Get single stream channel estimate
            chanEstSSPilots = vhtSingleStreamChannelEstimate(demodVHTLTF,cfgVHT);
            
            % Extract VHT data field
            vhtdata = rxWave(pktOffset+(ind.VHTData(1):ind.VHTData(2)),:);
            
            % Estimate the noise power in VHT data field
            noiseVarVHT = vhtNoiseEstimate(vhtdata,chanEstSSPilots,cfgVHT);
            
            % Recover equalized symbols at data carrying subcarriers using
            % channel estimates from VHT-LTF
            [rxPSDU,~,eqDataSym] = wlanVHTDataRecover(vhtdata,chanEstVHTLTF,noiseVarVHT,cfgVHT);
            
            % SNR estimation per receive antenna
            powVHTLTF = mean(VHTLTF.*conj(VHTLTF));
            estSigPower = powVHTLTF-noiseVarVHT;
            estimatedSNR = 10*log10(mean(estSigPower./noiseVarVHT));
        end
    end
    
    % Set output
    Y = struct( ...
        'RxPSDU',           rxPSDU, ...
        'EqDataSym',        eqDataSym, ...
        'RxWaveformLength', rxWaveformLength, ...
        'NoiseVar',         noiseVarVHT, ...
        'EstimatedSNR',     estimatedSNR);
    
end

function plotResults(ber,packetLength,snrMeasured,MCS,cfgVHT)
    % Visualize simulation results

    figure('Outerposition',[50 50 900 700])
    subplot(4,1,1);
    plot(MCS);
    xlabel('Packet Number')
    ylabel('MCS')
    title('MCS selected for transmission')

    subplot(4,1,2);
    plot(snrMeasured);
    xlabel('Packet Number')
    ylabel('SNR')
    title('Estimated SNR')

    subplot(4,1,3);
    plot(find(ber==0),ber(ber==0),'x') 
    hold on; stem(find(ber>0),ber(ber>0),'or') 
    if any(ber)
        legend('Successful decode','Unsuccessful decode') 
    else
        legend('Successful decode') 
    end
    xlabel('Packet Number')
    ylabel('BER')
    title('Instantaneous bit error rate per packet')

    subplot(4,1,4);
    windowLength = 3; % Length of the averaging window
    movDataRate = movsum(8*cfgVHT.APEPLength.*(ber==0),windowLength)./movsum(packetLength,windowLength)/1e6;
    plot(movDataRate)
    xlabel('Packet Number')
    ylabel('Mbps')
    title(sprintf('Throughput over last %d packets',windowLength))
    
end
