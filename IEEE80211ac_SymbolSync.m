%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Fine time synchronization using LTF (without CP) with cross correlation
% RX_frame: RX Frame (column vector)
% sync_word: LTF without long CP (column vector)
% cros_results: cross-correlation results of RX_frame (column vector) 
% LTF_index: End index of the LTF
%
% Copyright (C) 2021-2022  Shiyue He (hsy1995313@gmail.com)
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
function [cros_results, LTF_index] = IEEE80211ac_SymbolSync(RX_frame, sync_word, refine)

global N_FFT

Nrxs = size(RX_frame, 2);

if nargin == 2
    refine = false;
end

%% Cross correlation
cros_results = zeros(size(RX_frame));
for rx = 1: Nrxs
    SyncSize = 2 * N_FFT; 
    
    for isamp = SyncSize : size(RX_frame, 1)
        cros_results(isamp, rx) = sync_word' * RX_frame(isamp - SyncSize + 1: isamp, rx);
    end

    % Normalized to one
    cros_results(:, rx) = cros_results(:, rx) ./ (sync_word' * sync_word);
    cros_results(:, rx) = abs(cros_results(:, rx)).^2;
end

cros_results = sum(cros_results, 2);

%% Refine time synchronization for MIMO setup
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