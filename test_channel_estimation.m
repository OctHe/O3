%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OFDM-MIMO channel estimation
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
Ntxs = 2;

%% Normalzied channel
H = exp(2j * pi * rand(Ntxs, Ntxs));

[~,  LTFtx, DLTF] = IEEE80211ac_PreambleGenerator(Ntxs); 

DLTFRX = zeros(size(DLTF));
for idltf = 1: size(DLTF, 1)
    DLTFRX(idltf, :) = (H * DLTF(idltf, :).').';
end

CSI = IEEE80211ac_ChannelEstimator(DLTFRX, Ntxs, Ntxs);
