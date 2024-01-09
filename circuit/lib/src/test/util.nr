use dep::std::println;
use dep::state::types::{Game, Turn, Bitboard, BitboardIndex, REQUIRED_BITBOARDS};

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

// Immutable `C`urried `C`losure.
// Curried parameters `game` and `piece` are always the same for each call to the
//   lambda returned by this function; meaning many test cases can be made
//   against the same base state.
// If the new state is desired one can bind the return value and invoke `.apply`.
pub fn cc(game: Game, piece: u3) -> fn[(Game, u3)](BitboardIndex, BitboardIndex) -> Game {
    |from, to| game.apply(Turn { piece, from, to, promotion_piece: 0 })
}

// Create a simple `Game` where we've only provided some bitboards.
// TODO: Make a PR for a function like this, at least 3 or more bugs present.
// FIXME: Errors when using `Bitboard` here for some reason?
// fn create_simple<Bitboard, N>(given_bbs: [Bitboard; N]) -> Game {
// XXX: Test helper only
pub fn game<N>(given_bbs: [u64; N]) -> Game {
    let required_bbs = REQUIRED_BITBOARDS as u64; // Cannot use in println as `REQUIRED_BITBOARDS`.

    if N == 0 {
        assert(false, "Need at least 1 Bitboard");
    } else if N > required_bbs {
        // Cannot template assertion messages.
        dep::std::println(f"At most can receive {required_bbs} Bitboards, given {N}");
        assert(false, "Too many Bitboards given, see REQUIRED_BITBOARDS");
    }

    // FIXME: Lots of compiler type errors in here for some reason??
    // FIXME: Cannot instantiate as [0 as Bitboard; REQUIRED_BITBOARDS] due to
    //        LSP formatting `plain::Bitboard` bug.
    // let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as Bitboard; REQUIRED_BITBOARDS];
    // let mut set_bbs: [Bitboard; REQUIRED_BITBOARDS] = dep::std::unsafe::zeroed();
    let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as u64; REQUIRED_BITBOARDS];

    for idx in 0..given_bbs.len() {
        bbs[idx] = given_bbs[idx];
        // bbs[idx] = (given_bbs[idx] as u64); // Types erased by unsafe::zeroed().
    }

    Game { bbs, army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1 }
}
