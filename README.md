
RetroVerse
==========

###### *Started August 06, 2023*

A series of computer cards using the [VME bus](https://en.wikipedia.org/wiki/VMEbus) as a common
backplane, in the style of modular computer equipment, laboratory test equipment, and industrial
controls systems.

I've always liked the VME bus for its adaptability.  It's an asynchronous bus with dynamic sizing,
so it can support both controllers and peripherals that require different signaling speeds and bus
widths to communicate, without requiring a specialized bus interface chip.  It supports multiple
controllers without the need for a special slot on the backplane, because it uses daisy chained
priority bus arbitration.  It's based on the Eurocard standard form factor (VME stands for Versa
Module Eurocard), and uses standard and readily available DIN41612 connectors, comes in a 3U
variant, and it's possible to still buy equipment that conforms to the standard, namely card cases
and power supplies.  The 3U Eurocard standard, which uses 160x100mm boards, is also fairly
affordable for PCB printing, and it's possible to make 100x100mm cards, which can be printed for as
low as $2.  The bus is perhaps slow by modern standards, but for CPUs that are below 100MHz, it's
the perfect bus to build 16-bit and 32-bit retro computers around.

The project name comes from retro computers (newly designed computers based on old CPUs and parts),
and the V in VME which stands for Versa.

I have ordered an off-the-shelf desktop card case from
[Schroff](https://schroff.nvent.com/en-de/products/enc24576-106) via Digikey, on backorder, a used
Schroff 3U 11-slot backplane from eBay, and I plan to adapt an affordable [MeanWell power
supply](https://www.meanwell.com/productPdf.aspx?i=488) to power it.  I'm hoping to be able to
install multiple CPU cards into the same system to make a simple multiprocessor machine.  I've
already made a generic card using a microcontroller wired to the bus, that I intended to use as a
bus analyzer called
[BigBoy](https://github.com/transistorfet/retroverse/tree/main/components/bigboy), but it's a bit
too slow for that so I'll try instead to use it as a generic peripheral.  I've also made a CPU card
with a MC68030, onboard RAM, Flash, and serial ports, and a small 16-bit memory card with up to 4MB
of static RAM, a board for handling the bus arbitration and interrupt signals on the bus (separate
instead of as part of the CPU card because it will be a multiprocessor system), and I've built Tom's
CompactFlash card from [COMET](https://github.com/tomstorey/COMET) to use as the main storage drive for the system.

I had originally intended to design and build my own backplane using 4-row connectors with some of
the P2 connector's signals on an extended P1, but I abandoned that idea in the interest of
interoperability and ended up buying a used 11-slot Schroff backplane from eBay.  Tom Storey has
designed a 3-slot and 8-slot backplane as part of [COMET](https://github.com/tomstorey/COMET) which
is a good choice for those who wish to build their own.

I also intend to eventually make a 68010 version using only DIP chips and hopefully all hardwired
logic, so that there's no need for specialized PLD programmers.  I might also make cards with other
CPUs.  It should be possible for the system to support different CPUs in the same system at the same
time, running their own code.  My larger hope is for the VME bus to be used more broadly in the
hobbyist retro computer community as a common means of constructing systems.

Some of the design and build process was live-streamed and recordings are available at
[youtube.com/@transistorfet](https://www.youtube.com/@transistorfet)


Why VMEbus?
-----------

* it uses the eurocard form factor, and equipment such as cases can still be bought new or used

* it's asynchronous, so it can support devices operating at different speeds

* it supports dynamic bus sizing for 8-bit, 16-bit, and multiplexed 32-bit operations in 3U

* in the 6U form factor, it can also support full 32-bit or multiplexed 64-bit operations

* the DIN41612 connectors it uses are still widely available with solder tails

* supports cheap 3U board sizes of 100mm x 160mm or 100mm x 100mm

* also supports 6U board sizes for bigger and more complex devices


Why Not VMEBus?
---------------

* it can be a bit more complicated to interface to for simple 8-bit systems

* it's slower than newer buses like CompactPCI

* when using passive termination instead of active termination, it can draw a lot of current (2A+)
  with no cards

* each signal can draw a fair amount of current, which may be out of range for some logic chips (the
  standard requires that each pin can sink 48mA or more but typically it's <25mA in smaller and
  slower systems)


About VMEbus
------------

* [Understanding VMEBus](https://mdavidsaver.github.io/epics-doc/vme/understanding-vme.pdf)
* [VME FAQ from VITA](https://www.vita.com/VMEbus-FAQ)
* [VME P1 Connector Pinout](https://allpinouts.org/pinouts/connectors/buses/vme-versamodule-eurocard-p1/)
* [VME64](https://www.ge.infn.it/~musico/Vme/Vme64.pdf)


Other VME Projects
------------------

#### VMEbus prototyping card PCB:

* [https://github.com/rhaamo/VME](https://github.com/rhaamo/VME)

#### Proto Boards, Blanking Plates, Plate Adapters, ECB backplanes:

* [https://www.ebay.ca/usr/martenelectric](https://www.ebay.ca/usr/martenelectric)
* [https://www.martenelectric.cz/index.html](https://www.martenelectric.cz/index.html)

#### COMET backplane, prototyping card, and single board computer:

* [https://hackaday.io/project/192539-comet68k](https://hackaday.io/project/192539-comet68k)
* [https://github.com/tomstorey/COMET](https://github.com/tomstorey/COMET)
* computer card is missing bus arbitration, but the backplane supports it

[If you know of any other hobbyist VME components or projects that others can build, please get in
contact with me.  I'd love to add them to this list]


Single-CPU System
-----------------

This is generally where I'm at, as of January 2025.  I have a simple single-CPU system with
SystemBoard, k30p-VME, Tom Storey's CF Card, and MemBird Woodcock (although it's not used by the
software atm).  It can boot [Gloworm](https://github.com/transistorfet/gloworm), using the CF card
as the ATA device, and the FTDIs on k30p as the TTY and network SLIP connection.  I can ping it from
my computer over SLIP, and run applications off the CF card.

![alt text](images/basic-single-cpu-system-angle.jpg "A green PCB backplane that says Schroff with white DIN41612 connectors, and 4 cards plugged into the first 4 of 11 slots.  The first and last are short 100mm long cards with the last being red and shown clearly while the first is black and is mostly obscured by the others.  The second card is purple with a white aluminum frontpanel that says 'ComputieVME', a Motorola logo, and 'k30p-VME' near the top in black text, with a trapezoid grey handle at the bottom, and two USB-C cables coming out of the frontpanel, the top one being a mauve and the the bottom being a light teal green.  The third card is green and has a compact flash card sticking out the top with no frontpanel.  The view is looking mostly down and to the left with the backplane flat on a black metal shelving unit about waist high, with the cards sticking upwards.  An oscilloscope can be be seen on the same shelf behind the backplane, and a small white fan is just out of view.")
![alt text](images/basic-single-cpu-system-side-angle.jpg "A green PCB backplane with white DIN41612 connectors, and 4 cards plugged into the first 4 of 11 slots.  The first and last are short 100mm long cards with the last being red and can mostly been seen while the first is black and is mostly obscured by the others.  The second card is purple with a white aluminum frontpanel with a trapezoid grey handle at the bottom, and two USB-C cables coming out of the frontpanel, the top one being a mauve and the the bottom being a light teal green.  The third card is green and has a compact flash card sticking out the top with no frontpanel.  The view is looking mostly sideways and a bit to the left, with backplane flat on a black metal shelving unit about waist high, with the cards sticking upwards.  An oscilloscope can be be seen on the same shelf behind the backplane, partially obscured by the cards.  A small white fan is just out of view, and a small teal desk lamp is in the foreground shining on the cards.")


Desktop Case
------------

I bought a brand new Schroff PropacPro 3U 63HP 266mm deep Unshielded Complete Desktop case.  I
initially requested a quote from Schroff, but unsurprisingly they sent me back a list of authorized
redistributors instead.  It turned out that Digikey did actually have the cases available for
backorder but the listing was uncategorized, so you had to search specifically for the part number
to find it.

* [https://schroff.nvent.com/en-ca/products/enc24576-006](https://schroff.nvent.com/en-ca/products/enc24576-006)
* [https://www.digikey.ca/en/products/detail/schroff/24576006/24659562](https://www.digikey.ca/en/products/detail/schroff/24576006/24659562)


Backplane
---------

I bought a Schroff 23000-041 11-Slot backplane, used from eBay.  Luckily it has automatic
daisy-chaining, so when a slot doesn't have a card in it, the daisy-chained signals are shorted in
order to bypass that slot.  It also has active termination, which I have enabled with the jumpers,
so it takes only 10mA or so of 5V power without any cards connected.

![alt text](images/Schroff-backplane-front.jpg "Schroff 23000-041 11-Slot VME Backplane with a green PCB and white DIN41612 connectors")


k30p-VME
--------

A CPU card with a Motorola 68030 CPU, and an ATF1508AS CPLD for the control logic.  It has 2MB of
static RAM onboard, 512KB of Flash, a MC68681 dual serial port controller, with space for two
onboard FTDIs, and some push-button and LEDs that can be controlled by the serial controller.  The
CPLD can control the onboard transceivers to make a VME request from the CPU, based on the address
that the CPU is requesting.  I've tested it with 8-bit and 16-bit cycles, but I've designed it with
the transceivers that are required to make an A40/MD32 bus access, and hope to implement it soon
using BigBoy as the test peripheral.

While building the first revision, I found a number of issues.  The transceivers don't turn off when
the CPLD is being programmed, or when it's unprogrammed, and that means they write into each other,
and can damage each other.  I reworked in some pull-up resistors for the /OE signals to disable the
transceivers when the CPLD outputs are low or tri-stated.  I also originally had the FTDI powered by
the board, which meant it would disconnect from the computer every time the board was power cycled,
which was quite problematic when testing.  I tried to rework it so that it was powered by the USB
bus, but at first that didn't work.  After replacing the chip with an external FTDI, I tried
reworking it again and found that the USB-C cable only works in one orientation because I don't have
the main differential pair from each side of the USB-C connector jumped together.  The full errata
is here:
[k30p-VME-rev1-errata](https://github.com/transistorfet/retroverse/blob/main/components/computie-vme/hardware/k30p-VME/revisions/k30p-VME-rev1-errata.txt)

![alt text](images/k30p-VME-rev.1-reworked-assembled.jpg "The fully assembled and unplugged k30p-VME CPU Card, with purple solder mask, white silkscreen text, and a big greyish-white DIN41612 connector on the right side.  A big black plastic PGA chip in the centre reads MC68030RP33B.  There is some rework to the transceivers on the right, with some chip resistors and red 30AWG wire soldered in place, and some red 30AWG wire around the FTDIs on the left to power them from the USB bus.  A mauve-coloured USB-C cable is connected to the first USB port and a teal green USB-C cable is connected to the second USB port (bottom)")
![alt text](images/k30p-VME-rev.1-reworked-assembled-in-backplane.jpg "The fully assembled k30p-VME CPU Card in the backplane, with purple solder mask and white silkscreen text")
![alt text](images/k30p-rev.1-frontpanel.jpg "The frontpanel, which is an aluminum PCB with white solder mask and black text labels, with the name 'ComputieVME' at the top, a Motorola logo beside the screw for the card bracket behind, and 'k30p-VME' below that.  Next are two green LEDs side by side labelled 'STATUS / RUN', then a red reset button, then 4 yellow LEDs in a 2 x 2 pattern with labels 'OP 4 / OP5' and 'OP6 / OP7', and then two black buttons next to each other labelled 'IP 2 / IP3'. Then there are two USB-C connectors angled up and down with a mauve cable in the USB1 and a teal green cable in USB2.  Finally there is a grey trapezoid handle from Schroff with a bare aluminum front piece that is mostly obscuring the rest of the handle.  The top and bottom have screws to hold the card into a case (which isn't present) with grey plastic collars to hold the screws in place.")


MemBird Woodcock
----------------

A memory card with up to 4MB of either Static RAM or Pseudo-static RAM powered by either 5V or 3.3V,
which can be selected by a soldered jumper and by using different chips (memory and transceiver
chips in particular).  It can only respond to A24 cycles, and only 8-bit or 16-bit accesses, but
that should serve well enough as common memory for when I have multiple CPU cards.  In future I will
make another MemBird board with an FPGA and SDRAM to allow for 128MB+ of memory, but until then,
this will suffice.

The building of this board went really smoothly.  Soldering went better than normal for SMT parts.
I was using ChipQuik NoClean Liquid flux, which worked well.  I only had one chip that was visibly
unconnected on closer inspection, and I didn't find any unintended bridges.  The board was behaving
strangely when I first tested it before I cleaned the flux off, but once I cleaned it and let it dry
overnight, it worked perfectly.

It's named after the American Woodcock, a small bird that moves along with a slow rhythmic walk,
since this card only has a small amount of memory, and will be slower to access, being only 16-bits.

![alt text](images/MembirdWoodcock-rev.1-assembled.jpg "The fully assembled and unplugged MemBird Woodcock Memory Card, with red solder mask, white silkscreen text, and a big greyish-white DIN41612 connector on the right side.  A silkscreen picture of an American Woodcock bird is near the top.")
![alt text](images/MembirdWoodcock-rev.1-assembled-in-backplane.jpg "The fully assembled MemBird Woodcock Memory Card in the backplane, with red solder mask and white silkscreen text")


SystemboardSMT
--------------

A system board with an ATF1508AS in the centre, and a clock, and that's about it.  It's primary
function is to handle the bus arbitration logic, but I can also use it as a dummy 8-bit peripheral
for testing.

I designed and built this board second, before the k30p and MemBird Woodcock, because it was simple
and would act as a test for the ATF1508, which I hadn't used before (other than in the devkit I
bought from Atmel).  The initial logic for the bus arbitration state machine turned out to be very
wrong, and that was causing problems for the k30p, which was hanging indefinitely.  I thought it was
the k30p's logic, but it turned out it wasn't receiving the bus grant from this card.

![alt text](images/SystemboadSMT-rev.1-assembled.jpg "The fully assembled and unplugged SystemboardSMT System Card, with matte black solder mask, white silkscreen text, and a big greyish-white DIN41612 connector on the right side.")
![alt text](images/SystemboadSMT-rev.1-assembled-in-backplane.jpg "The fully assembled SystemboardSMT System Card in the backplane, with matte black solder mask, white silkscreen text")


BigBoy
------

This was the first card I made and I intended to use it as a bus analyzer among other things, but
it's a bit too slow to catch most cycles, so I think I'll need an FPGA card instead for that
function, but it can work as a slow peripheral.  It has an STM32H743 microcontroller in a 208 pin
QFP package in the centre with the 5V tolerant I/O connected directly to the VME bus for the control
signals, and through transceivers for the data and address signals.  On the board is also a 100BaseT
ethernet interface, a full speed USB port (so 12Mbps I assume is the fastest), a microSD card slot
(where I accidentally put the footprint on backwards), and a few headers for external FTDIs, I2C,
and SPI device.

It's called BigBoy because it has the big boy microcontroller in the largest TQPF package available,
with a big 4-row DIN41612 connector which was an idea to add an extra row to P1 for the upper data
and address signals of a 32-bit system, which is optional (the 4-row connector can be plugged into a
3-row or 4-row backplane).  I've mostly abandoned this idea in favour of sticking to the standard,
and using the A40/MD32 cycle on a 3U system, or perhaps eventually making a 6U system and cards if I
want full-sized, higher speed, 32- or 64-bit systems in the future, all while maintaining
interoperability with existing used backplanes.  The logo is of [Bronson the
Cat](https://www.instagram.com/iambronsoncat/?hl=en) who is *such a big boy*

![alt text](images/BigBoy-rev.1.jpg "A PCB with blue solder mask and white silkscreen with a large black chip in the centre at a 45 degree angle with the text on it upside down (unintentionally design that way). It has a large grep DIN41612 connector on the right side, and a metal-shielded RJ-45 jack and some buttons and LEDs on the left.")
![alt text](images/BigBoy-rev.1-assembled.jpg "A PCB with blue solder mask and white silkscreen with a large black chip in the centre at a 45 degree angle with the text on it upside down, plugged into a green backplane with the card sticking upwards.  A rainbow of others cards can just be seen behind the blue card: red, green, purle, and black from nearest to furthest.")
![alt text](images/BigBoy-rev.1-frontpanel.jpg "The frontpanel, which is an aluminum PCB with white solder mask and black text labels, with the name 'BigBoy' at the top, above a chrome-plated screw.  Next downard are 4 blue LEDs in a 2 x 2 pattern, two black pushbuttons side-by-side, a microSD card slot, a micro USB connector with a large oval cutout in the frontpanel, and then an RJ-45 jack with a very large square cutout in the frontpanel which leaves less than a millimeter of aluminum on the top side of the connector/right side of the panel when oriented vertically.")

