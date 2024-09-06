<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
Stochastic Multiplier, Adder and Self-Multiplier. 
Using bipolar representation, takes 2 9-bit streams as input and outputs the average product, sum and product in 9-bits after 2^17+1 clk cycles.


## How to test
Input 2 repeating streams of 9 bits (+1 bit buffer) that represent the numbers to be multiplied/added and read the serial output result, which is also 9bits (+1 bit buffer).
The self multiplier only processes input from the 1st stream.

## External hardware
ADALM2000
