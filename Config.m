%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Configuration of O3. It gives variables that are both knwon for TX and RX
% 
% Copyright (C) 2021-2024 OctHe 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Config(version)

    global c 
    global LSTS LLTS PILOTS MCS_TAB
    global N_FFT N_PILOT N_DATA N_CP N_STF N_LTF N_TAIL
    global DC_INDEX PILOT_INDEX GUARD_INDEX DATA_INDEX NONZERO_INDEX

    %% Light speed
    c = 3e8;

    %% Short/Long training symbol and pilot
    LSTS = sqrt(1/2)* ...
        [ 0 0  1+1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0 ...	subcarriers -28 : -1  
          0 0 0 -1-1j 0 0 0 -1-1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0 0  1+1j 0 0].';	% subcarriers 1 : 28
                        
    LLTS = ...
        [ 1  1 -1 -1  1  1 -1  1 -1  1  1  1  1  1  1 -1 -1  1  1 -1  1 -1  1  1  1  1 ...  subcarriers -26 : -1
          1 -1 -1  1  1 -1  1 -1  1 -1 -1 -1 -1 -1  1  1 -1 -1  1 -1  1 -1  1  1  1  1].';	% subcarriers 1 : 26

    PILOTS{1} = [1 1 -1 1].';

    N_LSTF      = 160;          % LSTF length; 16 * 10
    N_LLTF      = 160;          % LLTF length: 32 +2 * 64
    N_TAIL      = 6;            % Number of tail bits
    N_FFT       = 64;           % FFT size
    N_CP        = 16;           % Number of cyclic prefix

    if version == 'legacy'

        %% MCS
        MCS_TAB.mod = [2, 2, 4, 4, 16, 16, 64, 64];  % Modulation
        MCS_TAB.rate = [2, 4, 2, 4,  2,  4,  3,  4];  % Code rate (2 -> 1/2; 3 -> 2/3; 4 -> 3/4)


        %% Subcarriers
        DC_INDEX = 33;
        PILOT_INDEX = DC_INDEX + [-21, -7, 7, 21];
        GUARD_INDEX = DC_INDEX + [-32:-27, 27:31];
        DATA_INDEX = DC_INDEX + [-26:-22, -20:-8, -6:-1, 1:6, 8:20, 22:26];
        NONZERO_INDEX = DC_INDEX + [-26:-1, 1:26];

        N_PILOT = length(PILOT_INDEX);
        N_DATA = length(DATA_INDEX);
        N_NONZERO = length(NONZERO_INDEX);

    endif
