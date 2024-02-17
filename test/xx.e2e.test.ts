import { beforeAll, describe, test, expect } from 'bun:test'
import { exchangeSalts, player, type Players } from './xx_player'
import { Noir } from '@noir-lang/noir_js'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { deserialize } from 'bun:jsc'
import { legal__white_moves, illegal__white_moves } from './fixtures/xx_lit';

const org_stderr_write = process.stderr.write.bind(process.stderr)

// Docs: https://bun.sh/docs/api/file-io#incremental-writing-with-filesink
// TODO: We call `.kill()` (and await it) from the test runner on _this_ process, does
//   that clean up the FileSink correctly?

const log_file = Bun.file('loggies.txt')

// If file is empty or does not exist it's size is 0 (really it's an object
//   of `[Blob detatched]` but I am not sure how to handle that currently). If
//   said size 0 use the file as-is, else get a slice at it's length to
//   effectively append.
const log_file_view = log_file.size > 0 ? log_file.slice(log_file.size * 2) : log_file
console.log('at', log_file_view)

const log_w = log_file_view.writer()

// Checks if stderr output is a Roarr log line and if it is writes it to log file
//   and prevents it from being sent to stderr.
process.stderr.write = (data, callback) => {
    // Crude way of detecting if we're logging via Roarr but it'll do for now.
    // OPT: If this becomes a problem, i.e. we start logging 1-line JSON objects ourselves
    //      then simply add a prefix to Roarr which is a magic string to match on
    //      `startsWith` -- also ugly but fine for our purposes.
    if (data.startsWith('{"')) {
        // In-process logging, yucky. Probably fine for now.
        log_w.write(data)
        log_w.flush() // Want to see our logs immediately.
        return
    }

    // Pass through to real `process.stderr.write`.
    return org_stderr_write(data, callback)
}

import { Roarr as log } from 'roarr'

const { promise: c_promise, resolve: c_resolve } = Promise.withResolvers()

process.on('message', (message) => {
    switch (message.kind) {
        case 'CIRCUITS':
            c_resolve(message.msg)
            break
    }
})

//
function iterateScenarios(scenario_object: {}, test_fn) {
    Object.entries(scenario_object).forEach(([scenario, data]) => {
        // console.log('top level loop ->', scenario)

        if (data[Symbol.toStringTag] === 'Generator') {
            describe(scenario, async () => {

                const name_template = data.next().value
                let iter_idx = 0

                console.log('  is generator')
                for (const gen_data of data) {
                    iter_idx += 1
                    // console.log('    generator test', gen_data.move.to)
                    test(`[${iter_idx}] ${name_template(gen_data.move.from, gen_data.move.to)}`, async () => {
                        test_fn(gen_data)
                    })
                }
            })
        } else {
            // console.log('  is literal scenario')
            test(scenario, async () => {
                test_fn(data)
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
                log.debug('received')
                const post_white = await players.white.executeMove(
                    data.cur_board,
                    data.move
                )
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
