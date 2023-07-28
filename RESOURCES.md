# Resources

Resources used for learning to complete this project.

## Noir

- Noir recursive proofs demo: [link](https://github.com/Savio-Sou/recursion-demo/blob/main/src/main.nr).

## Rust

- Learn X In Y Minutes: [link](https://learnxinyminutes.com/docs/rust/).

## Bevy

### Docs / Discussion

- Bevy builtins index: [link](https://bevy-cheatbook.github.io/builtins.html).
- Web loading bar discussion: [link](https://github.com/bevyengine/bevy-website/issues/338).
- Mouse input: [link](https://bevy-cheatbook.github.io/input/mouse.html).
- Coordinates: [link_1](https://www.mikechambers.com/blog/2022/10/29/understanding-the-2d-coordinate-system-in-bevy/) [link_2](https://bevy-cheatbook.github.io/features/coords.html).
- Cursor screenspace to worldspace: [link](https://bevy-cheatbook.github.io/cookbook/cursor2world.html).

### Examples

- Seperate async and multi-threaded: [link](https://github.com/bevyengine/bevy/tree/latest/examples/async_tasks).
- Iterating `Query` results: [link](https://github.com/bevyengine/bevy/blob/main/examples/ecs/iter_combinations.rs).
- Cursor screenspace position: [link](https://github.com/bevyengine/bevy/issues/2158#issuecomment-1517803673).
- Relative cursor position: [link](https://bevyengine.org/examples/UI%20(User%20Interface)/relative-cursor-position/).

### Demos

- Minesweeper WASM code: [link](https://gitlab.com/qonfucius/minesweeper-tutorial).
- 2048 WASM code: [link](https://github.com/DarkLichCode/bevy_demo_2048).

## Chess

### Assets

- Wikipedia chess assets: [link](https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces).

## WASM

### Docs

- MDN Rust to WASM: [link](https://developer.mozilla.org/en-US/docs/WebAssembly/Rust_to_Wasm).

### Rust tooling

- `wasm-pack`: [site](https://rustwasm.github.io/docs/wasm-pack/introduction.html) [repo](https://github.com/rustwasm/wasm-pack).




### Dunegon To Organise

- https://github.com/GoogleChromeLabs/wasm-bindgen-rayon
- https://github.com/bevyengine/bevy/issues/4078
- https://www.mikechambers.com/blog/2022/10/30/managing-window-size-in-bevy/
- https://www.youtube.com/watch?v=f4s1h2YETNY (shader art coding)
- https://github.com/romenjelly/bevy_debug_grid/tree/master/src
- https://github.com/dmackdev/bevy_jaipur/blob/master/src/card_selection.rs
- https://github.com/Anshorei/bevy_interact_2d/blob/master/src/drag.rs
- https://github.com/bevyengine/bevy/issues/4301 (bevy taskpool)
- https://github.com/bevyengine/bevy/pull/4346 (bevy taskpool platform agnostic interface)
- https://github.com/rustwasm/wasm-bindgen/issues/3048 (wasm-bindgen Atomics.waitAsync())

- https://github.com/bevyengine/bevy/issues/4078 (Bevy WASM multithreading tracking issue)
- https://www.tweag.io/blog/2022-11-24-wasm-threads-and-messages/ (WASM threads and messages with Rust)

webassembly atomic instructions
- https://webassembly.github.io/threads/core/syntax/instructions.html#atomic-memory-instructions

is WebWorker.postMessage() slow?
- https://surma.dev/things/is-postmessage-slow/

contains some discussion on webworkers in bevy
- https://github.com/bevyengine/bevy/issues/88


TODO: Brotli compress.

profile        no wasm-opt   wasm-opt   brotli -Z       config
debug          30            -          -            -
release (a)    24.6          15.7       -            s, thin   | Os
release (b)    23.6          13.2       -            z, thin   | Os
release (c)    16.1          10.9       -            z, fat    | Os
release (d)    16.1          10         -            z, fat    | Oz
release (e)    14.1          9.2        2.5          z, fat, 1 | Oz
release (f)    10            6.4        1.9          z, fat, 1 | Oz | core_pipeline, ui, asset, winit, webgl2
release (g)    9.3           5.7        1.3          z, fat, 1 | Oz | core_pipeline, ui, asset, winit

Google's wasm-bindgen rayon useful snippets and insight
- https://github.com/GoogleChromeLabs/wasm-bindgen-rayon/blob/e13485d6d64a062b890f5bb3a842b1fe609eb3c1/demo/index.js#L25-L29
- https://github.com/GoogleChromeLabs/wasm-bindgen-rayon/blob/e13485d6d64a062b890f5bb3a842b1fe609eb3c1/demo/wasm-worker.js#L28-L31
- https://github.com/GoogleChromeLabs/wasm-bindgen-rayon/blob/main/src/workerHelpers.js

- https://docs.rs/spmc/latest/spmc/ (Single Producer Multiple Consumer ; work-stealing)

- https://web.dev/webassembly-threads/#rust
- https://surma.dev/things/is-postmessage-slow/
- https://www.chromium.org/developers/design-documents/inter-process-communication/

- https://doc.rust-lang.org/std/process/index.html

- https://nextjs-bbjs.netlify.app/ (bb.js example)
- https://github.com/noir-lang/nextjs-bbjs-demo/blob/main/src/app/multithreading.tsx

Aztec NPM packages
- https://www.npmjs.com/package/@aztec/barretenberg?activeTab=code
- https://www.npmjs.com/package/@aztec/sdk?activeTab=code

- https://github.com/richardanaya/wasm-service/blob/main/index.html

Rust wasm-opt bindings, use this to construct a build.rs later on
- https://github.com/brson/wasm-opt-rs
- https://docs.rs/wasm-opt/latest/wasm_opt/
- https://github.com/w3f/Grants-Program/pull/1070
- https://github.com/bevyengine/bevy/blob/0566e73af460b9d128354a20970b1e1e0cc3b719/tools/build-wasm-example/src/main.rs#L35 (Bevy build.rs wasm example)

Wasm tools (incl wasm-opt)
- https://github.com/WebAssembly/binaryen

Wasm size optimisation
- https://rustwasm.github.io/docs/book/reference/code-size.html
- https://github.com/bevyengine/bevy/issues/3800 (feature removal)
- https://github.com/bevyengine/bevy/tree/main/examples#2-use-wasm-opt-from-the-binaryen-package
- https://rustwasm.github.io/book/reference/code-size.html

Cargo features
- https://doc.rust-lang.org/cargo/reference/features.html
- https://dev.to/rimutaka/cargo-features-explained-with-examples-194g

Cargo profiles
- https://doc.rust-lang.org/cargo/reference/profiles.html

Bevy's features
- https://github.com/bevyengine/bevy/blob/main/Cargo.toml#L62

Rust wasm
- https://surma.dev/things/rust-to-webassembly/

Rust threading
- https://doc.rust-lang.org/book/ch16-02-message-passing.html
- https://doc.rust-lang.org/book/ch13-01-closures.html#capturing-references-or-moving-ownership (threads and `move`)
- https://github.com/crossbeam-rs/crossbeam
- https://github.com/bevyengine/bevy/blob/main/examples/async_tasks/async_compute.rs (Bevy)
- https://github.com/bevyengine/bevy/blob/main/examples/async_tasks/external_source_external_thread.rs (Bevy)
- https://docs.rs/crossbeam-channel/latest/crossbeam_channel/
- https://docs.rs/crossbeam-channel/latest/crossbeam_channel/macro.select.html
- https://github.com/crossbeam-rs/crossbeam/blob/master/crossbeam-channel/tests/same_channel.rs
- https://github.com/crossbeam-rs/crossbeam/issues/470
- https://github.com/crossbeam-rs/crossbeam/issues/966
- https://github.com/chemicstry/wasm_thread
- https://github.com/chemicstry/wasm_thread/issues/8
- https://github.com/chemicstry/wasm_thread/issues/6 (useful info on channels)
- https://www.tweag.io/blog/2022-11-24-wasm-threads-and-messages/

Other rust wasm crates
- https://github.com/daxpedda/wasm-worker/blob/main/examples/testing.rs
- https://docs.rs/gloo-worker/0.3.0/gloo_worker/
- https://github.com/rustwasm/twiggy (doesnt work with multithreaded wasm)
- https://github.com/rustwasm/gloo/pull/340/files#diff-2e9d962a08321605940b5a657135052fbcef87b5e360662bb527c96d9a615542 (useful type example)

Bevy examples/crates
- https://github.com/johanhelsing/bevy_sparse_grid_2d

Rust logging
- https://docs.rs/fern/latest/fern/

- https://github.com/thedodd/trunk/blob/master/src/pipelines/rust.rs (build scripts)

Rust networking
- https://docs.rs/tower/0.4.13/tower/index.html
