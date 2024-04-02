// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

import { BarretenbergBackend, ProofData } from '@noir-lang/backend_barretenberg'
import { Noir, blake2s256 } from '@noir-lang/noir_js'
import { type InputValue } from '@noir-lang/noirc_abi'

import { getNoirCircuits, logCommand, logHeading, resolveProjectRootDir } from '../../test/utility/misc'
import { checkTestEnvironment } from '../../test/utility/precheck'
const root_dir = await resolveProjectRootDir()
const CIRCUITS = await getNoirCircuits(root_dir)
const { checks, args } = await checkTestEnvironment(root_dir, CIRCUITS)
if (checks === false) {
    process.exit(1)
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// TODO: Right now we block until this is done, make this and JS test suite
//       async _later_.
// const yolo = Bun.spawnSync(['nargo', 'test', '--show-output', '--workspace'], {
//     cwd: root_dir,
// })
// const tingting = yolo
//     .stdout
//     .toString()
//     .split(`bingbong_end`)[0]
//     .split(`bingbong_start`)[1]
//     .split('\n')
//     .filter((x) => x)
// // console.log(yolo.stdout.toString())
// console.log(tingting)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

const c_utility = await import(CIRCUITS.bin.find((c) => c.name === 'xx_util').artifact)
// const c_aggregate = await import(
//     CIRCUITS.bin.find((c) => c.name === 'xx_aggregate').artifact
// )
const c_player = await import(CIRCUITS.bin.find((c) => c.name === 'xx_player').artifact)
const c_start = await import(CIRCUITS.bin.find((c) => c.name === 'xx_start').artifact)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// Utility backend and Noir.
const util_nr = new Noir(c_utility)

// Aggregate backend and Noir.
// const aggregate_be = new BarretenbergBackend(c_aggregate, {
//     threads: BACKEND_THREADS,
// })
// const aggregate_nr = new Noir(c_aggregate, aggregate_be)

// Player backend and Noir.
const player_be = new BarretenbergBackend(c_player, { threads: BACKEND_THREADS })
const player_nr = new Noir(c_player, player_be)

// Start backend and Noir.
const start_be = new BarretenbergBackend(c_start, { threads: BACKEND_THREADS })
const start_nr = new Noir(c_start, start_be)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

const VALID_WHITE_START = 'BBDB'
const VALID_BLACK_START = 'VBXB'
const VALID_START_BOARD = 'BBDBVBXBAA'

const NOTHING_FIELD = '0x0000000000000000000000000000000000000000000000000000000000000000'

// TODO: Length of array from Noir specifically?
export const NOTHING_RECURSION = {
    proof: Array(93).fill(NOTHING_FIELD),
    public: Array(26).fill(NOTHING_FIELD),
    vk: Array(114).fill(NOTHING_FIELD),
    vk_hash: NOTHING_FIELD,
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

const start_pf = await startProof('BBDBVBXBAA')
console.log('======================================== START PROOF')
console.log(start_pf)
console.log('================================================================')

// const w_m1 = await commit(VALID_START_BOARD, 'BBDBBI', 1n)
// console.log(w_m1)
console.log('======================================== PROOF 1')
const w_m1_e = await moveExecute('BBDBVBXBAA', 'BBDBBI', 1n, start_pf, true)
const pf = await moveProve(w_m1_e.witness)
console.log('proof', pf)
console.log('================================================================')

console.log('======================================== PROOF 2')
const b_m1_e = await moveExecute('BBDBVBXBBB', 'VBXBAQ', 1n, pf)
const pf_2 = await moveProve(b_m1_e.witness)
console.log('proof 2', pf_2)
console.log('================================================================')

console.log('======================================== FINAL VERIFY')
const ivc_valid = await verifyProof(pf_2)
console.log('is valid?', ivc_valid)
console.log('================================================================')

// console.log(foo)
// const bar = await commit('BBDBVBXBAA', 'BBDBAG', 1n)
// console.log(bar)
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

async function verifyProof (proof: ProofData) {
    const is_valid = await player_nr.verifyProof(proof)
    return is_valid
}

async function startProof (board_serial: string) {
    const start_exec = await start_nr.execute({
        start_serial: board_serial,
    })

    const start_proof = await start_be.generateProof(start_exec.witness)

    return start_proof
}

function stringToHex (str: string) {
    return `0x${
        Array.from(new TextEncoder().encode(str), (b) => b.toString(16).padStart(2, '0'))
            .join('')
    }`
}

async function playTurn (board_serial: string, move_serial: string, secret: bigint) {
    const move_commit = await commit(board_serial, move_serial, secret)
}

async function moveExecute (
    board_serial: string,
    move_serial: string,
    secret: bigint,
    recur: any,
    blah: boolean = false,
) {
    // const encoded = stringToHex(board_serial)
    // console.log('encoding', board_serial, 'as', encoded)

    console.log('======================================== RECUR')
    console.log(recur)
    console.log('================================================================')

    let artifacts
    if (blah) {
        artifacts = await start_be.generateRecursiveProofArtifacts(
            recur,
            recur.publicInputs.length,
        )
    } else {
        artifacts = await player_be.generateRecursiveProofArtifacts(
            recur,
            recur.publicInputs.length,
        )
    }

    console.time('moveExecute')
    const move_execd = await player_nr.execute({
        proof: artifacts.proofAsFields,
        public: blah ? NOTHING_RECURSION.public : recur.publicInputs, // Expected public inputs and it works, good!
        // public: NOTHING_RECURSION.public, // Use this line and see it will fail, because of bogus public inputs. Good!
        vk: artifacts.vkAsFields,
        vk_hash: artifacts.vkHash,
        cur_state_serial: board_serial,
        cur_move_serial: move_serial,
        secret: secret.toString(16),
        // moar_state: encoded,
    })

    console.timeEnd('moveExecute')
    return move_execd
}

async function moveProve (witness: Uint8Array) {
    console.time('moveProve')
    const move_proof = player_be.generateProof(witness)

    console.timeEnd('moveProve')
    return move_proof
}

async function commit (board_serial: string, move_serial: string, secret: bigint) {
    const move_commit = await util_nr.execute({
        // TODO: Make these functions to abstract away Noir's `Option`.
        input: {
            state: {
                _is_some: true,
                _value: {
                    cur_state_serial: board_serial,
                    cur_move_serial: move_serial,
                    secret: secret.toString(16),
                },
            },
        },
    })

    // console.log('move commit:', move_commit)
    return move_commit.returnValue.state_commitment._value
}
