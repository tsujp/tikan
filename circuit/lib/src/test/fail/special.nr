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

// ---------------- White illegal.

#[test(should_fail_with = "SLIDER move PATTERN")]
fn pawn_en_passant_capture_white_1() {
    let _ = t::sc::PAWN[2].assert_delta(
        t::Piece::PAWN,
        t::sq::c2, // Cannot magically teleport to the en-passant capture square.
        t::sq::e6,
        [(t::bb::WHITE, t::bb::PAWN, 0xFF)] // Doesn't matter what is here.
    );
}

#[test(should_fail_with = "PAWN special move DIAGONAL EN-PASSANT PATTERN")]
fn pawn_en_passant_capture_white_2() {
    let _ = t::sc::PAWN[2].assert_delta(
        t::Piece::PAWN,
        t::sq::a2, // Illegal diagonal sliding.
        t::sq::e6,
        [(t::bb::WHITE, t::bb::PAWN, 0xFF)] // Doesn't matter what is here.
    );
}

#[test(should_fail_with = "PAWN special move ANTI-DIAGONAL EN-PASSANT PATTERN")]
fn pawn_en_passant_capture_white_3() {
    let _ = t::sc::PAWN[2].assert_delta(
        t::Piece::PAWN,
        t::sq::h3, // Illegal anti-diagonal sliding.
        t::sq::e6,
        [(t::bb::WHITE, t::bb::PAWN, 0xFF)] // Doesn't matter what is here.
    );
}

// ---------------- Black illegal.

#[test(should_fail_with = "SLIDER move PATTERN")]
fn pawn_en_passant_capture_black_1() {
    let _ = t::sc::PAWN[3].assert_delta(
        t::Piece::PAWN,
        t::sq::a7,
        t::sq::h3,
        [(t::bb::WHITE, t::bb::PAWN, 0xFF)] // Doesn't matter what is here.
    );
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_en_passant_capture_black_2() {
    let _ = t::sc::PAWN[3].assert_delta(
        t::Piece::PAWN,
        t::sq::h6,
        t::sq::h3,
        [(t::bb::WHITE, t::bb::PAWN, 0xFF)] // Doesn't matter what is here.
    );
}

#[test(should_fail_with = "PAWN special move ANTI-DIAGONAL EN-PASSANT PATTERN")]
fn pawn_en_passant_capture_black_3() {
    let _ = t::sc::PAWN[3].assert_delta(
        t::Piece::PAWN,
        t::sq::f5,
        t::sq::h3,
        [(t::bb::WHITE, t::bb::PAWN, 0xFF)] // Doesn't matter what is here.
    );
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- EN-PASSANT TARGET

// ---------------------------------------------------------------------------
// ---------------------------------------------- CASTLING
