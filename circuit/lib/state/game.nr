use dep::std::{wrapping_add, wrapping_mul, wrapping_sub};
use dep::util::bit_logic as bl;
use crate::types::{Bitboard, BitboardIndex, REQUIRED_BITBOARDS, PIECE_OFFSET, BitboardOf, Player, Piece, Game, Turn, Move};

// global STARTING_BITBOARDS: [Bitboard; REQUIRED_BITBOARDS] = [
//   0xFFFF,
//   0xFFFF000000000000,
//   0x4200000000000042,
//   0x2400000000000024,
//   0x8100000000000081,
//   0x0800000000000008,
//   0x1000000000000010,
//   0x00FF00000000FF00,
//   // TODO: Put proper starting fog mask here.
//   0x42069,
// ];

// See https://www.chessprogramming.org/Flipping_Mirroring_and_Rotating#Flip_about_the_Diagonal
// global SHIFTED_ANTI_DIAGONAL: u64 = 0x02040810204081;

// global PAWN_START_RANKS: [Bitboard; 2] = [
//     0xFF00,
//     0xFF000000000000
// ];

// global NOT_8_RANK: u64 = 0x00FFFFFFFFFFFFFF;
// global NOT_1_RANK: u64 = 0xFFFFFFFFFFFFFF00;

// global A_FILE: u64 = 0x0101010101010101;
// global NOT_A_FILE: u64 = 0xFEFEFEFEFEFEFEFE;
// global NOT_H_FILE: u64 = 0x7F7F7F7F7F7F7F7F;

// These APIs are mostly for testing because inputs to circuits in the wild
//   auto-instantiate the `Game` struct directly instead of calling a
//   method, this method makes it easier than having multiple test helpers
//   spread all over the place.
// XXX: Put here and not on the `Game` struct because doing so there is giving:
//      `expected global variable got local variable` in other files.
pub fn init<N>(given_bbs: [u64; N], with_fog: bool) -> Game {
    let required_bbs = REQUIRED_BITBOARDS as u64; // Cannot use in println as `REQUIRED_BITBOARDS`.

    if N == 0 {
        assert(false, "Need at least 1 Bitboard");
    } else if N > required_bbs {
        // Cannot template assertion messages.
        dep::std::println(f"At most can receive {required_bbs} Bitboards, given {N}");
        assert(false, "Too many Bitboards given, see REQUIRED_BITBOARDS");
    }

    // FIXME: Lots of compiler type errors in here for some reason??
    // FIXME: Cannot instantiate as [0 as Bitboard; REQUIRED_BITBOARDS] due to
    //        LSP formatting `plain::Bitboard` bug.
    // let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as Bitboard; REQUIRED_BITBOARDS];
    // let mut set_bbs: [Bitboard; REQUIRED_BITBOARDS] = dep::std::unsafe::zeroed();
    let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as u64; REQUIRED_BITBOARDS];

    for idx in 0..given_bbs.len() {
        bbs[idx] = given_bbs[idx];
        // bbs[idx] = (given_bbs[idx] as u64); // Types erased by unsafe::zeroed().
    }

    // Last bitboard is fog. If the bitboard is all 1s it means to compute fog for the board.
    bbs[BitboardOf::FOG] = if with_fog {
        compute_fog(bbs[BitboardOf::WHITE], bbs[BitboardOf::BLACK])
    } else {
        0xFFFFFFFFFFFFFFFF // u64 max.
    };

    Game { bbs, army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1, has_fog: with_fog }
}

// XXX: ADDED AS PART OF FOG, DOCS ETC PL0X.
// Creates a fog bitboard.
pub fn compute_fog(w: Bitboard, b: Bitboard) -> Bitboard {
    // let all_pieces: Bitboard = w | b;
    let all_pieces: Bitboard = w; // Only white (TODO: Make it take the army bb single arg if this approach works).

    let all_bits = (all_pieces as Field).to_le_bits(64);

    let mut fog: Bitboard = 0;

    // URG_TODO: I believe compute_fog should only compute for our own pieces
    //           unless we happen to illuminate an enemy's (how to tell that
    //           in the first place _beforehand_).

    // FIXME: Compiler `cannot determine loop bound at compile-time` for some reason.
    // for i in 0..all_bits.len() {
    for i in 0..64 {
        let bit = all_bits[i];

        let bit_fog = if bit == 1 {
            bl::taxi_mask((2 as Field).pow_32(i) as u64)
        } else {
            0
        };

        fog |= bit_fog;
    }

    fog
}

