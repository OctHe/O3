%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Preamble Generation for IEEE 802.11. Now it supports IEEE 802.11a
% bw: 1, 2, 4, 8 == [20, 40, 80, 160] MHz
% STF_t(VHT): (N_CP + N_CP + N_SC + N_SC, 1);
% LTF_t(VHT): (N_CP + N_CP + N_SC + N_SC, 1);
%
% Copyright (C) 2021.11.22  Shiyue He (hsy1995313@gmail.com)
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
function [STF_t, LTF_t] = IEEE80211ac_PreambleGenerator(bw)

global N_FFT N_SC N_CP SC_INDEX 
global STS LTS

switch bw
    case 1 % 20 MHz

        STF_f = zeros(N_FFT, 1);
        LTF_f = zeros(N_FFT, 1);

        STF_f(SC_INDEX) = STS;
        LTF_f(SC_INDEX) = LTS;

        STF_t = 1/sqrt(N_SC) * N_FFT * ifft(fftshift(STF_f));
        LTF_t = 1/sqrt(N_SC) * N_FFT * ifft(fftshift(LTF_f));

        STF_t = [STF_t(end - 2 * N_CP +1: end); STF_t; STF_t];
        LTF_t = [LTF_t(end - 2 * N_CP +1: end); LTF_t; LTF_t];

    case 2 % 40 MHz

    otherwise
        error('ERROR: bw must be 1/2');
end