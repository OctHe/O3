%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Fine time synchronization using LTF (without CP) with cross correlation
% RX_frame: RX Frame (column vector)
% LTF: LTF without CP (column vector)
% sync_results: cross-correlation results of RX_frame (column vector) 
% LTF_index: symbol sync index (scalar)
%
% Copyright (C) 2021.12.12  Shiyue He (hsy1995313@gmail.com)
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
function [sync_results, LTF_index] = IEEE80211ac_SymbolSync(RX_frame, LTF)

global N_FFT

SyncSize = 2 * N_FFT; 
sync_results = zeros(size(RX_frame));
for index = SyncSize : size(RX_frame, 1)
    sync_results(index, :) = LTF' * RX_frame(index - SyncSize + 1: index, :);
end

% Normalized to one
sync_results = sync_results ./ (LTF' * LTF);
[~, LTF_index] = max(abs(sync_results)); 



