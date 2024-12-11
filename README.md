
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
priority bus arbitration.  It uses standard and readily available DIN41612 connectors, comes in a 3U
variant, and it's possible to still buy equipment that conforms to the standard, namely card cases
and power supplies.  The 3U Eurocard standard, which uses 160x100mm boards, is also fairly
affordable for PCB printing, and it's possible to make 100x100mm cards, which can be printed for as
low as $2.  The bus is perhaps slow by modern standards, but for CPUs that are below 100MHz, it's
the perfect bus to build 16-bit and 32-bit retro computers around.

My intention is to build a backplane, dedicated bus arbitration and interrupt controller card, and a
generic 68030-based CPU card to start.  I have ordered an off-the-shelf desktop card case from
[Schroff](https://schroff.nvent.com/en-de/products/enc24576-106) via Digikey, on backorder, and I
plan to adapt an affordable [MeanWell power supply](https://www.meanwell.com/productPdf.aspx?i=488).
I'm hoping to be able to install multiple CPU cards into the same system to make a simple
multiprocessor machine.  I've already made a generic card using a microcontroller wired to the bus,
that I intended to use as a bus analyzer called
[BigBoy](https://github.com/transistorfet/retroverse/tree/main/controllers/bigboy), but I haven't
written software for it yet.

I also intend to eventually make a 68010 version using only DIP chips and hopefully all hardwired
logic, so that a specialized PLD programmer won't be needed to build one.  I might also make cards
with other CPUs.  It should be possible for the system to support different CPUs in the same system
at the same time.  My larger hope is for the VME bus to be used more broadly in the hobbyist
computer community as a common means of interoperability.


Why VMEbus?
-----------

* it uses the eurocard form factor, and equipment such as cases can still be bought new or used

* it's asynchronous, so it can support devices operating at different speeds

* the DIN41612 connectors it uses are still widely available with solder tails


[Understanding VMEBus](https://mdavidsaver.github.io/epics-doc/vme/understanding-vme.pdf)
[VME FAQ from VITA](https://www.vita.com/VMEbus-FAQ)
[VME P1 Connector Pinout](https://allpinouts.org/pinouts/connectors/buses/vme-versamodule-eurocard-p1/)
[VME64](https://www.ge.infn.it/~musico/Vme/Vme64.pdf)


Other VME Projects
------------------

VMEbus prototyping card PCB:
    - https://github.com/rhaamo/VME

Proto Boards, Blanking Plates, Plate Adapters, ECB backplanes:
    - https://www.ebay.ca/usr/martenelectric
    - https://www.martenelectric.cz/index.html

COMET backplane, prototyping card, and single board computer:
    - https://hackaday.io/project/192539-comet68k
    - https://github.com/tomstorey/COMET
    - computer card is missing bus arbitration, but the backplane supports it


Desktop Case
------------

I bought a brand new Schroff PropacPro 3U 63HP 266mm deep Unshielded Complete Desktop case.  I
initially requested a quote from Schroff, but unsurprisingly they sent me back a list of authorized
redistributors instead.  It turned out that Digikey did actually have the cases available for
backorder but the listing was uncategorized, so you had to search specifically for the part number
to find it.

https://schroff.nvent.com/en-ca/products/enc24576-006
https://www.digikey.ca/en/products/detail/schroff/24576006/24659562?s=N4IgTCBcDaIARgCwFYDsA2AtABm%2BkAugL5A

