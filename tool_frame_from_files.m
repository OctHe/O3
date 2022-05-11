%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Decoding retransmitted frame from a file that has real-word traces
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
global N_CP N_FFT N_LTFN

Nzeros = 1000;

Nrate = 20e6;
sec = 0.01;
Nstream = Nrate * sec;

%% Meta data
load('ieee80211_meta_data.mat')
Nrxs = Ntxs;

if Ntxs > 1
    disp('Warning: The sample rate may be 10e6 in GRC?');
end

%% Traces
stream = zeros(Nstream, Nrxs);

for irx = 1: Nrxs
    
    fid = fopen(['ieee80211ac_frame_rx_chain_' num2str(irx) '.bin'], 'r');
    bins = reshape(fread(fid, (Nrate + Nstream) * 2, 'float'), 2, []).';
    fclose(fid);
    
    % Ignore the first second to avoid hardware issue
    stream(:, irx) = bins(Nrate +1: Nrate + Nstream, 1) + 1j * bins(Nrate +1: Nrate + Nstream, 2);
        
end

%% Offline demodulation
Nblock = floor(Nstream / (Nzeros + Nsamp));	% Divide stream to multiple blocks.
                                            % The block size is equal to the
                                            % sum of the interval and the
                                            % frame size 

Nframe = Nblock -1;   % Expected received frames. We ignore the last block
for ib = 1: Nframe
    
    raw_sig = stream((ib-1) * (Nzeros + Nsamp) +1: ib * (Nzeros + Nsamp), :);
    
    % Fine time synchronization
    [STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Nrxs);
    [sync_results, LTF_index] = OFDM_SymbolSync(raw_sig, LTF(N_CP *2 +1: end, 1));
    LTF_index = LTF_index + (ib -1) * (Nzeros + Nsamp); % Abs index in the stream

    % Channel estimation
    DLTF_rx = stream(LTF_index +1: LTF_index + N_LTFN * (N_CP + N_FFT), :);    
    
    CSI = IEEE80211ac_ChannelEstimator(DLTF_rx, Ntxs, Nrxs);
    
    Payload_RX_t = stream(LTF_index + N_LTFN * (N_CP + N_FFT) +1: LTF_index + Nsamp - N_STF - N_LTF, :);
    
    Payload_RX_f = IEEE80211ac_Demodulator(Payload_RX_t, CSI);
    
    EVM = abs(Payload_RX_f - ModDataTX);
    if ib <= 5
        figure;
        cdfplot(reshape(EVM, [], 1));
        xlabel("EVM"); ylabel("CDF");
    end
    
end