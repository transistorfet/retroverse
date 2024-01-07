//#![deny(warnings)]
#![no_main]
#![no_std]

use panic_rtt_target as _;
use rtt_target::{rtt_init_print, rprintln};

use hal::prelude::*;
use hal::pac;
use stm32h7xx_hal as hal;

#[cortex_m_rt::entry]
fn main() -> ! {
    rtt_init_print!();
    rprintln!("booting");

    rprintln!("starting power");
    let mut cp = pac::CorePeripherals::take().unwrap();
    let dp = pac::Peripherals::take().unwrap();

    rprintln!("starting power");
    let pwr = dp.PWR.constrain();
    rprintln!("freezing power");
    let pwrcfg = pwr.freeze();

    let rcc = dp.RCC.constrain();
    let ccdr = rcc.sys_ck(100.MHz()).freeze(pwrcfg, &dp.SYSCFG);

    rprintln!("configuring I/O");
    let gpioa = dp.GPIOA.split(ccdr.peripheral.GPIOA);
    let gpioc = dp.GPIOC.split(ccdr.peripheral.GPIOC);

    //let mut led1 = gpioc.pc1.into_push_pull_output();
    //let mut led2 = gpioa.pa3.into_push_pull_output();
    //let mut led3 = gpioa.pa4.into_push_pull_output();
    let mut led4 = gpioc.pc13.into_push_pull_output();

    let mut delay = cp.SYST.delay(ccdr.clocks);

    //led1.set_high();
    //led2.set_high();
    //led3.set_high();
    led4.set_low();

    rprintln!("main loop");
    loop {
        //led.toggle();
        delay.delay_ms(1000_u16);

        //rprintln!("Led toggled");
    }
}



