%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% BFi: CTC transmition from BLE to Wi-Fi with cross detection This is only a
% simulation to show the pattern from the BLE to the Wi-Fi. It is not a
% systematic transmission pipeline.
%
% BLE symbol duration: 1 us; BLE bandwidth 2 MHz
% Wi-Fi symbol duration: 4 us; Wi-Fi bandwidth 20 MHz
% Wi-Fi subcarriers: 64
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
BW = 20;                % Wi-Fi bandwidth == 20 MHz
SamplesPerBits = 20;    % BLE symbol rate == 1 Msym/s
Sensitivity = pi / 2 / SamplesPerBits; % Phase difference between the adjacent samples

Np = 8;     % Number of BLE preamble for 1 Msym/s code rate
Preamble = repmat([1; 0], 4, 1);    % Preamble for 1 Msym/s code rate

Nbits = 4;

Offset = 0;    % Frequency offset of 9 BLE devices: [-10: 2: 10]

%% BFi transmitter
RawBits = randi(2, [Nbits, 1]) -1;

BFi_Bits = BFi_Encoder(RawBits);

%% BLE transmitter
BLE_Bits = [Preamble; BFi_Bits];

BLE_Frame = BLE_Modulator(BLE_Bits, SamplesPerBits, Sensitivity);
Nt = size(BLE_Frame, 1);

%% BLE frame in the view of Wi-Fi receiver
% BLE channels: 5 - 10, 38, 11 - 12 (2414 - 2430 MHz)
% Wi-Fi channel 3: 2422 MHz
BFi_Frame = BLE_Frame .* exp(-2j * pi * Offset / BW * (0: (Nt-1)).');

%% Wi-Fi receiver
[auto_results, ~] = OFDM_PacketDetection(BFi_Frame, 0.95);

%% Figures
figure; hold on;
plot(real(BFi_Frame));
plot(imag(BFi_Frame));
title("BLE Frame at Wi-Fi receiver");

figure;
plot(abs(auto_results));
ylim([0, 1.1]);
title("Preamble periodicity");


