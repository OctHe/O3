%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Write a null data packet (NDP) packet to files
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
Nzeros = 100;

IEEE80211ac_GlobalVariables;

%% Preambles
[STF, LTF, DLTF] = IEEE80211ac_PreambleGenerator(Ntxs);

for itx = 1: Ntxs
    stream = [zeros(Nzeros, 1); STF(:, itx); LTF(:, itx); DLTF(:, itx)];

    bins = reshape([real(stream), imag(stream)].', [], 1);
    fid = fopen(['ieee80211ac_ndp_chain_' num2str(itx) '.bin'], 'w');
    fwrite(fid, bins, 'float');
    fclose(fid);

    %% Figures
    figure; hold on
    plot(real(stream));
    plot(imag(stream));
    title(['Stream for chain ' num2str(itx)]);
end
