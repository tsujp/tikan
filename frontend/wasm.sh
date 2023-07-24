#!/usr/bin/env bash

# Naive commands for now, polish later.

cargo build --target wasm32-unknown-unknown

wasm-bindgen --out-dir ./www/frontend/ \
						 --target web \
             ./target/wasm32-unknown-unknown/release/frontend.wasm

ruby -run -ehttpd ./www/
