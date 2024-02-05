import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { TransactionDescription } from 'ethers/lib/utils'
import { Circuit } from './types';
import { exchangeSalts, player, type Players } from './player';
import { Noir } from '@noir-lang/noir_js'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { white_valid_pawns } from './fixtures/lights';

import { serialize, deserialize } from "bun:jsc";
const { promise: c_promise, resolve: c_resolve } = Promise.withResolvers()
    // for await (const chunk of Bun.stdin.stream()) {
    //     // chunk is Uint8Array
    //     // this converts it to text (assumes ASCII encoding)
    //     const chunkText = Buffer.from(chunk)
    //     const deserial = deserialize(chunkText)
    //     switch (deserial.kind) {
    //         case 'CIRCUITS':
    //             console.log('received this', deserial)
    //             c_resolve(deserial.msg)
    //             break
    //     }
    // }
    ; (async () => {
        for await (const chunk of Bun.stdin.stream()) {
            const chunkText = Buffer.from(chunk)
            const deserial = deserialize(chunkText)
            switch (deserial.kind) {
                case 'CIRCUITS':
                    console.log('received this', deserial)
                    c_resolve(deserial.msg)
                    break
            }
        }
    })()

console.log('argies', Bun.argv)

// process.send("Hello from child bing bong!!!!")
// // process.send({ message: "Hello from child as object" });

// const { promise: c_promise, resolve: c_resolve } = Promise.withResolvers()

// process.on('message', ({ kind, msg }) => {
//     console.log('CHILD GOT MESSAGE', kind, msg)
//     switch (kind) {
//         case 'CIRCUITS':
//             console.log('received', msg)
//             c_resolve(msg)
//     }
// });

// console.log('circuits are', await CIRCUITS)

//
// * * * * * * * * * * * * * * * * * * * * * * * BOILERPLATE
// * * * * * * * * * * * * *

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

// Force code depending on circuits (everything essentially) to wait for the circuits message
//   to come in and be resolved.
const CIRCUITS = await c_promise
console.log('gottem!!!!')
// const CIRCUITS = {
//     bin: [
//         {
//             name: "player",
//             root: "/Users/tsujp/programming/~aztec/tikan/circuit/player",
//             artifact: "/Users/tsujp/programming/~aztec/tikan/circuit/player/target/tikan_player.json",
//         },
//         {
//             name: "state_commitment",
//             root: "/Users/tsujp/programming/~aztec/tikan/circuit/pedersen",
//             artifact: "/Users/tsujp/programming/~aztec/tikan/circuit/pedersen/target/tikan_pedersen.json",
//         }
//     ],
//     lib: [
//         {
//             name: "tikan",
//             root: "/Users/tsujp/programming/~aztec/tikan/circuit/lib",
//         }
//     ],
// }

const player_circuit = await import(CIRCUITS.bin.find((c) => c.name === 'player').artifact)
// console.log('player circuit is', player_circuit)
const state_commitment_circuit: Circuit = await import(CIRCUITS.bin.find((c) => c.name === 'state_commitment').artifact)
// console.log('state', state_commitment_circuit)
// const state_commitment_circuit: Circuit = await import(CIRCUITS.state_commitment.circuit)

describe('two players (non-recursive)', async () => {
    let players: Players
    // const commit = new Noir()
    const commit = new Noir(state_commitment_circuit)
    console.log('done!')

    // Instantiate required backends.
    beforeAll(async () => {
        const w = await player('white', player_circuit, BACKEND_THREADS, commit)
        const b = await player('black', player_circuit, BACKEND_THREADS, commit)

        players = {
            white: w,
            black: b,
        }
    })

    describe('valid moves', async () => {
        describe('black accepts white pawn', async () => {
            Object.entries(white_valid_pawns).forEach(([scenario, data]) => {
                test(scenario, async () => {
                    exchangeSalts(players)

                    const white_turn_data = await players.white.playTurn(
                        data.public_state,
                        data.white_move,
                    )

                    console.log(white_turn_data)

                    // Black verifies white's proof.
                    // const black_accepts_white = await players.black.acceptTurn(
                    //     white_turn_data,
                    // )
                    // console.log(white_turn_data.publicInputs)
                    // expect(black_accepts_white).toBeTrue()
                }, 30000)
            })
        })
    })
})
