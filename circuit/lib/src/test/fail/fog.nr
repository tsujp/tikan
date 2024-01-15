use dep::state::types::Game;
use crate::test::util::cc as cc;
use crate::test::util::swiss as t;

//
// FAILING FOG
//

fn scenario(idx: u64, from: u6, to: u6) -> () {
    let _ = cc(t::sc::KNIGHT[idx].with_fog.game, t::Piece::KNIGHT)(from, to);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE FOG (ILLEGAL)

// ---------------- Knights

#[test(should_fail_with = "KNIGHT move FOG")]
fn fog_knight_1() {
    scenario(0, t::sq::a1, t::sq::b3);
}

#[test(should_fail_with = "KNIGHT move FOG")]
fn fog_knight_2() {
    scenario(0, t::sq::h1, t::sq::f2);
}

// ---------------- Bishops
// ---------------- Rooks
// ---------------- Queens
// ---------------- Kings

// XXX: KINGS ONLY REQUIRE MOVE TESTS FOR SPECIAL CASTLING MOVE __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// See comment in `pass/fog.nr`.

// ---------------- Pawns

// XXX: PAWNS REQUIRE NO ILLEGAL FOG MOVE TESTS __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// See comment in `pass/fog.nr` as it's the same; there is no illegal move a
//   pawn can make that would be illegal only in the context of fog.