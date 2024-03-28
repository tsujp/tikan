import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { type InputValue } from '@noir-lang/noirc_abi'

import { checkTestEnvironment } from '../../../test/utility/precheck'
import { getNoirCircuits, resolveProjectRootDir, logHeading } from '../../../test/utility/misc'
const root_dir = await resolveProjectRootDir()
const CIRCUITS = await getNoirCircuits(root_dir)
const { checks, args } = await checkTestEnvironment(root_dir, CIRCUITS)
if (checks === false) process.exit(1)

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

// ----------------------------------------------------------
// ----------------------------------------------------------

const commit = await import(CIRCUITS.bin.find((c) => c.name === 'linear_commitment').artifact)
const player = await import(CIRCUITS.bin.find((c) => c.name === 'linear_player').artifact)

// Commit backend and proving instantiation.
const commit_backend = new BarretenbergBackend(commit, {
    threads: BACKEND_THREADS
})
const commit_noir = new Noir(commit, commit_backend)

// Player backend and proving instantiation.
const player_backend = new BarretenbergBackend(player, {
    threads: BACKEND_THREADS
})
const player_noir = new Noir(player, player_backend)

// ----------------------------------------------------------
// ----------------------------------------------------------

const VALID_WHITE_START = [{ idx: 1, lights: true }, { idx: 3, lights: true }] as const

const VALID_BLACK_START = [{ idx: 21, lights: true }, { idx: 23, lights: true }] as const

const VALID_START_BOARD = {
    turn: 0,
    halfmove: 0,
    commits: [
        { x: '0x0', y: '0x0' },
        { x: '0x0', y: '0x0' },
    ],
    players: [
        VALID_WHITE_START,
        VALID_BLACK_START,
    ]
} as const

// ----------------------------------------------------------
// ----------------------------------------------------------

console.log('WHITE LEGIT MOVE AND BLACK ACCEPTS')

// 1. White commits to move by executing their move against current board state
//    with the commitment being the post-move board state, and said move. So
//    they commit that their move produces current-board -> post-move-board.

const w_m1 = {
    pieces: [{ idx: 1, lights: true }, { idx: 3, lights: true }],
    from: 1,
    to: 5
}

// Execute state_commitment helper to perform (1).
const w_c1 = await commitToMove(VALID_START_BOARD, w_m1)

// 2. Generate proof of move by providing current-board, post-move-board, and
//    commitment from (1) all as public input and with our move as private
//    input.

const w_p1 = await proveMove(w_m1, VALID_START_BOARD, w_c1.pst_board, w_c1.commitment)

// 3. Black verifies white's move proof.

const b__w_p1__accept = await verifyMove(w_p1)
console.log('accepts?', b__w_p1__accept)

// Correctly fails verification with bad public inputs.
// w_p1.publicInputs[w_p1.publicInputs.length - 1] = "0x123abc"
// console.log(w_p1.publicInputs)
// const b__w_p1__accept2 = await verifyMove(w_p1)
// console.log('accepts?', b__w_p1__accept2)
// ---/

// ----------------------------------------------------------
// ----------------------------------------------------------

console.log('WHITE LEGIT MOVE, AND BLACK ACCEPTS, THEN BLACK RETURNS ADVANCED GAME STATE')

// Black will return a, strictly-speaking, legal pst-move-board however not a
//   legal pst-move-board for this game sequence and so white will accept that
//   board but they shouldn't as it's not legal in-sequence.
// TODO: Combating this.



// ----------------------------------------------------------
// ----------------------------------------------------------

async function verifyMove(proof_data) {
    return player_noir.verifyProof(proof_data)
}

async function proveMove(move: {}, cur_board: {}, pst_board: {}, state_commitment: {}) {
    return player_noir.generateProof({cur_board, pst_board, move, state_commitment})
}

async function commitToMove(cur_board: {}, move: {}) {
    const { returnValue: rv } = await commit_noir.execute({
        input: {
            state: {
                _is_some: true,
                _value: {
                    cur_board,
                    move
                }
            }
        }
    })

    return {
        commitment: rv.state_commitment._value[0],
        pst_board: rv.state_commitment._value[1],
    }
}

// ----------------------------------------------------------
// ----------------------------------------------------------

process.on('SIGINT', () => {
    console.log('Cleaning up...')
    process.exit(0)
})
