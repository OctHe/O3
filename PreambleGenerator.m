%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Preamble Generation for IEEE 802.11. Now it supports IEEE 802.11a
% STF_t(Legend): (N_CP + N_CP + N_SC + N_SC, 1);
% LTF_t(Legend): (N_CP + N_CP + N_SC + N_SC, 1);
%
% Copyright (C) 2021.11.03  Shiyue He (hsy1995313@gmail.com)
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
function [STF_t, LTF_t] = PreambleGenerator

global N_SC ShortTrainingSymbol LongTrainingSymbol TONES_INDEX

ShortPreamble_f = zeros(N_SC, 1);
LongPreamble_f = zeros(N_SC, 1);

ShortPreamble_f(TONES_INDEX) = ShortTrainingSymbol;
LongPreamble_f(TONES_INDEX) = LongTrainingSymbol;

ShortPreamble_t = ifft(ShortPreamble_f);
LongPreamble_t = ifft(LongPreamble_f);

STF_t = [ShortPreamble_t(N_SC/2+1: N_SC); ShortPreamble_t; ShortPreamble_t];
LTF_t = [LongPreamble_t(N_SC/2+1: N_SC); LongPreamble_t; LongPreamble_t];