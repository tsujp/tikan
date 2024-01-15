use dep::state::types::Game;
use crate::test::util::cc as cc;
use crate::test::util::swiss as t;

// TODO: Maybe more tests? Only a few though.

//
// FAILING FOG TESTS
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
    // let _ = cc(sc::KNIGHT[0].with_fog.game, Piece::KNIGHT)(0, 17);
}

#[test(should_fail_with = "KNIGHT move FOG")]
fn fog_knight_2() {
    scenario(0, t::sq::h1, t::sq::f2);
    // let _ = cc(sc::KNIGHT[0].with_fog.game, Piece::KNIGHT)(7, 13);
}

// TODO: Rest of pieces.
