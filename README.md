# sim80211

This is a simulation platform for the physical layer of IEEE 802.11 standard.
The platform is based on MATLAB for off-line process because MATLAB has lots of useful toolbox to simplify the design.
It includes basic signal process blocks, such as channel coding, modulation/demodulation, channel estimation.

## Supported Standard

For now, this project supports IEEE 802.11a/g/n/ac standard.
Note that IEEE 802.11a works at 5G Hz band and IEEE 802.11g works at 2.4G Hz band with the same PHY layer.

IEEE 802.11n/ac use a different PHY layer with 56 subcarriers, so we rewrite new files for them.

## Simulations

sim80211 give lots of examples to show the simulation results.

The curve of BER vs SNR can be found when running

    IEEE80211g_BERvsSNR

On-shot transmission of IEEE 802.11a/g with different channel models can be found:

    IEEE80211g_transceiver_awgn
    IEEE80211g_transceiver_rician

## Files for GNURadio

sim80211 provides a tool to generate signals of IEEE 802.11 standard, which can directly as an input file to GNURadio with file sink.

As an example, you can run
    
    IEEE80211ac_preamble_to_gnuradio.m

