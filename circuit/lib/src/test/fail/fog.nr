use dep::state::types::Game;
use crate::test::util::cc as cc;
use crate::test::util::swiss as t;

//
// FAILING FOG
//

fn knight_s(from: u6, to: u6) -> () {
    let _ = cc(t::sc::KNIGHT[0].with_fog.game, t::Piece::KNIGHT)(from, to);
}

fn slider_s(from: u6, to: u6, piece: u3) -> () {
    let _ = cc(t::sc::COMMON_SLIDING[0].game, piece)(from, to);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE FOG (ILLEGAL)

// ---------------- Knights

#[test(should_fail_with = "KNIGHT move FOG")]
fn knight_1() {
    knight_s(t::sq::a1, t::sq::b3);
}

#[test(should_fail_with = "KNIGHT move FOG")]
fn knight_2() {
    knight_s(t::sq::h1, t::sq::f2);
}

// ---------------- Bishops / Rooks / Queens (all together as sliders)

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_1() {
    // Diagonal with a capture.
    slider_s(t::sq::a1, t::sq::h8, t::Piece::BISHOP);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_2() {
    // Diagonal.
    slider_s(t::sq::a1, t::sq::d4, t::Piece::BISHOP);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_3() {
    // Anti-diagonal with capture.
    slider_s(t::sq::h1, t::sq::a8, t::Piece::QUEEN);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_4() {
    // Anti-diagonal.
    slider_s(t::sq::h1, t::sq::c6, t::Piece::QUEEN);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_5() {
    // Horizontal with capture.
    slider_s(t::sq::a4, t::sq::h4, t::Piece::ROOK);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_6() {
    // Horizontal.
    slider_s(t::sq::a4, t::sq::e4, t::Piece::ROOK);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_7() {
    // Vertical with capture.
    slider_s(t::sq::e8, t::sq::e1, t::Piece::ROOK);
}

#[test(should_fail_with = "SLIDER move FOG")]
fn slider_bishop_rook_queen_8() {
    // Vertical.
    slider_s(t::sq::e8, t::sq::e5, t::Piece::ROOK);
}

// ---------------- Kings

// XXX: KINGS ONLY REQUIRE MOVE TESTS FOR SPECIAL CASTLING MOVE __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// See comment in `pass/fog.nr`.

// ---------------- Pawns

// XXX: PAWNS REQUIRE NO ILLEGAL FOG MOVE TESTS __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// See comment in `pass/fog.nr` as it's the same; there is no illegal move a
//   pawn can make that would be illegal only in the context of fog.
