// Helper so I can declare a BigInt using underscores as seperators for easier
//   visual grepping.
function Big (bi: string) {
   // TODO: Check valid hex with underscores?
   return BigInt(bi.replace(/_/g, ''))
}

function board (bb: string | string[]) {
   if (Array.isArray(bb)) {
      return bb.map((b) => Big(b))
   }

   return [Big(bb)]
}

const digits = Math.ceil(64 / Math.log2(2))

// Configurable.
const idnt_pre = 0 // Overall output indent.
const cell_width = 2 // Fixed-width content of board cells.
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

const BOARD_SYMBOLS = ['w', 'b', 'N', 'B', 'R', 'Q', 'K', 'P']

// Indices are printed in LERLEF ordering as per indexing in Tikan.
function print_bb (
   bbs: bigint[],
   with_indices: boolean = false,
   empty_square_character: string = '0',
) {
   if ([1, 8].includes(bbs.length) == false) {
      throw new Error(
         'Input bitboards must be an array of either 1 bitboard or 8 bitboards.',
      )
   }

   // If it's a single bitboard the piece code to print is '1' (for a set bit).
   const single_bb = bbs.length === 1

   // Bitboards `S`liced `R`rank `R`eversed.
   const bbs_srr = bbs.map((bb, i) => {
      let m = bb
         .toString(2)
         .padStart(digits, '0')
         .replaceAll('0', empty_square_character)
         .match(/.{8}/g)

      if (m == null) {
         throw new Error('Could not parse input bitboards into string')
      }

      let r_rev = m.flatMap((r) => Array.from(r).reverse())

      return r_rev
   })

   let pop_arr = [...new Array(64)]

   if (single_bb) {
      pop_arr = [...bbs_srr[0]]
   } else {
      const armies_bb = [bbs_srr[0], bbs_srr[1]]
      const [, , ...pieces_bb] = bbs_srr

      armies_bb.forEach((army_bb, ai) => {
         pieces_bb.forEach((piece_bb, pi) => {
            piece_bb.forEach((_, sq_idx) => {
               if (army_bb[sq_idx] === '1' && piece_bb[sq_idx] === '1') {
                  // console.log('army', ai, 'has piece at', sq_idx)
                  pop_arr[sq_idx] = `${BOARD_SYMBOLS[ai]}${BOARD_SYMBOLS[pi + 2]}`
               } else {
                  // Only set empty square character if the square hasn't been processed yet.
                  pop_arr[sq_idx] == null &&
                     (pop_arr[sq_idx] = empty_square_character)
               }
            })
         })
      })
   }

   // Compute `title_indices` padding so it's centred over board cells.
   const f_title_indices = ' '.repeat(
      idnt_tab + Math
         .floor(
            (7 *
                  ((cell_width - 1) + idnt_gap +
                     (with_indices === true ? idnt_idx : 0)) + 8) / 2,
         ) - Math
         .floor(title_indices.length / 2),
   )

   // Title line.
   console.log(`${f_pre}${title_rank}${f_title_indices}${title_indices}`)

   pop_arr.forEach((c: string, i) => {
      // Width of visible characters of true-branch should be equal to `idnt_idx`
      //   cbf computing that now, this is already overengineered enough.
      const indices = with_indices === true
         ? ` \x1b[38;5;243m${(i ^ 56).toString().padStart(2, ' ')}\x1b[0m`
         : ''
      const char = `${c}`.padStart(cell_width)
      const square = `${char}${indices}`

      if (i % 8 === 0) {
         // Print rank and first a-file board cell as required.
         process.stdout.write(
            `\n${f_pre}${f_to_rank}${8 - (i >> 3)}${f_from_rank}${f_tab}${square}`,
         )
      } else {
         // Else print each b through h-file board cell.
         process.stdout.write(`${f_gap}${square}`)
      }
   })

   console.log('\n') // Two newlines, but visually just one (first ends rank 1s line).

   // +1 for rank characters absence.
   const f_file_lead = ' '.repeat(
      idnt_pre + idnt_to_rank + idnt_from_rank + idnt_tab + 2,
   )
   const f_file_gap = ' '.repeat(
      (cell_width - 1) + idnt_gap + (with_indices === true ? idnt_idx : 0),
   )

   // Print files.
   process.stdout.write(f_file_lead)
   title_files.forEach((f) => {
      process.stdout.write(`${f}${f_file_gap}`)
   })
   console.log(`${title_file}\n\n`)
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

const x = board('0x100900058000011')
const b1 = board([
   '0x100058000010',
   '0x1010000020001000',
   '0x100048000010',
   '0',
   '0x10000000',
   '0',
   '0',
   '0x1010000020001000',
])

print_bb(x, false, '.')

print_bb(b1, false, '.')
