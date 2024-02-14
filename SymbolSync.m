%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Find the maximum value of the cross corrleation between the samples in
% the RxBuffer and sync_word. This is usually the fine time synchronization
% using time domain LTS
% RxBuffer: The received samples (column vector)
% sync_word: LTF without long CP (column vector)
% cros_results: cross-correlation results of RxBuffer (column vector) 
% LTF_index: End index of the LTF
%
% Copyright (C) 2021-2022, 2024 OctHe
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cros_results, LTF_index] = SymbolSync(RxBuffer, sync_word, refine)

global N_FFT

Nrxs = size(RxBuffer, 2);

if nargin == 2 || Nrxs == 1
    refine = false;
end

% Cross correlation
cros_results = zeros(size(RxBuffer));
for rx = 1: Nrxs
    SyncSize = 2 * N_FFT; 
    
    for isamp = SyncSize : size(RxBuffer, 1)
        cros_results(isamp, rx) = sync_word' * RxBuffer(isamp - SyncSize + 1: isamp, rx);
    end

    % Normalized to one
    cros_results(:, rx) = cros_results(:, rx) ./ (sync_word' * sync_word);
    cros_results(:, rx) = abs(cros_results(:, rx)).^2;
end

cros_results = sum(cros_results, 2);

% Refine time synchronization for MIMO setup
% Dong Wang, Jinyun Zhang. Timing Synchronization for MIMO-OFDM WLAN
% Systems. IEEE WCNC 2007.
% Two optimization variables for this algorithm
refine_window = 5;
MAX_CDD = 4;

refined_results = zeros(size(cros_results));
for isamp = 1: size(cros_results, 1) - refine_window -MAX_CDD
    refined_results(isamp) = ...
        sum(cros_results(isamp: isamp + refine_window -1)) - ...
        0.1 * sum(cros_results(isamp + MAX_CDD: isamp + MAX_CDD + refine_window -1));
end

if refine
    [~, LTF_index] = max(refined_results);
else
    [~, LTF_index] = max(cros_results);
end
