%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% BLE modulation
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
clear; close all;

%% Variables
Nbits = 4;
Preamble = repmat([1; 0], 4, 1);    % Preamble for 1Msym/s
SamplesPerBits = 2;
Sensitivity = pi / 2 / SamplesPerBits; % Phase difference between the adjacent samples

%% BLE modulation
TxBits = [Preamble; randi(2, [Nbits, 1])-1];

BLE_Frame = BLE_Modulator(TxBits, SamplesPerBits, Sensitivity);

%% figure;
figure; hold on;
plot(real(BLE_Frame));
plot(imag(BLE_Frame));
ylim([-1.2, 1.2]);
title("I/Q data");

figure;
plot(angle(BLE_Frame));
ylim([-4, 4]);
title("Phase");
