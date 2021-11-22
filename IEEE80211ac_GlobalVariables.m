%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file gives common paramters for IEEE 802.11n/ac protocol
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
function IEEE80211ac_GlobalVariables

%% Frame structure in IEEE 802.11g protocol
global N_FFT N_SC N_CP N_STF N_DATA
N_FFT                   = 64;           % FFT length
N_SC                    = 56;        	% Number of tones
N_CP                    = 16;           % Cyclic prefix length
N_STF                   = 160;          % STF length; 16 * 10
N_DATA                  = 52;

%% Subcarriers
global  PILOT_INDEX DATA_INDEX SC_INDEX GUARD_INDEX
SC_INDEX 	= [5: 32, 34: 61];                              % Non-zero subcarriers indices: [-28: -1, 1:28]
DATA_INDEX  = [5:11, 13:25, 27:32, 34:39, 41:53, 55:61];    % Data subcarrier indices
PILOT_INDEX = [12 26 40 54];                                % Pilot subcarrier indices: [-21, -7, 7, 21]
GUARD_INDEX = [1: 4, 33,  62: 64];

%% Preambles and pilot
global STS LTS PILOTS_20
STS = sqrt(1/2)* ...
    [ 0 0 0 0  1+1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 ...	% subcarriers -28 : -1  
      0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0 0].';	% subcarriers 1 : 28
              
% L_STS_40 = [STS_20; zeros(11, 1); STS_20];         
LTS = sqrt(1/2)* ...
    [ 1  1  1  1 -1 -1  1  1 -1  1 -1  1  1  1  1  1  1 -1 -1  1  1 -1  1 -1  1  1  1  1 ...  subcarriers -28 : -1
      1 -1 -1  1  1 -1  1 -1  1 -1 -1 -1 -1 -1  1  1 -1 -1  1 -1  1 -1  1  1  1  1 -1 -1 ];	% subcarriers 1 : 28
                   
PILOTS_20 = ...        % Ref to Table 19-19 in IEEE 802.11ac standard
    [ 1,  1,  1, -1;
      1,  1, -1, -1;
      1,  1, -1, -1;
      1,  1,  1, -1 ].';

%% MCS map in IEEE 802.11g standard
global MCS_MAT
MCS_MAT = [2, 2, 4, 4, 16, 16, 64, 64;
    2, 4, 2, 4, 2, 4, 3, 4];

%% Coding in IEEE 802.11g standard
global SCREAMBLE_POLYNOMIAL SCREAMBLE_INIT CONV_TRELLIS TAIL_LEN
SCREAMBLE_POLYNOMIAL    = [1 0 0 0 1 0 0 1];
SCREAMBLE_INIT          = [0 1 0 0 1 0 1];
CONV_TRELLIS            = poly2trellis(7, [133 171]);
TAIL_LEN                = 6;
