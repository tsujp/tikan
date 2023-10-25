import { BarretenbergBackend } from '@noir-lang/backend_barretenberg'
import { Noir } from '@noir-lang/noir_js'
import { describe, expect, test } from 'bun:test'
import { checkTestEnvironment } from './utility/precheck'

const wd = process.cwd()

const BACKEND_THREADS = 6;

describe('pre-test checks', () => {
   test('test environment configured correctly', () => {
      expect(checkTestEnvironment(wd)).toBeTrue()
   })
})

test('white moves, black accepts', async () => {
   const res = await foo()
   console.log(res)
   expect(res).toBeTrue()
})

import white_circuit from '../white/target/tikan_white.json' assert { type: 'json' }
import black_circuit from '../black/target/tikan_black.json' assert { type: 'json' }

async function foo () {
   const white_backend = new BarretenbergBackend(white_circuit, BACKEND_THREADS)
   const white_noir = new Noir(white_circuit, white_backend)

   const black_backend = new BarretenbergBackend(black_circuit, BACKEND_THREADS)
   const black_noir = new Noir(black_circuit, black_backend)

   process.stdout.write('init white noir...')
   await white_noir.init()
   console.log(' done')

   process.stdout.write('init black noir...')
   await black_noir.init()
   console.log(' done')

   const white_pawn_g2_g4 = {
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
         piece: 5,
         from: 14,
         to: 30,
         promotion_piece: 0,
      },
   }

   // Execute circuit (we want the return output) instead of directly proving.
   process.stdout.write('executing white circuit...')
   const { witness: white_witness, returnValue: white_returnValue } = await white_noir.execute(white_pawn_g2_g4)
   console.log('done')

   console.log('WHITE CIRCUIT RETURN VALUE')
   console.log(white_returnValue)

   process.stdout.write('generate white proof...')
   const white_proof = await white_backend.generateFinalProof(white_witness)
   console.log('done')

   // -----------
   const black_verify_white = await black_noir.verifyFinalProof(white_proof)
   console.log('black accepts whites move?', black_verify_white)
   if (black_verify_white === false) return false

   const black_pawn_g7_g5 = {
      board: white_returnValue,
      move: {
         piece: 5,
         from: 53,
         to: 38,
         promotion_piece: 0
      }
   }

   process.stdout.write('executing black circuit...')
   const { witness: black_witness, returnValue: black_returnValue } = await black_noir.execute(black_pawn_g7_g5)
   console.log('done')

   console.log('BLACK CIRCUIT RETURN VALUE')
   console.log(black_returnValue)

   process.stdout.write('generate black proof...')
   const black_proof = await black_backend.generateFinalProof(black_witness)
   console.log('done')

   // ------------
   const white_verify_black = await white_noir.verifyFinalProof(black_proof)
   console.log('white accepts blacks move?', white_verify_black)
   if (white_verify_black === false) return false
   
   return true
}
