# OOM

OOM means Open-source OFDM simulation based on Matlab.
The simulation platform contains baseband processes and algorithms of the OFDM system, including follows

- Modulation and demodulation
- Encoding and decoding
- Coarse and fine time synchronization
- Channel estimation
- OFDM Backscatter

In addition, the frame structure and transmission parameters are referenced to the IEEE 802.11 standard, which is the well-known wireless protocol, but are not guaranteed to be compatible with the standard.
The project uses Matlab 2017 and later, but the Matlab version has not been development.
Since I don't have Matlab license anymore, no new features and bug fixes will be added in the near future.

## Configuration

Before running the scripts, the configuration is required by running in the command line of Matlab

    IEEE80211ac_GlobalVariables;

## OFDM Baseband Scripts

Then, you can run 

    simulation_OFDM_BER.m

The results will show the BER vs SNR curve.
Other simulation scripts also can be run.

## OFDM Backscatter Scripts

The projcts also contains simulation about OFDM backscatter, please run

    simulation_FS_backscatter.m

and 

    simultion_HEMIMO.m

for detail.
