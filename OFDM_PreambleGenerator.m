%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Preamble Generation for OFDM. It supports MIMO communication
% Ntxs: The number of transmit chain
% STF(VHT): ((N_CP + N_FFT)*2, Ntxs);
% LTF1(VHT): ((N_CP + N_FFT)*2, Ntxs);
% LTFn(VHT): DLTF
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
function [STF, LTF1, LTFn] = OFDM_PreambleGenerator(Ntxs)

global N_FFT N_TONE N_CP N_LTFN TONE_INDEX VHT_CS HT_P_LTF
global VHT_STS VHT_LTS

if Ntxs <= 0
    error('Error: Ntx must be 1/2/3/4 !');
elseif Ntxs > 4
    error('Error: Ntx must be 1/2/3/4 !');
end

VHT_STF_f = zeros(N_FFT, 1);
VHT_LTF_f = zeros(N_FFT, 1);

VHT_STF_f(TONE_INDEX) = VHT_STS;
VHT_LTF_f(TONE_INDEX) = VHT_LTS;

VHT_STF_t = zeros(N_FFT, Ntxs);
VHT_LTF_t = zeros(N_FFT, Ntxs);

LTFn = zeros(N_LTFN * (N_CP + N_FFT), Ntxs);

for itx = 1: Ntxs

    VHT_STF_t(:, itx) = 1/sqrt(N_TONE) * N_FFT * ifft(fftshift(VHT_STF_f));
    VHT_LTF_t(:, itx) = 1/sqrt(N_TONE) * N_FFT * ifft(fftshift(VHT_LTF_f));

    % Cyclic shift delay (CSD) blocks
    VHT_STF_t(:, itx) = circshift(VHT_STF_t(:, itx), VHT_CS{Ntxs}(itx));
    VHT_LTF_t(:, itx) = circshift(VHT_LTF_t(:, itx), VHT_CS{Ntxs}(itx));
    
    % Data and extend LTF
    DLTF_t = zeros(N_CP + N_FFT, N_LTFN);
    for iltf = 1: N_LTFN
        DLTF_t(:, iltf) = HT_P_LTF(iltf, itx) * ...
            [VHT_LTF_t(end - N_CP +1: end, itx); VHT_LTF_t(:, itx)];
    end
    LTFn(:, itx) = reshape(DLTF_t, [], 1);
end

STF = [VHT_STF_t(end - 2 * N_CP +1: end, :); VHT_STF_t; VHT_STF_t];
LTF1 = [VHT_LTF_t(end - 2 * N_CP +1: end, :); VHT_LTF_t; VHT_LTF_t];

