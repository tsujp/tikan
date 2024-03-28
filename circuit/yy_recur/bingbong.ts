import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { type InputValue } from '@noir-lang/noirc_abi'

import { checkTestEnvironment } from '../../test/utility/precheck'
import { getNoirCircuits, resolveProjectRootDir, logHeading } from '../../test/utility/misc'
const root_dir = await resolveProjectRootDir()
const CIRCUITS = await getNoirCircuits(root_dir)
const { checks, args } = await checkTestEnvironment(root_dir, CIRCUITS)
if (checks === false) process.exit(1)

const BACKEND_THREADS = 8 as const
const wd = process.cwd()

const yy_start = await import(CIRCUITS.bin.find((c) => c.name === 'yy_start').artifact)
const yy_recur = await import(CIRCUITS.bin.find((c) => c.name === 'yy_recur').artifact)

// Recursion backend and noir
const recur_backend = new BarretenbergBackend(yy_recur, {
    threads: BACKEND_THREADS
})
const recur_noir = new Noir(yy_recur, recur_backend)

// Start backend and noir
const start_backend = new BarretenbergBackend(yy_start, {
    threads: BACKEND_THREADS
})
const start_noir = new Noir(yy_start, start_backend)

// Start witness and proof.
const start_proof = await start_noir.generateProof({
    some_num: 69
})
// console.log('start proof:', start_proof)
const start_proof_artifacts = await start_backend.generateRecursiveProofArtifacts(start_proof, start_proof.publicInputs.length)
console.log('start proof artifacts:', start_proof_artifacts)

// const recur_execute = await recur_noir.execute({
//     verification_key: start_proof_artifacts.vkAsFields,
//     proof: start_proof_artifacts.proofAsFields,
//     public_inputs: [69],
//     key_hash: start_proof_artifacts.vkHash,
// })
// console.log('recur execute:', recur_execute)

console.time('generate final proof')
const final_proof = await recur_noir.generateProof({
    verification_key: start_proof_artifacts.vkAsFields,
    proof: start_proof_artifacts.proofAsFields,
    public_inputs: [],
    key_hash: start_proof_artifacts.vkHash,
})
console.timeEnd('generate final proof')
console.log('final proof:', final_proof)


// const verify_final_proof = await recur_noir.verifyProof(final_proof)
// console.log('verify final proof:', verify_final_proof)


// const start_proof = await start_noir.generateProof({
//     some_num: 69
// })


process.on('SIGINT', () => {
    console.log('Cleaning up...')
    process.exit(0)
})
