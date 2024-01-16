use dep::state::types::{Turn};
use crate::test::util::swiss as t;

//
// FAILING PAWN
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- NOTHING MOVE (ILLEGAL)

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move() {
    let _ = t::sc::PAWN[0].game.apply(Turn { piece: t::Piece::PAWN, from: t::sq::a2, to: t::sq::a2, promotion_piece: 0 });
}
