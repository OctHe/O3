%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Preamble Generation for each user in HD-MIMO model
% Ntxs: The number of transmit users
% Ntags: The number of backscatters
% STF: OFDM STF
% LTF: OFDM LTF
% HDLTF: HDLTF for hybrid channel estimation (Ambient part)
% BTF: Backscatter training field for channel estimation
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
function [STF, LTF, HDLTF, BTF] = HDMIMO_PreambleGenerator(Ntxs, Ntags)

global N_STF N_LTF N_FFT N_TONE N_CP TONE_INDEX
global VHT_LTS

P2 = [1, 1; 1, -1];
P = [P2, P2; P2, -P2];

%% STF and LTF
% HD-MIMO focuses on uplink transmission for single-antenna user.
% Each user does not use cyclic shift in the preamble because of spatical
% diversity
STF = zeros(N_STF, Ntxs);
LTF = zeros(N_LTF, Ntxs);

for itx = 1: Ntxs
    [STF(:, itx), LTF(:, itx), ~] = OFDM_PreambleGenerator(1);
end

%% HD-LTF
% HD-LTF is based on DLTF in IEEE 802.11ac protocol
DLTF_f = zeros(N_FFT, 1);
DLTF_f(TONE_INDEX) = VHT_LTS;
DLTF_t = 1/sqrt(N_TONE) * N_FFT * ifft(fftshift(DLTF_f));
DLTF = [DLTF_t(end - N_CP +1: end); DLTF_t];

BTF = [-ones(Ntxs, Ntags); kron(P(1: Ntags, 1: Ntags), ones(Ntxs, 1))];

P_HDLTF = kron(ones(Ntags +1, 1), P(1: Ntxs, 1: Ntxs));
HDLTF = kron(P_HDLTF, DLTF);