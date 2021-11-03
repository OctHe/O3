%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Fine time synchronization using long preambles with cross correlation
% OFDM_Frame_RX: column vector
% SyncResult: column vector; 
% PayloadIndex: long preamble w/o CP; scalar
%
% Copyright (C) 2021.11.03  Shiyue He (hsy1995313@gmail.com)
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
function [SyncResult, PayloadIndex] = OFDM_TimeSync(OFDM_Frame_RX)

global N_CP LONG_PREAMBLE_LEN

[~,  LongPreambleTX] = PreambleGenerator; 
LongPreambleTX = LongPreambleTX(2*N_CP+1: end);

SyncSize = LONG_PREAMBLE_LEN; 
SyncResult = zeros(size(OFDM_Frame_RX));
for index = SyncSize : size(OFDM_Frame_RX, 1)
    SyncResult(index, :) = LongPreambleTX' * OFDM_Frame_RX(index - SyncSize + 1: index, :);
end
SyncResult = SyncResult ./ (LongPreambleTX' * LongPreambleTX);    % Normalized to one
[~, PayloadIndex] = max(abs(SyncResult)); 



