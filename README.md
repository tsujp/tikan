# Tikan

Zero knowledge fog of war chess implemented using Aztec's zk circuit language
Noir; with universal frontend in Rust.

# Project structure

TODO

# Dependencies

Noir is under active development, as is Bevy, if you want to build this project
yourself please ensure you're using **exactly** the version numbers of Noir
and Bevy as specified in the relevant files otherwise your build may not work.

```
Noir
Rust 1.71.0
Bevy 0.11.0
wasm-bindgen-cli
```

# TODOs

## Circuits

- [] WASM backend instantiated with data passed in from frontend.
- [] Bitboard state representation.
- [] Recursive proof validation (persistence-layer agnostic).

## Frontend

- [x] Basics of Rust and Bevy.
- [x] Compile current _stuff_ and confirm it works via WASM in a browser.
- [] Create a Hello World WASM module and instantiate it alongside (1) showing multiple modules can be used.
- [] Using (2) try and do this in a WebWorker so that the game and the second WASM module run on seperate threads (because...)
- [] Replace the Hello World WASM module with the Noir WASM backend.
	  - Computing a proof will block so having another thread is key (hence 3).
- [x] Basic build system for WASM frontend.
- [] "Proper" build system for WASM (not just simple shell script currently).
- [] Optimise WASM build for size.
- [] Profile game memory usage and Noir WASM backend usage (ceiling is 4GiB).

## Other

- [] Tidy up etymology.

#### Etymology

짙다 = (adj.) thick, heavy, dense, deep, dark
안개 = (n.) fog or mist

짙은 안개 = dense fog

Romanised for intuitive spelling -> tikun ange
Abbreviated -> TIKun ANge -> tikan
