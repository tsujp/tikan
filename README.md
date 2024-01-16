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
Noir 0.22.0 (0.22.0+420a5c74a14dcfeede04337a42282093a7b5e63e)
acvm-backend-barretenberg 0.15.1
```

## Tests

Rather than keeping track of wanted tests within test files and having to open say 6 different files to check all have the same we can trust ourselves to keep this file up to date (famous last words) with the tests we want and whether or not we've implemented them. Ideally in the future this is automated.

### Moves

Focus is piece move patterns, legal and illegal versions of those, and special game mechanics like en-passant capture.

<table>
  <thead>
    <!-- <tr>
      <td rowspan="2" colspan="2" />
      <th scope="colgroup" />
      <th scope="colgroup" colspan="2">Sliders</th>
    </tr> -->
    <tr>
      <td rowspan="2" colspan="2" />
      <th scope="colgroup" colspan="2">Knight</th>
      <th scope="colgroup" colspan="2">Bishop / Rook / Queen</th>
      <th scope="colgroup" colspan="2">King</th>
      <th scope="colgroup" colspan="2">Pawn</th>
    </tr>
    <tr>
      <th scope="col">L</th>
      <th scope="col">I</th>
      <th scope="col">Legal</th>
      <th scope="col">Illegal</th>
      <th scope="col">L</th>
      <th scope="col">I</th>
      <th scope="col">L</th>
      <th scope="col">I</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="rowgroup" rowspan="2">General</th>
      <th scope="row">Capture</th>
      <!-- N -->
      <td>❌</td>
      <td>❌</td>
      <!-- B / R / Q -->
      <td>❌</td>
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>❌</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Nothing move</th>
      <!-- N -->
      <td>--</td>
      <td>✅</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>❌</td>
      <!-- K -->
      <td>--</td>
      <td>❌</td>
      <!-- P -->
      <td>--</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="rowgroup" rowspan="2">Pattern</th>
      <th scope="row">Empty board</th>
      <!-- N -->
      <td>✅</td>
      <td>✅</td>
      <!-- B / R / Q -->
      <td>❌</td>
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>❌</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Dense board</th>
      <!-- N -->
      <td>✅</td>
      <td>✅</td>
      <!-- B / R / Q -->
      <td>❌</td>
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>❌</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="rowgroup" rowspan="2">Blocked</th>
      <th scope="row">Faux-empty board**</th>
      <!-- N -->
      <td>--</td>
      <td>✅</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>❌</td>
      <!-- K -->
      <td>--</td>
      <td>❌</td>
      <!-- P -->
      <td>--</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Dense board</th>
      <!-- N -->
      <td>--</td>
      <td>✅</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>❌</td>
      <!-- K -->
      <td>--</td>
      <td>❌</td>
      <!-- P -->
      <td>--</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="rowgroup" rowspan="5">Special</th>
      <th scope="row">King's side castle</th>
      <!-- N -->
      <td>--</td>
      <td>--</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>--</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>--</td>
      <td>--</td>
    </tr>
    <tr>
      <th scope="row">Queen's side castle</th>
      <!-- N -->
      <td>--</td>
      <td>--</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>--</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>--</td>
      <td>--</td>
    </tr>
    <tr>
      <th scope="row">Promotion</th>
      <!-- N -->
      <td>--</td>
      <td>--</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>--</td>
      <!-- K -->
      <td>--</td>
      <td>--</td>
      <!-- P -->
      <td>✅</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">En-passant capture</th>
      <!-- N -->
      <td>--</td>
      <td>--</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>--</td>
      <!-- K -->
      <td>--</td>
      <td>--</td>
      <!-- P -->
      <td>❌</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">En-passant target</th>
      <!-- N -->
      <td>--</td>
      <td>--</td>
      <!-- B / R / Q -->
      <td>--</td>
      <td>--</td>
      <!-- K -->
      <td>--</td>
      <td>--</td>
      <!-- P -->
      <td>✅</td>
      <td>--</td>
    </tr>
    <tr>
      <th scope="rowgroup" rowspan="2">Fog</th>
      <th scope="row">Movement</th>
      <!-- N -->
      <td>✅</td>
      <td>✅</td>
      <!-- B / R / Q -->
      <td>❌</td>
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>--</td>
      <td>--</td>
    </tr>
    <tr>
      <th scope="row">Lights toggle</th>
      <!-- N -->
      <td>❌</td>
      <td>❌</td>
      <!-- B / R / Q -->
      <td>❌</td>
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
      <td>❌</td>
      <!-- P -->
      <td>❌</td>
      <td>❌</td>
    </tr>
  </tbody>
</table>

#### Notes

- Faux-empty board `**` isn't strictly empty, rather it contains the minimum required pieces for the test scenario. It is still named 'empty' in tests for easier running of tests by name-pattern.
- Cells containing `--` are not applicable.

### Captures

Purely 'normal' piece captures.

<table>
  <thead>
    <tr>
      <td rowspan="1" colspan="1" />
      <th scope="col">Pawn</th>
      <th scope="col">Knight</th>
      <th scope="col">Bishop</th>
      <th scope="col">Rook</th>
      <th scope="col">Queen</th>
      <th scope="col">King</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Pawn</th>
      <!-- P -->
      <td>✅</td>
      <!-- N -->
      <td>❌</td>
      <!-- B -->
      <td>❌</td>
      <!-- R -->
      <td>❌</td>
      <!-- Q -->
      <td>✅</td>
      <!-- K -->
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Knight</th>
      <!-- P -->
      <td>❌</td>
      <!-- N -->
      <td>❌</td>
      <!-- B -->
      <td>❌</td>
      <!-- R -->
      <td>❌</td>
      <!-- Q -->
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Bishop</th>
      <!-- P -->
      <td>❌</td>
      <!-- N -->
      <td>❌</td>
      <!-- B -->
      <td>❌</td>
      <!-- R -->
      <td>❌</td>
      <!-- Q -->
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Rook</th>
      <!-- P -->
      <td>❌</td>
      <!-- N -->
      <td>❌</td>
      <!-- B -->
      <td>❌</td>
      <!-- R -->
      <td>❌</td>
      <!-- Q -->
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Queen</th>
      <!-- P -->
      <td>❌</td>
      <!-- N -->
      <td>❌</td>
      <!-- B -->
      <td>❌</td>
      <!-- R -->
      <td>❌</td>
      <!-- Q -->
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">King</th>
      <!-- P -->
      <td>❌</td>
      <!-- N -->
      <td>❌</td>
      <!-- B -->
      <td>❌</td>
      <!-- R -->
      <td>❌</td>
      <!-- Q -->
      <td>❌</td>
      <!-- K -->
      <td>❌</td>
    </tr>
  </tbody>
</table>


### Logic

#### LS1B

  - [x] LS1B happy path.
  - [x] LS1B sad path.

#### MS1B

  - [ ] MS1B happy path.
  - [ ] LS1B sad path.

#### Diagonals

##### Masks
  Diag masking is the basis for all diag (diagonal and anti-diagonal) sliding piece movement (bishop, queen, king), so these masks must be correct without weird wrapping or edge-artifacting.

  - [x] Diagonal masks for every starting edge square.
  - [x] Anti-diagonal masks for every starting edge square.

##### Same-diagonal
  Whether two given square indices are on the same diag forms the basis of computing the required diag mask.

  - [x] Same diagonal and NOT same anti-diagonal.
  - [x] Same anti-diagonal and NOT same diagonal.


# TODOs

## Documentation

- [] Repo structure.
- [] test.sh script.
- [] Javascript test harness.
- [] Project structure (bitboards etc).
- [] bb_term project
- [] break_to_seed.ts
- [] gimme_that_enum.ts

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

##### For you

Checkmark and cross copy-pasta: ✅ ❌
