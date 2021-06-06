# Trace Driven Emulation of Rate Adaptation (TDE-RA) Project

This is a simulation platform for the rate adaptation algorithm.
The platform is based on MATLAB for off-line process because MATLAB has lots of useful toolbox to simplify the design.
The platform includes basic signal process blocks in PHY layer, including channel coding, modulation, synchronization, channel estimation.
You can design your own rate adaptation algorithm by deploying the trace-driven evaluation.
The traces can be collected from commercial wireless devices or USRP.

## Supported Standard

1. IEEE 802.11a standard (Legacy mode)

Rate adaptation for IEEE 802.11a standard is based on the [*comm toolbox*](https://www.mathworks.com/help/comm/).

2. IEEE 802.11ac standard (Very High Throughput, VHT)

Rate adaptation for IEEE 802.11ac standard is based on the [*WLAN toolbox*](https://www.mathworks.com/help/wlan/).
