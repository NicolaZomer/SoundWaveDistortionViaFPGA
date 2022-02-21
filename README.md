# Sound wave distortion via FPGA using PMOD interface
In this project we implement on a Field Programable Gate Array (FPGA) a distortion effect in sound waves that is called "Overdrive" or "Clipping". This happens when the amplitude of a soundwave is restricted when it exceeds a given threshold. The resulting sounds are "dirty" and "fuzzy" due to the introduction of high frequency components in the signal.

We used an Artix-7 FPGA from Xilinx, together with Xilinx Vivado Design Studio 2018.3. Moreover, the Digilent Pmod I2S2 is used, in order to allow the FPGA to transmit and receive stereo audio signals via the I2S protocol.

<p align="center">
  <img src="MAPD_flowchart.png" width="500" />
</p>

