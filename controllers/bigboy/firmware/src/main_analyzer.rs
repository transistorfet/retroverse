
use rtt_target::rprintln;

use core::fmt::Write;
use core::cell::{Cell, RefCell};
use cortex_m::interrupt::{free, Mutex};
use hal::prelude::*;
use hal::gpio::{PinState, ExtiPin, Edge, PG0, PA5, PA6, PA8, PB0, PB1, PB2, PB4, PB5, PC6, PC7, Input, Output};
use hal::pac;
use hal::pac::{interrupt, NVIC, GPIOE, GPIOF, GPIOJ, GPIOI};
use stm32h7xx_hal as hal;
use hal::rcc::ResetEnable;

use crate::vme::{Direction, Bus, BusPins, Transceiver, TransceiverPins, AddressModifier, AddressModifierPins, ControlBusPins, ControlBus, DataTransferBus, BusArbitration};


type AddressBusType = BusPins<TransceiverPins<PA8<Output>, PB1<Output>>, TransceiverPins<PB0<Output>, PB2<Output>>, GPIOF, GPIOE>;
type DataBusType = BusPins<TransceiverPins<PC6<Output>, PC7<Output>>, TransceiverPins<PA5<Output>, PA6<Output>>, GPIOJ, GPIOI>;
type ControlBusType = ControlBusPins<TransceiverPins<PB4<Output>, PB5<Output>>>;
type DataTransferBusType = DataTransferBus<ControlBusType, AddressBusType, DataBusType>;

static ADDRESS_STROBE: Mutex<RefCell<Option<PG0<Input>>>> =
    Mutex::new(RefCell::new(None));
static DATA_TRANSFER_BUS: Mutex<RefCell<Option<DataTransferBusType>>> =
    Mutex::new(RefCell::new(None));
//static ADDRESS_BUS: Mutex<RefCell<Option<AddressBusType>>> =
//    Mutex::new(RefCell::new(None));
//static DATA_BUS: Mutex<RefCell<Option<DataBusType>>> =
//    Mutex::new(RefCell::new(None));

