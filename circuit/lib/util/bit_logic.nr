use dep::std::{wrapping_add, wrapping_mul};

// TODO: Comment which ones are used for what e.g. "this is for masking diagonal-mask generation" etc.
global NOT_8_RANK: u64 = 0x00FFFFFFFFFFFFFF;
global NOT_1_RANK: u64 = 0xFFFFFFFFFFFFFF00;

global NOT_A_FILE: u64 = 0xFEFEFEFEFEFEFEFE;
global NOT_H_FILE: u64 = 0x7F7F7F7F7F7F7F7F;

// TODO: Move these global bitboard masks to `/lib/state/src/bitboards.nr`. Note that will be moving bitboard masks to this MODULE later so put them there instead.

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
pub fn is_bit_set(occupancy: u64, idx: u8) -> bool {
    ((occupancy >> idx) & 1) as bool
}
// pub fn is_bit_set<T>(occupancy: T, idx: T): T where Field -> bool {
//     ((occupancy >> idx) & 1) as bool
// }

// Return single occupancy mask marking position of most significant 1-bit in
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

// pub fn east_ray(about_idx: u64) -> u64 {
//     2 * ((1 << (about_idx | 7)) - (1 << about_idx))
// }

// pub fn west_ray(about_idx: u64) -> u64 {
//     (1 << about_idx) - (1 << (about_idx & 56))
// }

// Return mask with all positions below single occupancy input mask set to 1.
pub fn west_ray_3_8(input_idx: u8) -> u8 {
    (1 as u8 << (input_idx as u8)) - (1 as u8 << 0)
}

// Return mask with all positions above single occupancy input mask set to 1.
pub fn east_ray_3_8(input_idx: u8) -> u8 {
    (128 as u8 - (1 as u8 << input_idx as u8)) * 2
}

// XXX: Compiler does not like this here.
// global DEBRUIJN_POS: [Field, 32] = [
//   0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
//   31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
// ];

