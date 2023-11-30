// Move validation and output special bitboard state.

// Validate a move as the big if statement stuff in `game.nr` (previously `board.nr`) does but do not return any bitboard masking stuff for special shit e.g. pawn en-passant captures. Instead return an Option poor mans enum which `game.nr` will if over to construct the special mask there. Seperation of concerns and all that.

use dep::std::println;

use crate::types::{Move, Game, Turn, Bitboard};
use dep::util::bit_logic as bl;

// TODO: Continue `game.nr` refactoring. Want to get that big if-statement to
// 1. if pawn
// 2. else if knight
// 3. compute sliding move mask (since all remaining pieces are sliders)
// 4. if king restrict that mask to 1 taxicab distance about the king

impl Move {
    pub fn check_legal(board: Game, turn: Turn) -> bool {
        assert(
            // See `XXX [420]` for magic number 2.
            bl::is_bit_set(
                board.bbs[board.army] & board.bbs[turn.piece + 2],
                turn.from as Bitboard
            ),
           "Piece in army does NOT EXIST at given index"
        );

        assert(
            turn.from != turn.to,
           "Cannot move onto your own square in the same turn"
        );

        true
    }
}
