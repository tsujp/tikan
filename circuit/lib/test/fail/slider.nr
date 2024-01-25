use dep::state::types::{Turn};
// use crate::test::util::{cc, cc_promote, assert_bbs};
use crate::test::util::swiss as t;

//
// FAILING SLIDER (Bishop / Rook / Queen / King)
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- NOTHING MOVE (ILLEGAL)

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move_1() {
    let _ = t::sc::COMMON_SLIDING[1].game.apply(Turn { piece: t::Piece::BISHOP, from: t::sq::a1, to: t::sq::a1, promotion_piece: 0 });
}

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move_2() {
    let _ = t::sc::COMMON_SLIDING[1].game.apply(Turn { piece: t::Piece::ROOK, from: t::sq::b2, to: t::sq::b2, promotion_piece: 0 });
}

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move_3() {
    let _ = t::sc::COMMON_SLIDING[1].game.apply(Turn { piece: t::Piece::QUEEN, from: t::sq::c3, to: t::sq::c3, promotion_piece: 0 });
}

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn nothing_move_4() {
    let _ = t::sc::COMMON_SLIDING[1].game.apply(Turn { piece: t::Piece::KING, from: t::sq::d4, to: t::sq::d4, promotion_piece: 0 });
}
