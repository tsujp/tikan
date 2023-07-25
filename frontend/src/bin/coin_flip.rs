use gloo_console::log;
use gloo_worker::Registrable;
use tikan::Multiplier;

fn main() {
    // Show panic information in console.debug() since Rust stdlib will not output
    //   to console API by itself.
    console_error_panic_hook::set_once();

    log!("hello from worker registration");

    Multiplier::registrar().register();
}
