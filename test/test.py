# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT
#imnport the coco functionality
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

prbs_size=31 #Size of the LSFR
#Fill two lists with 0's
PRBSN=[0]*prbs_size
PRBSO=[0]*prbs_size
#It will not work if all the FFs are set to zero.  
#Set the highest register to 1
PRBSO[prbs_size-1]=1
# Set number of clock cycles to test.
n_clock=10000
#set output lists to 1
out=[1]*(n_clock)
# Run thoughthe simulation to create the idealized output.
for i in range(n_clock):
  #input the feedback
  PRBSN[0]=PRBSO[27]^PRBSO[30]
  #shift the vlaues
  for j in range(prbs_size-1):
    count=prbs_size-j-1
    PRBSN[count]=PRBSO[count-1]
  #update the array
  for j in range(len(PRBSN)):
    PRBSO[j]=PRBSN[j]    
  #take the output from the rightmost FF.
  out[i]=PRBSN[prbs_size-1]
#Start the test  
@cocotb.test() 
async def test_project(dut):
    dut._log.info("Start")
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    #Start the clock
    cocotb.start_soon(clock.start())

    # Run through reset sequence.  Start low, go high, go back to low. The test begins when the reset goes low.
    dut._log.info("Reset")
    #Set inputs for enable, ui_in and uio_in
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    #Set reset to 0
    dut.rst_n.value = 0
    #wait 5 clock cycle
    await ClockCycles(dut.clk, 5)
    #Set reset to 1
    dut.rst_n.value = 1
    # wait for five clock cycles.
    await ClockCycles(dut.clk, 5)
    #Set reset to 0
    dut.rst_n.value = 0
    #True test begins here.
    dut._log.info("Test project behavior")
    #Compare output to theory for each clock cycle
    for i in range(0,n_clock):
    # Wait for one clock cycle to see the output values
    	await ClockCycles(dut.clk, 1)
    # The following assertion is just an example of how to check the output values.
    # Test (assert) that we are getting the expected output. 
    	assert dut.uo_out[0].value == out[i]

