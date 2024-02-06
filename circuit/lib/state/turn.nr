use crate::types::{Turn, BitboardOf};

impl Turn {
    // Returns an array of struct members as Fields, for use in hashing
    //   functions (e.g. Pedersen).
    pub fn decompose(self) -> [Field; 11] {
        // [self.piece as Field, self.from as Field, self.to as Field, self.promotion_piece as Field, move_salt]
        [
            self.piece as Field,
            self.from as Field,
            self.to as Field,
            self.promotion_piece as Field,
            self.lights as Field,
            self.bbs[BitboardOf::KNIGHT - 2] as Field,
            self.bbs[BitboardOf::BISHOP - 2] as Field,
            self.bbs[BitboardOf::ROOK - 2] as Field,
            self.bbs[BitboardOf::QUEEN - 2] as Field,
            self.bbs[BitboardOf::KING - 2] as Field,
            self.bbs[BitboardOf::PAWN - 2] as Field
        ]
    }
}
