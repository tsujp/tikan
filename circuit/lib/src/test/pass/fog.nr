use crate::test::util::swiss as t;

//
// PASSING FOG
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- FOG MASKS

#[test]
fn complex() {
    assert(t::compute_fog(0x8002200000044001, 0) == 0x67FDDF766EFBBFE6);
    assert(t::compute_fog(0x1000064301001A, 0x1C05420080004000) == 0x7FFFFFFFFFFFFFFF);
}

#[test]
fn simple() {
    assert(t::compute_fog(0x8000000, 0) == 0x81C361C0800);
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

// ---------------- Bishops
// ---------------- Rooks
// ---------------- Queens
// ---------------- Kings

// XXX: KINGS ONLY REQUIRE MOVE TESTS FOR SPECIAL CASTLING MOVE __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// The current fog mask completely overlaps a kings possible valid moves
//   except for castling; so that is the only move pattern tested.

// ---------------- Pawns

// XXX: PAWNS REQUIRE NO LEGAL FOG MOVE TESTS __UNDER THE CURRENT FOG MASK__ (taxicab-2).
// The current fog mask completely overlaps a pawns possible valid moves
//   including en-passant, as such it is impossible for a pawn to make a legal
//   move that would have to consider fog.