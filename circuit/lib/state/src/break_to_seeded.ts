// Break a unified set of bitboards into seedable values (basically, the
//   bitboards for the pieces per player only).

const PIECES_OFFSET = 2
const DIGITS = Math.ceil(64 / Math.log2(16))
const PIECES = ['KNIGHT', 'BISHOP', 'ROOK', 'QUEEN', 'KING', 'PAWN'] as const

function Big(bi: string | bigint) {
    if (typeof bi === 'string') {
        return BigInt(bi.replace(/_/g, ''))
    } else {
        return BigInt(bi)
    }
}

// Recursive conditional types:
//   (1) https://github.com/microsoft/TypeScript/pull/21316
//   (2) https://github.com/microsoft/TypeScript/issues/26223
type TupleOf<T, N extends number> = N extends N ? number extends N ? T[] : _TupleOf<T, N, []> : never;
type _TupleOf<T, N extends number, R extends unknown[]> = R['length'] extends N ? R : _TupleOf<T, N, [T, ...R]>;

type UserBbs = TupleOf<string, 8> | TupleOf<bigint, 8>
type InputBbs = TupleOf<bigint, 8>

type PieceBackprop = {
    bb: bigint,
    piece: string,
    piece_idx: number,
}

// Return an easily readable one (with underscore seperators), and a copyable one.
function to_hex(num: bigint) {
    // Easier to add regex on 4 _value_ characters by _not_ prefixing 0x here.
    const base = num.toString(16).padStart(DIGITS, '0').toLocaleUpperCase()
    const easy = base.match(/.{4}/g)?.join('_')

    return `0x${easy} \x1b[38;5;243m(0x${base})\x1b[0m`
}

function print_bbs(bbs: InputBbs) {
    bbs.forEach(bb => console.log(`0x${bb.toString(16).toLocaleUpperCase()}`))
}

function board(bbs: UserBbs) {
    if (bbs.length !== 8) {
        throw new Error(
            'Input bitboards must be an array of 8 bitboards.',
        )
    }

    return bbs.map((b) => Big(b)) as InputBbs
}

function or_pieces(bbs: InputBbs) {
    return (bbs[2] | bbs[3] | bbs[4] | bbs[5] | bbs[6] | bbs[7])
}

let was_error = false
function single_bitboard_error(text: string, name: string, idx: number, given: bigint, expected: bigint, delta: bigint) {
    was_error = true

    console.error(`${name} (bb: ${idx})  --  ${text}`)
    console.log(`     Given:  ${to_hex(given)}`)
    console.log(`  Expected:  ${to_hex(expected)}`)
    console.log(`     Delta:  ${to_hex(delta)}`)
    console.log(`             --> XOR ${name}'s bitboard to remove`)
    console.log(`             -->  OR bitboard of choice to add`)
}

function same_bit_error(alpha_name: string, alpha_idx: number, beta_name: string, beta_idx: number, alpha: bigint, beta: bigint, same_bit: bigint) {
    was_error = true

    console.error(`${alpha_name} (bb: ${alpha_idx}) and ${beta_name} (bb: ${beta_idx})  --  same bit set`)
    console.log(`   Given ${alpha_name.at(0)}:  ${to_hex(alpha)}`)
    console.log(`   Given ${beta_name.at(0)}:  ${to_hex(beta)}`)
    console.log(`  Same Bit:  ${to_hex(same_bit)}`)
    console.log(`             --> XOR either bitboard`)
}

const player_bit_error = same_bit_error.bind(undefined, 'WHITE', 0, 'BLACK', 1)
const phantom_error = single_bitboard_error.bind(undefined, 'phantom piece')
const orphan_error = single_bitboard_error.bind(undefined, 'orphaned piece')

