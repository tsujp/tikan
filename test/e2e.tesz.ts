import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { join } from 'path'
import { white_valid_pawns } from './fixtures/white_start'
import { Players, exchangeSalts, player } from './player'
import { Circuit, CircuitDefinition, Piece } from './types'
import { getCircuitDefinitions } from './utility/get_circuits'
import { checkTestEnvironment } from './utility/precheck'

//
// * * * * * * * * * * * * * * * * * * * * * * * BOILERPLATE
// * * * * * * * * * * * * *

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

// TODO XXX
// I wish we could import.meta.resolveSync to our own package.json but this is
//   fine so long as we remember to update relative paths against this file to
//   said package.json.
const PROJECT_ROOT = join(import.meta.dir, '..') // Brittle as fuck.
const PACKAGE_JSON = join(PROJECT_ROOT, 'package.json')

const CIRCUITS = await getCircuitDefinitions(PACKAGE_JSON, PROJECT_ROOT)

//
// * * * * * * * * * * * * * * * * * * * * * * * ENV CHECK, COMPILE CIRCUITS
// * * * * * * * * * * * * *

const preCheckGood = checkTestEnvironment(wd, CIRCUITS)

describe('pre-test checks', () => {
    test('check environment and compile circuits', () => {
        expect(preCheckGood).toBeTrue()
    })
})

//
// * * * * * * * * * * * * * * * * * * * * * * * TESTS PROPER
// * * * * * * * * * * * * *

const player_circuit: Circuit = await import(CIRCUITS.player.circuit)
const state_commitment_circuit: Circuit = await import(CIRCUITS.state_commitment.circuit)

describe('two players (non-recursive)', async () => {
    let players: Players
    const commit = new Noir(state_commitment_circuit)

    // Instantiate required backends.
    beforeAll(async () => {
        const w = await player('white', player_circuit, BACKEND_THREADS, commit)
        const b = await player('black', player_circuit, BACKEND_THREADS, commit)

        players = {
            white: w,
            black: b,
        }
    })

    // describe('valid moves', async () => {
    //     test('black accepts white pawn', async () => {

    //         exchangeSalts(players)

    //         const white_turn_data = await players.white.playTurn(
    //             {
    //                 bbs: [
    //                     '0xffff', // White board
    //                     '0xffff000000000000', // Black board
    //                     '0x4200000000000042', // Knights
    //                     '0x2400000000000024', // Bishops
    //                     '0x8100000000000081', // Rooks
    //                     '0x0800000000000008', // Queens
    //                     '0x1000000000000010', // Kings
    //                     '0x00ff00000000ff00', // Pawns
    //                 ],
    //                 army: 0, // Current army's turn (Board::Piece enum index)
    //                 castle_rights: 15, // Bitmask castle rights K Q k q, 1 = yes, 0 = no
    //                 en_passant: 0, // En-passant target square index (LERLEF 6-bits)
    //                 halfmove: 0, // Halfmove count
    //                 fullmove: 1, // Fullmove count
    //             },
    //             {
    //                 piece: Piece.PAWN,
    //                 from: 14, // g2
    //                 to: 30, // g4
    //                 promotion_piece: 0,
    //             },
    //         )

    //         // Black verifies white's proof.
    //         const black_accepts_white = await players.black.acceptTurn(
    //             white_turn_data,
    //         )
    //         console.log(white_turn_data.publicInputs)
    //         expect(black_accepts_white).toBeTrue()
    //     }, 30000)
    // })

    describe('valid moves', async () => {
        describe('black accepts white pawn', async () => {
            Object.entries(white_valid_pawns).forEach(([scenario, data]) => {
                test(scenario, async () => {
                    exchangeSalts(players)

                    const white_turn_data = await players.white.playTurn(
                        data.input_board,
                        data.white_move,
                    )

                    // Black verifies white's proof.
                    const black_accepts_white = await players.black.acceptTurn(
                        white_turn_data,
                    )
                    // console.log(white_turn_data.publicInputs)
                    expect(black_accepts_white).toBeTrue()
                }, 30000)
            })
        })
    })
})