/*
//! Demo for STM32H747I-DISCO eval board using the Real Time for the Masses
//! (RTIC) framework.
//!
//! STM32H747I-DISCO: RMII TXD1 is on PG12
//!
//! If you are using the following boards, you will need to change the TXD1 pin
//! assignment below!
//! NUCLEO-H743ZI2: RMII TXD1 is on PB13
//! NUCLEO-H745I-Q: RMII TXD1 is on PB13
//!
//! This demo responds to pings on 192.168.1.99 (IP address hardcoded below)
//!
//! We use the SysTick timer to create a 1ms timebase for use with smoltcp.
//!
//! The ethernet ring buffers are placed in SRAM3, where they can be
//! accessed by both the core and the Ethernet DMA.
#![deny(warnings)]
#![no_main]
#![no_std]

use panic_rtt_target as _;
use rtt_target::{rtt_init_print, rprintln};

use core::mem::MaybeUninit;
use core::ptr::addr_of_mut;
use core::sync::atomic::AtomicU32;

use smoltcp::iface::{Config, Interface, SocketSet, SocketStorage};
use smoltcp::time::Instant;
use smoltcp::wire::{HardwareAddress, IpAddress, IpCidr};

use stm32h7xx_hal::{ethernet, rcc::CoreClocks, stm32};

/// Configure SYSTICK for 1ms timebase
fn systick_init(mut syst: stm32::SYST, clocks: CoreClocks) {
    let c_ck_mhz = clocks.c_ck().to_MHz();

    let syst_calib = 0x3E8;

    syst.set_clock_source(cortex_m::peripheral::syst::SystClkSource::Core);
    syst.set_reload((syst_calib * c_ck_mhz) - 1);
    syst.enable_interrupt();
    syst.enable_counter();
}

/// TIME is an atomic u32 that counts milliseconds.
static TIME: AtomicU32 = AtomicU32::new(0);

/// Locally administered MAC address
const MAC_ADDRESS: [u8; 6] = [0x02, 0x00, 0x11, 0x22, 0x33, 0x44];

/// Ethernet descriptor rings are a global singleton
#[link_section = ".sram3.eth"]
static mut DES_RING: ethernet::DesRing<4, 4> = ethernet::DesRing::new();

// This data will be held by Net through a mutable reference
pub struct NetStorageStatic<'a> {
    socket_storage: [SocketStorage<'a>; 8],
}
// MaybeUninit allows us write code that is correct even if STORE is not
// initialised by the runtime
static mut STORE: MaybeUninit<NetStorageStatic> = MaybeUninit::uninit();

pub struct Net<'a> {
    iface: Interface,
    ethdev: ethernet::EthernetDMA<4, 4>,
    sockets: SocketSet<'a>,
}
impl<'a> Net<'a> {
    pub fn new(
        store: &'a mut NetStorageStatic<'a>,
        mut ethdev: ethernet::EthernetDMA<4, 4>,
        ethernet_addr: HardwareAddress,
        now: Instant,
    ) -> Self {
        let config = Config::new(ethernet_addr);
        let mut iface = Interface::new(config, &mut ethdev, now);
        // Set IP address
        iface.update_ip_addrs(|addrs| {
            let _ = addrs.push(IpCidr::new(IpAddress::v4(192, 168, 2, 99), 0));
        });

        let sockets = SocketSet::new(&mut store.socket_storage[..]);

        Net::<'a> {
            iface,
            ethdev,
            sockets,
        }
    }

    /// Polls on the ethernet interface. You should refer to the smoltcp
    /// documentation for poll() to understand how to call poll efficiently
    pub fn poll(&mut self, now: i64) {
        let timestamp = Instant::from_millis(now);

        self.iface
            .poll(timestamp, &mut self.ethdev, &mut self.sockets);
    }
}

#[rtic::app(device = stm32h7xx_hal::stm32, peripherals = true)]
mod app {
    use stm32h7xx_hal::{ethernet, ethernet::PHY, gpio, prelude::*};

    use super::*;
    use core::sync::atomic::Ordering;

    #[shared]
    struct SharedResources {}
    #[local]
    struct LocalResources {
        net: Net<'static>,
        lan8742a: ethernet::phy::LAN8742A<ethernet::EthernetMAC>,
        link_led: gpio::gpioi::PI14<gpio::Output<gpio::PushPull>>,
    }

    #[init]
    fn init(
        mut ctx: init::Context,
    ) -> (SharedResources, LocalResources, init::Monotonics) {
        rtt_init_print!();
        rprintln!("booting");

        // Initialise power...
        let pwr = ctx.device.PWR.constrain();
        let pwrcfg = pwr.smps().freeze();

        // Link the SRAM3 power state to CPU1
        ctx.device.RCC.ahb2enr.modify(|_, w| w.sram3en().set_bit());

        // Initialise clocks...
        let rcc = ctx.device.RCC.constrain();
        let ccdr = rcc
            .sys_ck(200.MHz())
            .hclk(200.MHz())
            .freeze(pwrcfg, &ctx.device.SYSCFG);

        // Initialise system...
        ctx.core.SCB.enable_icache();
        // TODO: ETH DMA coherence issues
        // ctx.core.SCB.enable_dcache(&mut ctx.core.CPUID);
        ctx.core.DWT.enable_cycle_counter();

        // Initialise IO...
        let gpioa = ctx.device.GPIOA.split(ccdr.peripheral.GPIOA);
        let gpioc = ctx.device.GPIOC.split(ccdr.peripheral.GPIOC);
        let gpiog = ctx.device.GPIOG.split(ccdr.peripheral.GPIOG);
        let gpioi = ctx.device.GPIOI.split(ccdr.peripheral.GPIOI);
        let mut link_led = gpioi.pi14.into_push_pull_output(); // LED3
        link_led.set_high();

        let rmii_ref_clk = gpioa.pa1.into_alternate();
        let rmii_mdio = gpioa.pa2.into_alternate();
        let rmii_mdc = gpioc.pc1.into_alternate();
        let rmii_crs_dv = gpioa.pa7.into_alternate();
        let rmii_rxd0 = gpioc.pc4.into_alternate();
        let rmii_rxd1 = gpioc.pc5.into_alternate();
        let rmii_tx_en = gpiog.pg11.into_alternate();
        let rmii_txd0 = gpiog.pg13.into_alternate();
        let rmii_txd1 = gpiog.pg12.into_alternate(); // STM32H747I-DISCO

        // Initialise ethernet...
        assert_eq!(ccdr.clocks.hclk().raw(), 200_000_000); // HCLK 200MHz
        assert_eq!(ccdr.clocks.pclk1().raw(), 100_000_000); // PCLK 100MHz
        assert_eq!(ccdr.clocks.pclk2().raw(), 100_000_000); // PCLK 100MHz
        assert_eq!(ccdr.clocks.pclk4().raw(), 100_000_000); // PCLK 100MHz

        let mac_addr = smoltcp::wire::EthernetAddress::from_bytes(&MAC_ADDRESS);
        let (eth_dma, eth_mac) = unsafe {
            ethernet::new(
                ctx.device.ETHERNET_MAC,
                ctx.device.ETHERNET_MTL,
                ctx.device.ETHERNET_DMA,
                (
                    rmii_ref_clk,
                    rmii_mdio,
                    rmii_mdc,
                    rmii_crs_dv,
                    rmii_rxd0,
                    rmii_rxd1,
                    rmii_tx_en,
                    rmii_txd0,
                    rmii_txd1,
                ),
                &mut DES_RING,
                mac_addr,
                ccdr.peripheral.ETH1MAC,
                &ccdr.clocks,
            )
        };

        // Initialise ethernet PHY...
        let mut lan8742a = ethernet::phy::LAN8742A::new(eth_mac);
        lan8742a.phy_reset();
        lan8742a.phy_init();
        // The eth_dma should not be used until the PHY reports the link is up

        unsafe { ethernet::enable_interrupt() };

        // unsafe: mutable reference to static storage, we only do this once
        let store = unsafe {
            let store_ptr = STORE.as_mut_ptr();

            // Initialise the socket_storage field. Using `write` instead of
            // assignment via `=` to not call `drop` on the old, uninitialised
            // value
            addr_of_mut!((*store_ptr).socket_storage)
                .write([SocketStorage::EMPTY; 8]);

            // Now that all fields are initialised we can safely use
            // assume_init_mut to return a mutable reference to STORE
            STORE.assume_init_mut()
        };

        let net = Net::new(store, eth_dma, mac_addr.into(), Instant::ZERO);

        // 1ms tick
        systick_init(ctx.core.SYST, ccdr.clocks);

        (
            SharedResources {},
            LocalResources {
                net,
                lan8742a,
                link_led,
            },
            init::Monotonics(),
        )
    }

    #[idle(local = [lan8742a, link_led])]
    fn idle(ctx: idle::Context) -> ! {
        loop {
            // Ethernet
            match ctx.local.lan8742a.poll_link() {
                true => ctx.local.link_led.set_low(),
                _ => ctx.local.link_led.set_high(),
            }
        }
    }

    #[task(binds = ETH, local = [net])]
    fn ethernet_event(ctx: ethernet_event::Context) {
        unsafe { ethernet::interrupt_handler() }

        let time = TIME.load(Ordering::Relaxed);
        ctx.local.net.poll(time as i64);
    }

    #[task(binds = SysTick, priority=15)]
    fn systick_tick(_: systick_tick::Context) {
        TIME.fetch_add(1, Ordering::Relaxed);
    }
}
*/

