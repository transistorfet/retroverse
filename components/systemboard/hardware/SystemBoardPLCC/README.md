
SystemBoard
===========

Status: Never Built

Latest: Rev. 1

### About

A somewhat generic card with an ATF1508 programmable logic device, which is intended to act as the
system board of the VME bus, handling the resolution and granting of the bus during bus
arbitration, and interrupt acknowledging.  It has a clock and a reset button, which can be
programmed in the logic to reset all devices on the bus.

I have not actually built this version of the card, and instead built the SystemBoardSMT after
finding out that the PLCC version of the ATF1508AS was End-of-Life, and out of stock at Digikey
and Mouser.  It should work, but I'd recommend comparing the signals to the other version.  There
maybe be one or two signals that should be shuffled, depending on what's most important.

