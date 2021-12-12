%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Waveform for preambles
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
clear;
close all;

%% Variables
bw = 1;    % [1/2] = [20/40] MHz
Ntx = 1;

IEEE80211ac_GlobalVariables(bw);

%% Preambles
[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Ntx);

%% Figures
 figure;
for itx = 1: Ntx
    subplot(Ntx, 1, itx); hold on;
    plot(real([STF(:, itx); LTF(:, itx); DLTF(:, itx)]));
    plot(imag([STF(:, itx); LTF(:, itx); DLTF(:, itx)]));
    title(['Transmit chain ' num2str(itx)]);
end
