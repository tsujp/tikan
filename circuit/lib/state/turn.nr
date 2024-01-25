use crate::types::Turn;

impl Turn {
    // Returns an array of struct members as Fields, for use in hashing
    //   functions (e.g. Pedersen).
    pub fn decompose(self) -> [Field; 4] {
        // [self.piece as Field, self.from as Field, self.to as Field, self.promotion_piece as Field, move_salt]
        [self.piece as Field, self.from as Field, self.to as Field, self.promotion_piece as Field]
    }
}
