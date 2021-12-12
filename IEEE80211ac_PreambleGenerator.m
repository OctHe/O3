%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Preamble Generation for IEEE 802.11. Now it supports IEEE 802.11a
% Ntx: The number of transmit chain
% STF(VHT): ((N_CP + N_FFT)*2, 1);
% LTF1(VHT): ((N_CP + N_FFT)*2, 1);
%
% Copyright (C) 2021.12.12  Shiyue He (hsy1995313@gmail.com)
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
function [STF, LTF1, DLTF] = IEEE80211ac_PreambleGenerator(Ntx)

global N_FFT N_SYNC N_CP SYNC_INDEX CYCLIC_SHIFT P_HT_LTF
global STS LTS

if Ntx <= 0
    error('Error: Ntx nust be 1/2/3/4 !');
elseif Ntx > 4
    error('Error: Ntx nust be 1/2/3/4 !');
end

    STF_f = zeros(N_FFT, 1);
    LTF_f = zeros(N_FFT, 1);
    
    STF_f(SYNC_INDEX) = STS;
    LTF_f(SYNC_INDEX) = LTS;
    
    STF_t = zeros(N_FFT, Ntx);
    LTF_t = zeros(N_FFT, Ntx);
    
    if Ntx <= 2
        N_DLTF = Ntx;
    else
        N_DLTF = 4;
    end
    DLTF = zeros(N_DLTF * (N_CP + N_FFT), Ntx);
    
for itx = 1: Ntx

    STF_t(:, itx) = 1/sqrt(N_SYNC) * N_FFT * ifft(fftshift(STF_f));
    LTF_t(:, itx) = 1/sqrt(N_SYNC) * N_FFT * ifft(fftshift(LTF_f));

    % Cyclic shift delay (CSD) blocks
    STF_t(:, itx) = circshift(STF_t(:, itx), CYCLIC_SHIFT{Ntx}(itx));
    LTF_t(:, itx) = circshift(LTF_t(:, itx), CYCLIC_SHIFT{Ntx}(itx));
    
    % Data LTF
    DLTF_t = zeros(N_CP + N_FFT, N_DLTF);
    for iltf = 1: N_DLTF
        DLTF_t(:, iltf) = P_HT_LTF(iltf, itx) * ...
            [LTF_t(end - N_CP +1: end, itx); LTF_t(:, itx)];
    end
    DLTF(:, itx) = reshape(DLTF_t, [], 1);
end

STF = [STF_t(end - 2 * N_CP +1: end, :); STF_t; STF_t];
LTF1 = [LTF_t(end - 2 * N_CP +1: end, :); LTF_t; LTF_t];

