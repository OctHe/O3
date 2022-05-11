%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Convolutional coding/decoding
%
% Copyright (C) 2022  Shiyue He (hsy1995313@gmail.com)
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
clear;
close all;

%% Variables
Ndata = 234;

global MCS_TAB MAX_MCS N_TAIL

%% Modulation and demodulation
for MCS_Index = 1: MAX_MCS
    
    DataTX = randi(2, [Ndata, 1]) -1;
    TailDataTX = [DataTX; zeros(N_TAIL, 1)];
    
    EncodedData = IEEE80211ac_ConvolutionalEncoder(TailDataTX, MCS_TAB.rate(MCS_Index));
    TailDataRX = IEEE80211ac_ConvolutionalDecoder(EncodedData, MCS_TAB.rate(MCS_Index));
    DataRX = TailDataRX(1: end - N_TAIL);
    
    %% Error symbol
    BER = sum(DataRX ~= DataTX) / Ndata;
    
    if BER == 0
        disp(['Convolutional encoder/decoder correct! (Code rate == ' num2str(MCS_TAB.rate(MCS_Index)) ')']);
    else
        disp(['Symbol Errors:' num2str(BER) ' (Code rate == ' num2str(MCS_TAB.rate(MCS_Index)) ')']);
        
        figure;
        stem(DataRX ~= DataTX);
        title(['Error bit position' ' (Code rate == ' num2str(MCS_TAB.rate(MCS_Index)) ')']);
    end
end
