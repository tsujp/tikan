use dep::std::{wrapping_add, wrapping_mul};

// Equiv. NOT_8_RANK & NOT_H_FILE; positive diagonal pre-shift masking.
global FILL_A1_G7_MASK: u64 = 0x7F7F7F7F7F7F7F;

// Equiv. NOT_1_RANK & NOT_A_FILE; negative diagonal pre-shift masking.
global FILL_B2_H8_MASK: u64 = 0xFEFEFEFEFEFEFE00;

// Equiv. NOT_8_RANK & NOT_A_FILE; positive anti-diagonal pre-shift masking.
global FILL_H1_B7_MASK: u64 = 0xFEFEFEFEFEFEFE;

// Equiv. NOT_1_RANK & NOT_H_FILE; negative anti-diagonal pre-shift masking.
global FILL_G2_A8_MASK: u64 = 0x7F7F7F7F7F7F7F00;

// 'LERLEF index' means a square index (0 - 63) in little endian rank, little
//   endian file order; and NOT a single occupancy bitboard mask.

// XXX: I'm not a fan of the hungarian naming here (including the types within
//      the actual names en masse) however due to Noir requiring _exact_ data
//      types to functions and to prevent having to constantly check I've
//      opted to append their input-output unsigned integer sizes for my sanity.

// Least significant 1-bit is intersection of non-empty bitboard with it's two's
//   complement; taking the two's complement directly does not work in Noir due
//   to overflow checks so we compute it ourselves by taking the 1's complement
//   (which is just binary NOT) and adding (with overflow wrapping) 1.
pub fn ls1b_8(b: u8) -> u8 {
    b & (wrapping_add(!b, 1))
}

// Checks that given occupancy has a bit of value 1 (set) at given LERLEF
//   index. Occupancy is a bitboard mask.
pub fn is_bit_set(occupancy: u64, idx: u64) -> bool {
    ((occupancy >> idx) & 1) as bool
}
// pub fn is_bit_set<T>(occupancy: T, idx: T): T where Field -> bool {
//     ((occupancy >> idx) & 1) as bool
// }

// Return single occupancy mask marking position of most significant 1-bt in
//   the given 8-bit input, or 0 if the input has no bits set.
pub fn ms1b_8(b: u8) -> u8 {
    if (b == 0) {
        0
    } else {
        // Binary search.
        let mut idx = b;
        idx |= idx >> 4;
        idx |= idx >> 2;
        idx |= idx >> 1;

        (idx >> 1) + 1
    }
}

pub fn east_ray(about_idx: u64) -> u64 {
    2 * ((1 << (about_idx | 7)) - (1 << about_idx))
}

pub fn west_ray(about_idx: u64) -> u64 {
    (1 << about_idx) - (1 << (about_idx & 56))
}

// Return mask with all positions below single occupancy input mask set to 1.
pub fn west_ray_3_8(input_idx: u3) -> u8 {
    (1 as u8 << (input_idx as u8)) - (1 as u8 << 0)
}

// Return mask with all positions above single occupancy input mask set to 1.
pub fn east_ray_3_8(input_idx: u3) -> u8 {
    (128 as u8 - (1 as u8 << input_idx as u8)) * 2
}

// XXX: Compiler does not like this here.
// global DEBRUIJN_POS: [Field, 32] = [
//   0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
//   31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
// ];

// DeBruijn log2 (MS1B as index).
pub fn ms1b_idx_8_3(b: u8) -> u3 {
    // TODO
    // XXX: This is the version for 32-bits and under, fine for us. Have a crack
    //      at brute-forcing a dense magic lookup table (like this) but for
    //      8-bits for fun later on.
    let DEBRUIJN_POS: [u6; 32] = [
        0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
        31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
    ];

    // Magic.
    // let idx = DEBRUIJN_POS[((b as u32) * (0x077CB531 as u32)) >> 27];
    let idx = DEBRUIJN_POS[wrapping_mul(b as u32, 0x077CB531 as u32) >> 27];

    assert(idx < 8, "DeBruijn lookup for MS1B above 8-bit value");

    idx as u3
}

