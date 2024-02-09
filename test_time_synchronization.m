%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Time synchronization results (coarse and fine time sync)
%
% Copyright (C) 2021-2024 OctHe
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;

Standard('legacy');

%% Variables
global N_CP
global L_STS L_LTS

Ntxs = 1;
Nzeros = 100;

groundtruth = Nzeros + 320;  % ground truth is the end of the LTF

    
disp(['******************************']);

% Preambles
LSTF = FreqProcessing(L_STS, 'training');
LLTF = FreqProcessing(L_LTS, 'training');

stream = [zeros(Nzeros, 1); LSTF(end - 2 * N_CP +1: end); LSTF; LSTF; LLTF(end - 2 * N_CP +1: end); LLTF; LLTF];

% Figures: TX preambles
figure;
for itx = 1: Ntxs
    subplot(itx, 1, itx); hold on;
    plot(real([LSTF(:, itx); LLTF(:, itx)]));
    plot(imag([LSTF(:, itx); LLTF(:, itx)]));
    title(['Transmit chain ' num2str(itx)]);
end

% Coarse time synchronization
[auto_results, pkt_index] = PacketDetection(stream, 0.95);

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

% % Fine time synchronization
% if itx == 1
%     [sync_results, LTF_index] = OFDM_SymbolSync(stream, LTF(2*N_CP +1: end, 1));
% else
%     [sync_results, LTF_index] = OFDM_SymbolSync(stream, LTF(2*N_CP +1: end, 1), true);
% end

% % Figures: Cross correlation results
% figure;
% plot(abs(sync_results));
% title("Normalized synchronization results");

% if LTF_index == groundtruth
%     disp(['Fine time synchronization correct!']);
% else
%     disp(['Fine time synchronization error!']);
%     disp(['         Delay: ' num2str(LTF_index - groundtruth) ' Sample(s)']);
% end