function to_seed(bbs: InputBbs) {
    console.log('\x1b[1mChecking...\x1b[0m')

    // Computed player bitboard, extra bits in given player bitboard are
    //   ignored via `&` union.
    const computed_white = bbs[0] & or_pieces(bbs)
    const computed_black = bbs[1] & or_pieces(bbs)

    // Extra bits in given player bitboard compared to our calculated version.
    const delta_pre_white = computed_white ^ bbs[0]
    const delta_pre_black = computed_black ^ bbs[1]

    // If intersection of both player-bitboards delta is above 0 then they both
    //   have the same bit set, claiming a piece (regardless of whether it exists)
    //   on the same square.
    const player_same_bit = delta_pre_white & delta_pre_black
    if (player_same_bit > 0n) { player_bit_error(bbs[0], bbs[1], player_same_bit) }

    // Phantom piece in player-bitboard (player bitboard claims pieces that
    //   doesn't exist).
    const phantom_white = delta_pre_white ^ player_same_bit
    if (phantom_white > 0n) { phantom_error('WHITE', 0, bbs[0], computed_white, phantom_white) }

    const phantom_black = delta_pre_black ^ player_same_bit
    if (phantom_black > 0n) { phantom_error('BLACK', 1, bbs[1], computed_black, phantom_black) }

    // Fine for this tool's scope.
    const backprop_mask_check: PieceBackprop[] = []
    bbs.slice(PIECES_OFFSET).reduce((board, bb, idx) => {
        const piece_idx = idx + 2
        const piece = PIECES[idx]

        // Check for duplicate piece bits by scanning through prior bitboards with
        //   the current _given_ bitboard.
        backprop_mask_check.forEach((backprop) => {
            const same_bit_delta = backprop.bb & bb
            if (same_bit_delta > 0n) {
                same_bit_error(backprop.piece, backprop.piece_idx, piece, piece_idx, backprop.bb, bb, same_bit_delta)
            }
        })

        backprop_mask_check.push({ bb, piece, piece_idx })

        // The relative complement of the current piece mask `bb` against the
        //   board reveals orphaned (error) bits.
        const expect = board & bb
        const delta = expect ^ bb

        // There are orphaned bits.
        if (delta > 0n) { orphan_error(piece, piece_idx, bb, expect, delta) }

        // Done analysing this piece bitboard, XOR it from board mask to remove.
        return board ^ expect
    }, computed_white | computed_black)

    process.stdout.write('\x1b[1mDONE:\x1b[0m ')
    if (was_error) {
        process.stdout.write('\x1b[91mbitboard has errors, see above to fix')
    } else {
        process.stdout.write('\x1b[92mbitboard is good')
    }
    console.log('\x1b[0m')
}

const TO_BREAK_01 = board([
    0x4221C044108n,
    0x2047518002000000n,
    0x1040002000000n,
    0x42000008000000n,
    0x2004000000004100n,
    0x8000000008n,
    0x100000040000n,
    0x412214000000n
])


// ---------------------------------------------------------------------------
// ---------------------------------------------- TESTS

// White player bitboard itself has the error (claiming phantom pieces).
const TEST__01 = board([
    0x193CFFn, // error.
    0xFF3C080000000000n,
    0xFF000000000000FFn,
    0x4000000000400n,
    0x8000000000800n,
    0x10000000001000n,
    0x20000000002000n,
    0x80000080000n
])

// Piece bitboard has an error (orphaned piece belongs to neither player).
const TEST__02 = board([
    0x83CFFn,
    0xFF3C080000000000n,
    0xFF000000000000FFn,
    0x4000000000400n,
    0x8000000010800n, // error.
    0x10000000001000n,
    0x20000000002000n,
    0x80000080000n
])

// Both black and white player bitboards have errors (claiming phantom pieces)
//   and there is a piece bitboard error (orphaned piece belongs to neither player).
const TEST__03 = board([
    0x42083CFFn, // error.
    0xFF3C088100000000n, // error.
    0xFF000000000000FFn,
    0x4000000000400n,
    0x8000000000800n,
    0x10001818001000n, // error.
    0x20000000002000n,
    0x80000080000n
])

// Both player-bitboards have the same bit set, and two piece-bitboards have the
//   same bit set, and both player-bitboards have a phantom bit.
const TEST__04 = board([
    0x8200083CFFn, // error.
    0xFF3C084200000000n, // error.
    0xFF000000000000FFn,
    0x4000000000400n,
    0x8000000000800n,
    0x10000000001000n,
    0x20000010002000n, // error.
    0x80010080000n // error.
])

// to_seed(TEST__01)
// to_seed(TEST__02)
// to_seed(TEST__03)
// to_seed(TEST__04)
