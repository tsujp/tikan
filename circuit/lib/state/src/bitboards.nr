use crate::types::{Bitboard, BitboardIndex};

//
// Pre-defined bitboard constants.
//

// For 90-degree clockwise single-file-to-rank rotation.
global SHIFTED_ANTI_DIAGONAL: u64 = 0x02040810204081;

global PAWN_START_RANKS: [Bitboard; 2] = [
    0xFF00,
    0xFF000000000000
];

// Area masks for pre-shift overflow prevention.
global A_FILE: u64 = 0x0101010101010101;

// TODO: Check these are what they say they are, also comment which ones are used for what e.g. "this is for masking diagonal-mask generation" etc.
global NOT_8_RANK: u64 = 0x00FFFFFFFFFFFFFF;
global NOT_1_RANK: u64 = 0xFFFFFFFFFFFFFF00;

global NOT_A_FILE: u64 = 0xFEFEFEFEFEFEFEFE;
global NOT_H_FILE: u64 = 0x7F7F7F7F7F7F7F7F;