// DeBruijn log2 (MS1B as index).
pub fn ms1b_idx_8_3(b: u8) -> u8 {
    // TODO
    // XXX: This is the version for 32-bits and under, fine for us. Have a crack
    //      at brute-forcing a dense magic lookup table (like this) but for
    //      8-bits for fun later on.
    let DEBRUIJN_POS: [u8; 32] = [
        0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
        31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
    ];

    // Magic.
    // let idx = DEBRUIJN_POS[((b as u32) * (0x077CB531 as u32)) >> 27];
    let idx = DEBRUIJN_POS[wrapping_mul(b as u32, 0x077CB531 as u32) >> 27];

    assert(idx < 8, "DeBruijn lookup for MS1B above 8-bit value");

    idx as u8
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

// Helper to prevent `as u8` spam.
pub fn rank_idx_6_3(square_idx: u8) -> u8 {
    rank_idx_6_6(square_idx) as u8
}

// Helper to prevent `as u8` spam.
pub fn file_idx_6_3(square_idx: u8) -> u8 {
    file_idx_6_6(square_idx) as u8
}

// Given a LERLEF index return rank index (0 - 7).
// XXX: YOLO
pub fn rank_idx_6_6(square_idx: u8) -> u8{
    square_idx >> 3 // Floor divides by 8.
}

// Given LERLEF index return file index (0 - 7)
// XXX: YOLO
pub fn file_idx_6_6(square_idx: u8) -> u8{
    square_idx & 7 // Modulo 8.
}

// Return LERLEF index marking start of rank for the given LERLEF index.
// XXX: YOLO
pub fn rank_start_idx_6(square_idx: u8) -> u8 {
    // `idx & 56` effectively computes: `floor(idx / 8) * 8`.
    //
    // So for 44 (square e6): 44 / 8 = 5.5... floored is 5... times 8 is 40.
    square_idx & 56
}

// Given LERLEF index return mask of the rank that index is on.
pub fn rank_mask_6_64(square_idx: u8) -> u64 {
    // Square 44 is on the 6th rank and the starting index of the 6th rank
    //   is square 40 (a6), if we shift 0xFF (8 1s) 40 places left that yields
    //   a mask of that rank from 40 - 47 (8 squares).
    (0xFF as u64) << rank_start_idx_6(square_idx)
}

// Given two LERLEF square indices return the absolute difference between them
//   without overflowing.
// XXX: YOLO
pub fn abs_6(a: u8, b: u8) -> u8{
    let mut signed_diff_bits = ((a as i8) - (b as i8)) as u8;
    let sub = signed_diff_bits >> 4;

    signed_diff_bits ^= sub;
    signed_diff_bits -= sub;

    (signed_diff_bits & 0x0F) as u8
}

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

// Single-step ordinal directions with overflow protection where
//   applicable. These only work on versions of Noir above at least
//   `0.20.0+54a1ed58c991eefa7ac9304b894c7046c294487b` as the Noir team finally
//   saw the light and had the compiler optimise shifts that 'fall-off' to zero
//   instead of requiring the programmer to do it.
// TODO: Elsewhere in the codebase (and that's A LOT of places) remove logic that used to guard for this; or don't since array-based rewrite is coming soon.

pub fn step_north(about_occ: u64) -> u64 {
    about_occ << 8
}

pub fn step_north_east(about_occ: u64) -> u64 {
    (about_occ & NOT_H_FILE) << 9
}

pub fn step_east(about_occ: u64) -> u64 {
    (about_occ & NOT_H_FILE) << 1
}

pub fn step_south_east(about_occ: u64) -> u64 {
    (about_occ & NOT_H_FILE) >> 7
}

pub fn step_south(about_occ: u64) -> u64 {
    about_occ >> 8
}

pub fn step_south_west(about_occ: u64) -> u64 {
    (about_occ & NOT_A_FILE) >> 9
}

pub fn step_west(about_occ: u64) -> u64 {
    (about_occ & NOT_A_FILE) >> 1
}

pub fn step_north_west(about_occ: u64) -> u64 {
    (about_occ & NOT_A_FILE) << 7
}

// Returns a 2-distance taxicab mask about the given point (single occupancy
//   bitboard mask).
pub fn taxi_mask(about_occ: u64) -> u64 {
    // Variables are named according to their ordinal directions and how many
    //   taxicab squares from the origin they are. So `w2` is west 2 squares.

    // |  1  |  2  |  3  |  4  |  5  |     [Local File]
    // +-----+-----+-----+-----+-----+

    //             +-----+
    //             |  N2 |
    //       +-----+-----+-----+
    //       | NW1 |  N1 | NE1 |
    // +-----+-----+-----+-----+-----+
    // |  W2 |  W1 | ___ |  E1 |  E2 |     [Taxicab Mask]
    // +-----+-----+-----+-----+-----+
    //       | SW1 |  S1 | SE1 |
    //       +-----+-----+-----+
    //             |  S2 |
    //    X     Y  +-----+

    // +-----+-----+-----+-----+-----+
    // |  1  |  2  |  3  |  4  |  5  |     [Local File]

    // XXX: This implementation is NOT aiming for efficiency since a rewrite
    //      into array-based logic for the entire move-validation engine will
    //      happen; so there's no point spending a bunch of time to optimise
    //      what we know will be removed just over the horizon.

    let n1 = step_north(about_occ);
    let n2 = step_north(n1);

    let ne1 = step_north_east(about_occ);

    let e1 = step_east(about_occ);
    let e2 = step_east(e1);

    let se1 = step_south_east(about_occ);

    let s1 = step_south(about_occ);
    let s2 = step_south(s1);

    let sw1 = step_south_west(about_occ);

    let w1 = step_west(about_occ);
    let w2 = step_west(w1);

    let nw1 = step_north_west(about_occ);

    let res = n2 | n1 | ne1 | e2 | e1 | se1 | s2 | s1 | sw1 | w2 | w1 | nw1 | about_occ;

    res
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
pub fn on_same_diagonal(a_idx: u8, b_idx: u8) -> bool {
    if (a_idx > b_idx) {
        (a_idx - b_idx) % 9 == 0
    } else {
        (b_idx - a_idx) % 9 == 0
    }
}

// Given two square indices return true if those indices are on the same anti-diagonal.
pub fn on_same_anti_diagonal(a_idx: u8, b_idx: u8) -> bool {
    let a_rank = rank_idx_6_6(a_idx);
    let b_rank = rank_idx_6_6(b_idx);

    let a_file = file_idx_6_6(a_idx);
    let b_file = file_idx_6_6(b_idx);

    (a_rank + a_file) == (b_rank + b_file)
}

// Given two square indices return true if those indices are on the same rank.
pub fn on_same_rank(a_idx: u8, b_idx: u8) -> bool {
    rank_idx_6_6(a_idx) == rank_idx_6_6(b_idx)
}

// Given two square indices return true if those indices are on the same file.
pub fn on_same_file(a_idx: u8, b_idx: u8) -> bool {
    file_idx_6_6(a_idx) == file_idx_6_6(b_idx)
}
