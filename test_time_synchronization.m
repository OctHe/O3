%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Time synchronization results (coarse and fine time sync)
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
clear;
close all;

%% Variables
global N_CP

Ntxs = 4;
Nzeros = 100;

groundtruth = Nzeros + 320;  % ground truth is the end of the LTF

%% Time sync for MIMO
for ntx = 1: Ntxs
    
    disp(['******************************']);
    disp(['Ntxs == Nrxs == ' num2str(ntx)]);
    
    % Preambles
    [STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(ntx);
    stream = [zeros(Nzeros, 1); sum([STF; LTF], 2); zeros(Nzeros, 1)];
    
    % Figures: TX preambles
    figure;
    for itx = 1: ntx
        subplot(ntx, 1, itx); hold on;
        plot(real([STF(:, itx); LTF(:, itx)]));
        plot(imag([STF(:, itx); LTF(:, itx)]));
        title(['Transmit chain ' num2str(itx)]);
    end
    
    % Coarse time synchronization
    [auto_results, pkt_index] = OFDM_PacketDetection(stream, 0.95);
    
    if pkt_index < groundtruth
        disp(['coarse time synchronization correct!']);
    else
        disp(['coarse time synchronization error!']);
        disp(['         Packet index: ' num2str(pkt_index)]);
        disp(['         Expected index: ' num2str(Nzeros +1)]);
    end
    
    % Figures: Auto-correlation results
    figure;
    plot(abs(auto_results));
    title("Packet detection results");
    
    % Fine time synchronization
    if ntx == 1
        [sync_results, LTF_index] = OFDM_SymbolSync(stream, LTF(2*N_CP +1: end, 1));
    else
        [sync_results, LTF_index] = OFDM_SymbolSync(stream, LTF(2*N_CP +1: end, 1), true);
    end
    
    % Figures: Cross correlation results
    figure;
    plot(abs(sync_results));
    title("Normalized synchronization results");

    if LTF_index == groundtruth
        disp(['Fine time synchronization correct!']);
    else
        disp(['Fine time synchronization error!']);
        disp(['         Delay: ' num2str(LTF_index - groundtruth) ' Sample(s)']);
    end
end

