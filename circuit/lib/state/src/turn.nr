// Turn generation from starting position.
//
// Check is not considered as it is not a part of Fog of War Chess and constitutes a huge
//   amount of non-trivial effort for something which WILL be removed and .'. is
//   the definition of wasted time and energy.

use dep::std::println;

use crate::types::{Bitboard, BitboardIndex, BitboardOf, Piece, Turn};
use dep::std::{wrapping_add, wrapping_mul};
// Inner: promotion rank indices tuples (LERLEF).
// Outer: index of army for whom their pawns promote at.
global PROMOTION_RANKS = [
    [56, 63],
    [0, 7]
];

fn assert_piece(p: u3) {
    assert(Piece::KNIGHT <= p & p <= Piece::PAWN, "Piece is NOT a pawn, knight, bishop, rook, queen, or king.");
}

impl Turn {
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

    // Returns an array of struct members as Fields, for use in hashing
    //   functions (e.g. Pedersen).
    pub fn decompose(self) -> [Field; 4] {
        // [self.piece as Field, self.from as Field, self.to as Field, self.promotion_piece as Field, move_salt]
        [self.piece as Field, self.from as Field, self.to as Field, self.promotion_piece as Field]
    }
}
