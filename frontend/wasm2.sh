#!/usr/bin/env bash

set -euxo pipefail

# Naive commands for now, polish later.

# The Rust standard library needs to be recompiled with atomics enabled. To do
#   that we use Cargo's unstable `-Z build-std` feature.
#
# Next we need to compile everything with the `atomics` and `bulk-memory`
#   features enabled, ensuring that LLVM will generate atomic instructions,
#   shared memory, passive segments, etc.

RUSTFLAGS='-C target-feature=+atomics,+bulk-memory,+mutable-globals' \
	cargo +nightly build \
		--target wasm32-unknown-unknown \
		-Z build-std=std,panic_abort
  # cargo +nightly build --example simple --target wasm32-unknown-unknown --release -Z build-std=std,panic_abort

# Note the usage of `--target no-modules` here which is required for passing
# the memory import to each wasm module.
wasm-bindgen \
  target/wasm32-unknown-unknown/debug/frontend.wasm \
  --out-dir ./www/frontend/ \
  --target no-modules


# Old
# cargo build --workspace --target wasm32-unknown-unknown

# wasm-bindgen --out-dir ./www/frontend/ \
# 						 --target web \
#              ./target/wasm32-unknown-unknown/debug/frontend.wasm
# 						 # --split-linked-modules \

# ruby -run -ehttpd ./www/
