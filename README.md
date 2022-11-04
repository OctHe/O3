# OFDM Baseband Simulation Platform

OFDM Baseband Simulation Platform (OBSP) is a simulation platform that relates to an OFDM-based system.
The simulation platform contains only baseband processes and algorithms of the proposed OFDM system, including follows

- Modulation and demodulation
- Encoding and decoding
- Coarse and fine time synchronization
- Channel estimation

In addition, the frame structure and transmission parameters are referenced to the IEEE 802.11 standard, which is the well-known wireless protocol, but are not guaranteed to be compatible with the standard.
The project uses MATLAB 2017 and later, but the MATLAB version has not been development.
No new features will be added.

## Configuration

Before running the scripts, the configuration is required by running in the command line of Octave

    IEEE80211ac_GlobalVariables;

Then, you can run 

    simulation_OFDM_BER.m

The results will show the BER vs SNR curve.
Other simulation scripts also can be run.

The projcts also contains simulation about OFDM backscatter, please run

    simulation_FS_backscatter.m

and 

    simultion_HEMIMO.m

for detail.
