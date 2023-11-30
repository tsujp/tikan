use dep::std::println;

use dep::state::game::Game;

// Test helper to dump board state as bitfields which can be trivially
//   serialised by a simple web frontend to visually show board state. This
//   is being done instead of printing to stdout as with many tests such a
//   long output would be tedious to explore.
// This isn't on the Game struct since it's a _test_ helper not an
//   implementation detail.
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