impl Game {
    // Returns an array of struct members as Fields, for use in hashing
    //   functions (e.g. Pedersen).
    fn decompose(self) -> [Field; 14] {
        [
            self.bbs[BitboardOf::WHITE] as Field,
            self.bbs[BitboardOf::BLACK] as Field,
            self.bbs[BitboardOf::KNIGHT] as Field,
            self.bbs[BitboardOf::BISHOP] as Field,
            self.bbs[BitboardOf::ROOK] as Field,
            self.bbs[BitboardOf::QUEEN] as Field,
            self.bbs[BitboardOf::KING] as Field,
            self.bbs[BitboardOf::PAWN] as Field,
            self.bbs[BitboardOf::FOG] as Field,
            self.army as Field,
            self.castle_rights as Field,
            self.en_passant as Field,
            self.halfmove,
            self.fullmove
        ]
    }

    pub fn apply(self, move: Turn) -> Game {
        let army = self.army;
        let from_idx = move.from as Bitboard;
        let to_idx = move.to as Bitboard;
        let piece = move.piece + PIECE_OFFSET;

        let from_bb = 0 as Bitboard | 1 << from_idx;
        let to_bb = 0 as Bitboard | 1 << to_idx;

        let move_result = Move::check_legal(self, move);

        // ----------
        let mut new_bbs = self.bbs;

        // TODO: Rename `update_piece_bb` -> `us_update_bb`.
        let update_piece_bb = from_bb ^ to_bb ^ move_result.special_bbs.remove;
        // dep::std::println(f"update_piece_bb: {update_piece_bb}"); // TODO: Uncomment later.

        // TODO: Rename `ep_capture_bb` -> `them_update_bb`.
        let ep_capture_bb = move_result.ep_capture_bb.unwrap_or(0);
        // dep::std::println(f"ep_capture_bb: {ep_capture_bb}"); // TODO: Uncomment later.

        let summon_bb = move_result.special_bbs.summon.0;
        let summon_piece = move_result.special_bbs.summon.1 as u3;
        // TODO: PR cannot print global constants.
        // dep::std::println(f"piece_offset: {PIECE_OFFSET}");

        // Since we don't take an input of the type of piece captured we need to
        //   execute this for every piece bitboard.
        let mut is_capture = false;
        for bb_idx in BitboardOf::KNIGHT..BitboardOf::PAWN + 1 {
            // let current_bb = new_bbs[bb_idx];
            // dep::std::println(f"current bb: {current_bb}");

            // if ((bb_idx != piece as u4) & (new_bbs[bb_idx] & to_bb) > 0) {
            if ((new_bbs[bb_idx] & to_bb) > 0) {
                // Captured piece.
                new_bbs[bb_idx] ^= to_bb;
                // dep::std::println(f"wat: {to_bb}");
                is_capture = true;
            }
        }

        // Piece that did the moving.
        new_bbs[piece] ^= update_piece_bb ^ ep_capture_bb;

        new_bbs[summon_piece + PIECE_OFFSET] |= summon_bb;
        new_bbs[army] ^= (update_piece_bb | summon_bb);
        new_bbs[!army] ^= ep_capture_bb | if is_capture { to_bb } else { 0 };

        // `fullmove` is incremented after black's turn.
        let fullmove = self.fullmove + if army == Player::BLACK { 1 } else { 0 };

        // Update fog.
        if self.has_fog {
            new_bbs[BitboardOf::FOG] = compute_fog(new_bbs[BitboardOf::WHITE], new_bbs[BitboardOf::BLACK]);
        }

        // TODO: Update castle rights.

        let mut new_board = Game {
            bbs: new_bbs,
            army: !army,
            castle_rights: self.castle_rights,
            en_passant: move_result.en_passant.unwrap_or(0),
            halfmove: self.halfmove,
            fullmove: fullmove,
            has_fog: self.has_fog
        };

        new_board
    }
}
