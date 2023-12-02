use dep::std::println;

use crate::types::{Bitboard, BitboardIndex, Move, Game, Turn, Piece};
use dep::util::bit_logic as bl;

use crate::bitboards as bb;

//
// Move validation and output special bitboard state.
//

// XXX HERE
// Validate a move as the big if statement stuff in `game.nr` (previously `board.nr`) does but do not return any bitboard masking stuff for special shit e.g. pawn en-passant captures. Instead return an Option poor mans enum which `game.nr` will if over to construct the special mask there. Seperation of concerns and all that.

// ---------------------------------------------------------------------------

// Hacky-ish way to make the interface to each piece-type's validation function
//   less brittle / verbose.
// OPT: A way to improve that in future?
struct Data {
    game: Game,
    turn: Turn,
    from_idx64: Bitboard,
    to_idx64: Bitboard,
    piece: u3,
    from_bb: Bitboard,
    to_bb: Bitboard
}

impl Data {
    pub fn init(game: Game, turn: Turn) -> Self {
        let tf = turn.from as Bitboard;
        let tt = turn.to as Bitboard;

        Self {
            game: game,
            turn: turn,
            from_idx64: tf,
            to_idx64: tt,
            piece: turn.piece + 2, // Offset to types.nr::BitboardOf
            from_bb: 0 as Bitboard | 1 << tf,
            to_bb: 0 as Bitboard | 1 << tt
        }
    }
}

// To be returned from all `PIECE_legal` functions (common interface), only
//   some have data we actually care about updating however.
// struct MoveDelta {
//     special_bb: Bitboard,
//     en_passant: BitboardIndex,
// }

// TODO: Continue `game.nr` refactoring. Want to get that big if-statement to
// 1. if pawn
// 2. else if knight
// 3. compute sliding move mask (since all remaining pieces are sliders)
// 4. if king restrict that mask to 1 taxicab distance about the king

// fn pawn_legal(d: Data) {
//     // Universal shift offset (only applies when black moves).
//     // TODO: u64 back to Bitboard when `nargo fmt` plain:: bug fixed.
//     let dir = (d.game.army as u64) << 4;

//     let mut en_passant: BitboardIndex = 0;

//     let mut moves = if (bb::PAWN_START_RANKS[d.game.army] & d.from_bb) > 0 {
//         // Double push, mark ourselves as an en-passant target.
//         // TODO: Shift by direction, needs to be square BEHIND so we can
//         // use one simple lookup by index. Current Jordan to past Jordan.. what? Look at this later on.
//         en_passant = d.turn.to;

//         // Double push first move; generalised shift.
//         let __tmp = (d.from_bb << 8) >> dir;
//         __tmp | (__tmp << 8) >> dir
//     } else {
//         // Single push first move; generalised shift.
//         (d.from_bb << 8) >> dir
//     };

//     // File mask of pawn.
//     let file = bb::A_FILE * (1 << (d.from_idx64 & 7));

//     // Mask of pieces in current file, pawns can only capture diagonally
//     //   so exclude these squares from our push options (if they so
//     //   happen to intersect).
//     let same_file_blockers = (self.bbs[army] | self.bbs[!army]) & file;
//     moves &= !same_file_blockers;

//     // En passant target.
//     let ep = (1 << self.en_passant as plain::Bitboard);

//     // Mask of legal diagonal movements (because an enemy piece lets
//     //   us capture); this does not include en passant.
//     let diags = (((5 << from_idx - 1) << 8) >> dir) & self.bbs[!army];
//     moves |= (diags | ep);

//     // let foo_bb = ep_bb;
//     // to_bb = ep_bb;

//     // println(f"k-0xFF k-{from_bb} k-{moves} k-{same_file_blockers} k-{ep} k-{diags} k-{foo_bb} k-0x00 k-0x00");
//     // println(f"k-0x0");

//     assert(bl::is_bit_set(moves, to_idx), "PAWN move is INVALID");

//     // The (at this point) valid move was an en passant capture, need
//     //   to set the capture bitboard with the correct index.
//     if (move.to == self.en_passant) {
//         // println("was an ep capture");
//         let ep_bb = (ep >> 8) << dir;
//         special_bb = ep_bb;
//     }
// }

pub fn knight_legal(d: Data) {
    // Product of absolute difference between rank/file of to/from squares must
    //   be 2 for the move to be valid.
    let r1 = bl::rank_idx_6_6(d.turn.from);
    let r2 = bl::rank_idx_6_6(d.turn.to);

    let f1 = bl::file_idx_6_6(d.turn.from);
    let f2 = bl::file_idx_6_6(d.turn.to);

    assert((bl::abs_6(r1, r2) as u12 * bl::abs_6(f1, f2) as u12) == 2, "KNIGHT move pattern invalid");

    // As well as not landing on a friendly piece.
    let friendlies = d.game.bbs[d.game.army];
    assert((friendlies & d.to_bb) == 0, "KNIGHT cannot capture friendly pieces");
}

impl Move {
    // Assert move is good, return optional special_bb data to XOR.
    pub fn check_legal(game: Game, turn: Turn) -> bool {
        // Check piece actually exists.
        assert(
            // See `XXX [420]` for magic number 2.
            bl::is_bit_set(
                game.bbs[game.army] & game.bbs[turn.piece + 2],
                turn.from as Bitboard
            ),
           "Piece in army does NOT EXIST at given index"
        );

        // Check there's an actual move delta.
        assert(turn.from != turn.to, "Cannot move onto your own square in the same turn");

        // Helper-deduplication / convenient data-container.
        let in_data = Data::init(game, turn);

        // Check the move is legal.
        // TODO: Can I treat pawns as a weird bishop / rook and simply restrict the movement based on where it's moving to? I think I can and then I can reuse the sliding logic I already have.
        // if turn.piece == Piece::PAWN {
        //     pawn_legal(in_data);
        // }
        if turn.piece == Piece::KNIGHT {
            knight_legal(in_data);
        }

        true
    }
}
