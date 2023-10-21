use dep::std::println;

// use crate::bitboard::Bitboard as Bitboard;
use crate::bitboard::Bitboard as Bitboard;
use crate::bitboard::BitboardIndex as BitboardIndex;
use crate::bitboard::assert_u64 as assert_u64;
use crate::bitboard::assert_u6 as assert_u6;
use crate::bitboard::assert_u4 as assert_u4;
use crate::bitboard::assert_u1 as assert_u1;
use crate::move::all_knight_moves as all_knight_moves;


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


// Soldiers are pawns, knights, bishops, rooks, queens, and kings.
fn assert_soldier_piece(piece: Field) -> u3 {
    let p_cast: u3 = piece as u3;

    assert(
        (piece == p_cast as Field) & (Piece::PAWN as u3 <= p_cast) & (p_cast <= Piece::KING as u3),
        "Given piece is NOT a pawn, knight, bishop, rook, queen, or king."
    );

    p_cast
}


// Checks that a given army has a given soldier at a given LERLEF index.
// XXX: When bit-shifting LHS and RHS must be of the same size so while `idx`
//      WILL be at most 6-bits in _value_ it is given in 64-bit _representation_
//      to prevent endless `as` casts here and elsewhere.
// fn assert_soldier_at_index(army_units: Bitboard, idx: Bitboard) {
//     assert(
//         // ((army_units >> (idx as Bitboard)) & 1) as bool,
//         ((army_units >> idx) & 1) as bool,
//         "Given army does NOT have a piece at expected LERLEF index."
//     );
// }

// Checks that given occupancy has a bit of value 1 (set) at given LERLEF
//   index. Occupancy is a bitboard mask.
fn is_square_occupied(occupancy: Bitboard, idx: Bitboard) -> bool {
    ((occupancy >> idx) & 1) as bool
}


// fn check_knight_move() {
    
// }


struct Board {    
    // Square positions accessed in LERLEF order.
    pieces: [Bitboard; REQUIRED_BITBOARDS],
    turn: u1,
    castle_rights: u4,
    en_passant: BitboardIndex, 
    halfmove: Field,
    fullmove: Field
}


impl Board {
    // A new board is always empty.
    // pub fn new() -> Self {
    //     Self {
    //         pieces: [0 as Bitboard; REQUIRED_BITBOARDS]
    //     }
    // }

    // Like `new` but sets `pieces` field.
    pub fn from_serial(
        bbs: [Field; REQUIRED_BITBOARDS],
        // __turn: Field,
        __turn: u1,
        // __castle_rights: Field,
        __castle_rights: u4,
        // __en_passant: Field,
        __en_passant: BitboardIndex,
        __halfmove: Field,
        __fullmove: Field
    ) -> Self {
        // Cannot cast arrays as a whole so we must do so per array element in
        //   a for loop as map does not work for casting too.
        let mut __pieces = [0 as Bitboard; REQUIRED_BITBOARDS];

        for i in 0 .. REQUIRED_BITBOARDS {
            let bb64 = assert_u64(bbs[i]);
            __pieces[i] = bb64;
        }

        // TODO: Assert valid bitboard state.
        
        Self {
            pieces: __pieces,
            // turn: __turn as u1,
            turn: __turn,
            // castle_rights: __castle_rights as u4,
            castle_rights: __castle_rights,
            // en_passant: __en_passant as Bitboard,
            en_passant: __en_passant,
            halfmove: __halfmove,
            fullmove: __fullmove
        }
    }


    // [WAT1]
    // Integer types (let x: u6) and casts (foo as u12) result in the variable
    //   value being its assigned value modulo the maximum value of its data
    //   type. So `x` if set to `y` will be `y % 2^6`; `foo` would be `y % 2^12`.
    // This means assigning huge and obviously incorrect values to integers
    //   results in modulo-remainder value assignment which is not obvious.
    // Reported as a bug here: https://github.com/noir-lang/noir/issues/3227
    // The workaround is to accept a Field, cast manually, and in addition to
    //   range checking also check that expanded-cast (back to Field) has not
    //   been modulo-aletered.


