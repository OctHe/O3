%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file gives common paramters for IEEE 802.11a/g protocol
% 
% Copyright (C) 2021.11.18  Shiyue He (hsy1995313@gmail.com)
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

clear all;

%% Version
global VERSION
VERSION     = 'g';

%% Frame structure
global N_FFT N_PILOT N_SC N_CP N_STF N_LTF N_DATA N_TAIL MIN_BITS
N_FFT       = 64;           % FFT size
N_PILOT     = 4;        	% Number of pilots
N_DATA      = 48;           % Number of data subcarriers
N_SC        = 52;           % Number of VHT subcarriers
N_CP        = 16;           % Cyclic prefix length
N_STF       = 160;          % STF length; 16 * 10
N_LTF       = 160;          % LTF length: 32 +2 * 64
N_TAIL      = 6;            % Tail bits

MIN_BITS    = 144;          % The minimal required bits in a frame.
                            % This wants to avoid errors with inproper
                            % vector size.
                            % It is related to convolutional encoder, 
                            % number of data carriers, MCS, etc.
                            
%% Subcarriers
global DC_INDEX PILOT_INDEX GUARD_INDEX DATA_INDEX SC_INDEX
DC_INDEX    = 33;
PILOT_INDEX = DC_INDEX + [-21, -7, 7, 21];
GUARD_INDEX = DC_INDEX + [-32:-27, 27:31];
DATA_INDEX  = DC_INDEX + [-26:-22, -20:-8, -6:-1, 1:6, 8:20, 22:26];
SC_INDEX    = DC_INDEX + [-26:-1, 1:26];

%% STF, LTF, and pilot
global L_STS L_LTS PILOTS
L_STS = sqrt(1/2)* ...
    [ 0 0 0 0  1+1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 ...	% subcarriers -28 : -1  
      0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0 0].';	% subcarriers 1 : 28
                    
L_LTS = ...
    [ 1  1 -1 -1  1  1 -1  1 -1  1  1  1  1  1  1 -1 -1  1  1 -1  1 -1  1  1  1  1 ...  subcarriers -26 : -1
      1 -1 -1  1  1 -1  1 -1  1 -1 -1 -1 -1 -1  1  1 -1 -1  1 -1  1 -1  1  1  1  1].';	% subcarriers 1 : 26

PILOTS{1} = [1 1 -1 1].';

%% MCS map
global MCS_TAB MCS_MAX
MCS_MAX         = 8;
MCS_TAB.mod     = [2, 2, 4, 4, 16, 16, 64, 64];  % Modulation
MCS_TAB.rate    = [2, 4, 2, 4,  2,  4, 3 ,  4];  % Code rate
                                                            % 2 -> 1/2; 
                                                            % 3 -> 2/3;
                                                            % 4 -> 3/4; 


%% Coding
global SCREAMBLE_POLYNOMIAL SCREAMBLE_INIT CONV_TRELLIS
SCREAMBLE_POLYNOMIAL    = [1 0 0 0 1 0 0 1];
SCREAMBLE_INIT          = [0 1 0 0 1 0 1];
CONV_TRELLIS            = poly2trellis(7, [133 171]);
