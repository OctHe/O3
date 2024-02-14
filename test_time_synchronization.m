%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Time synchronization results (coarse and fine time sync)
%
% Copyright (C) 2021-2024 OctHe
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;

Config('legacy');

%% Variables
global N_CP
global LSTS LLTS

Ntxs = 1;
Nzeros = 100;

groundtruth = Nzeros + 320;  % ground truth is the end of the LTF

    
disp(['******************************']);

% Preambles
LSTS_t = FreqProcessing(LSTS, 'training');
LLTS_t = FreqProcessing(LLTS, 'training');
LSTF = [LSTS_t(end - 2 * N_CP +1: end); LSTS_t; LSTS_t];
LLTF = [LLTS_t(end - 2 * N_CP +1: end); LLTS_t; LLTS_t];
stream = [zeros(Nzeros, 1); LSTF; LLTF; zeros(Nzeros, 1)];

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

% Fine time synchronization
[sync_results, LTF_index] = SymbolSync(stream, LLTF(2*N_CP +1: end, 1));

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

