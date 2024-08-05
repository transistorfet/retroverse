
//#![deny(warnings)]
#![no_main]
#![no_std]

use panic_rtt_target as _;
use rtt_target::{rtt_init_print, rprintln};

use core::fmt::Write;
use hal::prelude::*;
use hal::gpio::PinState;
use hal::pac;
use stm32h7xx_hal as hal;
use hal::rcc::ResetEnable;

//mod main_peripheral;
mod main_analyzer;
mod vme;

#[cortex_m_rt::entry]
fn main() -> ! {
    rtt_init_print!();
    rprintln!("booting");

    //main_peripheral::run_as_peripheral();
    main_analyzer::run();
}

/*
#[exception]
unsafe fn HardFault(ef: &cortex_m_rt::ExceptionFrame) -> ! {
    panic!("HardFault at {:#?}", ef);
}

#[exception]
unsafe fn DefaultHandler(irqn: i16) {
    panic!("Unhandled exception (IRQn = {})", irqn);
}
*/

#[cfg(test)]
mod test {}
