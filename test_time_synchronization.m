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

Nss = 1;
Nzeros = 100;

enable_figure = false;

groundtruth = Nzeros + 320;  % ground truth is the end of the LTF

% Preamble
LSTF = Modulator(LSTS, 'training');
LLTF = Modulator(LLTS, 'training');
stream = [zeros(Nzeros, 1); LSTF; LLTF; zeros(Nzeros, 1)];

if enable_figure
    figure;
    for iss = 1: Nss
        subplot(iss, 1, iss); hold on;
        plot(real([LSTF(:, iss); LLTF(:, iss)]));
        plot(imag([LSTF(:, iss); LLTF(:, iss)]));
        title(['Spatial streams ' num2str(iss)]);
    end
endif

% Coarse time synchronization
[auto_results, pkt_index] = PacketDetection(stream, 0.95);

if pkt_index < groundtruth
    disp(['coarse time synchronization correct!']);
else
    disp(['coarse time synchronization error!']);
    disp(['         Packet index: ' num2str(pkt_index)]);
    disp(['         Expected index: ' num2str(Nzeros +1)]);
end

if enable_figure
    figure;
    plot(abs(auto_results));
    title("Packet detection results");
endif

% Fine time synchronization
[sync_results, LTF_index] = SymbolSync(stream, LLTF(2*N_CP +1: end, 1));

if enable_figure
    figure;
    plot(abs(sync_results));
    title("Normalized synchronization results");
endif

if LTF_index == groundtruth
    disp(['Fine time synchronization correct!']);
else
    disp(['Fine time synchronization error!']);
    disp(['         Delay: ' num2str(LTF_index - groundtruth) ' Sample(s)']);
end

save signal/Tx LSTF LLTF
