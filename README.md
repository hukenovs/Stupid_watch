There is a LCD+TIMER on FPGA Implementation

Device: DEVKIT on Spartan3E (XC3S500E-4PQ208C)
	http://www.sz-21eda.com/

Input: PS/2 keyboard, 8 triggers, 5 buttons
PS/2 Keyboard:
	https://eewiki.net/pages/viewpage.action?pageId=28278929

Output: VGA display (640x480), LED Matrix 8x8
VGA Controller:
	https://eewiki.net/pages/viewpage.action?pageId=15925278 
 
Chips: 
DS1302  - Trickle-Charge Timekeeping Chip (Maxim Integrated)
LCD1602 - Display 16x2 with parallel interface (Noname)
 
Video: see my channel on youtube 

Software:

Aldec Active-HDL 9.3: 
	https://www.aldec.com/
Xilinx ISE 14.7: 
	http://www.xilinx.com/

Design Summary Report:

Number of External IOBs                     42 out of 158    26%
   Number of BUFGMUXs                        4 out of 24     16%
   Number of DCMs                            1 out of 4      25%
   Number of RAMB16s                         3 out of 20     15%
   Number of MULT18x18s                      0 out of 20      0%
   Number of Slices                        993 out of 4656   21%
      Number of SLICEMs                     39 out of 2328    1%
	  
Design statistics:
   Minimum period: 6.666ns{1} (Maximum frequency: 150.015MHz)