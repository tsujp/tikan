import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { join } from 'path'
import { Players, exchangeSalts, player } from './player'
import { Circuit, CircuitDefinition } from './types'
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

// TODO: waste time typing this (TypeScript) later.
// @ts-ignore
const asyncMap = (items, fn) => Promise.all(items.map(fn))

async function getCircuitDefinitions (): Promise<CircuitDefinition> {
    const circuits: string[][] = await import(PACKAGE_JSON).then(({ circuits }) =>
        Object.entries(circuits)
    )

    const circuit_paths = circuits.map(([_, dir]) => join(PROJECT_ROOT, dir))
    const circuit_jsons = await asyncMap(circuit_paths, async (path: string) => {
        const { package: { name } } = await import(join(path, 'Nargo.toml'))
        const json = join(path, `target/${name}.json`)
        return json
    })

    const circuit_defs = circuits.reduce((acc, [ref_name, _], i) => {
        acc[ref_name] = {
            path: circuit_paths[i],
            circuit: circuit_jsons[i],
        }
        return acc
    }, {} as CircuitDefinition)

    return circuit_defs
}

const CIRCUITS = await getCircuitDefinitions()

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

// TODO: Put this elsewhere.
const test_board = {
    bbs: [
        '0x080000f7ff',
        '0xffef001000000000',
        '0x4200000000000042',
        '0x2400000000000024',
        '0x8100000000000081',
        '0x0800000000000008',
        '0x1000000000000010',
        '0xef00180000f700',
    ],
    army: 0,
    castle_rights: 15,
    en_passant: 44, // e6
    halfmove: 0,
    fullmove: 1,
}

let test_move = {
    piece: 5, // pawn,
    from: 35,
    to: 44,
    promotion_piece: 0,
}

const start_game_commitment =
    '0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000001'
// END TODO

type Armies = 'white' | 'black'

const player_circuit: Circuit = await import(CIRCUITS.player.circuit)
const aggregate_circuit: Circuit = await import(CIRCUITS.aggregate.circuit)
const state_commitment_circuit: Circuit = await import(CIRCUITS.state_commitment.circuit)

describe('two-player (prover)', async () => {
    let players: Players<Armies>
    const commit = new Noir(state_commitment_circuit)
    const aggregate = new Noir(aggregate_circuit)

    // Instantiate required backends.
    beforeAll(async () => {
        players = {
            white: player(
                'white',
                player_circuit,
                aggregate_circuit,
                BACKEND_THREADS,
                commit,
                aggregate,
            ),
            black: player(
                'black',
                player_circuit,
                aggregate_circuit,
                BACKEND_THREADS,
                commit,
                aggregate,
            ),
        }
    })

    // Cleanup instantiated backends.
    afterAll(async () => {
        process.stdout.write('Cleaning up backends... ')
        // TODO: Go through keys recursively instead and call `.destroy()`

        // await commit.destroy()
        // await players.white.noir.destroy()
        // // await players.white.backend.destroy() // TODO: Why does this hang?
        // await players.black.noir.destroy()
        // await players.black.backend.destroy()

        // await commit.destroy()

        // // await players.white.noir.destroy()

        // for (const k in players) {
        //    process.stdout.write(`${players[k].name}... `)
        //    const be = players[k].backend
        //    // console.log(players[k].noir)
        //    await players[k].noir.destroy()
        //    await players[k].backend.destroy()
        //    console.log('be', be, be == null)
        //    process.stdout.write('done ')
        // }
        console.log('all done')
    })

    describe('game', async () => {
        test('black initiates game (base proof), white verifies', async () => {
            exchangeSalts(players.white, players.black)
            const black_turn_data = await players.black.startGame()
            // console.log(start_game_proof)

            const white_turn_data = await players.white.playMove(black_turn_data)
        })

        // test('white makes a move', async () => {
        //    // TODO: Put this in a beforeEach so it happens each turn.
        //    exchangeSalts(players.white, players.black)

        //    // White knows the board state (it's public), and white has now decided
        //    //   what move they are going to play. First they need to produce a
        //    //   commitment to that move.
        //    // TODO: In future probably `board` is included in the commitment (see said circuit).
        //    const move_proof = await players.white.playMove(test_board, test_move)
        //    // const move_commitment = await players.white.commitMove(test_move)
        //    // console.log('white move commitment', move_commitment)

        //    // White has committed their move, now they can compute a move-proof
        //    //   to advance the gamestate.
        //    // const move = await players.white.playMove(test_board, )

        //    // const res = await foo()
        //    // console.log(res)
        //    const res = true
        //    expect(res).toBeTrue()
        // })
    })
})

async function foo () {
    return true
}

export { CircuitDefinition }
