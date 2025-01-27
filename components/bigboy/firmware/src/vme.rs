
use core::ops::Deref;
use core::convert::Infallible;
use rtt_target::rprintln;

use stm32h7xx_hal as hal;
use hal::prelude::*;
use hal::pac::gpioa;
use hal::hal::digital::v2::{StatefulOutputPin, OutputPin, InputPin, PinState, ToggleableOutputPin};
use hal::gpio::{ErasedPin, DynamicPin, Pin, Output, OpenDrain, PushPull, Input};
use hal::delay::Delay;

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum Direction {
    Output,
    Input,
}

pub trait Transceiver {
    fn enable(&mut self);
    fn disable(&mut self);
    fn direction(&mut self) -> Direction;
    fn set_direction(&mut self, direction: Direction);

    fn enable_output(&mut self) {
        self.disable();
        self.set_direction(Direction::Output);
        self.enable();
    }
}

pub struct TransceiverPins<OE, DIR>
where
    OE: StatefulOutputPin,
    DIR: StatefulOutputPin,
{
    oe: OE,
    dir: DIR,
}

impl<OE, DIR> TransceiverPins<OE, DIR>
where
    OE: StatefulOutputPin,
    DIR: StatefulOutputPin,
{
    pub fn new(oe: OE, dir: DIR) -> Self {
        Self {
            oe,
            dir,
        }
    }
}

impl<OE, DIR> Transceiver for TransceiverPins<OE, DIR>
where
    OE: StatefulOutputPin,
    DIR: StatefulOutputPin,
{
    #[inline]
    fn enable(&mut self) {
        let _ = self.oe.set_low();
    }

    #[inline]
    fn disable(&mut self) {
        let _ = self.oe.set_high();
    }

    #[inline]
    fn direction(&mut self) -> Direction {
        if let Ok(true) = self.dir.is_set_high() {
            Direction::Output
        } else {
            Direction::Input
        }
    }

    #[inline]
    fn set_direction(&mut self, direction: Direction) {
        let _ = match direction {
            Direction::Output => self.dir.set_high(),
            Direction::Input => self.dir.set_low(),
        };
    }
}


pub struct BusPins<HT, LT, H, L>
where
    HT: Transceiver,
    LT: Transceiver,
    H: Deref<Target = gpioa::RegisterBlock>,
    L: Deref<Target = gpioa::RegisterBlock>,
{
    name: &'static str,
    high_t: HT,
    low_t: LT,
    high: H,
    low: L,
    direction: Direction,
}

impl<HT, LT, H, L> BusPins<HT, LT, H, L>
where
    HT: Transceiver,
    LT: Transceiver,
    H: Deref<Target = gpioa::RegisterBlock>,
    L: Deref<Target = gpioa::RegisterBlock>,
{
    pub fn new(name: &'static str, mut high_t: HT, mut low_t: LT, high: H, low: L) -> Self {
        let direction = Direction::Output;

        high_t.disable();
        low_t.disable();
        high_t.set_direction(direction);
        low_t.set_direction(direction);

        high.moder.write(|w| unsafe { w.bits(0x5555_5555) });
        high.otyper.write(|w| unsafe { w.bits(0x0000_0000) });
        high.ospeedr.write(|w| unsafe { w.bits(0xFFFF_FFFF) });
        high.odr.write(|w| unsafe { w.bits(0x0000) });

        low.moder.write(|w| unsafe { w.bits(0x5555_5555) });
        low.otyper.write(|w| unsafe { w.bits(0x0000_0000) });
        low.ospeedr.write(|w| unsafe { w.bits(0xFFFF_FFFF) });
        low.odr.write(|w| unsafe { w.bits(0x0000) });

        Self {
            name,
            high_t,
            low_t,
            high,
            low,
            direction,
        }
    }
}

