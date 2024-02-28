import { beforeAll, describe, test, expect } from 'bun:test'
import { exchangeSalts, player, type Players } from './xx_player'
import { Noir } from '@noir-lang/noir_js'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { deserialize } from 'bun:jsc'
import { legal__white_moves, illegal__white_moves, illegal__white__general } from './fixtures/xx_lit'

const { promise: c_promise, resolve: c_resolve } = Promise.withResolvers()

process.on('message', (message) => {
    switch (message.kind) {
        case 'CIRCUITS':
            c_resolve(message.msg)
            break
    }
})

function debugLogTestStart(test_name: string) {
    // TODO: Header format etc.
    console.log(`  logs for: ${test_name}`)
    // console.log('cur_board', data)
    // console.log(`    IN  <-  t=${data.cur_board.turn} h=${data.cur_board.halfmove}`)
}

function debugLogTestEnd() {

}

//
function iterateScenarios(scenario_object: {}, test_fn) {
    Object.entries(scenario_object).forEach(([scenario, data]) => {
        // console.log('top level loop ->', scenario)

        if (data[Symbol.toStringTag] === 'Generator') {
            describe(scenario, async () => {

                const name_template = data.next().value
                let iter_idx = 0

                // console.log('  is generator')
                for (const gen_data of data) {
                    iter_idx += 1
                    // console.log('    generator test', gen_data.move.to)
                    test(`[${iter_idx}] ${name_template(gen_data.move.from, gen_data.move.to)}`, async () => {
                        console.log('FOOOOOOOO', expect.getState())
                        // debugLogTestStart(`${iter_idx} ${name_template(gen_data.move.from, gen_data.move.to)}`)
                        process.send({ tag: 'MSG', msg: `${iter_idx} ${name_template(gen_data.move.from, gen_data.move.to)}`, data: null })
                        // process.send({ msg: '', data: gen_data })
                        await test_fn(gen_data)
                        // console.log('test return:', wat)
                        debugLogTestEnd()
                        // console.log('done')
                    })
                }
            })
        } else {
            // console.log('  is literal scenario')
            test(scenario, async () => {
                debugLogTestStart(scenario)
                await test_fn(data)
                // debugLogTestEnd()
            })
        }
    })
}

//
// * * * * * * * * * * * * * * * * * * * * * * * BOILERPLATE
// * * * * * * * * * * * * *

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

// Force code depending on circuits (everything essentially) to wait for the circuits message
//   to come in and be resolved.
const CIRCUITS = await c_promise

const commitment = await import(CIRCUITS.bin.find((c) => c.name === 'xx_commitment').artifact)
const player_circ = await import(CIRCUITS.bin.find((c) => c.name === 'xx_player').artifact)

import { getRandomValues } from 'crypto'
function gimmeSalt() {
    const value = new BigUint64Array(1)
    // salt.ours = hexInt(getRandomValues(value)[0].toString(16))
    return `0x${getRandomValues(value)[0].toString(16)}`
}

