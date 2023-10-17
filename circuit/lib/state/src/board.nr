use dep::std::println;

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
        self.pieces[player].data |= 1 << idx;
        self.pieces[piece].data |= 1 << idx;
    }
}


// FEN is read left-to-right and indexes the board top-left to bottom-right
//   so we need to convert those indices to bitfield-order which is bottom-
//   left to top-right.


// Chess board is laid out A1 bottom-left H8 top-right so for a 64-bit bitfield
// representation of a board we will lay out the index as:

//    [RANK]          [INDICES]
//
//       8    56  57  58  59  60  61  62  63
//       7    48  49  50  51  52  53  54  55
//       6    40  41  42  43  44  45  46  47
//       5    32  33  34  35  36  37  38  39
//       4    24  25  26  27  28  29  30  31
//       3    16  17  18  19  20  21  22  23
//       2     8   9  10  11  12  13  14  15
//       1     0   1   2   3   4   5   6   7
//
//             a   b   c   d   e   f   g   h   [FILE]



//    [RANK]          [INDICES]
//
//       1     0   1   2   3   4   5   6   7
//       2     8   9  10  11  12  13  14  15
//       3    16  17  18  19  20  21  22  23
//       4    24  25  26  27  28  29  30  31
//       5    32  33  34  35  36  37  38  39
//       6    40  41  42  43  44  45  46  47
//       7    48  49  50  51  52  53  54  55
//       8    56  57  58  59  60  61  62  63
//
//             a   b   c   d   e   f   g   h   [FILE]
