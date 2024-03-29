%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Rician Channel Model
% Reference: IEEE 802.11n Indoor MIMO WLAN Channel Models
%
% Copyright (C) 2024 OctHe
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef ChannelModel

    properties

        % Time interval between samples (ns)
        Ts

        % The samples start from 0
        Nstart

        % RMS delay profile (ns)
        rms_delay

        % Cluster
        cluster
        taps

        % Doppler frequency
        Doppler

        % K factor (dB) for LOS condition
        K

        % Breakpoint distance (m)
        breakpoint
        % shadow fading (dB)
        los_shadow
        nlos_shadow

    endproperties

    methods

        function H = ChannelModel(model, BW, fc, d, Ntx, Ltx_cm, Nrx, Lrx_cm, v)

            global c

            H.Nstart = 0;

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
                    H.cluster = struct("delay", {0:10:90, ...
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
                    H.cluster = struct("delay", {[0, 10, 20, 30, 50, 80, 110, 140, 180, 230, 280, 330, 380, 430, 490], ...
                                            [50, 80, 110, 140, 180, 230, 280, 330, 380, 430, 490, 560], ...
                                            [180, 230, 280, 330, 380, 430, 490], ...
                                            [490, 560, 640, 730]},
                                        "power", {[-2.6, -3, -3.5, -3.9, -4.5, -5.6, -6.9, -8.2, -9.8, -11.7, -13.9, -16.1, -18.3, -20.5, -22.9], ...
                                            [-1.8, -3.2, -4.5, -5.8, -7.1, -9.9, -10.3, -14.3, -14.7, -18.7, 19.9, -22.4], ...
                                            [-7.9, -9.6, -14.2, -13.8, -18.6, -18.1, -22.8], ...
                                            [-20.6, -20.5, -20.7, -24.6]},
                                        "AoA", {163.7, 251.8, 80, 182},
                                        "RxAS", {35.8, 41.6, 37.4, 40.3},
                                        "AoD", {105.6, 293.1, 61.9, 275.7},
                                        "TxAS", {36.1, 42.5, 38, 38.7});
                    H.K = 3;
                    H.breakpoint = 15;
                    H.nlos_shadow = 6;
                case 'F'
                    H.rms_delay = 150;
                    H.cluster = struct("delay", {[0, 10, 20, 30, 50, 80, 110, 140, 180, 230, 280, 330, 400, 490, 600], ...
                                            [50, 80, 110, 140, 180, 230, 280, 330, 400, 490, 600, 730], ...
                                            [180, 230, 280, 330, 400, 490, 600], ...
                                            [400, 490, 600], ...
                                            [600, 730], ...
                                            [880, 1050]},
                                        "power", {[-3.3, -3.6, -3.9, -4.2, -4.6, -5.3, -6.2, -7.1, -8.2, -9.5, -11.0, -12.1, -14.3, -16.7, -19.9], ...
                                            [-1.8, -2.8, -3.5, -4.4, -5.3, -7.4, -7.0, -10.3, -10.4, -13.8, -15.7, -19.9], ...
                                            [-5.7, -6.7, -10.4, -9.6, -14.1, -12.7, -18.5], ...
                                            [-8.8, -13.3, -18.7], ...
                                            [-12.9, -14.2], ...
                                            [-16.3, -21.2]},
                                        "AoA", {315.1, 180.4, 74.7, 251.5, 68.5, 246.2},
                                        "RxAS", {48, 55, 74.7, 251.5, 68.5, 246.2},
                                        "AoD", {56.2, 183.7, 153, 112.5, 291, 62.3},
                                        "TxAS", {41.6, 55.2, 47.4, 27.2, 33, 38});
                    H.K = 6;
                    H.breakpoint = 20;
                    H.nlos_shadow = 6;
                otherwise
                    error("Channel model must be A/B/C/D/E/F!");
            endswitch

            H.los_shadow = 3;

            PL = H.pathloss(model, d);

            Ncluster = length(H.cluster);
            Ttap = H.cluster(1).delay(1): H.Ts: (H.cluster(Ncluster).delay(end) + H.Ts);
            Ntap = length(Ttap);
            H.taps = zeros(Nrx, Ntx, Ncluster, Ntap);
            H.Doppler = zeros(Ncluster, 1);
            for icluster = 1: Ncluster
                clstr = H.cluster(icluster);

                AoD = rand_space_angle(clstr.AoD, clstr.TxAS);
                AoA = rand_space_angle(clstr.AoA, clstr.RxAS);
                phase_AoD = 2j * pi * fc * (Ltx_cm / 100) * cos(2 * pi * AoD / 360) / c * (0: Ntx-1).';
                phase_AoA = 2j * pi * fc * (Lrx_cm / 100) * cos(2 * pi * AoA / 360) / c * (0: Nrx-1);

                if v > 0
                    H.Doppler(icluster) = RandDoppler(v, fc);
                else
                    H.Doppler(icluster) = 0;
                end

                for itap = 1: Ntap
                    if H.Ts * (itap -1) < clstr.delay(1)
                        continue;
                    endif

                    tap_amp = 10^(interp1(clstr.delay, clstr.power, Ttap(itap), 'extrap')/20);

                    H.taps(:, :, icluster, itap) = 10^(-PL / 20) * tap_amp * (...
                                sqrt(H.K / (H.K + 1)) * exp(2j * pi * rand(Nrx, Ntx)) .* (exp(phase_AoD) * exp(phase_AoA)) + ...
                                sqrt(1 / (H.K + 1)) * (1 / sqrt(2) * (randn(Nrx, Ntx) + 1j * randn(Nrx, Ntx))) ...
                            );

                endfor
            endfor
        endfunction

        function PL = pathloss(H, model, d)

            % The path loss is set ad 70 dB when Tx-Rx distance is 5 m.
            % This is an experienced value and may be change in different environments.
            d0 = 5;
            PL0 = 70;

            if d <= d0
                error("The pathloss model may be inaccurate for d <= 5 case.");
            endif

            % The shadow is limited by 14 dB
            if d > H.breakpoint
                PL = PL0 + 20 * log10(H.breakpoint) + ...
                    35 * log10(d / H.breakpoint) + ...
                    max(H.nlos_shadow * randn(), 14);
            else
                PL = PL0 = 20 * log10(d) + max(H.los_shadow * randn(), 14);
            endif

        endfunction

        function y = channel(H, x)

            Nsamp = size(x, 2);

            Nrx = size(H.taps, 1);
            Ntx = size(H.taps, 2);
            Ncluster = size(H.taps, 3);
            Ntap = size(H.taps, 4);

            y = zeros(size(x));
            x = [zeros(Ntx, Ntap -1), x];

            % Space domain processing
            for irx = 1: Nrx
                for itx = 1: Ntx

                    taps_reshape = reshape(H.taps(irx, itx, :, :), Ncluster, Ntap);
                    % Time domain processing
                    for isamp = 1: Nsamp

                        Doppler_shift = exp(2j * pi * H.Doppler * H.Ts * (H.Nstart: H.Nstart + Ntap -1));
                        time_varying_tap = sum(taps_reshape .* Doppler_shift, 1);

                        y(irx, isamp) = y(irx, isamp) + ...
                            sum(time_varying_tap(end:-1:1) .* x(itx, isamp: isamp + Ntap -1));

                        H.Nstart = H.Nstart + 1;

                    endfor
                endfor
            endfor

        endfunction

    endmethods

endclassdef
