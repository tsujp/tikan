#!/usr/bin/env bash

set -euxo pipefail

# Naive commands for now, polish later.

cargo build --target wasm32-unknown-unknown

wasm-bindgen --out-dir ./www/frontend/ \
						 --target web \
             ./target/wasm32-unknown-unknown/debug/frontend.wasm
						 # --split-linked-modules \

ruby -run -ehttpd ./www/
