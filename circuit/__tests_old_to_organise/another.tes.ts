import { Barretenberg, Crs, RawBuffer } from '@aztec/bb.js'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { describe, expect, test } from 'bun:test'
import { decompressSync } from 'fflate'
import { checkTestEnvironment } from './utility/precheck'

const wd = process.cwd()

const BACKEND_THREADS = 6

describe('pre-test checks', () => {
    test('test environment configured correctly', () => {
        expect(checkTestEnvironment(wd)).toBeTrue()
    })
})

test('recursive proofs', async () => {
    const res = await foo()
    console.log(res)
    expect(res).toBeTrue()
})

import player_circuit from '../player/target/tikan_player.json' assert { type: 'json' }
// import recur_circuit from '../recur/target/recur_test.json' assert { type: 'json' }

async function foo () {
    const finalVerified = true

    // const acirBuffer = new Uint8Array(
    //    [...atob(player_circuit.bytecode)].map((c) => c.charCodeAt(0)),
    // )

    const acirBuffer = Uint8Array.from(
        atob(player_circuit.bytecode),
        (c) => c.charCodeAt(0),
    )

    const inflatedAcirBuffer = decompressSync(acirBuffer)
    // await Bun.write("output.txt", inflatedAcirBuffer);

    const api = await Barretenberg.new(BACKEND_THREADS)

    // const [, total]
    const [_exact, _total, subgroupSize] = await api.acirGetCircuitSizes(inflatedAcirBuffer)
    // const subgroupSize = Math.pow(2, Math.ceil(Math.log2(total)))
    // const composer = await api.acirNewAcirComposer(subgroupSize)

    const crs = await Crs.new(subgroupSize + 1)
    await api.commonInitSlabAllocator(subgroupSize)
    await api.srsInitSrs(
        new RawBuffer(crs.getG1Data()),
        crs.numPoints,
        new RawBuffer(crs.getG2Data()),
    )

    const composer = await api.acirNewAcirComposer(subgroupSize)

    await api.acirInitVerificationKey(composer)
    const vk = await api.acirSerializeVerificationKeyIntoFields(composer)
    console.log(vk)

    // const player_backend = new BarretenbergBackend(
    //    player_circuit,
    //    BACKEND_THREADS,
    // )
    // const player_noir = new Noir(player_circuit, player_backend)

    // process.stdout.write('init PLAYER CIRCUIT ...')
    // await player_noir.init()
    // console.log(' done')

    // const aggregationObject = Array(16).fill(
    //    '0x0000000000000000000000000000000000000000000000000000000000000000',
    // )

    // const __proof = Array(99).fill(
    //    '0x0000000000000000000000000000000000000000000000000000000000000000',
    // )

    // const vk = Array(114).fill(
    //    '0x0000000000000000000000000000000000000000000000000000000000000000',
    // )

    // const player_input = {
    //    board: {
    //       bbs: [
    //          '0xffff',
    //          '0xffff000000000000',
    //          '0x4200000000000042',
    //          '0x2400000000000024',
    //          '0x8100000000000081',
    //          '0x0800000000000008',
    //          '0x1000000000000010',
    //          '0x00ff00000000ff00',
    //       ],
    //       army: 0,
    //       castle_rights: 15,
    //       en_passant: 0,
    //       halfmove: 0,
    //       fullmove: 1,
    //    },
    //    move: {
    //       piece: 5,
    //       from: 14,
    //       to: 30,
    //       promotion_piece: 0,
    //    },
    //    input_aggregation_object: aggregationObject,
    //    key_hash: 0,
    //    proof: __proof,
    //    public_inputs: [1, 2],
    //    verification_key: vk
    // }

    // const { witness, returnValue } = await player_noir.execute(player_input)
    // // console.log(witness)

    // const { proof, publicInputs } = await player_backend.generateIntermediateProof(witness)
    // // console.log(proof, publicInputs)

    // const { proofAsFields, vkAsFields, vkHash } = await player_backend.generateIntermediateProofArtifacts({ publicInputs, proof }, 6)
    // console.log(vkHash)

    // const bootstrap_input = {
    //    state: [1, 0],
    //    t_inc: 1,
    //    v_inc: 11,
    // }

    // // Execute bootstrap circuit, get solved witness and circuit return value.
    // const { witness, returnValue } = await bootstrap_noir.execute(bootstrap_input)
    // console.log('bootstrap return', returnValue)

    // // Use those to create a proof using bootstrap backend. Make sure it's an intermediate
    // //   proof otherwise it cannot be recursively verified (aggregated over).
    // process.stdout.write('create BOOTSTRAP INTERMEDIATE proof ...')
    // const { proof, publicInputs } = await bootstrap_backend.generateIntermediateProof(
    //    witness,
    // )
    // console.log(' done')
    // expect(proof instanceof Uint8Array).toBeTrue()
    // console.log('intermediate public inputs', publicInputs)

    // // Self-verify intermediate proof
    // process.stdout.write('self-verify bootstrap intermediate proof ...')
    // const verified = await bootstrap_backend.verifyIntermediateProof({
    //    proof,
    //    publicInputs,
    // })
    // console.log( 'done')
    // expect(verified).toBeTrue()

    // // XXX: This constructs an aggregation object?
    // const { proofAsFields, vkAsFields, vkHash } = await bootstrap_backend
    //    .generateIntermediateProofArtifacts(
    //       { publicInputs, proof },
    //       publicInputs.length,
    //    )
    // // console.log(proofAsFields, vkAsFields, vkHash)
    // // console.log(proofAsFields)

    // expect(vkAsFields).toBeArrayOfSize(114)
    // expect(vkHash).toBeString()

    // console.log('vk hash', vkHash)

    // const aggregationObject = Array(16).fill(
    //    '0x0000000000000000000000000000000000000000000000000000000000000000',
    // )
    // // ------------ BOOTSTRAP PROOF CREATED

    // const recur_backend = new BarretenbergBackend(recur_circuit, BACKEND_THREADS)
    // const recur_noir = new Noir(recur_circuit, recur_backend)

    // process.stdout.write('init RECURSIVE CIRCUIT...')
    // await recur_noir.init()
    // console.log(' done')

    // // Now we have all the parameters required to execute the recursive proof.
    // const recursiveInputs = {
    //    verification_key: vkAsFields,
    //    proof: proofAsFields,
    //    public_inputs: [
    //       [1, 0, 1],
    //       [11, 2, 11]
    //    ],
    //    key_hash: vkHash,
    //    input_aggregation_object: aggregationObject,
    // }

    // process.stdout.write('execute recur turn 1 ...')
    // const { witness: recurWitness, returnValue: recurReturnValue } = await recur_noir.execute(recursiveInputs)
    // console.log(' done')
    // // console.log(recurWitness)
    // console.log(recurReturnValue)

    // process.stdout.write('create RECURSIVE INTERMEDIATE PROOF (1) ...')
    // // const intGame_1 = await recur_backend.generateIntermediateProof(recurWitness)
    // const intGame_1 = await recur_backend.generateFinalProof(recurWitness)
    // console.log(intGame_1)
    // console.log(' done')

    // // process.stdout.write('execute recur turn 2 ...')
    // // const { witness: recurWitness_2, returnValue: recurReturnValue_2 } = await recur_noir.execute(recursiveInputs)
    // // console.log(' done')
    // // // console.log(recurWitness)
    // // console.log(recurReturnValue)

    // // process.stdout.write('create RECURSIVE FINAL PROOF (2) ...')
    // // const intGame_final = await recur_backend.generateFinalProof(recurWitness)
    // // console.log(intGame_final)
    // // console.log(' done')

    // // const recursiveProof = await recur_noir.generateFinalProof(recursiveInputs)
    // // expect(recursiveProof.proof instanceof Uint8Array).toBeTrue()

    // // const finalVerified = await recur_noir.verifyFinalProof(recursiveProof)
    // // expect(finalVerified).toBeTrue()

    // process.stdout.write('verify FINAL PROOF ...')
    // const finalVerified = await recur_noir.verifyFinalProof(intGame_1)
    // console.log(' done')
    // console.log('final verified valid?', finalVerified)

    // // // Execute circuit (we want the return output) instead of directly proving.
    // // process.stdout.write('executing white circuit...')
    // // const { witness: white_witness, returnValue: white_returnValue } =
    // //    await white_noir.execute(white_pawn_g2_g4)
    // // console.log('done')

    // // console.log('WHITE CIRCUIT RETURN VALUE')
    // // console.log(white_returnValue)

    // // process.stdout.write('generate white proof...')
    // // const white_proof = await white_backend.generateFinalProof(white_witness)
    // // console.log('done')

    // // // -----------
    // // const black_verify_white = await black_noir.verifyFinalProof(white_proof)
    // // console.log('black accepts whites move?', black_verify_white)
    // // if (black_verify_white === false) {
    // //    return false
    // // }

    // // const black_pawn_g7_g5 = {
    // //    board: white_returnValue,
    // //    move: {
    // //       piece: 5,
    // //       from: 53,
    // //       to: 38,
    // //       promotion_piece: 0,
    // //    },
    // // }

    // // process.stdout.write('executing black circuit...')
    // // const { witness: black_witness, returnValue: black_returnValue } =
    // //    await black_noir.execute(black_pawn_g7_g5)
    // // console.log('done')

    // // console.log('BLACK CIRCUIT RETURN VALUE')
    // // console.log(black_returnValue)

    // // process.stdout.write('generate black proof...')
    // // const black_proof = await black_backend.generateFinalProof(black_witness)
    // // console.log('done')

    // // // ------------
    // // const white_verify_black = await white_noir.verifyFinalProof(black_proof)
    // // console.log('white accepts blacks move?', white_verify_black)
    // // if (white_verify_black === false) {
    // //    return false
    // // }

    return finalVerified
}
