%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Channel model generation from the collected traces. 
%   It only support single-antenna case.
%   dur: [start_time end_time] (us)
%   Interval: timestamp interval (us)
%   var: The params to remove the outliers
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function [snr, tstamp] = chModelfromTraces(csiFile, chModel, dur, var)

%% Trace params
load(csiFile);

fft_size    = 64;
BW          = 20e6;
SC_IND_DATA = [5:32 34:61];
noiseFloor  = -80;
s2us        = 1e6;

traceStart = csi{1}.timestamp;
dur = dur + traceStart;

%% Remove outliers
% In the single-antenna case, we extract the rssi from the first antenna
% So we use rssi1 in the trace
csi_num = 0;
rssi_base = csi{1}.rssi1;    % Compare with SNR base
for index = 1: size(csi, 1)
    
    if csi{index}.timestamp < dur(1) || csi{index}.timestamp > dur(2)
        continue;
    end
    
    if abs(csi{index}.rssi1 - rssi_base) > var
        continue;
    else
        csi_num = csi_num +1;
        csi_clear{csi_num} = csi{index};
        rssi_base = csi_clear{csi_num}.rssi1;
    end
    
  
end

%% CSI processing
tstamp = zeros(csi_num, 1);
rssi_dBm = zeros(csi_num, 1);
rssi_mW = zeros(csi_num, 1);
outputCSI_mW = zeros(fft_size, csi_num);
chResponse_mW = zeros(fft_size, csi_num);

for index = 1: csi_num
    
    tstamp(index) = csi_clear{index}.timestamp;
    
    rssi_dBm(index) = (csi_clear{index}.rssi1 -95);
    
    %% Normalization
    
    tstamp(index) = (tstamp(index) - traceStart);
    
    rssi_mW(index) = 10^(rssi_dBm(index) / 10);
    
    extractedCSI = reshape(csi_clear{index}.csi(1, 1, :), [], 1);
    outputCSI_mW(SC_IND_DATA, index) = extractedCSI * ...
        rssi_mW(index) / (extractedCSI' * extractedCSI);
    
    chResponse_mW(:, index) = fft(fftshift(outputCSI_mW(:, index)));
end

%% Channel model
if chModel == "awgn"
    snr = rssi_dBm - noiseFloor;
    
end

tstamp = tstamp / s2us;

% figure;
% plot(tstamp, snr);
% 
% figure;
% plot(abs(outputCSI_mW(:, 1:50)));
% 
% figure;
% plot(abs(chResponse_mW(:, 1:50)));
% 
% outputCSI_mW;