use crate::test::util::swiss as t;

// TODO: Maybe more tests? Only a few though.

//
// PASSING FOG TESTS
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

#[test]
fn fog_knight() {
    let piece = t::Piece::KNIGHT;

    let white_s1 = t::sc::COMMON[0].with_fog;

    // Fairly standard moves.

    // b5 to a7 (capture pawn).
    let _ = white_s1.assert_delta(
        piece,
        t::sq::b5,
        t::sq::a7,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x11000000000000), (t::bb::BLACK, t::bb::PAWN, 0x4420000000000)]
    );

    // b5 to c7 (capture pawn).
    let _ = white_s1.assert_delta(
        piece,
        t::sq::b5,
        t::sq::c7,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x14000000000000), (t::bb::BLACK, t::bb::PAWN, 0x1420000000000)]
    );

    // b5 to d4.
    let _ = white_s1.assert_delta(
        piece,
        t::sq::b5,
        t::sq::d4,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x10000008000000)]
    );
    // TODO: Knight jumps over fog onto a lit square.
    // TODO: Black does a move.
}

// TODO: Assert post-move fog is correct, have a piece capture another and include the calculated fog in the bbs to check.