    // Validates input move data _structure_ and then tries to apply the
    //   move to the current gamestate which may fail if the move is illegal.
    // From and to are taken as indices as in order to validate a single bit
    //   in a bitboard is set we will have to bitscan or use other complex
    //   tricks which require hardware access (specific assembly instructions)
    //   so it is simpler and less wasteful to take an index, validate it is
    //   within range 0 - 63 and then produce a bitboard with a single bit at
    //   said index ourselves.
    //
    // * Validating structure, for example, as the `piece` parameter is expected
    //     to be in closed range 2 - 7. A 3-bit unsigned integer can itself be
    //     in the closed range 0 - 8. So that is validated.
    pub fn apply_move(
        self,
        soldier: Field,
        from_index: Field, // WAT1
        to_index: Field, // WAT1
        capture: Field,
        promotion_piece: u3
    ) {
        let turn_of = self.turn;
        println(f"apply_move(): army u-{turn_of} moves piece u-{soldier} from u-{from_index} to u-{to_index}  /  capture? u-{capture}");

        // Validate input (things from users are scary).
        let piece = assert_soldier_piece(soldier);
        let from_idx = assert_u6(from_index) as Bitboard;
        let to_idx = assert_u6(to_index) as Bitboard;

        assert_u1(capture);

        // Validate piece to move is in-fact at starting position claimed.
        // TODO: Board instantiation `from_serial` would have already validated
        //       that bitboards match for given pieces so we can simply check
        //       the index in the bitboard now.
        assert(
            is_square_occupied(
               self.pieces[turn_of] & self.pieces[piece],
               from_idx
            ),
           "Given army does NOT have a piece at expected LERLEF index."
        );

        // TODO: Do we NEED the capture bit set or can it be inferred?
        // Validate target position `to_idx` is either empty or only populated
        //   by soldiers of the opposing army; one cannot move a piece to a
        //   square already occupied by themselves.
        // XXX: Will do this and more by getting the relative complement from post-calculated moves. No, actually intersection to move invalid moves?
        // assert(
        //     is_square_occupied(self.pieces[turn_of], to_idx) == false,
        //     "Destination square already occupied by piece on the same team (e.g. moving a white knight to a square already occupied by a white pawn)."
        // );

        // Piece of type at stated location validated, create bitboard with
        //   bit at its location (index) set to 1 and all others 0.
        let from_bb = 0 as Bitboard | 1 << from_idx;
        println(f"from_bb: {from_bb}");

        // Compute bitmask of valid (on an empty board) knight moves. We could
        //   find the absolute difference between the rank and file of the
        //   from and to locations but because there are no negative integers
        //   in Noir that's going to involve a bunch of if-else spaghetti and
        //   we need the bitboard _anyway_ to set the piece's new location.
        // TODO: In it's own function for knights.
        // let l1 = (from_bb >> 1) & 0x7f7f7f7f7f7f7f7f as Bitboard;
        // let l2 = (from_bb >> 2) & 0x3f3f3f3f3f3f3f3f as Bitboard;
        // let r1 = (from_bb << 1) & 0xfefefefefefefefe as Bitboard;
        // let r2 = (from_bb << 2) & 0xfcfcfcfcfcfcfcfc as Bitboard;
        // let h1 = l1 | r1;
        // let h2 = l2 | r2;
        // let res_mask = (h1<<16) | (h1>>16) | (h2<<8) | (h2>>8);
        // println(f"(empty board) all valid moves: {res_mask}");
        let res_mask = all_knight_moves(from_bb);

        // TODO: Tomorrow:
        //    1. Bitshift like in `assert_soldier_at_index` but given the `to`
        //       index now; if that passes the given move is in-theory valid.
        //    2. Check it's not moving onto a square already occupied by it's
        //       own pieces.
        //    3. Update the piece's BB.

        // Relative complement of all valid move indices and piece
        //   locations of the same army. I.e., all valid places
        //   which can be moved to as you cannot capture your own pieces.
        let foo = res_mask & !self.pieces[turn_of];
        println(f"(current board) all valid moves: {foo}");

        // We can check if `foo` has a 1 set at `to_idx` to determine if the
        //   requested move is valid now.        
        assert(
            is_square_occupied(foo, to_idx),
            "Given move is INVALID; either improper move pattern or square is already occupied by piece in same team."
        );

        // Move is now fully validated and we can update the gamestate bitboard
        //   for the current army and piece.
        let to_bb = 0 as Bitboard | 1 << to_idx;
        println(f"to_bb: {to_bb}");
        
        // A bitboard with the from and to positions both set to 1.
        let update_piece_mask = from_bb ^ to_bb;
        println(f"post-move update mask: {update_piece_mask}");

        // Since the positions in the (currently) unchanged piece bb will have
        //   only a single bit intersection (the from_bb) XORing the update
        //   mask with the original locations creates a bb with pieces in
        //   their correct locations post-move.
        let update_piece_bb = self.pieces[piece] ^ update_piece_mask;
        println(f"update_piece_bb: {update_piece_bb}");

        // Finally the army union bb must be updated.
        let update_army_bb = self.pieces[turn_of] ^ update_piece_mask;
        println(f"update_army_bb: {update_army_bb}");

        

        // Do actual updates:
        // let _x = self.pieces[turn_of];
        // println(f"army before: {_x}");
        // let _y = self.pieces[piece];
        // println(f"piece before: {_y}");

        // let _x2 = self.pieces[turn_of] ^ update_army_bb;

        // // let _x2 = self.pieces[turn_of];
        // println(f"army after: {_x2}");
        // let _y2 = self.pieces[piece];
        // println(f"after piece bb: {_y2}");
    }

    // Places piece for player at location (by square index).
    // TODO: Enforce our indexing pattern.
    // TODO: When enums param `piece` should be constrained.
    // pub fn put_player_piece(&mut self, player: Field, piece: Field, idx: u64) {
    //     // println(f"Place piece for player u{player} at u{idx}");
    //     // self.pieces[player].data |= 1 << idx;
    //     // self.pieces[piece].data |= 1 << idx;
    //     self.pieces[player].data |= 1 << (63 - idx); // BERLEF indexing.
    //     self.pieces[piece].data |= 1 << (63 - idx); // BERLEF indexing.
    // }
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
