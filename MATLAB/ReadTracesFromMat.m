function [SNRs_dB, CSI, TracesNums, Timestamps] = ReadTracesFromMat(FileName)
% Read traces from a specific mat file
% The mat file include Timestamps and linear csi (30 subcarriers)
% todo: output csi (64 subcarriers)

global N_SC N_CP 
global TONES_INDEX
global DEBUG

% GlobalVariables;


%% Read from file

load(FileName);

SNRs = mean(CSI .* conj(CSI), 1).';
SNRs_dB = db(SNRs);

TracesNums = size(SNRs_dB, 1);