pub fn reverse_8(b: u8) -> u8 {
    // TODO: If this more efficient or is to_le_bytes() and reconstructing
    //       the value by successively calling .pow_32() and summing more
    //       efficient on gates?
    (((b as u64) * 0x0202020202 as u64 & 0x010884422010 as u64) % 0x03ff) as u8
}

// XXX: I believe these are flattened when compiled so it's not actually
//      "calling" another function at runtime.

// TODO: Can generic with integer size so only one of these is needed with
//       less scuffed naming?

// Helper to prevent `as u3` spam.
pub fn rank_idx_6_3(square_idx: u6) -> u3 {
    rank_idx_6_6(square_idx) as u3
}

// Helper to prevent `as u3` spam.
pub fn file_idx_6_3(square_idx: u6) -> u3 {
    file_idx_6_6(square_idx) as u3
}

// Given a LERLEF index return rank index (0 - 7).
pub fn rank_idx_6_6(square_idx: u6) -> u6 {
    square_idx >> 3 // Floor divides by 8.
}

// Given LERLEF index return file index (0 - 7)
pub fn file_idx_6_6(square_idx: u6) -> u6 {
    square_idx & 7 // Modulo 8.
}

// Return LERLEF index marking start of rank for the given LERLEF index.
pub fn rank_start_idx_6(square_idx: u6) -> u6 {
    // `idx & 56` effectively computes: `floor(idx / 8) * 8`.
    //
    // So for 44 (square e6): 44 / 8 = 5.5... floored is 5... times 8 is 40.
    square_idx & 56
}

// Given LERLEF index return mask of the rank that index is on.
pub fn rank_mask_6_64(square_idx: u6) -> u64 {
    // Square 44 is on the 6th rank and the starting index of the 6th rank
    //   is square 40 (a6), if we shift 0xFF (8 1s) 40 places left that yields
    //   a mask of that rank from 40 - 47 (8 squares).
    (0xFF as u64) << (rank_start_idx_6(square_idx) as u64)
}

// pub fn abs(a: u6) -> u32 {
//     let mut y = a as u32;
//     let s = y >> 31;
//     y ^= s;
//     y -= s;

//     y
// }

// Given single occupancy bitboard mask return mask of diagonals about
//   that mask.
// NB: A diagonal is strictly oriented from south-west to north-east.
//       i.e. `/`
pub fn diagonal_mask_64(about_occ: u64) -> u64 {
    // (1) Unrolled positive diagonal fill mask.
    let _p_d_1 = (about_occ & FILL_A1_G7_MASK) << 9;
    let _p_d_2 = (_p_d_1 & FILL_A1_G7_MASK) << 9;
    let _p_d_3 = (_p_d_2 & FILL_A1_G7_MASK) << 9;
    let _p_d_4 = (_p_d_3 & FILL_A1_G7_MASK) << 9;
    let _p_d_5 = (_p_d_4 & FILL_A1_G7_MASK) << 9;
    let _p_d_6 = (_p_d_5 & FILL_A1_G7_MASK) << 9;
    let _p_d_7 = (_p_d_6 & FILL_A1_G7_MASK) << 9;
    let _p_d = _p_d_1 + _p_d_2 + _p_d_3 + _p_d_4 + _p_d_5 + _p_d_6 + _p_d_7;

    // (2) Unrolled negative diagonal fill mask.
    let _n_d_1 = (about_occ & FILL_B2_H8_MASK) >> 9;
    let _n_d_2 = (_n_d_1 & FILL_B2_H8_MASK) >> 9;
    let _n_d_3 = (_n_d_2 & FILL_B2_H8_MASK) >> 9;
    let _n_d_4 = (_n_d_3 & FILL_B2_H8_MASK) >> 9;
    let _n_d_5 = (_n_d_4 & FILL_B2_H8_MASK) >> 9;
    let _n_d_6 = (_n_d_5 & FILL_B2_H8_MASK) >> 9;
    let _n_d_7 = (_n_d_6 & FILL_B2_H8_MASK) >> 9;
    let _n_d = _n_d_1 + _n_d_2 + _n_d_3 + _n_d_4 + _n_d_5 + _n_d_6 + _n_d_7;

    _p_d + _n_d
}

