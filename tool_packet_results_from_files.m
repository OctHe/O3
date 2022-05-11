%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Packet detection result from a file that has real-word traces
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
global N_STF N_LTF
global N_CP N_FFT N_LTFN N_DATA
global MCS_TAB

Nzeros = 1000;

Nrate = 1e6;
sec = 0.1;
Nstream = Nrate * sec;

%% Meta data
load('ieee80211_meta_data.mat')
Nrxs = Ntxs;

%% Traces
stream = zeros(Nstream, Nrxs);

for irx = 1: Nrxs
    
    fid = fopen(['ieee80211ac_frame_rx_chain_' num2str(irx) '.bin'], 'r');
    bins = reshape(fread(fid, (Nrate + Nstream) * 2, 'float'), 2, []).';
    fclose(fid);
    
    % Ignore the first second to avoid hardware issue
    stream(:, irx) = bins(Nrate +1: Nrate + Nstream, 1) + 1j * bins(Nrate +1: Nrate + Nstream, 2);
    
    %% Figures
    figure; hold on
    plot(1/Nrate: 1/Nrate: sec, real(stream(:, irx)));
    plot(1/Nrate: 1/Nrate: sec, imag(stream(:, irx)));
    title(['Stream from chain ' num2str(irx)]);
    
end

%% Coarse time synchronization at the file scale
[auto_results, ~] = OFDM_PacketDetection(stream, 0.95);

figure;
plot(auto_results);
ylim([0, 1.5]);
title(['Time sync result (Nrxs = ' num2str(Nrxs) ')']);

%% Fine time synchronization
Nblock = floor(Nstream / (Nzeros + Nsamp));	% Divide stream to multiple blocks.
                                            % The block size is equal to the
                                            % sum of the interval and the
                                            % frame size 

Nframe = Nblock -1;   % Expected received frames. We ignore the last block
for ib = 2: Nframe
    raw_sig = stream((ib-1) * (Nzeros + Nsamp) +1: ib * (Nzeros + Nsamp), :);
    
    % Fine time synchronization
    [STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Nrxs);
    [sync_results, LTF_index] = OFDM_SymbolSync(raw_sig, LTF(N_CP *2 +1: end, 1), true);
    LTF_index = LTF_index + (ib -1) * (Nzeros + Nsamp); % Abs index in the stream
    pkt_index = LTF_index - N_STF - N_LTF;
    
    frame_RX = stream(pkt_index +1: pkt_index + Nsamp, :);
    
    if ib <= 5
        figure;
        plot(abs(sync_results));
        title('Time sync result');
        
        for irx = 1: Nrxs
            figure;
            plot(abs(frame_RX));
            xlabel('Sample index'); ylabel('Amplitude');
            title(['RX frame at RX chain ' num2str(irx)]);

        end
    end
    
    % Channel estimation
    DLTF_rx = stream(LTF_index +1: LTF_index + N_LTFN * (N_CP + N_FFT), :);    
    
    CSI = IEEE80211ac_ChannelEstimator(DLTF_rx, Ntxs, Nrxs);
    
    if ib <= 5
        figure;
        for irx = 1: Nrxs
            subplot(Nrxs , 1, irx); hold on;
            plot(real(DLTF_rx(:, irx)));
            plot(imag(DLTF_rx(:, irx)));
        end

        
        figure;
        for itx = 1: Ntxs
        for irx = 1: Nrxs
            subplot(Ntxs , Nrxs, (itx -1) * Nrxs + irx);
            plot(abs(CSI(:, irx, itx)));
            title(['Amp (TX: ' num2str(itx) '; RX: ' num2str(irx) ')']);
        end
        end
        
        figure;
        for itx = 1: Ntxs
        for irx = 1: Nrxs
            subplot(Ntxs , Nrxs, (itx -1) * Nrxs + irx);
            plot(angle(CSI(:, irx, itx)));
            title(['Phase (TX: ' num2str(itx) '; RX: ' num2str(irx) ')']);
        end
        end
    end
    
end