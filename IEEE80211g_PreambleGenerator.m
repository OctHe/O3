%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Preamble Generation for IEEE 802.11. Now it supports IEEE 802.11a
% Ntx: The number of transmit chain
% STF(VHT): ((N_CP + N_FFT)*2, 1);
% LTF1(VHT): ((N_CP + N_FFT)*2, 1);
% LTFn(VHT): DLTF + ELTF
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
function [STF, LTF] = IEEE80211g_PreambleGenerator

global N_FFT N_SC N_CP SC_INDEX
global L_STS L_LTS

STF_f = zeros(N_FFT, 1);
LTF_f = zeros(N_FFT, 1);

STF_f(SC_INDEX) = L_STS;
LTF_f(SC_INDEX) = L_LTS;

STF_t = 1/sqrt(N_SC) * N_FFT * ifft(fftshift(STF_f));
LTF_t = 1/sqrt(N_SC) * N_FFT * ifft(fftshift(LTF_f));

STF = [STF_t(end - 2 * N_CP +1: end, :); STF_t; STF_t];
LTF = [LTF_t(end - 2 * N_CP +1: end, :); LTF_t; LTF_t];

