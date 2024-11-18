use crate::test::util::cc as cc;
use crate::test::util::swiss as t;

//
// PASSING FOG
//

// TODO: Temp until `assert_delta` in slider tests.
fn slider_s(from: u8, to: u8, piece: u8) -> () {
    let _ = cc(t::sc::COMMON_SLIDING[0].game, piece)(from, to);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- FOG MASKS

#[test]
fn complex() {
    assert(t::compute_fog(0x8002200000044001, 0) == 0xE7FFFF766EFFFFE7);
    assert(t::compute_fog(0x1000064301001A, 0x1C05420080004000) == 0x7FFFFFFFFFFFFFFF);
    assert(t::compute_fog(0x1C478200000000FF, 0) == 0xFFFFFFC782FFFFFF);
    assert(t::compute_fog(0x1C638200000000FF, 0) == 0xFFFFFFE782FFFFFF);
}

#[test]
fn simple() {
    assert(t::compute_fog(0x8000000, 0) == 0x81C3E1C0800);
}

#[test]
fn empty() {
    assert(t::compute_fog(0, 0) == 0);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE FOG (LEGAL)

// ---------------- Knights

// MAYBE:
// It's not possible for a knight to jump over fog to capture a piece because of the fog
//   pattern in-use. If that pattern is changed then a test checking for such may be
//   useful. Right now all squares a knight can travel to the landing square would be
//   revealed from it's own presence.

#[test]
fn knight() {
    let knight = t::Piece::KNIGHT;
    let pawn = t::Piece::PAWN;

    let white_s1 = t::sc::COMMON[0].with_fog;

    // b5 to a7 (capture pawn).
    let _ = white_s1.assert_delta(
        knight,
        t::sq::b5,
        t::sq::a7,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x11000000000000), (t::bb::BLACK, t::bb::PAWN, 0x4420000000000)]
    );

    // b5 to c7 (capture pawn).
    let _ = white_s1.assert_delta(
        knight,
        t::sq::b5,
        t::sq::c7,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x14000000000000), (t::bb::BLACK, t::bb::PAWN, 0x1420000000000)]
    );

    // b5 to d4.
    let black_s1 = white_s1.assert_delta(
        knight,
        t::sq::b5,
        t::sq::d4,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x10000008000000)]
    );

    // TODO: This is a pawn move put it in it's own and do a black knight move instead.

    // b6 to c5 (capture pawn).
    let _  = black_s1.assert_delta(
        pawn,
        t::sq::b6,
        t::sq::c5,
        [(t::bb::BLACK, t::bb::PAWN, 0x5400400000000), (t::bb::WHITE, t::bb::PAWN, 0x42010000)]
    );
}

#[test]
fn slider_bishop_rook_queen_1() {
    // Diagonal.
    slider_s(t::sq::a1, t::sq::b2, t::Piece::BISHOP);
}

#[test]
fn slider_bishop_rook_queen_2() {
    // Anti-diagonal.
    slider_s(t::sq::h1, t::sq::g2, t::Piece::QUEEN);
}

#[test]
fn slider_bishop_rook_queen_3() {
    // Horizontal.
    slider_s(t::sq::a4, t::sq::c4, t::Piece::ROOK);
}

#[test]
fn slider_bishop_rook_queen_4() {
    // Vertical.
    slider_s(t::sq::e8, t::sq::e6, t::Piece::ROOK);
}

// ---------------- Kings

// XXX: KINGS ONLY REQUIRE MOVE TESTS FOR SPECIAL CASTLING MOVE __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// The current fog mask completely overlaps a kings possible valid moves
//   except for castling; so that is the only move pattern tested.

// ---------------- Pawns

// XXX: PAWNS REQUIRE NO LEGAL FOG MOVE TESTS __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// The current fog mask completely overlaps a pawns possible valid moves
//   including en-passant, as such it is impossible for a pawn to make a legal
//   move that would have to consider fog.
