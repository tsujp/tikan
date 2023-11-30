# Tikan

Zero knowledge fog of war chess implemented using Aztec's zk circuit language
Noir.


# Project structure

Major components are the JavaScript workspace for developer utilities and the test harness as well as the circuits themselves.

```text
.
├── circuit/         # Noir FoW Chess implementation.
├── frontend/        # FoW Chess web frontend (TODO).
├── util/            # Dev utilities.
│   ├── bb_term/         # View bitboards in a terminal.
│   ├── bb_web/          # View bitboards in a web browser.
│   └── dev/             # JS workspace package for shared dependencies.
```

## Circuits

TODO: Circuit folder structure etc. Any simple sequence diagrams of how the main circuit logic is structured?


# Dependencies

Noir is under active development if you want to build this project yourself please
ensure you're using **exactly** the version numbers of Noir as specified in the
relevant files otherwise your build may not work.

Currently (and as a goal) the entire project uses the same version of Noir for all circuits involved.

```
Noir 0.19.3 (4e3a5a9)
acvm-backend-barretenberg 0.15.1
```


# TODOs

## Documentation

- [] Repo structure.
- [] test.sh script.
- [] Javascript test harness.
- [] Project structure (bitboards etc).

## Circuits

- [x] Bitboard state representation.
- [] _(maybe)_ Recursive proof validation (persistence-layer agnostic).

## Frontend

- [] Svelte or SolidJS interface with circuit using `noir-js`.

## Tooling / Utility

- [] For common dependencies like Typescript some kind of workspace management with Bun instead of manually keeping the various `package.json`s in-sync.
- [] Where appropriate a workspace-based `tsconfig.json` for the various ones in sub-projects.

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
