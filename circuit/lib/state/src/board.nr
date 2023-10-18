use dep::std::println;
// use dep::std::unsafe::zeroed;

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


struct Board {    
    pieces: [Bitboard; REQUIRED_BITBOARDS],
}


impl Board {
    pub fn new() -> Self {
        Self {
            pieces: [Bitboard::new(); REQUIRED_BITBOARDS],
        }
    }

    // Places piece for player at location (by square index).
    // TODO: Enforce our indexing pattern.
    // TODO: When enums param `piece` should be constrained.
    pub fn put_player_piece(&mut self, player: Field, piece: Field, idx: u64) {
        // println(f"Place piece for player u{player} at u{idx}");
        // self.pieces[player].data |= 1 << idx;
        // self.pieces[piece].data |= 1 << idx;
        self.pieces[player].data |= 1 << (63 - idx); // BERLEF indexing.
        self.pieces[piece].data |= 1 << (63 - idx); // BERLEF indexing.
    }
}


// FEN is read left-to-right and indexes the board top-left to bottom-right
//   we'll keep this ordering when populating, and using bitboards.
// This means the bitfields are in big-endian order rank-wise, and little-endian
//   order file-wise. A.K.A. BERLEF square mapping.

//    [RANK]          [INDICES]
//
//       8     0   1   2   3   4   5   6   7
//       7     8   9  10  11  12  13  14  15
//       6    16  17  18  19  20  21  22  23
//       5    24  25  26  27  28  29  30  31
//       4    32  33  34  35  36  37  38  39
//       3    40  41  42  43  44  45  46  47
//       2    48  49  50  51  52  53  54  55
//       1    56  57  58  59  60  61  62  63
//
//             a   b   c   d   e   f   g   h   [FILE]
