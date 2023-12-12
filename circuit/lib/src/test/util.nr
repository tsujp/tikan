use dep::std::println;
use dep::state::types::{Game, Bitboard};

// Dump bb state as bitfields which can be trivially serialised by a simple web
//   frontend to visually show piece locations state. This is being done instead
//   of printing to stdout as with many tests such a long output would be tedious
//   to explore.
// XXX: Test helper only.
// XXX: This isn't on the Game struct since it's a _test_ helper not an implementation detail.
pub fn dump_gamestate(t: Field, b: Game) -> () {
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

// As there are no template assertion strings we manually assert each bitboard
//   index so we can have a specific assertion message for use in testing.
// XXX: Test helper only.
pub fn assert_bbs(real: Game, checks: [u64; 8]) {
    assert(real.bbs[0] == checks[0], "WHITE bitboards MISMATCH");
    assert(real.bbs[1] == checks[1], "BLACK bitboards MISATCH");
    assert(real.bbs[2] == checks[2], "KNIGHT bitboards MISATCH");
    assert(real.bbs[3] == checks[3], "BISHOP bitboards MISATCH");
    assert(real.bbs[4] == checks[4], "ROOK bitboards MISATCH");
    assert(real.bbs[5] == checks[5], "QUEEN bitboards MISATCH");
    assert(real.bbs[6] == checks[6], "KING bitboards MISATCH");
    assert(real.bbs[7] == checks[7], "PAWN bitboards MISATCH");
}
