use dep::std::println;
use dep::state::types::{Game, Turn, Bitboard, BitboardIndex, BitboardOf, REQUIRED_BITBOARDS};

// Namespace that wraps things commonly required for tests.
mod swiss {
    use dep::state::game::compute_fog;
    use crate::test::util::Sq as sq;
    use crate::test::util::SeedGame as sg;
    use crate::test::scenario as sc;
    use dep::state::types::{Piece, Player};
    use dep::state::types::BitboardOf as bb;
}

// Poor man's enum as mentioned numerous other places.
// XXX: You can generate this from `bun gimme_that_enum.ts`.
mod Sq {
    global a1: u6 = 0;
    global b1: u6 = 1;
    global c1: u6 = 2;
    global d1: u6 = 3;
    global e1: u6 = 4;
    global f1: u6 = 5;
    global g1: u6 = 6;
    global h1: u6 = 7;
    global a2: u6 = 8;
    global b2: u6 = 9;
    global c2: u6 = 10;
    global d2: u6 = 11;
    global e2: u6 = 12;
    global f2: u6 = 13;
    global g2: u6 = 14;
    global h2: u6 = 15;
    global a3: u6 = 16;
    global b3: u6 = 17;
    global c3: u6 = 18;
    global d3: u6 = 19;
    global e3: u6 = 20;
    global f3: u6 = 21;
    global g3: u6 = 22;
    global h3: u6 = 23;
    global a4: u6 = 24;
    global b4: u6 = 25;
    global c4: u6 = 26;
    global d4: u6 = 27;
    global e4: u6 = 28;
    global f4: u6 = 29;
    global g4: u6 = 30;
    global h4: u6 = 31;
    global a5: u6 = 32;
    global b5: u6 = 33;
    global c5: u6 = 34;
    global d5: u6 = 35;
    global e5: u6 = 36;
    global f5: u6 = 37;
    global g5: u6 = 38;
    global h5: u6 = 39;
    global a6: u6 = 40;
    global b6: u6 = 41;
    global c6: u6 = 42;
    global d6: u6 = 43;
    global e6: u6 = 44;
    global f6: u6 = 45;
    global g6: u6 = 46;
    global h6: u6 = 47;
    global a7: u6 = 48;
    global b7: u6 = 49;
    global c7: u6 = 50;
    global d7: u6 = 51;
    global e7: u6 = 52;
    global f7: u6 = 53;
    global g7: u6 = 54;
    global h7: u6 = 55;
    global a8: u6 = 56;
    global b8: u6 = 57;
    global c8: u6 = 58;
    global d8: u6 = 59;
    global e8: u6 = 60;
    global f8: u6 = 61;
    global g8: u6 = 62;
    global h8: u6 = 63;
}

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
pub fn assert_bbs<N>(real: Game, checks: [u64; N]) {
    check_count_bbs(N);

    // -------

    let mut given = real.bbs[2];
    let mut expected = checks[2];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "KNIGHT bitboards MISATCH");
    }

    // -------

    let mut given = real.bbs[3];
    let mut expected = checks[3];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "BISHOP bitboards MISATCH");
    }

    // -------

    let mut given = real.bbs[4];
    let mut expected = checks[4];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "ROOK bitboards MISATCH");
    }

    // -------

    let mut given = real.bbs[5];
    let mut expected = checks[5];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "QUEEN bitboards MISATCH");
    }

    // -------

    let mut given = real.bbs[6];
    let mut expected = checks[6];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "KING bitboards MISATCH");
    }

    // -------

    let mut given = real.bbs[7];
    let mut expected = checks[7];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "PAWN bitboards MISATCH");
    }

    // -------

    if N == 9 {
        let mut given = real.bbs[8];
        let mut expected = checks[8];

        if expected != given {
            dep::std::println(f"");
            dep::std::println(f"expected: {expected}");
            dep::std::println(f"given: {given}");
            assert(false, "FOG bitboards MISATCH");
        }
    }

    // -------

    let mut given = real.bbs[0];
    let mut expected = checks[0];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "WHITE bitboards MISMATCH");
    }

    // -------

    let mut given = real.bbs[1];
    let mut expected = checks[1];

    if expected != given {
        dep::std::println(f"");
        dep::std::println(f"expected: {expected}");
        dep::std::println(f"given: {given}");
        assert(false, "BLACK bitboards MISATCH");
    }
}

// Immutable `C`urried `C`losure.
// Curried parameters `game` and `piece` are always the same for each call to the
//   lambda returned by this function; meaning many test cases can be made
//   against the same base state.
// If the new state is desired one can bind the return value and invoke `.apply`.
pub fn cc(game: Game, piece: u3) -> fn[(Game, u3)](BitboardIndex, BitboardIndex) -> Game {
    |from, to| game.apply(Turn { piece, from, to, promotion_piece: 0 })
}

