# Tikan

Zero knowledge fog of war chess implemented using Aztec's zk circuit language
Noir.


# Project structure

TODO


# Dependencies

Noir is under active development if you want to build this project yourself please
ensure you're using **exactly** the version numbers of Noir as specified in the
relevant files otherwise your build may not work.

```
Noir 0.19.0
```


# TODOs

## Circuits

- [x] Bitboard state representation.
- [] _(maybe)_ Recursive proof validation (persistence-layer agnostic).

## Frontend

- [] Svelte or SolidJS interface with circuit using `noir-js`.

## Other Relevant

- [] For some reason Helix likes to make it REALLY hard to clean up whitespace in files and has likes to litter them maximally. Annoying stuff, the entire codebase could do with a good auto-formatting later on.
- [] Tidy up etymology.

## Irrelevant Stretch

- [x] Basic build system for WASM frontend.
- [x] Basics of Rust and Bevy.
- [x] Compile current _stuff_ and confirm it works via WASM in a browser.
- [] Create a Hello World WASM module and instantiate it alongside (1) showing multiple modules can be used.
- [] WASM backend instantiated with data passed in from frontend.
- [] Optimise WASM build for size.
- [] Profile game memory usage and Noir WASM backend usage (ceiling is 4GiB).
- [] WASM multithreading with SharedArrayBuffer? Rayon (a dependency of Bevy) can apparently
     do this already; alternative are WebWorkers which would require copying memory per call.
- [] Using (2) try and do this in a WebWorker so that the game and the second WASM module run on seperate threads (because...)
- [] Replace the Hello World WASM module with the Noir WASM backend.
	  - Computing a proof will block so having another thread is key (hence 3).
- [] "Proper" build system for WASM (not just simple shell script currently).


#### Etymology

짙다 = (adj.) thick, heavy, dense, deep, dark
안개 = (n.) fog or mist

짙은 안개 = dense fog

Romanised for intuitive spelling -> tikun ange
Abbreviated -> TIKun ANge -> tikan
