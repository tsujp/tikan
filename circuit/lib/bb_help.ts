// Helper so I can declare a BigInt using underscores as seperators for easier
//   visual grepping.
function Big (bi: string) {
   // TODO: Check valid hex with underscores?
   return BigInt(bi.replace(/_/g, ''))
}

// const x = BigInt('0x00FF00000000FF00')
// const x = Big('0x00_FF_00_00_00_00_FF_00') // Game start both army pawns.
// const x = Big('0x08_00_00_00_00_00_00_08')
// const x = Big('0x10_00_00_00_00_00_00_10')
// const x = Big('0xff000000001f00')
// const x = Big('0xf008')
const x = Big('0x081f000000000000')
// const x = Big('0x1000000000000010')

const digits = Math.ceil(64 / Math.log2(2))

// const whitePawns = BigInt('0xFF00') // Same as: pawnPattern << 8n
// const blackPawns = BigInt('0xFF000000000000') // Same as: pawnPattern << (8n * 6n)

// Configurable.
const idnt_pre = 0 // Overall output indent.
const idnt_gap = 2 // Space between board cells.
const idnt_idx = 3 // Amount of extra space index printing adds (should be computed instead).
const idnt_tab = 3 // Space between last character of `title_rank` and start of board cells.

const title_rank = '[RANK]'
const title_indices = '[INDICES]'
const title_file = '[FILE]'
const title_files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']

// No touching.
const f_pre = ' '.repeat(idnt_pre)
const f_gap = ' '.repeat(idnt_gap)
const f_tab = ' '.repeat(idnt_tab)

const idnt_to_rank = Math.ceil(title_rank.length / 2)
const f_to_rank = ' '.repeat(idnt_to_rank)
const idnt_from_rank = Math.floor(title_rank.length / 2) - 1 // -1 for rank character's absence.
const f_from_rank = ' '.repeat(idnt_from_rank)

// Indices are printed in BERLEF ordering as per indexing in Tikan.
function print_bb (bb: bigint, with_indices: boolean = false) {
   // Compute `title_indices` padding so it's centred over board cells.
   const f_title_indices = ' '.repeat(
      idnt_tab +
         Math.floor(
            (7 * (idnt_gap + (with_indices === true ? idnt_idx : 0)) + 8) / 2,
         ) - Math.floor(title_indices.length / 2),
   )

   // Title line.
   console.log(`${f_pre}${title_rank}${f_title_indices}${title_indices}`)

   // Print ranks and board cells.
   Array.from(bb.toString(2).padStart(digits, '0')).forEach((c, i) => {
      // Width of visible characters of true-branch should be equal to `idnt_idx`
      //   cbf computing that now, this is already overengineered enough.
      const indices = with_indices === true
         ? ` \x1b[38;5;243m${i.toString().padStart(2, ' ')}\x1b[0m`
         : ''
      const square = `${c}${indices}`

      if (i % 8 === 0) {
         // Print rank and first a-file board cell as required.
         process.stdout.write(
            `\n${f_pre}${f_to_rank}${8 - (i / 8)}${f_from_rank}${f_tab}${square}`,
         )
      } else {
         // Else print each b through h-file board cell.
         process.stdout.write(`${f_gap}${square}`)
      }
   })

   console.log('\n') // Two newlines, but visually just one (first ends rank 1s line).

   // +1 for rank characters absence.
   const f_file_lead = ' '.repeat(
      idnt_pre + idnt_to_rank + idnt_from_rank + idnt_tab + 1,
   )
   const f_file_gap = ' '.repeat(idnt_gap + (with_indices === true ? idnt_idx : 0))

   // Print files.
   process.stdout.write(f_file_lead)
   title_files.forEach((f) => {
      process.stdout.write(`${f}${f_file_gap}`)
   })
   console.log(`${title_file}\n\n`)
}

print_bb(x)

// print_bb(x, true)

// console.log(
//    `black bb: ${blackPawns.toString(2).padStart(digits, '0')} (${blackPawns})`,
// )
// console.log(
//    `white bb: ${whitePawns.toString(2).padStart(digits, '0')} (${whitePawns})`,
// )

// Helpers for serialising bitboard inputs TO the circuit and
//   deserialising bitboard outs FROM the circuit.

// const BITS_PER_PIECE = 1n

// const maxVal = BigInt('0xFFFFFFFFFFFFFFFF')
// const pawnPattern = BigInt('0xFF')

// console.log(digits)

// console.log()

// console.log(`add two numbers: ${blackPawns + whitePawns}`)

// // ----- ASCII string to hex (goal FEN -> HEX for circuit input)
// const minimalFen = '4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1'

// // FIXME:
// // Works but not needed for now just want a hex-byte array to paste into
// //   lib/lib.nr source code as a literal until Nargo 0.10.3 and can use
// //   strings instead.
// // for (let i = 0; i < minimalFen.length; i++) {
// //    const asciiCode = minimalFen.charCodeAt(i)
// //    console.log(minimalFen[i], asciiCode, asciiCode.toString(16))
// // }
// // -----

// const bytes = []

// for (let i = 0; i < minimalFen.length; i++) {
//    const asciiCode = minimalFen.charCodeAt(i)
//    bytes.push(`0x${asciiCode.toString(16)}`)
// }

// console.log(bytes)

// // console.log(b.toString(2).padStart(digits, '0'))

// // const a = pawns << 8n
// // const b = maxVal >> 16n
// // const c = b ^ maxVal

// // console.log(pawns.toString(2).padStart(digits, '0'))
// // console.log(a.toString(2).padStart(digits, '0'))
// // console.log(b.toString(2).padStart(digits, '0'))
// // console.log(c.toString(2).padStart(digits, '0'))
// // console.log(maxVal.toString(2).padStart(digits, '0'))
