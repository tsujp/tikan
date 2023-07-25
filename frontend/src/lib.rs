use gloo_console::log;
use gloo_worker::oneshot::oneshot;
// use gloo_worker::Registrable;
// use rand::prelude::*;
use rand::Rng;

use gloo_worker::{HandlerId, Worker, WorkerScope};

pub struct Multiplier {}

impl Worker for Multiplier {
    type Input = (u64, u64);
    type Message = ();
    type Output = ((u64, u64), u64);

    fn create(_scope: &WorkerScope<Self>) -> Self {
        Self {}
    }

    fn update(&mut self, _scope: &WorkerScope<Self>, _msg: Self::Message) {}

    fn received(&mut self, scope: &WorkerScope<Self>, msg: Self::Input, id: HandlerId) {
        scope.respond(id, (msg, msg.0 * msg.1));
    }
}

// fn main() {
//     // Show panic information in console.debug() since Rust stdlib will not output
//     //   to console API by itself.
//     console_error_panic_hook::set_once();

//     CoinFlip::registrar().register();
// }

// pub struct CoinFlip {}

// impl CoinFlip {
//     #[oneshot]
//     async fn DewIt(_: u32) -> u32 {
//         console_error_panic_hook::set_once();
//         log!("hello from web worker");
//         let mut rng = rand::thread_rng();
//         return rng.gen_range(0..2);
//     }
// }

// TODO: Use the `Worker` trait instead, for coin-flip MVP the oneshot macro is fine.
// #[oneshot]
// pub async fn DewIt(_: u32) -> u32 {
//     console_error_panic_hook::set_once();
//     log!("hello from web worker");
//     let mut rng = rand::thread_rng();
//     return rng.gen_range(0..2);
// }
