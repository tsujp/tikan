use dep::std::println;

// Poor man's enum of player types (by who moves first).
mod Player {
    global WHITE: Field = 0;
    global BLACK: Field = 1;
}


// 64 bits used for the 64 squares in a chess board.
type Bitfield = u64;


struct Bitboard {
    data: Bitfield,
}


impl Bitboard {
    pub fn new() -> Self {
        Self {
            data: 0,
        }
    }
}
