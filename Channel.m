%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Rician Channel Model
% Reference: IEEE 802.11n Indoor MIMO WLAN Channel Models
%
% Copyright (C) 2024  Shiyue He (hsy1995313@gmail.com)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Channel

    properties

        % Time interval between samples (ns)
        Ts

        % RMS delay profile (ns)
        rms_delay

        % Cluster
        cluster

        % K factor (dB) for LOS condition
        K

        % Breakpoint distance (m)
        breakpoint
        % shadow fading (dB)
        los_shadow
        nlos_shadow

    end

    methods

        function H = Channel(model, BW, d, Ntx, Nrx)

            H.Ts = 1000 / BW;

            switch (model)
                case 'A'
                    H.rms_delay = 0;
                    H.cluster = struct("delay", {0},
                                        "power", {0},
                                        "AoA", {45},
                                        "RxAS", {40},
                                        "AoD", {45},
                                        "TxAS", {40});
                    H.K = 0;
                    H.breakpoint = 5;
                    H.nlos_shadow = 4;
                case 'B'
                    H.rms_delay = 15;
                    H.cluster = struct("delay", {0:10:40, 20:10:80},
                                        "power", {[0, -5.4, -10.8, -16.2, -21.7], ...
                                                [-3.2, -6.3, -9.4, -12.5, -15.6, -18.7, -21.8]},
                                        "AoA", {4.3, 118.4},
                                        "RxAS", {14.4, 25.2},
                                        "AoD", {225.1, 106.5},
                                        "TxAS", {14.4, 25.4});
                    H.K = 0;
                    H.breakpoint = 5;
                    H.nlos_shadow = 4;
                case 'C'
                    H.rms_delay = 30;
                    H.cluster = struct("delay", {0:10:90,
                                        [60, 70, 80, 90, 110, 140, 170, 200]},
                                        "power", {[0, -2.1, -4.3, -6.5, -8.6, -10.8, -13.0, -15.2, -17.3, -19.5], ...
                                                [-5, -7.2, -9.3, -11.5, -13.7, -15.8, -18, -20.2]},
                                        "AoA", {290.3, 332.3},
                                        "RxAS", {24.6, 22.4},
                                        "AoD", {13.5, 56.4},
                                        "TxAS", {24.7, 22.5});
                    H.K = 0;
                    H.breakpoint = 5;
                    H.nlos_shadow = 5;
                case 'D'
                    H.rms_delay = 50;
                    H.cluster = struct("delay", {[0:10:90, 110, 140, 170, 200, 240, 290], ...
                                        [140, 170, 200, 240, 290, 340], ...
                                        [240, 290, 340, 390]},
                                        "power", {[0, -0.9, -1.7, -2.6, -3.5, -4.3, -5.2, -6.1, -6.9, -7.8, -9, -11.1, -13.7, -16.3, -19.3, -23.2], ...
                                        [-6.6, -9.5, -12.1, -14.7, -21.9, -25.5], ...
                                                [-18.8, -23.2, -25.2, -26.7]},
                                        "AoA", {158.9, 320.2, 276.1},
                                        "RxAS", {27.7, 31.4, 37.4},
                                        "AoD", {332.1, 49.3, 275.9},
                                        "TxAS", {27.4, 32.1, 36.8});
                    H.K = 2;
                    H.breakpoint = 10;
                    H.nlos_shadow = 5;
                case 'E'
                    H.rms_delay = 100;
                    H.Ncluster = 4;
                    H.Ntap = [15, 12, 7, 4];
                    H.K = 3;
                    H.breakpoint = 15;
                    H.nlos_shadow = 6;
                case 'F'
                    H.rms_delay = 150;
                    H.Ncluster = 6;
                    H.Ntap = [15, 12, 7, 3, 2, 2];
                    H.K = 6;
                    H.breakpoint = 20;
                    H.nlos_shadow = 6;
                otherwise
                    error("model must be A/B/C/D/E/F!");
            endswitch

            H.los_shadow = 3;


            L = H.pathloss(model, d);

            % Taps for each cluster
            Ncluster = length(H.cluster);
            Ttap = H.cluster(1).delay(1): H.Ts: H.cluster(Ncluster).delay(end);
            power_per_tap = zeros(Ttag, Ncluster);
            for cls_idx = 0: Ncluster
                for tap_idx = Ttap
                    power_per_tap(tappp_idx, cls_idx) = ...
                        10^(interp1(H.cluster(cls_idx).delay, H.cluster(cls_idx).power)/10);

                    % MIMO: Ntap x Nrx x Ntx
                    % AS for each tap
                    % Doppler for each tap
                endfor
            endfor

        endfunction

        function L = pathloss(H, model, d)

            if d <= 4
                error("The pathloss model may be inaccurate for d <= 4 case.");
            endif

            % The shadow is limited by 14 dB
            if d > H.breakpoint
                L = 20 * log10(H.breakpoint) + ...
                    35 * log10(d / H.breakpoint) + ...
                    max(H.nlos_shadow * randn(), 14);
            else
                L = 20 * log10(d) + max(H.los_shadow * randn(), 14);
            endif

        endfunction

    endmethods

endclassdef
