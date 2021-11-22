%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Write preambles to file
%
% Copyright (C) 2021.11.22  Shiyue He (hsy1995313@gmail.com)
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
bw = 1;    % 20 MHz

IEEE80211ac_GlobalVariables;

%% Preambles
[STF_t, LTF_t] = IEEE80211ac_PreambleGenerator(bw);

stream = [STF_t; LTF_t];
fid = fopen('~/Desktop/ieee80211_preamble.bin', 'w');

bins = reshape([real(stream), imag(stream)].', [], 1);

fwrite(fid, bins, 'float');

fclose(fid);

%% Figures
figure;
plot(abs(STF_t));
title('STF');

figure;
plot(abs(LTF_t));
title('LTF');