pub fn cc_promote(game: Game, piece: u3) -> fn[(Game, u3)](BitboardIndex, BitboardIndex, u2) -> Game {
    |from, to, promotion_piece| game.apply(Turn { piece, from, to, promotion_piece })
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- SEEDABLE GAME.

mod SeedGame {
    use dep::state::types::{Game, Turn, Bitboard, BitboardIndex, REQUIRED_BITBOARDS};

    pub fn init<N>(turn: u1, bb_defs: [BbDef; N]) -> SeededGame {
        SeededGame::init(turn, bb_defs, false, 0)
    }

    pub fn init_fog<N>(turn: u1, bb_defs: [BbDef; N]) -> SeededGame {
        SeededGame::init(turn, bb_defs, true, 0)
    }

    pub fn init_ep<N>(turn: u1, bb_defs: [BbDef; N], en_passant_target: BitboardIndex) -> SeededGame {
        // No point having fog with an en-passant test _UNDER CURRENT FOG PATTERN_ (taxicab-2).
        SeededGame::init(turn, bb_defs, false, en_passant_target)
    }

    type Seed = [[Bitboard; 6]; 2];
    type BbDef = (u4, u4, Bitboard);
    type SeededBbs = (Seed, [Bitboard; REQUIRED_BITBOARDS]);

    // Just want to be able to _quickly_ and _easily_ define scenarios without having
    //   to do a tonne of bitboard logic by hand because FUCK does it take so long
    //   to add tests.
    struct SeededGame {
        game: Game,
        seed: [[Bitboard; 6]; 2],
        has_fog: bool
    }

    impl SeededGame {
        // u4 is the same type as members of `types::BitboardOf`.
        fn init<N>(turn: u1, bb_defs: [BbDef; N], with_fog: bool, en_passant: BitboardIndex) -> Self {
            let seed = [[0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]];

            let (post_seed, bbs) = compute_seeded(seed, bb_defs, with_fog);

            Self {
                game: Game { bbs, army: turn, castle_rights: 0x0000, en_passant, halfmove: 0, fullmove: 1, has_fog: with_fog },
                seed: post_seed, // Saving the seed effectively saves pre-move bitboards per player.
                has_fog: with_fog,
            }
        }

        fn __assert<N>(self, piece: u3, from: BitboardIndex, to: BitboardIndex, promotion: u2, bb_defs: [(u4, u4, Bitboard); N]) -> Self {
            let game_post = self.game.apply(Turn { piece, from, to, promotion_piece: promotion });

            let (seed_post, bbs_post) = compute_seeded(self.seed, bb_defs, self.has_fog);

            crate::test::util::assert_bbs(game_post, bbs_post);

            // Didn't fail an assertion so we can return a new `SeedGame` where the
            //   seed is the move just made.
            Self {
                game: game_post,
                seed: seed_post,
                has_fog: self.has_fog,
            }
        }

        pub fn assert_delta<N>(self, piece: u3, from: BitboardIndex, to: BitboardIndex, bb_defs: [(u4, u4, Bitboard); N]) -> Self {
            self.__assert(piece, from, to, 0, bb_defs)
        }

        // Yes it's not super DRY but it also makes it clearer when writing tests
        //   versus constructing `Turn` (even literally) ourselves.
        pub fn assert_delta_promote<N>(self, piece: u3, from: BitboardIndex, to: BitboardIndex, promote: u2, bb_defs: [(u4, u4, Bitboard); N]) -> Self {
            self.__assert(piece, from, to, promote, bb_defs)
        }
    }

    fn compute_seeded<N>(
        seed: [[u64; 6]; 2],
        bb_defs: [(u4, u4, Bitboard); N],
        with_fog: bool
    ) -> SeededBbs {
        check_count_bb_tups(N);

        let mut sded = seed;

        // Compute sded bitboards by overriding bitboards with ones given to us.
        for tup in bb_defs {
            let (player, piece, bb): (u4, u4, Bitboard) = tup;

            // Magic number 2 is pieces offset (first two bitboards are white and black).
            sded[player][piece - 2] = bb;
        }

        let w = sded[0][0] | sded[0][1] | sded[0][2] | sded[0][3] | sded[0][4] | sded[0][5];
        let b = sded[1][0] | sded[1][1] | sded[1][2] | sded[1][3] | sded[1][4] | sded[1][5];

        let bbs = [
            w,
            b,
            sded[0][0] | sded[1][0],
            sded[0][1] | sded[1][1],
            sded[0][2] | sded[1][2],
            sded[0][3] | sded[1][3],
            sded[0][4] | sded[1][4],
            sded[0][5] | sded[1][5],

            if with_fog {
                dep::state::game::compute_fog(w, b)
            } else {
                0xFFFFFFFFFFFFFFFF // Max u64.
            }
        ];

        (sded, bbs)
    }

    // Internal to `mod SeedGame`.
    fn check_count_bb_tups(given: u64) {
        let max: u64 = 12; // 6 possible pices to set bitboards for * 2 players = 12.

        if given == 0 {
            assert(false, "Need at least 1 (player, piece, bb) tuple");
        } else if given > max {
            // Cannot template assertion messages.
            println(f"At most can receive {max} (player, piece, bb) tuples, received {given}");
            assert(false, "Too many (player, piece, bb) tuples given");
        }
    }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- INTERNAL HELPERS

// Internal to this file.
fn check_count_bbs(given: u64) {
    let max = REQUIRED_BITBOARDS as u64; // Cannot use in println as `REQUIRED_BITBOARDS`.

    if given == 0 {
        assert(false, "Need at least 1 Bitboard");
    } else if given > max {
        // Cannot template assertion messages.
        println(f"At most can receive {max} Bitboards, given {given}");
        assert(false, "Too many Bitboards given");
    }
}
