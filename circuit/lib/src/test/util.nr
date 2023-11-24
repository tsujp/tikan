use dep::std::println;

use dep::state::board::Board;
use dep::state::move::Move;
use dep::state::types::Piece;
use dep::util::bit_logic::ls1b_8;

// Test helper to dump board state as bitfields which can be trivially
//   serialised by a simple web frontend to visually show board state. This
//   is being done instead of printing to stdout as with many tests such a
//   long output will be tedious to explore.
// This isn't on the Board struct since it's a _test_ helper not an
//   implementation detail.
pub fn dump_gamestate(t: Field, b: Board) -> () {
    let tag = t;
    
    let b0 = b.bbs[0];
    let b1 = b.bbs[1];
    let b2 = b.bbs[2];
    let b3 = b.bbs[3];
    let b4 = b.bbs[4];
    let b5 = b.bbs[5];
    let b6 = b.bbs[6];
    let b7 = b.bbs[7];

    // It needs to be on one line of output for our little helper script to nab.
    println(f"k-{tag} k-{b0} k-{b1} k-{b2} k-{b3} k-{b4} k-{b5} k-{b6} k-{b7}");

    // Plus horrible hack k-0x0 to prevent spamming bitboard server.
    println(f"k-0x0");
}


// TODO: Put these tests (bit_logic) in their own file.
// TODO: Tests for ms1bu8 and is_bit_set

// XXX: Ideally small tests next to the actual definition but Nargo won't execute
//      them so whatever plop it here for now and investigate exactly why later.
#[test]
fn test_ls1bu8_happy () {
    // 0xc0 & -0xc0 == 0x40
    assert(ls1b_8(0xc0) == 0x40);

    // 0x20 & -0x20 == 0x20
    assert(ls1b_8(0x20) == 0x20);

    // 0x06 & -0x06 == 0x02
    assert(ls1b_8(0x06) == 0x02);

    // 0x80 & -0x80 == 0x80 (tests wrapping)
    assert(ls1b_8(0x80) == 0x80);

    // 0x00 & -0x00 = 0x00 (tests overflow)
    assert(ls1b_8(0x00) == 0x00);

    // 0xFF & -0xFF == 0x01
    assert(ls1b_8(0xFF) == 0x01);
}


#[test(should_fail)]
fn test_ls1bu8_sad () {
    assert(ls1b_8(0x20) == 0x40);
}
