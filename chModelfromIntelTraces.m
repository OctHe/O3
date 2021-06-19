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
function [snr, tstamp] = chModelfromIntelTraces(csiFile, chModel, dur)

%% Trace params
load(csiFile);

s2us        = 1e6;

traceStart = csi_trace{1}.timestamp_low;
dur = dur + traceStart;

csi_num = size(csi_trace, 1);
tstamp = zeros(csi_num, 1);
snr_dB = zeros(csi_num, 3);   % 3 antennas for Intel 5300 card


%% CSI processing
traceDur = (csi_trace{end}.timestamp_low - csi_trace{1}.timestamp_low) / s2us;
disp(['Total trace duration: ' num2str(traceDur) ' s']);

for index = 1: csi_num
    
    tstamp(index) = csi_trace{index}.timestamp_low;
    
    csi_scaled = squeeze(get_scaled_csi(csi_trace{index}));
    
    snr_dB(index) = db(csi_scaled(1, 1));  % Choose one of the subcarriers

end

csi_index = find(tstamp > dur(1) & tstamp < dur(2));

%% Channel model
if chModel == "awgn"
    snr = snr_dB(csi_index);
    tstamp = (tstamp(csi_index) - traceStart) / s2us;
end



