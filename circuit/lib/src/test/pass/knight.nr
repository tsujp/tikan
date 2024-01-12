use crate::test::util::swiss as t;

//
// PASSING KNIGHT TESTS
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE PATTERN (LEGAL)

#[test]
fn empty_pattern() {
    let piece = t::Piece::KNIGHT;
    let s = t::sc::KNIGHT[0].no_fog;

    // a1 to c2.
    let _ = s.assert_delta(
        piece,
        t::sq::a1,
        t::sq::c2,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8100000000000480)]
    );
    // a1 to b3.
    let _ = s.assert_delta(
        piece,
        t::sq::a1,
        t::sq::b3,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8100000000020080)]
    );
    // a8 to c7.
    let _ = s.assert_delta(
        piece,
        t::sq::a8,
        t::sq::c7,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8004000000000081)]
    );
    // a8 to b6.
    let _ = s.assert_delta(
        piece,
        t::sq::a8,
        t::sq::b6,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8000020000000081)]
    );
    // h8 to f7.
    let _ = s.assert_delta(
        piece,
        t::sq::h8,
        t::sq::f7,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x120000000000081)]
    );
    // h8 to g6.
    let _ = s.assert_delta(
        piece,
        t::sq::h8,
        t::sq::g6,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x100400000000081)]
    );
    // h1 to f2.
    let _ = s.assert_delta(
        piece,
        t::sq::h1,
        t::sq::f2,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8100000000002001)]
    );
    // h1 to g3.
    let _ = s.assert_delta(
        piece,
        t::sq::h1,
        t::sq::g3,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8100000000400001)]
    );
}

#[test]
fn dense_pattern() {
    let piece = t::Piece::KNIGHT;
    let s = t::sc::KNIGHT[2].no_fog;

    // b3 to c1.
    let _ = s.assert_delta(
        piece,
        t::sq::b3,
        t::sq::c1,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124520008402485)]
    );
    // b3 to a5.
    let _ = s.assert_delta(
        piece,
        t::sq::b3,
        t::sq::a5,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124520108402481)]
    );
    // b3 to c5.
    let _ = s.assert_delta(
        piece,
        t::sq::b3,
        t::sq::c5,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124520408402481)]
    );
    // d4 to b5.
    let _ = s.assert_delta(
        piece,
        t::sq::d4,
        t::sq::b5,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124520200422481)]
    );
    // d4 to f5.
    let _ = s.assert_delta(
        piece,
        t::sq::d4,
        t::sq::f5,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124522000422481)]
    );
    // d4 to f3.
    let _ = s.assert_delta(
        piece,
        t::sq::d4,
        t::sq::f3,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124520000622481)]
    );
    // d4 to e2.
    let _ = s.assert_delta(
        piece,
        t::sq::d4,
        t::sq::e2,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124520000423481)]
    );
    // e6 to g5.
    let _ = s.assert_delta(
        piece,
        t::sq::e6,
        t::sq::g5,
        [(t::bb::WHITE, t::bb::KNIGHT, 0x8124424008422481)]
    );
    // e6 to f8.
    let _ = s.assert_delta(
        piece,
        t::sq::e6,
        t::sq::f8,
        [(t::bb::WHITE, t::bb::KNIGHT, 0xa124420008422481)]
    );
}