// Given single occupancy bitboard mask return mask of anti-diagonals about
//   that mask.
// NB: An anti-diagonal is strictly oriented from south-east to north-west.
//       i.e. `\`
pub fn anti_diagonal_mask_64(about_occ: u64) -> u64 {
    // (1) Unrolled positive anti-diagonal fill mask.
    let _p_d_1 = (about_occ & FILL_H1_B7_MASK) << 7;
    let _p_d_2 = (_p_d_1 & FILL_H1_B7_MASK) << 7;
    let _p_d_3 = (_p_d_2 & FILL_H1_B7_MASK) << 7;
    let _p_d_4 = (_p_d_3 & FILL_H1_B7_MASK) << 7;
    let _p_d_5 = (_p_d_4 & FILL_H1_B7_MASK) << 7;
    let _p_d_6 = (_p_d_5 & FILL_H1_B7_MASK) << 7;
    let _p_d_7 = (_p_d_6 & FILL_H1_B7_MASK) << 7;
    let _p_d = _p_d_1 + _p_d_2 + _p_d_3 + _p_d_4 + _p_d_5 + _p_d_6 + _p_d_7;

    // (2) Unrolled negative anti-diagonal fill mask.
    let _n_d_1 = (about_occ & FILL_G2_A8_MASK) >> 7;
    let _n_d_2 = (_n_d_1 & FILL_G2_A8_MASK) >> 7;
    let _n_d_3 = (_n_d_2 & FILL_G2_A8_MASK) >> 7;
    let _n_d_4 = (_n_d_3 & FILL_G2_A8_MASK) >> 7;
    let _n_d_5 = (_n_d_4 & FILL_G2_A8_MASK) >> 7;
    let _n_d_6 = (_n_d_5 & FILL_G2_A8_MASK) >> 7;
    let _n_d_7 = (_n_d_6 & FILL_G2_A8_MASK) >> 7;
    let _n_d = _n_d_1 + _n_d_2 + _n_d_3 + _n_d_4 + _n_d_5 + _n_d_6 + _n_d_7;

    _p_d + _n_d
}

// Given a bitboard with squares of interest on a diagonal masked, return a
//   u8 such that each masked square (set bit) is moved vertically to the
//   first rank.
// NB: This is effectively a 45-degree rotation about a single chosen diagonal
//     where the results are always on the first rank with the same file index
//     as-in the original diagonal.
pub fn collapse_diagonal_to_rank_64_8(diag_occ: u64) -> u8 {
    let mut c = diag_occ;

    c |= c >> 32;
    c |= c >> 16;
    c |= c >> 8;

    (c & 0xFF) as u8
}

// TODO: Turn the `is file or rank` move logic currently in rook here.

// NB: For `on_same_XX` functions we don't want the callsite to have to order
//     the indices and said indicies won't always be given largest first if for
//     instance the move is "up" (positive direction) a diagonal, so the
//     implementations ought to work for both scenarios.

// Given two square indices return true if those indices are on the same diagonal.
pub fn on_same_diagonal(a_idx: u6, b_idx: u6) -> bool {
    if (a_idx > b_idx) {
        (a_idx - b_idx) % 9 == 0
    } else {
        (b_idx - a_idx) % 9 == 0
    }
}

// Given two square indices return true if those indices are on the same anti-diagonal.
pub fn on_same_anti_diagonal(a_idx: u6, b_idx: u6) -> bool {
    let a_rank = rank_idx_6_6(a_idx);
    let b_rank = rank_idx_6_6(b_idx);

    let a_file = file_idx_6_6(a_idx);
    let b_file = file_idx_6_6(b_idx);

    (a_rank + a_file) == (b_rank + b_file)
}