/*
use cortex_m_rt::{entry, exception};


use stm32h7xx_hal::{ethernet, ethernet::PHY};
use hal::prelude::*;
use hal::{stm32, stm32::interrupt};
use hal::pac;
use stm32h7xx_hal as hal;

const MAC_ADDRESS: [u8; 6] = [0x02, 0x00, 0x11, 0x22, 0x33, 0x44];

/// Ethernet descriptor rings are a global singleton
#[link_section = ".sram3.eth"]
static mut DES_RING: ethernet::DesRing<4, 4> = ethernet::DesRing::new();

#[entry]
fn main() -> ! {
    rtt_init_print!();
    rprintln!("booting");

    rprintln!("starting power");
    let mut cp = pac::CorePeripherals::take().unwrap();
    let dp = pac::Peripherals::take().unwrap();

    rprintln!("starting power");
    let pwr = dp.PWR.constrain();
    rprintln!("freezing power");
    let pwrcfg = pwr.smps().freeze();

    rprintln!("configuring clocks");
    let rcc = dp.RCC.constrain();
    let ccdr = rcc
        .sys_ck(200.MHz())
        .hclk(200.MHz())
        .freeze(pwrcfg, &dp.SYSCFG);


    rprintln!("configuring I/O");
    let gpioi = dp.GPIOI.split(ccdr.peripheral.GPIOI);
    let gpioa = dp.GPIOA.split(ccdr.peripheral.GPIOA);
    let gpioc = dp.GPIOC.split(ccdr.peripheral.GPIOC);
    let gpiog = dp.GPIOG.split(ccdr.peripheral.GPIOG);

    let mut led = gpioi.pi12.into_push_pull_output();

    let mut link_led = gpioi.pi14.into_push_pull_output(); // LED3
    link_led.set_high();

    let rmii_ref_clk = gpioa.pa1.into_alternate();
    let rmii_mdio = gpioa.pa2.into_alternate();
    let rmii_mdc = gpioc.pc1.into_alternate();
    let rmii_crs_dv = gpioa.pa7.into_alternate();
    let rmii_rxd0 = gpioc.pc4.into_alternate();
    let rmii_rxd1 = gpioc.pc5.into_alternate();
    let rmii_tx_en = gpiog.pg11.into_alternate();
    let rmii_txd0 = gpiog.pg13.into_alternate();
    let rmii_txd1 = gpiog.pg12.into_alternate();


    // Initialise ethernet...
    assert_eq!(ccdr.clocks.hclk().raw(), 200_000_000); // HCLK 200MHz
    assert_eq!(ccdr.clocks.pclk1().raw(), 100_000_000); // PCLK 100MHz
    assert_eq!(ccdr.clocks.pclk2().raw(), 100_000_000); // PCLK 100MHz
    assert_eq!(ccdr.clocks.pclk4().raw(), 100_000_000); // PCLK 100MHz

    let mac_addr = smoltcp::wire::EthernetAddress::from_bytes(&MAC_ADDRESS);
    let (eth_dma, eth_mac) = unsafe {
        ethernet::new(
            dp.ETHERNET_MAC,
            dp.ETHERNET_MTL,
            dp.ETHERNET_DMA,
            (
                rmii_ref_clk,
                rmii_mdio,
                rmii_mdc,
                rmii_crs_dv,
                rmii_rxd0,
                rmii_rxd1,
                rmii_tx_en,
                rmii_txd0,
                rmii_txd1,
            ),
            &mut DES_RING,
            mac_addr,
            ccdr.peripheral.ETH1MAC,
            &ccdr.clocks,
        )
    };

    rprintln!("initialize PHY");
    // Initialise ethernet PHY...
    let mut lan8742a = ethernet::phy::LAN8742A::new(eth_mac.set_phy_addr(0));
    rprintln!("reset PHY");
    lan8742a.phy_reset();
    rprintln!("init PHY");
    lan8742a.phy_init();

    rprintln!("enable interrupts");
    unsafe {
        ethernet::enable_interrupt();
        cp.NVIC.set_priority(stm32::Interrupt::ETH, 196); // Mid prio
        cortex_m::peripheral::NVIC::unmask(stm32::Interrupt::ETH);
    }

    // ----------------------------------------------------------
    // Main application loop

    rprintln!("main application start");
    let mut eth_up = false;
    loop {
        // Ethernet
        let eth_last = eth_up;
        eth_up = lan8742a.poll_link();
        match eth_up {
            true => link_led.set_low(),
            _ => link_led.set_high(),
        }

        if eth_up != eth_last {
            // Interface state change
            match eth_up {
                true => rprintln!("Ethernet UP"),
                _ => rprintln!("Ethernet DOWN"),
            }
        }


    }

/*
    rprintln!("configuring I/O");
    let gpioi = dp.GPIOI.split(ccdr.peripheral.GPIOI);
    let gpioa = dp.GPIOA.split(ccdr.peripheral.GPIOA);
    let gpioc = dp.GPIOC.split(ccdr.peripheral.GPIOC);
    let gpiog = dp.GPIOG.split(ccdr.peripheral.GPIOG);

    let mut led = gpioi.pi12.into_push_pull_output();

    let mut delay = cp.SYST.delay(ccdr.clocks);

    loop {
        led.set_high();
        delay.delay_ms(100_u16);

        led.set_low();
        delay.delay_ms(100_u16);

        let is_high = led.with_input(|x| x.is_high());
        rprintln!("LED pin high? {}", is_high);
    }
*/