describe('(execute) non-recursive', async () => {
    let players: Players
    const commit_nr = new Noir(commitment)

    // Instantiate required backends and create start position proofs.
    beforeAll(async () => {

        // const { returnValue: white_commit } = await commit.execute({
        //     board: board_start,
        //     player: 0,
        //     pieces: white_start,
        //     salt: 0,
        // })
        const w = await player('white', player_circ, BACKEND_THREADS, commit_nr)

        // const { returnValue: black_commit } = await commit.execute({
        //     board: board_start,
        //     player: 1,
        //     pieces: black_start,
        //     salt: 0
        // })
        // const b = await player('black', player_circ, BACKEND_THREADS, black_commit, '0x0')

        players = {
            white: w,
            // black: b,
        }
    })

    describe('legal', async () => {
        describe('white', async () => {
            iterateScenarios(legal__white_moves, async (data) => {
                process.send({ tag: 'DATA_IN', msg: '', data: data })
                const post_white = await players.white.executeMove(
                    data.cur_board,
                    data.move
                )
                process.send({ tag: 'DATA_OUT', msg: '', data: post_white[0] })
                process.send({ tag: 'DATA_OUT', msg: '', data: post_white[1] })
                // return 42069
                // console.log('baraaa')
                // console.log('blah', post_white)
            })
            // Object.entries(legal__white_moves).forEach(([scenario, data]) => {
            //     console.log('OBJECT MAP')
            //     console.log(scenario)
            //     console.log(typeof data)
            //     console.log(typeof data[Symbol.iterator])
            //     console.log(data[Symbol.iterator] === data)
            //     console.log(data.constructor)

            //     // Haven't tested if you construct a generator manually, since any function
            //     //   can return a generator by manually constructing an object that implements
            //     //   the iterable protocol.
            //     // OPT: Make this detection generic if there's a good reason to.
            //     console.log('IS ', data[Symbol.toStringTag] === 'Generator')

            //     for (const what of data) {
            //         console.log('GENERATOR')
            //     }
            //     // test(scenario, async () => {
            //     //     const post_white = await players.white.executeMove(
            //     //         data.cur_board,
            //     //         data.move
            //     //     )
            //     // }, 30000)
            // })
        })
    })

    describe('illegal', async () => {
        describe('white', async () => {
            iterateScenarios(illegal__white_moves, async (data) => {
                process.send({ tag: 'DATA_IN', msg: '', data: data })
                // expect(players.white.executeMove(
                //     data.cur_board,
                //     data.move
                // )).rejects.toThrow(new Error('Circuit execution failed: Error: Assertion failed: Invalid move pattern'))
                
                expect(players.white.executeMove(
                    data.cur_board,
                    data.move
                )).rejects.toThrow(new Error(data.rejects_with))
            })
        })
    })

    describe('illegal', async () => {
        describe('white', async () => {
            describe('general', async () => {
                iterateScenarios(illegal__white__general, async (data) => {
                    process.send({ tag: 'DATA_IN', msg: '', data: data })
                    expect(players.white.executeMove(
                        data.cur_board,
                        data.move
                    )).rejects.toThrow(new Error(data.rejects_with))
                })
            })
        })
    })

    // describe('illegal', async () => {
    //     describe('white', async () => {
    //         Object.entries(illegal__white_moves).forEach(([scenario, data]) => {
    //             test(scenario, async () => {
    //                 const post_white = await players.white.executeMove(
    //                     data.cur_board,
    //                     data.move
    //                 )
    //             }, 30000)
    //         })
    //     })
    // })

    // describe('illegal', async () => {
    //     describe('white', async () => {
    //         test('move {1,0} to {1,4} (move pattern)', async () => {
    //             // Illegal piece move pattern.
    //             expect(players.white.playMove(board_start, {
    //                 from_file: 1,
    //                 from_rank: 0,
    //                 to_file: 1,
    //                 to_rank: 4
    //             })).rejects.toThrow(new Error('Circuit execution failed: Error: Assertion failed: Illegal move pattern'))
    //         }, 5000)

    //         test('starting position', async () => {
    //             const white_start_2 = [{ file: 2, rank: 1, lit: true }, { file: 3, rank: 0, lit: true }]
    //             const black_start_2 = [{ file: 1, rank: 4, lit: true }, { file: 3, rank: 4, lit: true }]
    //             const board_start_2 = {
    //                 halfmove: 0,
    //                 turn: 0,
    //                 commits: [
    //                     { x: '0x0', y: '0x0' },
    //                     { x: '0x0', y: '0x0' },
    //                 ],
    //                 players: [
    //                     white_start_2,
    //                     black_start_2,
    //                 ],
    //             }

    //             expect(players.white.playMove(board_start_2, {
    //                 from_file: 2,
    //                 from_rank: 1,
    //                 to_file: 2,
    //                 to_rank: 2
    //             })).rejects.toThrow(new Error('Circuit execution failed: Error: Assertion failed: Illegal move pattern'))
    //         }, 5000)
    //     })
    // })

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
