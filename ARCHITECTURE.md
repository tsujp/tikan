# Architecture

Documentation on the architecture of key project components including considered
alternatives.

## WASM-centric Frontend

### Rust and Bevy

The game frontend is written as a Bevy game which can be compiled to WASM with
the required JavaScript bindings. I knew no Rust nor Bevy at the start of this
project (not a humble-brag, see the following sentence). The reason I chose
Rust and Bevy was for the ease of the _tooling_ available.

I wanted to avoid a frontend in React (needlessly complicated framework), as
well as saner alternatives like SolidJS, or Svelte because of the EXHAUSTING
nature of maintaining a JavaScript-based development environment. I say this as
a web developer of near 10 years (5 hobby, 5 professionally).

Bevy provides a way to distribute natively compiled executables (perhaps useful
later on) but crucially: a WASM compiled bundle with the bindings automatically
handled by Rust's `wasm-bindgen`.

I would have gone with Zig using something like the Sokol headers but I was
unsure of the tooling surrounding this and the author of the Sokol headers
who wrote a Pacman implementation using the Zig bindings for their library
noted a few quirks. Given the novel nature of this project I wanted to have
all quirks be related to the project at-hand (less variables to account for).

### WASM concurrency and parallelism

Within the context of a browser WASM executes as a single thread. The Noir
proving circuit will take some time to compute a move proof when invoked and
so not blocking the main rendering thread is key, this also applies to things
like playing audio too.

WebWorkers can be used to spawn a seperate thread however the cross-thread
communication is expensive because data is copied instead of shared.

-- TODO: investigating WebWorker vs SharedArrayBuffer still, write more once done.
