use crate::test::scenario::KNIGHT as K_SCENARIO;
use crate::test::util;
use dep::state::types::Piece;

//
// PASSING KNIGHT TESTS
//

// ---------------------------------------------------------------------------
// ---------------------------------------------- MOVE PATTERN (LEGAL)

#[test]
fn empty_pattern() {
    // a1 to c2.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(0, 10),
        [0x8100000000000480, 0, 0x8100000000000480, 0, 0, 0, 0, 0]
    );
    // a1 to b3.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(0, 17),
        [0x8100000000020080, 0, 0x8100000000020080, 0, 0, 0, 0, 0]
    );
    // a8 to c7.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(56, 50),
        [0x8004000000000081, 0, 0x8004000000000081, 0, 0, 0, 0, 0]
    );
    // a8 to c7.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(56, 41),
        [0x8000020000000081, 0, 0x8000020000000081, 0, 0, 0, 0, 0]
    );
    // h8 to f7.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(63, 53),
        [0x120000000000081, 0, 0x120000000000081, 0, 0, 0, 0, 0]
    );
    // h8 to g6.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(63, 46),
        [0x100400000000081, 0, 0x100400000000081, 0, 0, 0, 0, 0]
    );
    // h1 to f2.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(7, 13),
        [0x8100000000002001, 0, 0x8100000000002001, 0, 0, 0, 0, 0]
    );
    // h1 to g3.
    util::assert_bbs(
        util::cc(K_SCENARIO[0], Piece::KNIGHT)(7, 22),
        [0x8100000000400001, 0, 0x8100000000400001, 0, 0, 0, 0, 0]
    );
}

#[test]
fn dense_pattern() {
    // b3 to c1.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(17, 2),
        [0x8124520008402485, 0, 0x8124520008402485, 0, 0, 0, 0, 0]
    );
    // b3 to a5.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(17, 32),
        [0x8124520108402481, 0, 0x8124520108402481, 0, 0, 0, 0, 0]
    );
    // b3 to c5.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(17, 34),
        [0x8124520408402481, 0, 0x8124520408402481, 0, 0, 0, 0, 0]
    );
    // d4 to b5.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(27, 33),
        [0x8124520200422481, 0, 0x8124520200422481, 0, 0, 0, 0, 0]
    );
    // d4 to f5.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(27, 37),
        [0x8124522000422481, 0, 0x8124522000422481, 0, 0, 0, 0, 0]
    );
    // d4 to f3.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(27, 21),
        [0x8124520000622481, 0, 0x8124520000622481, 0, 0, 0, 0, 0]
    );
    // d4 to e2.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(27, 12),
        [0x8124520000423481, 0, 0x8124520000423481, 0, 0, 0, 0, 0]
    );
    // e6 to g5.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(44, 38),
        [0x8124424008422481, 0, 0x8124424008422481, 0, 0, 0, 0, 0]
    );
    // e6 to f8.
    util::assert_bbs(
        util::cc(K_SCENARIO[2], Piece::KNIGHT)(44, 61),
        [0xa124420008422481, 0, 0xa124420008422481, 0, 0, 0, 0, 0]
    );
}

// TODO: What is this?
#[test]
fn wat() {
    // U64 fillUpOccluded(U64 g, U64 p) {
    //    g |= p & (g <<  8);
    //    p &=     (p <<  8);
    //    g |= p & (g << 16);
    //    p &=     (p << 16);
    //    g |= p & (g << 32);
    //    return g;
    // }

    let mut g: u64 = 0x814e300;
    // let mut p: u64 = 0xe3fff7e30000;
    let mut p: u64 = 0xe3fdf4e00000;

    g |= p & (g <<  8);
    p &=     (p <<  8);
    // g |= p & (g << 16);
    // p &=     (p << 16);
    // g |= p & (g << 32);

    dep::std::println(p);
    dep::std::println(g);
}

// ----------------------------------

use dep::state::types::{Game, REQUIRED_BITBOARDS};
use dep::util::bit_logic as bl;

// TODO: Put in utilities.
// XXX: Test helper only
// fn create_simple<Bitboard, N>(given_bbs: [Bitboard; N]) -> Game {
fn create_simple<N>(given_bbs: [u64; N]) -> Game {
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
    // let mut set_bbs: [Bitboard; REQUIRED_BITBOARDS] = dep::std::unsafe::zeroed();
    let mut bbs: [u64; REQUIRED_BITBOARDS] = [0 as u64; REQUIRED_BITBOARDS];

    for idx in 0..given_bbs.len() {
        bbs[idx] = given_bbs[idx];
        // bbs[idx] = (given_bbs[idx] as u64);
    }

    Game { bbs, army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1 }
}

#[test]
fn fog_mvp_test() {
    // let g1 = create_simple([0x8002200000044001]);

    // XXX: Fog needs to be an intrinsic property on `Game`, i.e. it's now
    //      part of the input and output.

    // This test scenario is just white and blacks bb OR'd which is how
    //   the fog will be computed.

    let all_pieces: u64 = 0x8002200000044001 | 0;

    let all_bits = (all_pieces as Field).to_le_bits(64);

    let mut fog: u64 = 0;

    for i in 0..all_bits.len() {
        let bit = all_bits[i];

        let bit_fog = if bit == 1 {
            bl::taxi_mask((2 as Field).pow_32(i) as u64)
        } else {
            0
        };

        fog |= bit_fog;
        // dep::std::println(f"[{i}] bit: {bit}  /  bit_fog: {bit_fog}");
        // let b_fog = bl::taxi_mask(b);
    }

    dep::std::println(f"final fog: {fog}");

    assert(fog == 0x67FDDF766EFBBFE6);
}

#[test]
fn foobar2() {
    assert(create_simple([0x8002200000044001]).get_fog() == 0x67FDDF766EFBBFE6);
}
