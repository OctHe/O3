%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Write a OFDM frame with time interval to a file. This file can be inputed
% into the file source of GNURadio GRC.
%
% Copyright (C) 2022  Shiyue He (hsy1995313@gmail.com)
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
global MCS_TAB
global N_DATA

Ntxs        = 2;
Ninterval   = 1000;
Nbits       = 800;
MCSi        = 2;

Mod = MCS_TAB.mod(MCSi);
Nbps = log2(Mod) * N_DATA;

CONSTANT_PD = false;

%% Transmitter
if ~CONSTANT_PD
    BitsTX = randi(2, [Nbits, Ntxs]) -1;
else
    BitsTX = ones(Nbits, Ntxs);
end

Npad = Nbps - mod(Nbits, Nbps);
BitsPadTX = [BitsTX; zeros(Npad, Ntxs)];

[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Ntxs);
ModDataTX = qammod(BitsPadTX, Mod, 'InputType', 'bit', 'UnitAveragePower',true);
Payload_t = IEEE80211ac_Modulator(ModDataTX);

FrameTX = [STF; LTF; DLTF; Payload_t];

%% File writer
for itx = 1: Ntxs
    stream = [zeros(Ninterval, 1); FrameTX(:, itx)];

    bins = reshape([real(stream), imag(stream)].', [], 1);
    fid = fopen(['ieee80211ac_frame_tx_chain_' num2str(itx) '.bin'], 'w');
    fwrite(fid, bins, 'float');
    fclose(fid);
    
    % Figures
    figure; hold on
    plot(real(stream));
    plot(imag(stream));
    title(['Stream for chain ' num2str(itx)]);
end

%% Meta data
Nsamp = size(FrameTX, 1);
save("ieee80211_meta_data.mat", "BitsTX", "Ntxs", "ModDataTX", "Mod", "Nsamp");