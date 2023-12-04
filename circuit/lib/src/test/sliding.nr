use dep::std::println;
use crate::test::util::dump_gamestate;

use dep::state::types::{Game, Turn, Move, Piece, Bitboard, BitboardIndex, Sliding};

//
// Tests for sliding pieces (rook, bishop, queen, king). All these pieces share
//   the same move-check logic so a test on one is a test for all with the
//   exception of the king which requires an additional small mask to create the
//   correct 1-taxicab distance move restriction.
//

// ---------------------------------------------------------------------------

// BOARD_SCENARIOS: Diag-slider boards.

// TODO: SL_01 and SL_02 from a generic/helper itself etc?

// TODO: Paste in board from bb_term.
// Board consists of many pawns with but a few diag-sliders. Movement is fairly
//   restricted. All pawns are black, all sliders are white.
global SL_01: Game = Game {
    bbs: [ 0x27004400009630, 0x9050c232d3f20005, 0, 0, 0, 0x27004400009630, 0, 0x9077c276d3f29635 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// XXX: Test helper only.
fn sl01(from: BitboardIndex, to: BitboardIndex) {
    let _ = SL_01.apply(Turn { piece: Piece::QUEEN, from, to, promotion_piece: 0 });
}

// TODO: Paste in board from bb_term.
// Same as 01 except sliders are kings and not queens.
global SL_02: Game = Game {
    bbs: [ 0x27004400009630, 0x9050c232d3f20005, 0, 0, 0, 0, 0x27004400009630, 0x9077c276d3f29635 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// XXX: Test helper only.
fn sl02(from: BitboardIndex, to: BitboardIndex) {
    let _ = SL_02.apply(Turn { piece: Piece::KING, from, to, promotion_piece: 0 });
}

// King at e3 (20) on empty board.
global SL_03: Game = Game {
    bbs: [ 0x100000, 0, 0, 0, 0, 0, 0x100000, 0 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// XXX: Test helper only.
fn sl03(from: BitboardIndex, to: BitboardIndex) {
    let _ = SL_03.apply(Turn { piece: Piece::KING, from, to, promotion_piece: 0 });
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- RANKIFIED SLIDING DATA

#[test]
fn rankified_sliding_data_01() {
    // TODO: Bug report the LSP error isn't good when using `f` and `t` here, it says it expects an expression for `piece:` even though the error is the shorthand struct field assignment names being wrong for `from` and `to`.

    // e3 -> e5 (north) = 20 -> 36.
    let (dir, rd) = Move::TEST_ONLY_rankified_sliding_data(
        SL_03,
        Turn { piece: Piece::KING, from: 20, to: 36, promotion_piece: 0 }
    );

    assert(dir == Sliding::VERTICAL);

    // Rotating clockwise 90-degrees from/to should be 2 and 4 respectively.
    assert(rd.from == 2);
    assert(rd.to == 4);
}

// ---------------------------------------------------------------------------

// TODO: CLEANUP THIS FROM HERE ...
#[test]
fn empty_board__diagonal__north_edge__south() {
    println("foo");
    // 0x10708c48548eaa21

    // Omega dense all pawns: 9077c276d3f29635

    let board = Game {
        // bbs: [ 0x10708c48548eaa21, 0, 0, 0x10708c48548eaa21, 0, 0, 0, 0 ],
        bbs: [0x9077c276d3f29635, 0, 0, 0x9077c276d3f29635, 0, 0, 0, 0],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    let new_board = board.apply(
        Turn {
            piece: Piece::BISHOP,
            //
        // from: 52,
        // to: 10,
        //
        // from: 23,
        // to: 0,
        //
        // from: 22,
        // to: 4,
        // diagonal
        // from: 4,
        // to: 31,
        // anti-diagonal
        // from: 50,
        // to: 16,
        // diagonal
            from: 20,
            to: 27,
            promotion_piece: 0
        }
    );
}

// #[test]
// fn empty_board__anti_diagonal__north_edge__south () {

// }
// TODO: ... TO HERE (END CLEANUP)

// ---------------------------------------------------------------------------

// Test helper only.
fn _rom(bishop_bb: Bitboard, from: BitboardIndex, to: BitboardIndex, check_bb: Bitboard) {
    let board = Game {
        bbs: [bishop_bb, 0, 0, bishop_bb, 0, 0, 0, 0],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    let new_board = board.apply(Turn { piece: Piece::BISHOP, from, to, promotion_piece: 0 });

    let expected_bbs = [check_bb, 0, 0, check_bb, 0, 0, 0, 0];

    let mut does_match = true;

    for bb in 0..expected_bbs.len() {
        does_match &= (expected_bbs[bb] == new_board.bbs[bb]);
    }

    assert(does_match, "Invalid BISHOP movement on empty board");
}

// TODO: Rename this, test upward mask has no overflow.
#[test]
fn no_positive_overflow() {
    // Along anti-diagonal.
    _rom(0x01, 0, 63, 0x8000000000000000);
    _rom(0x0200, 9, 63, 0x8000000000000000);
    _rom(0x040000, 18, 63, 0x8000000000000000);
    _rom(0x08000000, 27, 63, 0x8000000000000000);
    _rom(0x1000000000, 36, 63, 0x8000000000000000);
    _rom(0x200000000000, 45, 63, 0x8000000000000000);
    _rom(0x40000000000000, 54, 63, 0x8000000000000000);
}

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn cannot_nothing_move() {
    _rom(0x01, 0, 0, 0x00);
    _rom(0x0200, 9, 9, 0x00);
    _rom(0x040000, 18, 18, 0x00);
    _rom(0x08000000, 27, 27, 0x00);
    _rom(0x1000000000, 36, 36, 0x00);
    _rom(0x200000000000, 45, 45, 0x00);
    _rom(0x40000000000000, 54, 54, 0x00);
    _rom(0x8000000000000000, 63, 63, 0x00);
}

// TODO: More from S01 in the test body here.
#[test]
fn diag_s01() {
    // Diagonals.
    sl01(48, 57);
    sl01(49, 58);
    sl01(49, 40);
    sl01(50, 59);
    sl01(50, 41);

    // Anti-diagonals.
    sl01(49, 56);
    sl01(49, 42);
    sl01(49, 28);
    sl01(50, 57);
    sl01(50, 43);
    sl01(50, 36);
}

#[test]
fn king_s02() {
    // Will be rankified to u8 then given to valid_rank_move.
    sl02(49, 57);
    sl02(49, 41);

    // Already a rank, given as u64.
    sl02(34, 35);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- KING EMPTY BOARD

#[test]
fn king_s03() {
    // Valid king moves on an empty board.
    sl03(20, 28); // n
    sl03(20, 29); // ne
    sl03(20, 21); // e
    sl03(20, 13); // se
    sl03(20, 12); // s
    sl03(20, 11); // sw
    sl03(20, 19); // w
    sl03(20, 27); // nw
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- KING ILLEGAL (MOVE PATTERN)

// ---------------- Scenario 2

#[test(should_fail_with = "KING move DIAGONAL PATTERN")]
fn king_illegal_03_s02() {
    // Attempt to move two squares north-east.
    sl02(34, 52);
}

// ---------------- Scenario 3

#[test(should_fail_with = "KING move VERTICAL PATTERN")]
fn king_illegal_01_s03() {
    sl03(20, 36); // n (e3 -> e5)
}

#[test(should_fail_with = "KING move DIAGONAL PATTERN")]
fn king_illegal_02_s03() {
    sl03(20, 38); // ne
}

#[test(should_fail_with = "KING move HORIZONTAL PATTERN")]
fn king_illegal_03_s03() {
    sl03(20, 22); // e
}

#[test(should_fail_with = "KING move ANTI DIAGONAL PATTERN")]
fn king_illegal_04_s03() {
    sl03(20, 6); // se
}

#[test(should_fail_with = "KING move VERTICAL PATTERN")]
fn king_illegal_05_s03() {
    sl03(20, 4); // s
}

#[test(should_fail_with = "KING move DIAGONAL PATTERN")]
fn king_illegal_06_s03() {
    sl03(20, 2); // sw
}

#[test(should_fail_with = "KING move HORIZONTAL PATTERN")]
fn king_illegal_07_s03() {
    sl03(20, 18); // w
}

#[test(should_fail_with = "KING move ANTI DIAGONAL PATTERN")]
fn king_illegal_08_s03() {
    sl03(20, 34); // nw
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- KING ILLEGAL (BLOCKED)

#[test(should_fail_with = "SLIDER move HORIZONTAL BLOCKED")]
fn king_illegal_01_s02() {
    sl02(49, 48);
}

#[test(should_fail_with = "SLIDER move HORIZONTAL BLOCKED")]
fn king_illegal_02_s02() {
    sl02(49, 50);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- GENERAL ILLEGAL (BLOCKED)

#[test(should_fail_with = "SLIDER move ANTI DIAGONAL BLOCKED")]
fn general_diag_blocked_s01() {
    sl01(49, 21);
}
