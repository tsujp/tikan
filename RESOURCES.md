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