impl<HT, LT, H, L> Bus for BusPins<HT, LT, H, L>
where
    HT: Transceiver,
    LT: Transceiver,
    H: Deref<Target = gpioa::RegisterBlock>,
    L: Deref<Target = gpioa::RegisterBlock>,
{
    #[inline]
    fn enable(&mut self) {
        self.high_t.enable();
        self.low_t.enable();
    }

    #[inline]
    fn disable(&mut self) {
        self.high_t.disable();
        self.low_t.disable();
    }

    #[inline]
    fn set_direction(&mut self, direction: Direction) {
        self.disable();

        self.high_t.set_direction(direction);
        self.low_t.set_direction(direction);
        self.direction = direction;

        match direction {
            Direction::Output => {
                self.high.moder.write(|w| unsafe { w.bits(0x5555_5555) });
                self.low.moder.write(|w| unsafe { w.bits(0x5555_5555) });
            },
            Direction::Input => {
                self.high.moder.write(|w| unsafe { w.bits(0x0000_0000) });
                self.low.moder.write(|w| unsafe { w.bits(0x0000_0000) });
            },
        }
    }

    #[inline]
    fn output(&mut self, value: u32) {
        if self.direction == Direction::Output {
            self.high.odr.write(|w| unsafe { w.bits(value >> 16) });
            self.low.odr.write(|w| unsafe { w.bits(value) });

            self.high_t.enable();
            self.low_t.enable();
        }
    }

    #[inline]
    fn input(&mut self) -> u32 {
        match self.direction {
            Direction::Input => {
                let high = self.high.idr.read().bits();
                let low = self.low.idr.read().bits();
                (high << 16) | (low & 0xFFFF)
            }
            Direction::Output => {
                let high = self.high.odr.read().bits();
                let low = self.low.odr.read().bits();
                (high << 16) | (low & 0xFFFF)
            }
        }
    }
}


pub trait Bus {
    fn enable(&mut self);
    fn disable(&mut self);
    fn set_direction(&mut self, direction: Direction);
    fn output(&mut self, value: u32);
    fn input(&mut self) -> u32;
}

#[derive(Copy, Clone, Debug)]
pub enum ReadWrite {
    Read,
    Write,
}

#[derive(Copy, Clone, Debug)]
pub enum AccessType {
    A16UserRead = 0x29,
    A24UserRead = 0x39,
}



pub trait AddressModifier {
    fn set_direction(&mut self, direction: Direction);
    fn output(&mut self, value: u8);
    fn input(&mut self) -> u8;
}


pub struct AddressModifierPins {
    pub am0: DynamicPin<'G', 5>,
    pub am1: DynamicPin<'G', 6>,
    pub am2: DynamicPin<'G', 7>,
    pub am3: DynamicPin<'G', 8>,
    pub am4: DynamicPin<'G', 9>,
    pub am5: DynamicPin<'G', 10>,
    pub direction: Direction,
}

impl AddressModifierPins {
    pub fn new(
        am0: DynamicPin<'G', 5>,
        am1: DynamicPin<'G', 6>,
        am2: DynamicPin<'G', 7>,
        am3: DynamicPin<'G', 8>,
        am4: DynamicPin<'G', 9>,
        am5: DynamicPin<'G', 10>,
    ) -> Self {
        Self {
            am0,
            am1,
            am2,
            am3,
            am4,
            am5,
            direction: Direction::Input,
        }
    }
}

impl AddressModifier for AddressModifierPins {
    #[inline]
    fn set_direction(&mut self, direction: Direction) {
        self.direction = direction;

        match direction {
            Direction::Output => {
                self.am0.make_open_drain_output();
                self.am1.make_open_drain_output();
                self.am2.make_open_drain_output();
                self.am3.make_open_drain_output();
                self.am4.make_open_drain_output();
                self.am5.make_open_drain_output();
            },
            Direction::Input => {
                self.am0.make_floating_input();
                self.am1.make_floating_input();
                self.am2.make_floating_input();
                self.am3.make_floating_input();
                self.am4.make_floating_input();
                self.am5.make_floating_input();
            },
        }
    }

    #[inline]
    fn output(&mut self, value: u8) {
        self.am0.set_state(PinState::from(value & 1 != 0));
        self.am1.set_state(PinState::from(value & (1 << 1) != 0));
        self.am2.set_state(PinState::from(value & (1 << 2) != 0));
        self.am3.set_state(PinState::from(value & (1 << 3) != 0));
        self.am4.set_state(PinState::from(value & (1 << 4) != 0));
        self.am5.set_state(PinState::from(value & (1 << 5) != 0));
    }

    #[inline]
    fn input(&mut self) -> u8 {
        (self.am0.is_high().unwrap() as u8) << 0 |
        (self.am1.is_high().unwrap() as u8) << 1 |
        (self.am2.is_high().unwrap() as u8) << 2 |
        (self.am3.is_high().unwrap() as u8) << 3 |
        (self.am4.is_high().unwrap() as u8) << 4 |
        (self.am5.is_high().unwrap() as u8) << 5
    }
}