pub fn run() -> ! {
    rprintln!("starting power");
    let mut cp = pac::CorePeripherals::take().unwrap();
    let dp = pac::Peripherals::take().unwrap();

    rprintln!("starting power");
    let pwr = dp.PWR.constrain();
    rprintln!("freezing power");
    let pwrcfg = pwr.freeze();

    let rcc = dp.RCC.constrain();
    let ccdr = rcc.sys_ck(400.MHz()).freeze(pwrcfg, &dp.SYSCFG);

    rprintln!("configuring I/O");
    let gpioa = dp.GPIOA.split(ccdr.peripheral.GPIOA);
    let gpiob = dp.GPIOB.split(ccdr.peripheral.GPIOB);
    let gpioc = dp.GPIOC.split(ccdr.peripheral.GPIOC);
    let gpiod = dp.GPIOD.split(ccdr.peripheral.GPIOD);

    //let gpiog = dp.GPIOG.split(ccdr.peripheral.GPIOG);
    //let gpioh = dp.GPIOH.split(ccdr.peripheral.GPIOH);
    let gpiok = dp.GPIOK.split(ccdr.peripheral.GPIOK);

    let mut led1 = gpioc.pc0.into_push_pull_output();
    let mut led2 = gpioa.pa3.into_push_pull_output();
    let mut led3 = gpioa.pa4.into_push_pull_output();
    let mut led4 = gpioc.pc13.into_push_pull_output();
    let button1 = gpioa.pa9.into_floating_input();


    let mut dl_oe = gpioa.pa5.into_push_pull_output();
    let mut dl_dir = gpioa.pa6.into_push_pull_output();
    let mut dh_oe = gpioc.pc6.into_push_pull_output();
    let mut dh_dir = gpioc.pc7.into_push_pull_output();
    let mut al_oe = gpiob.pb0.into_push_pull_output();
    let mut al_dir = gpiob.pb2.into_push_pull_output();
    let mut ah_oe = gpioa.pa8.into_push_pull_output();
    let mut ah_dir = gpiob.pb1.into_push_pull_output();
    let mut ctrl_oe = gpiob.pb4.into_push_pull_output();
    let mut ctrl_dir = gpiob.pb5.into_push_pull_output();
    al_oe.set_high();
    al_dir.set_low(); // low = INPUT (from bus), high = OUTPUT (to bus)
    ah_oe.set_high();
    ah_dir.set_low(); // low = INPUT (from bus), high = OUTPUT (to bus)
    dl_oe.set_high();
    dl_dir.set_low(); // low = INPUT (from bus), high = OUTPUT (to bus)
    dh_oe.set_high();
    dh_dir.set_low(); // low = INPUT (from bus), high = OUTPUT (to bus)
    ctrl_oe.set_low();
    ctrl_dir.set_low(); // low = INPUT (from bus), high = OUTPUT (to bus)


    let mut al = TransceiverPins::new(al_oe, al_dir);
    let mut ah = TransceiverPins::new(ah_oe, ah_dir);
    let mut dl = TransceiverPins::new(dl_oe, dl_dir);
    let mut dh = TransceiverPins::new(dh_oe, dh_dir);
    let ctrl = TransceiverPins::new(ctrl_oe, ctrl_dir);

    ccdr.peripheral.GPIOE.enable().reset();
    ccdr.peripheral.GPIOF.enable().reset();
    ccdr.peripheral.GPIOI.enable().reset();
    ccdr.peripheral.GPIOJ.enable().reset();
    ccdr.peripheral.GPIOG.enable().reset();
    ccdr.peripheral.GPIOH.enable().reset();
    //let mut address_bus = BusPins::new("address", ah, al, dp.GPIOF, dp.GPIOE);
    //let mut data_bus = BusPins::new("data", dh, dl, dp.GPIOJ, dp.GPIOI);

    macro_rules! configure_port {
        ($port:expr) => {
            $port.moder.write(|w| unsafe { w.bits(0x0000_0000) });
            $port.otyper.write(|w| unsafe { w.bits(0x0000_0000) });
            $port.ospeedr.write(|w| unsafe { w.bits(0xFFFF_FFFF) });
            $port.odr.write(|w| unsafe { w.bits(0x0000) });
        };
    }

    configure_port!(dp.GPIOE);
    configure_port!(dp.GPIOF);
    configure_port!(dp.GPIOG);
    configure_port!(dp.GPIOH);
    configure_port!(dp.GPIOI);
    configure_port!(dp.GPIOJ);

    /*
    let mut address_strobe = gpiog.pg0.into_floating_input();
    let data_strobe0 = gpiog.pg2.into_dynamic();
    let data_strobe1 = gpiog.pg1.into_dynamic();
    let write = gpiog.pg3.into_dynamic();
    let lword = gpiog.pg4.into_dynamic();

    let am0 = gpiog.pg5.into_dynamic();
    let am1 = gpiog.pg6.into_dynamic();
    let am2 = gpiog.pg7.into_dynamic();
    let am3 = gpiog.pg8.into_dynamic();
    let am4 = gpiog.pg9.into_dynamic();
    let am5 = gpiog.pg10.into_dynamic();
    let mut address_modifier = AddressModifierPins::new(am0, am1, am2, am3, am4, am5);
    address_modifier.set_direction(Direction::Input);

    let dtack = gpiog.pg14.into_floating_input();
    let berr = gpiog.pg15.into_floating_input();
    let retry = gpiod.pd7.into_floating_input();

    let mut signal = gpiob.pb12.into_push_pull_output();

    let mut control_bus = ControlBusPins::new(
        ctrl,
        data_strobe0,
        data_strobe1,
        write,
        lword,
        address_modifier,
        signal,
    );
    control_bus.set_direction(Direction::Input);

    //let control_bus = ControlPins::new(
    //    ctrl,
    //    address_strobe,
    //    data_strobe0,
    //    data_strobe1,
    //    write,
    //    lword,
    //    address_modifier,
    //    dtack,
    //    berr,
    //    retry,
    //);

    let mut vmebus = DataTransferBus::new(control_bus, address_bus, data_bus);
    */



    let sysreset = gpioa.pa0.into_open_drain_output_in_state(PinState::High);
    let acfail = gpiod.pd13.into_open_drain_output_in_state(PinState::High);
    let sysfail = gpiod.pd14.into_open_drain_output_in_state(PinState::High);

    /*
    let bbsy = gpioh.ph2.into_open_drain_output_in_state(PinState::High).erase();
    let bclr = gpioh.ph3.into_open_drain_output_in_state(PinState::High).erase();

    let br0 = gpioh.ph12.into_open_drain_output_in_state(PinState::High).erase();
    let br1 = gpioh.ph13.into_open_drain_output_in_state(PinState::High).erase();
    let br2 = gpioh.ph14.into_open_drain_output_in_state(PinState::High).erase();
    let br3 = gpioh.ph15.into_open_drain_output_in_state(PinState::High).erase();

    let bg0in = gpioh.ph4.into_floating_input().erase();
    let bg0out = gpioh.ph5.into_push_pull_output_in_state(PinState::High).erase();
    let bg1in = gpioh.ph6.into_floating_input().erase();
    let bg1out = gpioh.ph7.into_push_pull_output_in_state(PinState::High).erase();
    let bg2in = gpioh.ph8.into_floating_input().erase();
    let bg2out = gpioh.ph9.into_push_pull_output_in_state(PinState::High).erase();
    let bg3in = gpioh.ph10.into_floating_input().erase();
    let bg3out = gpioh.ph11.into_push_pull_output_in_state(PinState::High).erase();

    //let arbitration = BusArbitration {
    //    bbsy,
    //    bclr,
    //    br: [br0, br1, br2, br3],
    //    bgin: [bg0in, bg1in, bg2in, bg3in],
    //    bgout: [bg0out, bg1out, bg2out, bg3out],
    //};
    */

    let sysclk_pin = gpiod.pd15.into_alternate_af2();

    let (control, mut sysclk) = dp.TIM4
        .pwm_advanced(
            sysclk_pin,
            ccdr.peripheral.TIM4,
            &ccdr.clocks
        )
        .frequency(100.Hz())
        .center_aligned()
        .finalize();
    sysclk.set_duty(sysclk.get_max_duty() / 2);
    sysclk.enable();

    let mut delay = cp.SYST.delay(ccdr.clocks);
    //let mut output = gpioa.pa3.into_alternate();
    let mut timer = dp.TIM2.tick_timer(1.MHz(), ccdr.peripheral.TIM2, &ccdr.clocks);

    let tx = gpiod.pd8.into_alternate();
    let rx = gpiod.pd9.into_alternate();

    // Configure the serial peripheral
    let serial = dp
        .USART3
        .serial((tx, rx), 115_200.bps(), ccdr.peripheral.USART3, &ccdr.clocks)
        .unwrap();

    let (mut tx, mut rx) = serial.split();

    writeln!(tx, "Hello, world!").unwrap();

    led1.set_low();
    led2.set_low();
    led3.set_low();
    led4.set_low();

    /*
    // Configure the interrupt signals
    let iack = gpiok.pk0.into_open_drain_output_in_state(PinState::High);
    let irq = [
        gpiok.pk1.into_push_pull_output_in_state(PinState::High).erase(),
        gpiok.pk2.into_push_pull_output_in_state(PinState::High).erase(),
        gpiok.pk3.into_push_pull_output_in_state(PinState::High).erase(),
        gpiok.pk4.into_push_pull_output_in_state(PinState::High).erase(),
        gpiok.pk5.into_push_pull_output_in_state(PinState::High).erase(),
        gpiok.pk6.into_push_pull_output_in_state(PinState::High).erase(),
        gpiok.pk7.into_push_pull_output_in_state(PinState::High).erase(),
    ];
    */

    //al.set_direction(Direction::Input);
    //al.enable();
    //ah.set_direction(Direction::Input);
    //ah.enable();
    dl.set_direction(Direction::Input);
    dl.enable();
    //dh.set_direction(Direction::Input);
    //dh.enable();

    /*
    vmebus.address_bus.set_direction(Direction::Input);
    vmebus.address_bus.enable();
    vmebus.data_bus.set_direction(Direction::Input);
    vmebus.data_bus.enable();
    vmebus.control_bus.set_direction(Direction::Input);
    vmebus.control_bus.enable();

    let mut syscfg = dp.SYSCFG;
    let mut exti = dp.EXTI;
    address_strobe.make_interrupt_source(&mut syscfg);
    address_strobe.trigger_on_edge(&mut exti, Edge::RisingFalling);
    address_strobe.enable_interrupt(&mut exti);


    free(|cs| {
        ADDRESS_STROBE.borrow(cs).replace(Some(address_strobe));
        //ADDRESS_BUS.borrow(cs).replace(Some(address_bus));
        //DATA_BUS.borrow(cs).replace(Some(data_bus));
        DATA_TRANSFER_BUS.borrow(cs).replace(Some(vmebus));
        //BUTTON2_PIN.borrow(cs).replace(Some(button2));
        //LED.borrow(cs).replace(Some(led));
    });

    // Enable the button interrupts
    unsafe {
        cp.NVIC.set_priority(interrupt::EXTI0, 1);
        //cp.NVIC.set_priority(interrupt::EXTI9_5, 1);
        NVIC::unmask::<interrupt>(interrupt::EXTI0);
        //NVIC::unmask::<interrupt>(interrupt::EXTI9_5);
    }
    */

    #[derive(Default)]
    struct Values {
        GPIOE: u32,
        GPIOF: u32,
        GPIOG: u32,
        GPIOH: u32,
        GPIOI: u32,
        GPIOJ: u32,
    }

    macro_rules! output_port {
        ($name:literal, $port:ident, $previous:ident, $mask:literal) => {
            let value = dp.$port.idr.read().bits();
            if $previous.$port & $mask != value & $mask {
                $previous.$port = value & $mask;
                rprintln!("{:?}: {:04x}", $name, value);
            }
        };
    }

    let mut values = Values::default();
    rprintln!("main loop");
    loop {
        //output_port!("E", GPIOE, values, 0xffff);
        //output_port!("F", GPIOF, values, 0xffff);
        //output_port!("G", GPIOG, values, 0xffff);
        //output_port!("H", GPIOH, values, 0xfffe);
        output_port!("I", GPIOI, values, 0xffff);
        //output_port!("J", GPIOJ, values, 0xffff);
    }

/*
    let mut value = false;
    rprintln!("main loop");
    loop {
        led1.toggle();
        led2.toggle();
        led3.toggle();
        led4.toggle();
        delay.delay_ms(100_u16);

        value = !value;
        if value {
            virq1.set_high();
            al_oe.set_low();
            dp.GPIOE.moder.write(|w| unsafe { w.bits(0x5555_5555) });
            dp.GPIOE.odr.write(|w| unsafe { w.bits(0xFFFF) });
        } else {
            virq1.set_low();
            al_oe.set_high();
            dp.GPIOE.moder.write(|w| unsafe { w.bits(0x0000_0000) });
        }
        //rprintln!("Led toggled");
    }
*/
}



#[interrupt]
fn EXTI0() {
    rprintln!("here");
    free(|cs| {
        if let Some(address_strobe) = ADDRESS_STROBE.borrow(cs).borrow_mut().as_mut() {
            if let Some(mut bus) = DATA_TRANSFER_BUS.borrow(cs).borrow_mut().as_mut() {
                bus.control_bus.signal.set_high();

                let (addr_mod, readwrite, ds0, ds1, lword) = bus.control_bus.input();
                let address = bus.address_bus.input();
                let data = bus.data_bus.input();

                rprintln!("{:x}: {:?} {:?} {:?} {:?}", addr_mod, readwrite, ds0, ds1, lword);
                rprintln!(">> {:x}", address);
                rprintln!(">> {:x}", data);

                bus.control_bus.signal.set_low();
                while address_strobe.is_low() {}
            }
            address_strobe.clear_interrupt_pending_bit();
        }
    })
}

#[cfg(test)]
mod test {}
