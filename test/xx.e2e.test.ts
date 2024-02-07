import { beforeAll, describe, test } from 'bun:test'
import { exchangeSalts, player, type Players } from './xx_player'
import { Noir } from '@noir-lang/noir_js'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { deserialize } from 'bun:jsc'

const { promise: c_promise, resolve: c_resolve } = Promise.withResolvers()

    ; (async () => {
        for await (const chunk of Bun.stdin.stream()) {
            const chunkText = Buffer.from(chunk)
            const deserial = deserialize(chunkText)

            switch (deserial.kind) {
                case 'CIRCUITS':
                    c_resolve(deserial.msg)
                    break
            }
        }
    })()

//
// * * * * * * * * * * * * * * * * * * * * * * * BOILERPLATE
// * * * * * * * * * * * * *

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

// Force code depending on circuits (everything essentially) to wait for the circuits message
//   to come in and be resolved.
const CIRCUITS = await c_promise

const start_proof_circ = await import(CIRCUITS.bin.find((c) => c.name === 'xx_start_proof').artifact)
const start_commit_circ = await import(CIRCUITS.bin.find((c) => c.name === 'xx_start_commit').artifact)
const player_circ = await import(CIRCUITS.bin.find((c) => c.name === 'xx_player').artifact)

const white_start = [{ file: 1, rank: 0, lit: true }, { file: 3, rank: 0, lit: true }]
const black_start = [{ file: 1, rank: 4, lit: true }, { file: 3, rank: 4, lit: true }]
const board_start = {
    halfmove: 0,
    turn: 0,
    players: [
        white_start,
        black_start,
    ],
}

import { getRandomValues } from 'crypto'
function gimmeSalt() {
    const value = new BigUint64Array(1)
    // salt.ours = hexInt(getRandomValues(value)[0].toString(16))
    return `0x${getRandomValues(value)[0].toString(16)}`
}

describe('recursive', async () => {
    let players: Players

    // Instantiate required backends and create start position proofs.
    beforeAll(async () => {
        const commit = new Noir(start_commit_circ)

        const white_salt = gimmeSalt()
        const { returnValue: white_commit } = await commit.execute({
            board: board_start,
            player: 0,
            pieces: white_start,
            salt: white_salt,
        })
        const w = await player('white', player_circ, BACKEND_THREADS, start_proof_circ, white_commit, white_salt)

        const black_salt = gimmeSalt()
        const { returnValue: black_commit } = await commit.execute({
            board: board_start,
            player: 1,
            pieces: black_start,
            salt: black_salt
        })
        const b = await player('black', player_circ, BACKEND_THREADS, start_proof_circ, black_commit, black_salt)

        players = {
            white: w,
            black: b,
        }
    })

    describe('valid moves', async () => {
        describe('white', async () => {
            test('move {1,0} to {1,1}', async () => {
                await players.white.playMove(board_start, {
                    from_file: 1,
                    from_rank: 0,
                    to_file: 1,
                    to_rank: 1
                })
            }, 90000)
        })
    })

    // describe('valid moves', async () => {
    //     describe('black accepts white pawn', async () => {
    //         Object.entries(white_valid_pawns).forEach(([scenario, data]) => {
    //             test(scenario, async () => {
    //                 exchangeSalts(players) // TODO: Why again?

    //                 const post_white = await players.white.protoAttemptOne(
    //                     data.public_state,
    //                     data.white_move
    //                 )

    //                 // const white_turn_data = await players.white.playTurn(
    //                 //     data.public_state,
    //                 //     data.white_move,
    //                 // )

    //                 // console.log(post_white)

    //                 // Black verifies white's proof.
    //                 // const black_accepts_white = await players.black.acceptTurn(
    //                 //     white_turn_data,
    //                 // )
    //                 // console.log(white_turn_data.publicInputs)
    //                 // expect(black_accepts_white).toBeTrue()
    //             }, 30000)
    //         })
    //     })
    // })
})