pub trait ControlBus {
    fn enable(&mut self);
    fn disable(&mut self);
    fn set_direction(&mut self, direction: Direction);

    //fn output(&mut self, value: u8);
    fn input(&mut self) -> (u8, ReadWrite, bool, bool, bool);

    //fn start_transaction(&mut self, rw: ReadWrite);
    //fn end_transaction(&mut self);
    //fn wait_for_dtack(&mut self);
}

pub struct ControlBusPins<GATE>
where
    GATE: Transceiver
{
    pub gate: GATE,
    pub ds0: DynamicPin<'G', 2>,
    pub ds1: DynamicPin<'G', 1>,
    pub write: DynamicPin<'G', 3>,
    pub lword: DynamicPin<'G', 4>,
    pub address_mod: AddressModifierPins,
    pub signal: Pin<'B', 12, Output<PushPull>>,
    pub direction: Direction,
}

impl<GATE> ControlBusPins<GATE>
where
    GATE: Transceiver,
{
    pub fn new(
        gate: GATE,
        ds0: DynamicPin<'G', 2>,
        ds1: DynamicPin<'G', 1>,
        write: DynamicPin<'G', 3>,
        lword: DynamicPin<'G', 4>,
        address_mod: AddressModifierPins,
        signal: Pin<'B', 12, Output<PushPull>>,
    ) -> Self {
        Self {
            gate,
            ds0,
            ds1,
            write,
            lword,
            address_mod,
            signal,
            direction: Direction::Input,
        }
    }
}

impl<GATE> ControlBus for ControlBusPins<GATE>
where
    GATE: Transceiver,
{
    #[inline]
    fn enable(&mut self) {
        self.gate.enable();
    }

    #[inline]
    fn disable(&mut self) {
        self.gate.disable();
    }

    #[inline]
    fn set_direction(&mut self, direction: Direction) {
        self.direction = direction;
        self.gate.set_direction(direction);
        self.address_mod.set_direction(direction);

        match direction {
            Direction::Output => {
                self.ds0.make_open_drain_output();
                self.ds1.make_open_drain_output();
                self.write.make_open_drain_output();
                self.lword.make_open_drain_output();
            },
            Direction::Input => {
                self.ds0.make_floating_input();
                self.ds1.make_floating_input();
                self.write.make_floating_input();
                self.lword.make_floating_input();
            },
        }
    }

    #[inline]
    fn input(&mut self) -> (u8, ReadWrite, bool, bool, bool) {
        let addr_mod = self.address_mod.input();
        let readwrite = match self.write.is_high().unwrap() {
            true => ReadWrite::Read,
            false => ReadWrite::Write,
        };
        let ds0 = self.ds0.is_high().unwrap();
        let ds1 = self.ds1.is_high().unwrap();
        let lword = self.lword.is_high().unwrap();

        (addr_mod, readwrite, ds0, ds1, lword)
    }
}




pub struct DataTransferBus<CTRL, ADDR, DATA>
where
    CTRL: ControlBus,
    ADDR: Bus,
    DATA: Bus,
{
    pub control_bus: CTRL,
    pub address_bus: ADDR,
    pub data_bus: DATA,
}

impl<CTRL, ADDR, DATA> DataTransferBus<CTRL, ADDR, DATA>
where
    CTRL: ControlBus,
    ADDR: Bus,
    DATA: Bus,
{
    pub fn new(control_bus: CTRL, address_bus: ADDR, data_bus: DATA) -> Self {
        Self {
            control_bus,
            address_bus,
            data_bus,
        }
    }
}






