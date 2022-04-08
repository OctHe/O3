# sim80211

## Introduction
This is a simulation for the physical layer of IEEE 802.11a/g/n/ac standard.
It includes basic signal process blocks, such as channel coding, modulation/demodulation, channel estimation.

## Configuration of sim80211

Before running the scripts, the configuration is needed by running in the command window of MATLAB

    IEEE80211ac_GlobalVariables;

## Scripts for sim80211

sim80211 give lots of scripts to show different types of simulation results.

### BER curve of IEEE 802.11a/g

The simulation script can plot the curve of transmission results, such as

    simulation_BERvsSNR

### Rician channel

The transmission example of IEEE 802.11n/ac with time-varying Rician channel.
The script now supports 20~MHz bandwidth

    simulation_rician_model

### MIMO transceiver

Transmission example of IEEE 802.11n/ac with MIMO channel model.
It support concurrently transmit multiple space streams.
The TX/RX pair can support from 1 to 4.

    simulation_multiplexing



