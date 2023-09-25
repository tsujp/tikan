use dep::std::println;

// mod bitboard;
use crate::bitboard::Bitboard as Bitboard;

global REQUIRED_BITBOARDS: Field = 8;

// Purpose of each bitboard kept in array of bitboards (by index).
// NB: No unit structs or enums in Noir so this pattern instead.
mod Piece {
    global WHITE: Field = 0;
    global BLACK: Field = 1;
    global PAWN: Field = 2;
    global KNIGHT: Field = 3;
    global BISHOP: Field = 4;
    global ROOK: Field = 5;
    global QUEEN: Field = 6;
    global KING: Field = 7;
}

// NB: Until bitshifting with a mix of constants and parameterised values is fixed
//     use this wrapper (and the corresponding for right-shifts) since it magically
//     fixes the problem and allows base-1 bitshifts.
// NB: Tracking issue: https://github.com/noir-lang/noir/issues/2399
fn bs_l(rdx: u64, n: u64) -> u64 {
    (rdx as u64) << n
}

struct Board {    
    pieces: [Bitboard; REQUIRED_BITBOARDS],
}

impl Board {
    fn new() -> Self {
        Self {
            pieces: [Bitboard::new(); REQUIRED_BITBOARDS],
        }
    }

    // Places piece for player at location (by square index).
    // TODO: In which order are we indexing squares?
    fn put_player_piece(&mut self, player: u8, piece: Field, idx: u64) {
        println(f"Place piece for player u{player} at u{idx}");
        // self.pieces[player].data |= bs_l(1, idx);
        self.pieces[player].data |= 1 << idx;
        // self.pieces[piece].data |= bs_l(1, idx);
        self.pieces[piece].data |= 1 << idx;
    }
}
