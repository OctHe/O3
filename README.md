# O3

O3 means **O**pen-source **O**FDM simulation platform based on **O**ctave.
The simulation platform contains baseband processes and algorithms of the OFDM system, including follows

- Modulation and demodulation
- Encoding and decoding
- Coarse and fine time synchronization
- Channel estimation
- OFDM Backscatter

In addition, the frame structure and transmission parameters are refered from the IEEE 802.11 standard, which is the well-known wireless standard, but are not guaranteed to be compatible with it.

Note that the architecture of this project is under refactoring, so the functions may not work well.

## Configuration

If this is the first time to use Octave, please install the follows Octave forge packages in the command line of Octave:

    pkg install -forge control signal communications

It will download forge packages without super user privilege.
Before running the scripts, the configuration is required:

    pkg load communications
    IEEE80211ac_GlobalVariables

## Incompatible Scripts

This project was based on MATLAB, it works when the version is later than MATLAB 2017a.
However, since MATLAB is not open source, and I don't have the license anymore.
This project will transfer to Octave instead.
Unfortunately, Octave lacks some functions, such as scrambler and channel model.
Some scripts does not support, for now.

    simulation_FS_backscatter
    simulation_OFDM_BER
    simulation_OFDM_MIMO
    test_convolutional_code

## MATLAB version

In 2023, the project uses Octave instead of MATLAB, no new features of the MATLAB version will be considered.
The MATLAB version is in the [MATLAB branch](https://github.com/OctHe/OBSP/tree/MATLAB).

