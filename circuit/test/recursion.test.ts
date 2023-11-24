import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { describe, expect, test } from 'bun:test'
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

import bootstrap_circuit from '../dinit/target/recur_init_test.json' assert { type: 'json' }
import recur_circuit from '../recur/target/recur_test.json' assert { type: 'json' }

async function foo () {
    // -------------- BOOTSTRAP CIRCUIT CREATE PROOF
    const bootstrap_backend = new BarretenbergBackend(bootstrap_circuit, BACKEND_THREADS)
    const bootstrap_noir = new Noir(bootstrap_circuit, bootstrap_backend)

    process.stdout.write('init BOOTSTRAP CIRCUIT...')
    await bootstrap_noir.init()
    console.log(' done')

    const bootstrap_input = {
        start: 5,
    }

    // const bootstrap_proof = await bootstrap_noir.generateFinalProof(bootstrap_input)
    // console.log(bootstrap_proof)

    // Execute bootstrap circuit, get solved witness and circuit return value.
    const { witness, returnValue } = await bootstrap_noir.execute(bootstrap_input)
    console.log('bootstrap return', returnValue)

    // Use those to create a proof using bootstrap backend. Make sure it's an intermediate
    //   proof otherwise it cannot be recursively verified (aggregated over).
    const { proof, publicInputs } = await bootstrap_backend.generateIntermediateProof(
        witness,
    )
    expect(proof instanceof Uint8Array).toBeTrue()
    console.log('intermediate public inputs', publicInputs)

    // Self-verify intermediate proof
    const verified = await bootstrap_backend.verifyIntermediateProof({
        proof,
        publicInputs,
    })
    expect(verified).toBeTrue()

    // XXX: This constructs an aggregation object?
    const { proofAsFields, vkAsFields, vkHash } = await bootstrap_backend
        .generateIntermediateProofArtifacts({ publicInputs, proof }, publicInputs.length)
    // console.log(proofAsFields, vkAsFields, vkHash)
    // console.log(proofAsFields)

    expect(vkAsFields).toBeArrayOfSize(114)
    expect(vkHash).toBeString()

    const aggregationObject = Array(16).fill(
        '0x0000000000000000000000000000000000000000000000000000000000000000',
    )
    // ------------ BOOTSTRAP PROOF CREATED

    const recur_backend = new BarretenbergBackend(recur_circuit, BACKEND_THREADS)
    const recur_noir = new Noir(recur_circuit, recur_backend)

    process.stdout.write('init RECURSIVE CIRCUIT...')
    await recur_noir.init()
    console.log(' done')

    // Now we have all the parameters required to execute the recursive proof.
    const recursiveInputs = {
        verification_key: vkAsFields,
        proof: proofAsFields,
        // public_inputs: [bootstrap_input.start, 6],
        // public_inputs: [6, bootstrap_input.start],
        public_inputs: [10, bootstrap_input.start],
        // public_inputs: [6, bootstrap_input.start],
        // public_inputs: [
        //    // bootstrap_input.start,
        //    '0x0000000000000000000000000000000000000000000000000000000000000006',
        // ],
        key_hash: vkHash,
        input_aggregation_object: aggregationObject,
    }

    const recursiveProof = await recur_noir.generateFinalProof(recursiveInputs)
    expect(recursiveProof.proof instanceof Uint8Array).toBeTrue()

    const finalVerified = await recur_noir.verifyFinalProof(recursiveProof)
    expect(finalVerified).toBeTrue()

    // // Execute circuit (we want the return output) instead of directly proving.
    // process.stdout.write('executing white circuit...')
    // const { witness: white_witness, returnValue: white_returnValue } =
    //    await white_noir.execute(white_pawn_g2_g4)
    // console.log('done')

    // console.log('WHITE CIRCUIT RETURN VALUE')
    // console.log(white_returnValue)

    // process.stdout.write('generate white proof...')
    // const white_proof = await white_backend.generateFinalProof(white_witness)
    // console.log('done')

    // // -----------
    // const black_verify_white = await black_noir.verifyFinalProof(white_proof)
    // console.log('black accepts whites move?', black_verify_white)
    // if (black_verify_white === false) {
    //    return false
    // }

    // const black_pawn_g7_g5 = {
    //    board: white_returnValue,
    //    move: {
    //       piece: 5,
    //       from: 53,
    //       to: 38,
    //       promotion_piece: 0,
    //    },
    // }

    // process.stdout.write('executing black circuit...')
    // const { witness: black_witness, returnValue: black_returnValue } =
    //    await black_noir.execute(black_pawn_g7_g5)
    // console.log('done')

    // console.log('BLACK CIRCUIT RETURN VALUE')
    // console.log(black_returnValue)

    // process.stdout.write('generate black proof...')
    // const black_proof = await black_backend.generateFinalProof(black_witness)
    // console.log('done')

    // // ------------
    // const white_verify_black = await white_noir.verifyFinalProof(black_proof)
    // console.log('white accepts blacks move?', white_verify_black)
    // if (white_verify_black === false) {
    //    return false
    // }

    return true
}
