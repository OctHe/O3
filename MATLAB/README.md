# Trace_Driven_Simulation
This is a trace driven simulation code for 802.11a/g/n simulation. 
The transmission pipeline include rate adaptation, channel coding, modulation, sync, chanel estimation, demodulation.
Some block such as PHY header, real channel and noise, frame detection,  perform synchronization with pilot

There is a bug when I use code rate = 3. I think the reason is I make a mistake in viterbi deocoder 