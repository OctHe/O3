# SimScatter

## Introduction
This is a simulation for the physical layer of OFDM communication system and the OFDM backscatter system
The parameter setup, frame structure, and tranceiver pipelines are borrowed from IEEE 802.11 a/g/n/ac standards.

## Octave

This project wants to use the open-source Octave instead of the well-known MATLAB.
It has been tested in Debian 12 system, but is must be compatible with other operating systems that can run Octave.
It relies on the octave and the communications package, to install them, run the follow command in Debian

    sudo apt install octave-communications

The communications package and the octave can be automatically installed.
The information of the octave-communications can be shown with

    apt show octave-communications

## Configuration

Before running the IEEE 802.11n/ac scripts, the configuration is needed by running in the command window of Octave

    IEEE80211ac_GlobalVariables;

## To Do List

1. qammod cannot support BPSK
