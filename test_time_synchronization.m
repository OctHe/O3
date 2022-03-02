%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Time synchronization results
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
clear all;  % clear all for global variables
close all;

%% Variables
Ntxs = 4;

groundtruth = 320;  % ground truth is the end of the LTF

IEEE80211ac_GlobalVariables;
global N_CP

for ntx = 1: Ntxs
    
    %% Preambles
    [STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(ntx);
    stream = sum([STF; LTF; DLTF], 2);
    
    %% Figures: TX preambles
    figure;
    for itx = 1: ntx
        subplot(ntx, 1, itx); hold on;
        plot(real([STF(:, itx); LTF(:, itx); DLTF(:, itx)]));
        plot(imag([STF(:, itx); LTF(:, itx); DLTF(:, itx)]));
        title(['Transmit chain ' num2str(itx)]);
    end
    
    %% Time synchronization
    [sync_results, LTF_index] = IEEE80211ac_SymbolSync(stream, sum(LTF(2*N_CP +1: end, :), 2));

    %% Figures: Cross correlation results
    figure;
    plot(abs(sync_results));
    title("Normalized synchronization results");

    if LTF_index == groundtruth
        disp(['Correct! (Ntxs = ' num2str(ntx) ')']);
    else
        disp(['Error! (Ntxs = ' num2str(ntx) ')']);
        disp(['         Offset = ' num2str(groundtruth - LTF_index)]);
    end
end

