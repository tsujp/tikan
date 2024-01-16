use dep::state::types::{Promote};
use crate::test::util::{cc_promote};
use crate::test::util::swiss as t;

//
// FAILING SPECIAL
//

fn white_scenario(from: u6, to: u6, promote: u2) -> () {
    let _ = cc_promote(
        t::sg::init(
            t::Player::WHITE,
            // White pawns on last rank before promotion, some black pawns capturable.
            [
        (t::bb::WHITE, t::bb::PAWN, 0x55000000000000),
        (t::bb::BLACK, t::bb::PAWN, 0x2A00000000000000)
    ]
        ).game,
        t::Piece::PAWN
    )(from, to, promote);
}

fn black_scenario(from: u6, to: u6, promote: u2) -> () {
    let _ = cc_promote(
        t::sg::init(
            t::Player::BLACK,
            // Black pawns on last rank before promotion, some white pawns capturable.
            [
        (t::bb::WHITE, t::bb::PAWN, 0x2A),
        (t::bb::BLACK, t::bb::PAWN, 0x1500)
    ]
        ).game,
        t::Piece::PAWN
    )(from, to, promote);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- PROMOTION

// Really these are just checking the bounds of a u2 but meh.

#[test(should_fail)]
fn pawn_promote_vertical_1() {
    white_scenario(t::sq::a7, t::sq::a8, 4); // Attempt to promote to king.
}

#[test(should_fail)]
fn pawn_promote_vertical_2() {
    white_scenario(t::sq::c7, t::sq::c8, 5); // Attempt to promote to pawn.
}

#[test(should_fail)]
fn pawn_promote_vertical_3() {
    black_scenario(t::sq::a2, t::sq::a1, 4); // Attempt to promote to king.
}

#[test(should_fail)]
fn pawn_promote_vertical_4() {
    black_scenario(t::sq::c2, t::sq::c1, 5); // Attempt to promote to pawn.
}

#[test(should_fail)]
fn pawn_promote_diag_1() {
    white_scenario(t::sq::a7, t::sq::b8, 4); // Attempt to promote to king.
}

#[test(should_fail)]
fn pawn_promote_diag_2() {
    white_scenario(t::sq::c7, t::sq::d8, 5); // Attempt to promote to pawn.
}

#[test(should_fail)]
fn pawn_promote_diag_3() {
    black_scenario(t::sq::a2, t::sq::b1, 4); // Attempt to promote to king.
}

#[test(should_fail)]
fn pawn_promote_diag_4() {
    black_scenario(t::sq::c2, t::sq::d1, 5); // Attempt to promote to pawn.
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT CAPTURE

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT TARGET

// ---------------------------------------------------------------------------
// ---------------------------------------------- CASTLING
