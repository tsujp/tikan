use crate::test::util;
use dep::state::types::Piece;

// TODO: Maybe more tests? Only a few though.

//
// PASSING FOG TESTS
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- FOG MASKS.

#[test]
fn complex_1() {
    assert(util::bb_game([0x8002200000044001]).get_fog() == 0x67FDDF766EFBBFE6);
}

#[test]
fn simple_1() {
    assert(util::bb_game([0x8000000]).get_fog() == 0x81C361C0800);
}

#[test]
fn empty_1() {
    assert(util::bb_game([0]).get_fog() == 0);
}
