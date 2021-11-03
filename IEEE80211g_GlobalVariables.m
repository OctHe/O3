%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file gives common paramters for IEEE 802.11a/g protocol
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
function IEEE80211g_GlobalVariables

%% Frame structure in IEEE 802.11g protocol
global N_SC N_CP STF_LEN LONG_PREAMBLE_LEN TONES_NUM SC_DATA_NUM 
global SC_PILOT_NUM  
N_SC                    = 64;           % Number of subcarriers
N_CP                    = 16;           % Cyclic prefix length
STF_LEN                 = 160;          % STF length; 16 * 10
LONG_PREAMBLE_LEN       = 128; 
TONES_NUM               = 52;
SC_DATA_NUM             = 48;
SC_PILOT_NUM            = 4;

%% Subcarriers in IEEE 802.11g standard
global SC_IND_PILOTS SC_IND_DATA TONES_INDEX GUARD_SC_INDEX
SC_IND_PILOTS           = [8 22 44 58];                             % Pilot subcarrier indices
SC_IND_DATA             = [2:7 9:21 23:27 39:43 45:57 59:64];       % Data subcarrier indices, 0: N_SC -1
TONES_INDEX             = [2 :27 39: 64];                           % non-zero subcarriers index, 0:31, -32: -1
GUARD_SC_INDEX          = [1 28: 38];

%% STF, LTF, and pilot in IEEE 802.11g standard
global ShortTrainingSymbol LongTrainingSymbol PILOTS
ShortTrainingSymbol = sqrt(13/6)* ...
            [ 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 ...    % subcarriers 0 : 31
              0 0  1+1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0].';    % subcarriers -32 : -1
          
LongTrainingSymbol = [ 1 -1 -1  1  1 -1  1 -1  1 -1 -1 -1 -1 -1  1  1 -1 -1  1 -1  1 -1  1  1  1  1 ...     % subcarriers 0 : 31
                       1  1 -1 -1  1  1 -1  1 -1  1  1  1  1  1  1 -1 -1  1  1 -1  1 -1  1  1  1  1].';     % subcarriers -32 : -1
                   
PILOTS = [1 1 -1 1].';

%% MCS map in IEEE 802.11g standard
global MCS_MAT BITRATE_MAT CODE_RATE
MCS_MAT = [2, 2, 4, 4, 16, 16, 64, 64;
    2, 4, 2, 4, 2, 4, 3, 4];
CODE_RATE = [1/2, 3/4, 1/2, 3/4, 1/2, 3/4, 2/3, 3/4];        % Code rate
BITRATE_MAT = [6; 9; 12; 18; 24; 36; 48; 54];   % Unit: Mbps

%% Coding in IEEE 802.11g standard
global SCREAMBLE_POLYNOMIAL SCREAMBLE_INIT CONV_TRELLIS TAIL_LEN
SCREAMBLE_POLYNOMIAL    = [1 0 0 0 1 0 0 1];
SCREAMBLE_INIT          = [0 1 0 0 1 0 1];
CONV_TRELLIS            = poly2trellis(7, [133 171]);
TAIL_LEN                = 6;