/*
pub trait AddressModifier {
    fn output(&mut self, value: u8);
}

pub struct AddressModifierPins<AM0, AM1, AM2, AM3, AM4, AM5>
where
    AM0: StatefulOutputPin,
    AM1: StatefulOutputPin,
    AM2: StatefulOutputPin,
    AM3: StatefulOutputPin,
    AM4: StatefulOutputPin,
    AM5: StatefulOutputPin,
{
    am0: AM0,
    am1: AM1,
    am2: AM2,
    am3: AM3,
    am4: AM4,
    am5: AM5,
}

impl<AM0, AM1, AM2, AM3, AM4, AM5> AddressModifierPins<AM0, AM1, AM2, AM3, AM4, AM5>
where
    AM0: StatefulOutputPin,
    AM1: StatefulOutputPin,
    AM2: StatefulOutputPin,
    AM3: StatefulOutputPin,
    AM4: StatefulOutputPin,
    AM5: StatefulOutputPin,
{
    pub fn new(am0: AM0, am1: AM1, am2: AM2, am3: AM3, am4: AM4, am5: AM5) -> Self {
        Self {
            am0,
            am1,
            am2,
            am3,
            am4,
            am5,
        }
    }
}

impl<AM0, AM1, AM2, AM3, AM4, AM5> AddressModifier for AddressModifierPins<AM0, AM1, AM2, AM3, AM4, AM5>
where
    AM0: StatefulOutputPin<Error = Infallible>,
    AM1: StatefulOutputPin<Error = Infallible>,
    AM2: StatefulOutputPin<Error = Infallible>,
    AM3: StatefulOutputPin<Error = Infallible>,
    AM4: StatefulOutputPin<Error = Infallible>,
    AM5: StatefulOutputPin<Error = Infallible>,
{
    fn output(&mut self, value: u8) {
        self.am0.set_state(PinState::from(value & (1 << 0) != 0)).unwrap();
        self.am1.set_state(PinState::from(value & (1 << 1) != 0)).unwrap();
        self.am2.set_state(PinState::from(value & (1 << 2) != 0)).unwrap();
        self.am3.set_state(PinState::from(value & (1 << 3) != 0)).unwrap();
        self.am4.set_state(PinState::from(value & (1 << 4) != 0)).unwrap();
        self.am5.set_state(PinState::from(value & (1 << 5) != 0)).unwrap();
    }
}

pub struct ControlPins<GATE, AS, DS0, DS1, WRITE, LWORD, ADDRMOD, DTACK, BERR, RETRY>
where
    GATE: Transceiver,
    AS: StatefulOutputPin,
    DS0: StatefulOutputPin,
    DS1: StatefulOutputPin,
    WRITE: StatefulOutputPin,
    LWORD: StatefulOutputPin,
    ADDRMOD: AddressModifier,
    DTACK: InputPin,
    BERR: InputPin,
    RETRY: InputPin,
{
    gate: GATE,
    addr_strobe: AS,
    data_strobe0: DS0,
    data_strobe1: DS1,
    write: WRITE,
    lword: LWORD,
    address_modifier: ADDRMOD,
    dtack: DTACK,
    berr: BERR,
    retry: RETRY,
}

impl<GATE, AS, DS0, DS1, WRITE, LWORD, ADDRMOD, DTACK, BERR, RETRY> ControlPins<GATE, AS, DS0, DS1, WRITE, LWORD, ADDRMOD, DTACK, BERR, RETRY>
where
    GATE: Transceiver,
    AS: StatefulOutputPin<Error = Infallible>,
    DS0: StatefulOutputPin<Error = Infallible>,
    DS1: StatefulOutputPin<Error = Infallible>,
    WRITE: StatefulOutputPin<Error = Infallible>,
    LWORD: StatefulOutputPin<Error = Infallible>,
    ADDRMOD: AddressModifier,
    DTACK: InputPin,
    BERR: InputPin,
    RETRY: InputPin,
{
    pub fn new(gate: GATE, addr_strobe: AS, data_strobe0: DS0, data_strobe1: DS1, write: WRITE, lword: LWORD, address_modifier: ADDRMOD, dtack: DTACK, berr: BERR, retry: RETRY) -> Self {
        let mut control_bus = Self {
            gate,
            addr_strobe,
            data_strobe0,
            data_strobe1,
            write,
            lword,
            address_modifier,
            dtack,
            berr,
            retry,
        };

        control_bus.idle();
        control_bus
    }

    pub fn idle(&mut self) {
        self.gate.disable();
        self.gate.set_direction(Direction::Output);
        self.addr_strobe.set_high().unwrap();
        self.data_strobe0.set_high().unwrap();
        self.data_strobe1.set_high().unwrap();
        self.write.set_high().unwrap();
        self.lword.set_high().unwrap();
        self.address_modifier.output(0);
    }
}

pub trait ControlBus {
    fn start_transaction(&mut self, rw: ReadWrite);
    fn end_transaction(&mut self);
    fn wait_for_dtack(&mut self);
}

impl<GATE, AS, DS0, DS1, WRITE, LWORD, ADDRMOD, DTACK, BERR, RETRY> ControlBus for ControlPins<GATE, AS, DS0, DS1, WRITE, LWORD, ADDRMOD, DTACK, BERR, RETRY>
where
    GATE: Transceiver,
    AS: StatefulOutputPin<Error = Infallible>,
    DS0: StatefulOutputPin<Error = Infallible>,
    DS1: StatefulOutputPin<Error = Infallible>,
    WRITE: StatefulOutputPin<Error = Infallible>,
    LWORD: StatefulOutputPin<Error = Infallible>,
    ADDRMOD: AddressModifier,
    DTACK: InputPin,
    BERR: InputPin,
    RETRY: InputPin,
{
    fn start_transaction(&mut self, rw: ReadWrite) {
        self.gate.enable();
        self.addr_strobe.set_low().unwrap();
        self.data_strobe0.set_low().unwrap();
        //self.data_strobe1.set_low().unwrap();
        self.address_modifier.output(0x2D);

        match rw {
            ReadWrite::Read => self.write.set_high().unwrap(),
            ReadWrite::Write => self.write.set_low().unwrap(),
        }
    }

    fn end_transaction(&mut self) {
        self.data_strobe0.set_high().unwrap();
        self.data_strobe1.set_high().unwrap();
        self.addr_strobe.set_high().unwrap();
        self.gate.disable();
    }

    fn wait_for_dtack(&mut self) {
        while self.dtack.is_high().unwrap_or(false) {
            if self.berr.is_low().unwrap_or(false) {
                rprintln!("bus error");
            }
        }
    }
}

pub struct DataTransferBus<CTRL, ADDR, DATA>
where
    CTRL: ControlBus,
    ADDR: Bus,
    DATA: Bus,
{
    pub control_bus: CTRL,
    pub address_bus: ADDR,
    pub data_bus: DATA,
}

impl<CTRL, ADDR, DATA> DataTransferBus<CTRL, ADDR, DATA>
where
    CTRL: ControlBus,
    ADDR: Bus,
    DATA: Bus,
{
    pub fn new(control_bus: CTRL, address_bus: ADDR, data_bus: DATA) -> Self {
        Self {
            control_bus,
            address_bus,
            data_bus,
        }
    }

    pub fn read_a16(&mut self, delay: &mut Delay, address: u16) -> Result<u32, ()> {
        rprintln!("reading address {:x}", address);

        self.data_bus.set_direction(Direction::Input);
        self.data_bus.enable();
        self.address_bus.set_direction(Direction::Output);

        self.address_bus.output(address as u32);
        self.control_bus.start_transaction(ReadWrite::Read);

        rprintln!("waiting for dtack");
        self.control_bus.wait_for_dtack();
        let data = self.data_bus.input();

        self.control_bus.end_transaction();
        Ok(data)
    }

    pub fn write_a16(&mut self, delay: &mut Delay, address: u16, data: u16) -> Result<u32, ()> {
        rprintln!("writing address {:x}", address);

        self.data_bus.set_direction(Direction::Output);
        self.address_bus.set_direction(Direction::Output);

        self.address_bus.output(address as u32);
        self.control_bus.start_transaction(ReadWrite::Write);

        self.data_bus.output(data as u32);
        self.data_bus.enable();

        rprintln!("waiting for dtack");
        self.control_bus.wait_for_dtack();
        let data = self.data_bus.input();

        self.control_bus.end_transaction();
        Ok(data)
    }
}
*/

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum BusError {
    Busy,
}

pub struct BusArbitration {
    pub bbsy: ErasedPin<Output<OpenDrain>>,
    pub bclr: ErasedPin<Output<OpenDrain>>,
    pub br: [ErasedPin<Output<OpenDrain>>; 4],
    pub bgin: [ErasedPin<Input>; 4],
    pub bgout: [ErasedPin<Output>; 4],
}

impl BusArbitration {
    pub fn request_bus(&mut self, index: u8) -> Result<Grant<'_>, BusError> {
        if self.br[index as usize].is_high() {
            self.br[index as usize].set_low();
            // TODO while waitinig
        }
        // TODO actually do arbitration
        Ok(Grant { index, arbitration: self })
    }

    fn release_bus(&mut self, index: u8) {

    }
}

pub struct Grant<'a> {
    index: u8,
    arbitration: &'a mut BusArbitration,
}

impl<'a> Drop for Grant<'a> {
    fn drop(&mut self) {
        self.arbitration.release_bus(self.index);
    }
}

