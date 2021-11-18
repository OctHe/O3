# sim80211

This is a simulation platform for the physical layer of IEEE 802.11 standard.
The platform is based on MATLAB for off-line process because MATLAB has lots of useful toolbox to simplify the design.
It includes basic signal process blocks, such as channel coding, modulation/demodulation, channel estimation.

## Supported Standard

For now, this project supports IEEE 802.11a/g standard.
Note that IEEE 802.11a works at 5G Hz band and IEEE 802.11g works at 2.4G Hz band with the same PHY layer.

## Examples

sim80211 give lots of examples to show the simulation results.

### BER vs SNR curve

    IEEE80211g_BERvsSNR

### IEEE 802.11a/g at AWGN channel

    IEEE80211g_transceiver_rician

### IEEE 802.11a/g at Rician channel

    IEEE80211g_transceiver_rician