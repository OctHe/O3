# sim80211

## Introduction
This is a simulation for the physical layer of IEEE 802.11a/g/n/ac standard.
It includes basic signal process blocks, such as channel coding, modulation/demodulation, channel estimation.

## Scripts for sim80211

sim80211 give lots of scripts to show different types of simulation results.

### Simulations

The simulation script can plot the curve of transmission results, such as

    simulation_BERvsSNR

### Transceivers

trasceiver scripts give one-shot transmission of IEEE 802.11a/g standard with different channel modlels.

    transceiver_awgn
    transceiver_rician

### Tools for GNURadio

sim80211 provides a tool to generate indicated signals of IEEE 802.11 standard.
The files are compatible with the *file source* block for GNURadio 3.7.11.

As an example, you can run
    
    tool_preamble_to_gnuradio

