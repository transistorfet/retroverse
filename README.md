
RetroVerse
==========

###### *Started August 06, 2023*

A series of computer cards using the [VME bus](https://en.wikipedia.org/wiki/VMEbus) as a common
backplane, in the style of laboratory test equipment and modular industrial computers.

I've always liked the VME bus for its adaptability.  It's an asynchronous bus with dynamic sizing,
so it can support both controllers and peripherals that require different signaling speeds and bus
widths to communicate, without requiring a specialized bus interface chip.  It supports multiple
controllers without the need for a special slot on the backplane, because it uses daisy chained
priority bus arbitration.  It uses standard and readily available DIN41612 connectors, comes in a 3U
variant, and it's possible to still buy equipment that conforms to the standard, namely card cases
and power supplies.  The 3U Eurocard standard, which uses 160x100mm boards, is also fairly
affordable for PCB printing, and it's possible to make 100x100mm cards, which can be printed for as
low as $2.  The bus is perhaps slow by modern standards, but for CPUs that are below 100MHz, it's
the perfect bus to build 16- and 32-bit retro computers around.

My intention is to build a backplane, dedicated bus arbitration and interrupt controller card, and a
generic 68030-based CPU card to start.  I'll buy an off-the-shelf card case (possibly from
[Schroff](https://schroff.nvent.com/en-de/products/enc24576-106)) and a power supply.  I'm hoping to
be able to install multiple CPU cards into the same system to make a simple multiprocessor machine.
I'll also make either a [Fidget-based](https://github.com/transistorfet/fidget) FPGA card, or a
microcontroller-based card for debugging the bus, and acting as the first peripheral card on the
bus.

Once the base system is complete, I'll make a RAM board, possibly a disk drive or CompactFlash
controller card, and an ethernet card.  I also intend to eventually make a 68010 version using only
DIP chips and hopefully all hardwired logic, so that a specialized PLD programmer won't be needed to
build one.  I might also make cards with other CPUs.  It should be possible for the system to
support different CPUs in the same system at the same time.  My larger hope is for the VME bus to be
used more broadly in the hobbyist computer community as a common means of interoperability.



Ok hear me out.  Apple][s are really cool, but they're pretty big, especially with that CRT.  Who has
space for that in their daily work areas, and if it's not easily accessible, it might as well be on
another planet for how often it will get used.  No no no, it's gotta be more compact so it's easily
accessible.

Look at all these boards: <picture>
Each project is another board with more wires, stacked on more boards, with ribbon cables, on my desk
collecting dust, always in the way!  This will not do!  There must be a way to work on multiple things
at once, while taming this mess!

Enter the Eurocard form factor.  An existing standard with existing desktop equipment enclosures, like
this: <picture>

If each project can fit in the same case, connect to the same power supply, and maybe even share the
same bus, it can all sit on the shelf beside me.  While 3U and 6U desktop cases are not cheap, they are
about the same cost as about two to three prototype board revisions.  The readymade VME cases are about
ten times as much, but maybe we can make a cheap backplane for much less.  We're not using this for
industrial purposes after all.


Why VMEbus?
-----------

* it uses the eurocard form factor, and equipment such as cases can still be bought new or used

* it's asynchronous, so it can support devices operating at different speeds

* the DIN41612 connectors it uses are still widely available with solder tails



Hobbyist VME equipment
----------------------

VMEbus prototyping card PCB: https://github.com/rhaamo/VME

Proto Boards, Blanking Plates, Plate Adapters, ECB backplanes: https://www.ebay.ca/usr/martenelectric

COMET backplane, prototyping card, and single board computer:
    - https://hackaday.io/project/192539-comet68k
    - https://github.com/tomstorey/COMET
    - computer card is missing bus arbitration, but the backplane supports it


VME Equipment Manufacturers
---------------------------

