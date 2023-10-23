// Move generation from starting position.
//
// Check is not considered as it is not a part of Fog of War Chess and constitutes a huge
//   amount of non-trivial effort for something which WILL be removed and .'. is
//   the definition of wasted time and energy.

use dep::std::println;

use crate::types::{Bitboard, BitboardIndex, BitboardOf, Piece};

// Inner: promotion rank indices tuples (LERLEF).
// Outer: index of army for whom their pawns promote at.
global PROMOTION_RANKS = [
    [56, 63],
    [0, 7]
];

struct Move {
    piece: u3,
    from: BitboardIndex,
    to: BitboardIndex,
    promotion_piece: u2
}


fn assert_piece(p: u3) {
    assert(
        Piece::KNIGHT <= p & p <= Piece::PAWN,
        "Piece is NOT a pawn, knight, bishop, rook, queen, or king."
    );
}


impl Move {
    pub fn validate(self) {
        println(self);
        assert_piece(self.piece);
        // NB: Don't need to do this anymore (depending on bb.js circuit input behaviour) as promotion piece is u2.
        // Validate at least the _structure_ of a claimed promotion so that all
        //   _structural_ validation is done in one place.
        // if (
        //     (self.piece == Piece::PAWN)
        //         & (PROMOTION_RANKS[army][0] <= self.to)
        //         & (self.to <= PROMOTION_RANKS[army][1])
        // ) {
        //     println("claimed promotion move");
        //     assert(
        //       "Promotion piece is NOT a knight, bishop, rook, or queen."  
        //     );
        // }
    }
}


// Compute bitmask of valid knight moves from given bitboard position. The
//   relative complement of all _possible_ knight moves against pieces in the
//   same army is taken to eliminate moves where the knight lands on a square
//   that same army controls.
//
// Absolute difference is not used as there are no negative numbers in Noir and
//   while if-else spahgetti-ing is an option we need the bitboard to update
//   the gamestate anyway.
pub fn knight_moves(from_bb: Bitboard, comp: Bitboard) -> Bitboard {
    let l1 = (from_bb >> 1) & (0x7f7f7f7f7f7f7f7f as Bitboard);
    let l2 = (from_bb >> 2) & (0x3f3f3f3f3f3f3f3f as Bitboard);
    let r1 = (from_bb << 1) & (0xfefefefefefefefe as Bitboard);
    let r2 = (from_bb << 2) & (0xfcfcfcfcfcfcfcfc as Bitboard);
    let h1 = l1 | r1;
    let h2 = l2 | r2;

    // All valid moves (on an empty board).
    let all_moves = (h1 << 16) | (h1 >> 16) | (h2 << 8) | (h2 >> 8);

    // println(f"(empty board) all valid moves: {all_moves}");

    // res_mask

    // Relative complement.
    all_moves & !comp
}
