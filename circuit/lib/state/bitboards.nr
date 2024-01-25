use crate::types::{Bitboard, BitboardIndex};

//
// Pre-defined bitboard constants.
//

// TODO: Move this file to the `util/src/` module because I think it makes more sense there and we cannot have `/util/src` circlularly depending on `/state` as `/state` depends on `/util/src`.

// For 90-degree clockwise single-file-to-rank rotation.
global SHIFTED_ANTI_DIAGONAL: u64 = 0x02040810204081;

// Indexed in the same order as `types.nr::Player` (white then black).
global PAWN_START_RANKS: [Bitboard; 2] = [
    0xFF00,
    0xFF000000000000
];

// Indexed in the same order as `types.nr::Player` (white then black).
global PAWN_END_RANKS: [Bitboard; 2] = [
    0xFF00000000000000,
    0xFF
];

// Area masks for pre-shift overflow prevention.
global A_FILE: u64 = 0x0101010101010101;

// TODO: Comment which ones are used for what e.g. "this is for masking diagonal-mask generation" etc.
global NOT_8_RANK: u64 = 0x00FFFFFFFFFFFFFF;
global NOT_1_RANK: u64 = 0xFFFFFFFFFFFFFF00;

global NOT_A_FILE: u64 = 0xFEFEFEFEFEFEFEFE;
global NOT_H_FILE: u64 = 0x7F7F7F7F7F7F7F7F;
