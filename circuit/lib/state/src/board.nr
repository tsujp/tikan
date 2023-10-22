use dep::std::println;

use crate::types::{Bitboard, BitboardIndex};
use dep::util::utility::{assert_u64, assert_u6, assert_u4, assert_u1};
// use crate::move::all_knight_moves as knight_moves;
use crate::move::{knight_moves};


global REQUIRED_BITBOARDS: Field = 8;


// 6x2 bitboard board storage, this is a poor man's enum to access said boards.
// XXX: No unit structs or enums in Noir yet.
mod BitboardType {
    global WHITE: Field = 0;
    global BLACK: Field = 1;
    global PAWN: Field = 2;
    global KNIGHT: Field = 3;
    global BISHOP: Field = 4;
    global ROOK: Field = 5;
    global QUEEN: Field = 6;
    global KING: Field = 7;
}


fn assert_piece(p: Field) -> u3 {
    let p_cast: u3 = p as u3;

    assert(
        (p == p_cast as Field)
            & (BitboardType::PAWN as u3 <= p_cast)
            & (p_cast <= BitboardType::KING as u3),
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
fn is_bit_set(occupancy: Bitboard, idx: Bitboard) -> bool {
    ((occupancy >> idx) & 1) as bool
}

struct Board {
    // Square positions accessed in LERLEF order.
    bbs: [Bitboard; REQUIRED_BITBOARDS],
    army: u1,
    castle_rights: u4,
    en_passant: BitboardIndex,
    halfmove: Field,
    fullmove: Field
}


impl Board {
    // TODO: This is probably wasteful but until #3227 is fixed the public input
    //       `from_serial` needs to do the assertions and we don't want to
    //       loop the bbs twice.
    // fn from_move(
    //     bbs: [Bitboard; REQUIRED_BITBOARDS],
    //     army: u1,
    //     castle_rights: u4,
    //     en_passant: BitboardIndex,
    //     halfmove: Field,
    //     fullmove: Field
    // ) -> Self {
    //     Self {
    //         bbs: bbs,
    //         army: turn,
    //         castle_rights: castle_rights,
    //         en_passant: en_passant,
    //         halfmove: halfmove,
    //         fullmove: fullmove
    //     }
    // }
    
    pub fn from_serial(
        bbs: [Field; REQUIRED_BITBOARDS],
        // __turn: Field,
        turn: Field,
        // __castle_rights: Field,
        castle_rights: u4,
        // __en_passant: Field,
        en_passant: BitboardIndex,
        halfmove: Field,
        fullmove: Field
    ) -> Self {
        // Cannot cast arrays as a whole, must do so per array element in a for
        //   loop as casting in map is also not viable.
        let mut __bbs = [0 as Bitboard; REQUIRED_BITBOARDS];

        for i in 0 .. REQUIRED_BITBOARDS {
            let bb64 = assert_u64(bbs[i]);
            __bbs[i] = bb64;
        }

        // TODO: Assert valid bitboard state.

        Self {
            bbs: __bbs,
            // turn: __turn as u1,
            army: assert_u1(turn),
            // castle_rights: __castle_rights as u4,
            castle_rights: castle_rights,
            // en_passant: __en_passant as Bitboard,
            en_passant: en_passant,
            halfmove: halfmove,
            fullmove: fullmove
        }
    }

    // Validates input move data _structure_ and then tries to apply the move to
    //   the current gamestate which may fail if the move is illegal.
    // From and to are taken as indices to save us doing bitscans or 2's
    //   complement tricks. We can simply validate its a value within closed
    //   range 0 - 63 and produce a bitboard mask ourselves.
    //
    // 'Structure' meaning, for example, that the `soldier` parameter is
    //     expected to be in closed range 2 - 7. A 3-bit unsigned integer can
    //     itself represent closed range 0 - 8; so this must be validated.
    pub fn apply_move(
        self,
        soldier: Field, // WAT1
        from_index: Field, // WAT1
        to_index: Field, // WAT1
        capture: Field, // TODO: Do we really need to set this vs infer it?
        promotion_soldier: Field // WAT1
    ) -> Self {
        let army = self.army;
        println(f"apply_move(): army u-{army} moves piece u-{soldier} from u-{from_index} to u-{to_index}  /  capture? u-{capture}");

        // Validate input (things from users are scary).
        let piece = assert_piece(soldier);
        let from_idx = assert_u6(from_index) as Bitboard;
        let to_idx = assert_u6(to_index) as Bitboard;

        // TODO: Do we NEED the capture bit set or can it be inferred?
        assert_u1(capture);

        // Validate piece to move is in-fact at starting position claimed.
        // TODO: Board instantiation `from_serial` would have already validated
        //       that bitboards match for given pieces so we can simply check
        //       the index in the bitboard now.
        assert(
            is_bit_set(
               self.bbs[army] & self.bbs[piece],
               from_idx
            ),
           "Given army does NOT have a piece at expected LERLEF index."
        );

        // Piece at location valid; create bitboard with LERLEF-index bit set.
        let from_bb = 0 as Bitboard | 1 << from_idx;
        println(f"from_bb: {from_bb}");

        let moves = knight_moves(from_bb, self.bbs[army]);
        println(f"(current board) all valid moves: {moves}");

        // If `moves` has a 1 set at `to_idx` the requested move is valid.
        assert(
            is_bit_set(moves, to_idx),
            "Given move is INVALID; either improper move pattern or square is already occupied by a piece in the same team."
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
        let update_piece_bb = self.bbs[piece] ^ update_piece_mask;
        println(f"update_piece_bb: {update_piece_bb}");

        // Finally the army union bb must be updated.
        let update_army_bb = self.bbs[army] ^ update_piece_mask;
        println(f"update_army_bb: {update_army_bb}");

        let mut bbs = self.bbs;

        bbs[piece] ^= update_piece_mask;
        bbs[army] ^= update_piece_mask;

        let new_board = Board {
            bbs: bbs,
            army: !army,
            castle_rights: self.castle_rights,
            en_passant: self.en_passant,
            halfmove: self.halfmove,
            fullmove: self.fullmove
        };

        new_board
    }
}
