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
