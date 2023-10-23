// import { Crs, RawBuffer, newBarretenbergApiAsync } from '@aztec/bb.js/dest/node/index.js'
// import { compressWitness, executeCircuit } from '@noir-lang/acvm_js'
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { describe, expect, test } from 'bun:test'
import ethers from 'ethers'
import { decompressSync } from 'fflate'
import { checkTestEnvironment } from './utility/precheck'

const wd = process.cwd()

describe('pre-test checks', () => {
   test('test environment configured correctly', () => {
      expect(checkTestEnvironment(wd)).toBeTrue()
   })
})

test('prove 1 != 2', async () => {
   const res = await foo()
   console.log(res)
   expect(res).toBeTrue()
})

// Imported circuit is compressed by default, need to decompress it with fflate.
import circuit from '../white/target/tikan_white.json' assert { type: 'json' }
// import circuit from './maybe.json' assert { type: 'json' }

// const goodCircuitBytecode = circuit.bytecode

// NodeJS specific API steps would be:
//   ```
//   const useableAcirBuffer = Buffer.from(data, 'base64')
//   ````
//
// I'm choosing to use Web standard APIs to do that which looks like:
//   ```
//   const useableAcirBuffer = new Uint8Array(
//      [...atob(data)].map((c) => c.charCodeAt(0)),
//   )
//   ```

// TODO: Move all of this into a pre-check.

// const goodCircuitBytecode =
//    'H4sIAAAAAAAA/7WTMRLEIAhFMYkp9ywgGrHbq6yz5v5H2JkdCyaxC9LgWDw+H9gBwMM91p7fPeOzIKdYjEeMLYdGTB8MpUrCmOohJJQkfYMwN4mSSy0ZC0VudKbCZ4cthqzVrsc/yw28dMZeWmrWerfBexnsxD6hJ7jUufr4GvyZFp8xpG0C14Pd8s/q29vPCBXypvmpDx7sD8opnfqIfsM1RNtxBQAA'

// Get circuit bytecode and do t3h decompression.
// const acirBuffer = new Uint8Array(
//    [...atob(goodCircuitBytecode)].map((c) => c.charCodeAt(0)),
// )

// const inflatedAcirBuffer = decompressSync(acirBuffer)

async function foo () {
   const backend = new BarretenbergBackend(circuit)
   const noir = new Noir(circuit, backend)

   process.stdout.write('init noir...')
   await noir.init()
   console.log(' done')

   const input = {
      board: {
         bbs: [
            '0xffff',
            '0xffff000000000000',
            '0x4200000000000042',
            '0x2400000000000024',
            '0x8100000000000081',
            '0x0800000000000008',
            '0x1000000000000010',
            '0x00ff00000000ff00',
         ],
         army: 0,
         castle_rights: 15,
         en_passant: 0,
         halfmove: 0,
         fullmove: 1,
      },
      move: {
         piece: 0,
         from: 6,
         to: 21,
         promotion_piece: 0,
      },
   }

   process.stdout.write('generate proof...')
   const proof = await noir.generateFinalProof(input)
   console.log(' done')

   const verification = await noir.verifyFinalProof(proof)
   return verification
}

// async function foo () {
//    // /--- start init
//    const api = await newBarretenbergApiAsync(4)

//    const [, total] = await api.acirGetCircuitSizes(inflatedAcirBuffer)
//    const subgroupSize = Math.pow(2, Math.ceil(Math.log2(total)))
//    const crs = await Crs.new(subgroupSize + 1)
//    await api.commonInitSlabAllocator(subgroupSize)
//    await api.srsInitSrs(
//       new RawBuffer(crs.getG1Data()),
//       crs.numPoints,
//       new RawBuffer(crs.getG2Data()),
//    )

//    const acirComposer = await api.acirNewAcirComposer(subgroupSize)
//    // end init ---/

//    // Witness
//    // const input = { move: 2 }
//    // const input = { x: 1, y: 2 }
//    const input = {
//       before_board: [0, 2, 4, 8],
//       after_board: [0, 2, 5, 8],
//       move: 2,
//    }
//    const initialWitness = new Map<number, string>()
//    initialWitness.set(
//       1,
//       input.before_board.reduce(
//          (accumulator, byte) => accumulator + byte.toString(16).padStart(2, '0'),
//          '',
//       ),
//    )
//    initialWitness.set(
//       2,
//       input.after_board.reduce(
//          (accumulator, byte) => accumulator + byte.toString(16).padStart(2, '0'),
//          '',
//       ),
//    )
//    initialWitness.set(3, ethers.utils.hexZeroPad(`0x${input.move.toString(16)}`, 32))

//    initialWitness.set(4, '')
//    initialWitness.set(5, '')
//    initialWitness.set(6, '')
//    initialWitness.set(7, '')
//    initialWitness.set(8, '')
//    initialWitness.set(9, '')
//    // initialWitness.set(10, '')
//    // initialWitness.set(11, '')
//    // initialWitness.set(12, '')

//    const witnessMap = await executeCircuit(acirBuffer, initialWitness, () => {
//       throw Error('unexpected oracle')
//    })

//    const witness = compressWitness(witnessMap)
//    // ---/

//    // Proof
//    // Throws if proof could not be generated.
//    let proof = new Uint8Array()

//    try {
//       proof = await api.acirCreateProof(
//          acirComposer,
//          inflatedAcirBuffer,
//          decompressSync(witness),
//          false,
//       )
//    } catch (err) {
//       console.log('asddsa')
//    }

//    // console.log('PROOF IS', proof)
//    // ---/

//    // Verify
//    await api.acirInitProvingKey(acirComposer, inflatedAcirBuffer)
//    const verified = await api.acirVerifyProof(acirComposer, proof, false)
//    // ---/
//    return verified
// }
// -- done init acvm and bb.js

// -----

// const moveTests = describe('Movieieieieieeiasdasdasd')

// const whiteTests = describe({
//    name: 'white123112',
//    suite: moveTests,
//    beforeEach (this: { foo: string }) {
//       this.foo = 'bar'
//    },
// })

// it(whiteTests, 'bingBong', function () {
//    const { foo } = this
//    assertEquals(foo, 'bar')
// })