/*
    let gpioj = dp.GPIOJ.split(ccdr.peripheral.GPIOJ);

    let mut output = gpioj.pj5.into_push_pull_output();
    let mut input = gpioj.pj6.into_push_pull_output();

    let mut delay = cp.SYST.delay(ccdr.clocks);

    loop {
        output.toggle();
        delay.delay_ms(1000_u16);

        let is_high = input.with_input(|x| x.is_high());
        rprintln!("Input pin high? {}", is_high);
    }
*/
}


#[interrupt]
fn ETH() {
    unsafe { ethernet::interrupt_handler() }
}

/*

use {
    core::cell::RefCell,
    cortex_m::interrupt::{free as interrupt_free, Mutex},
    stm32h7xx_hal::{
        interrupt, pac,
        prelude::*,
        rcc::rec::UsbClkSel,
        stm32,
        usb_hs::{UsbBus, USB1_ULPI},
    },
    usb_device::prelude::*,
    usb_device::{bus::UsbBusAllocator, device::UsbDevice},
    usbd_serial::{DefaultBufferStore, SerialPort},
};

pub const VID: u16 = 0x2341;
pub const PID: u16 = 0x025b;

pub static mut USB_MEMORY_1: [u32; 1024] = [0u32; 1024];
pub static mut USB_BUS_ALLOCATOR: Option<UsbBusAllocator<UsbBus<USB1_ULPI>>> =
    None;
pub static SERIAL_PORT: Mutex<
    RefCell<
        Option<
            SerialPort<
                UsbBus<USB1_ULPI>,
                DefaultBufferStore,
                DefaultBufferStore,
            >,
        >,
    >,
> = Mutex::new(RefCell::new(None));
pub static USB_DEVICE: Mutex<RefCell<Option<UsbDevice<UsbBus<USB1_ULPI>>>>> =
    Mutex::new(RefCell::new(None));

#[cortex_m_rt::entry]
unsafe fn main() -> ! {
    let cp = cortex_m::Peripherals::take().unwrap();
    let dp = stm32::Peripherals::take().unwrap();

    // Power
    let pwr = dp.PWR.constrain();
    let vos = pwr.smps().freeze();

    // RCC
    let rcc = dp.RCC.constrain();
    let mut ccdr = rcc.sys_ck(80.MHz()).freeze(vos, &dp.SYSCFG);

    // 48MHz CLOCK
    let _ = ccdr.clocks.hsi48_ck().expect("HSI48 must run");
    ccdr.peripheral.kernel_usb_clk_mux(UsbClkSel::Hsi48);

    // If your hardware uses the internal USB voltage regulator in ON mode, you
    // should uncomment this block.
    // unsafe {
    //     let pwr = &*stm32::PWR::ptr();
    //     pwr.cr3.modify(|_, w| w.usbregen().set_bit());
    //     while pwr.cr3.read().usb33rdy().bit_is_clear() {}
    // }

    // Get the delay provider.
    let mut delay = cp.SYST.delay(ccdr.clocks);

    // GPIO
    let (
        gpioa,
        gpiob,
        gpioc,
        _gpiod,
        _gpioe,
        _gpiof,
        _gpiog,
        gpioh,
        gpioi,
        gpioj,
        _gpiok,
    ) = {
        (
            dp.GPIOA.split(ccdr.peripheral.GPIOA),
            dp.GPIOB.split(ccdr.peripheral.GPIOB),
            dp.GPIOC.split(ccdr.peripheral.GPIOC),
            dp.GPIOD.split(ccdr.peripheral.GPIOD),
            dp.GPIOE.split(ccdr.peripheral.GPIOE),
            dp.GPIOF.split(ccdr.peripheral.GPIOF),
            dp.GPIOG.split(ccdr.peripheral.GPIOG),
            dp.GPIOH.split(ccdr.peripheral.GPIOH),
            dp.GPIOI.split(ccdr.peripheral.GPIOI),
            dp.GPIOJ.split(ccdr.peripheral.GPIOJ),
            dp.GPIOK.split(ccdr.peripheral.GPIOK),
        )
    };

    // It is very likely that the board you're using has an external
    // clock source. Sometimes you have to enable them by yourself.
    // This is the case on the Arduino Portenta H7.
    let mut oscen = gpioh.ph1.into_push_pull_output();
    delay.delay_ms(10u32);
    oscen.set_high();
    // Wait for osc to be stable
    delay.delay_ms(100u32);

    // Set USB OTG pin floating
    let mut _usb_otg = gpioj.pj6.into_floating_input();

    // Reset USB Phy
    let mut usb_phy_rst = gpioj.pj4.into_push_pull_output();
    usb_phy_rst.set_low();
    delay.delay_ms(10u8);
    usb_phy_rst.set_high();
    delay.delay_ms(10u8);

    // Enable USB OTG_HS interrupt
    cortex_m::peripheral::NVIC::unmask(pac::Interrupt::OTG_HS);

    let usb = USB1_ULPI::new(
        dp.OTG1_HS_GLOBAL,
        dp.OTG1_HS_DEVICE,
        dp.OTG1_HS_PWRCLK,
        gpioa.pa5.into_alternate(),
        gpioi.pi11.into_alternate(),
        gpioh.ph4.into_alternate(),
        gpioc.pc0.into_alternate(),
        gpioa.pa3.into_alternate(),
        gpiob.pb0.into_alternate(),
        gpiob.pb1.into_alternate(),
        gpiob.pb10.into_alternate(),
        gpiob.pb11.into_alternate(),
        gpiob.pb12.into_alternate(),
        gpiob.pb13.into_alternate(),
        gpiob.pb5.into_alternate(),
        ccdr.peripheral.USB1OTG,
        &ccdr.clocks,
    );

    USB_BUS_ALLOCATOR = Some(UsbBus::new(usb, &mut USB_MEMORY_1));

    let usb_serial =
        usbd_serial::SerialPort::new(USB_BUS_ALLOCATOR.as_ref().unwrap());

    let usb_dev = UsbDeviceBuilder::new(
        USB_BUS_ALLOCATOR.as_ref().unwrap(),
        UsbVidPid(VID, PID),
    )
    .strings(&[usb_device::device::StringDescriptors::default()
        .manufacturer("Fake company")
        .product("Serial port")
        .serial_number("TEST PORT 1")])
    .unwrap()
    .device_class(usbd_serial::USB_CLASS_CDC)
    .max_packet_size_0(64)
    .unwrap()
    .build();

    interrupt_free(|cs| {
        USB_DEVICE.borrow(cs).replace(Some(usb_dev));
        SERIAL_PORT.borrow(cs).replace(Some(usb_serial));
    });

    loop {
        cortex_m::asm::nop();
    }
}

#[interrupt]
fn OTG_HS() {
    interrupt_free(|cs| {
        if let (Some(port), Some(device)) = (
            SERIAL_PORT.borrow(cs).borrow_mut().as_mut(),
            USB_DEVICE.borrow(cs).borrow_mut().as_mut(),
        ) {
            if device.poll(&mut [port]) {
                let mut buf = [0u8; 64];
                match port.read(&mut buf) {
                    Ok(count) if count > 0 => {
                        // Echo back in upper case
                        for c in buf[0..count].iter_mut() {
                            if 0x61 <= *c && *c <= 0x7a {
                                *c &= !0x20;
                            }
                        }

                        let mut write_offset = 0;
                        while write_offset < count {
                            match port.write(&buf[write_offset..count]) {
                                Ok(len) if len > 0 => {
                                    write_offset += len;
                                }
                                _ => {}
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
    })
}
*/

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
