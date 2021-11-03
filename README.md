# sim80211

This is a simulation platform for the physical layer of IEEE 802.11 standard.
The platform is based on MATLAB for off-line process because MATLAB has lots of useful toolbox to simplify the design.
It includes basic signal process blocks, such as channel coding, modulation/demodulation, channel estimation.

## Supported Standard

For now, this project supports IEEE 802.11a/g standard.
Note that IEEE 802.11a and IEEE 802.11g have the same PHY design, 
while IEEE 802.11a works at 5G Hz band and IEEE 802.11g works at 2.4G Hz band.

You can run 

    IEEE80211g_BERvsSNR.m

to get the BER vs SNR curve.

