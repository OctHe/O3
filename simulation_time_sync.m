%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Time synchronization results
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
clear all;
close all;

%% Variables
bw = 1;    % [1/2] = [20/40] MHz
Ntx = 1;
Nzeros = 100;

IEEE80211ac_GlobalVariables(bw);
global N_CP

%% Preambles
[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Ntx);
stream = [zeros(Nzeros, 1); sum([STF; LTF; DLTF], 2); zeros(Nzeros, 1)];
stream = stream + 0.01 * rand(size(stream, 1), 1);

[sync_results, LTF_index] = IEEE80211ac_SymbolSync(stream, sum(LTF(2*N_CP +1: end, :), 2));

%% Figures
figure; hold on;
plot(real(stream));
plot(imag(stream));
title("Raw signals");

figure;
plot(abs(sync_results));
title("Normalized synchronization results");

disp(['LTF index is ' num2str(LTF_index)]);