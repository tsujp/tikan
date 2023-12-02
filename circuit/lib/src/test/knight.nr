use dep::std::println;
use crate::test::util::dump_gamestate;

use dep::state::types::{Game, Turn, Piece, Bitboard, BitboardIndex};

//
// Knight tests.
//

// TODO: Tests that a knight can capture a piece and the state of the `Game` afterwards matches (correct pieces removed etc).

// ---------------------------------------------------------------------------

// BOARD_SCENARIOS: Knight boards.

// Board with 4 white rooks in each corner: a1, a8, h8, h1.
global N_01: Game = Game {
    bbs: [ 0x8100000000000081, 0, 0x8100000000000081, 0, 0, 0, 0, 0 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
};

// Board with knights one-move away from each other.
global N_02: Game = Game {
    bbs: [ 0x14000800140000, 0, 0x14000800140000, 0, 0, 0, 0, 0 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
};

// Dense board with lots of (and only) white pieces.
global N_03: Game = Game {
    bbs: [ 0x8124520008422481, 0, 0x8124520008422481, 0, 0, 0, 0, 0 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
};

// XXX: Test helper only.
fn _apply(game: Game, from: BitboardIndex, to: BitboardIndex) {
    let _ = game.apply(Turn { piece: Piece::KNIGHT, from, to, promotion_piece: 0 });
}

// ---------------------------------------------------------------------------

#[test(should_fail_with = "Cannot move onto your own square in the same turn")]
fn cannot_nothing_move() {
    _apply(N_01, 0, 0);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- EMPTY BOARD

#[test]
fn empty_board() {
    // Four corners.
    // -- a1
    _apply(N_01, 0, 10);
    _apply(N_01, 0, 17);

    // -- a8
    _apply(N_01, 56, 50);
    _apply(N_01, 56, 41);

    // -- h8
    _apply(N_01, 63, 53);
    _apply(N_01, 63, 46);

    // -- h1
    _apply(N_01, 7, 13);
    _apply(N_01, 7, 22);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- DENSE BOARD

#[test]
fn dense_board_n03() {
    _apply(N_03, 17, 2);
    _apply(N_03, 17, 32);
    _apply(N_03, 17, 34);
    _apply(N_03, 27, 33);
    _apply(N_03, 27, 37);
    _apply(N_03, 27, 21);
    _apply(N_03, 27, 12);
    _apply(N_03, 44, 38);
    _apply(N_03, 44, 61);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- ILLEGAL (MOVE PATTERN)

// ---------------- Scenario 1

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn empty_board_illegal_01_n01() {
    _apply(N_01, 1, 63);
}

#[test(should_fail_with = "KNIGHT move pattern invalid")]
fn empty_board_illegal_02_n01() {
    _apply(N_01, 0, 35);
}

#[test(should_fail_with = "KNIGHT move pattern invalid")]
fn empty_board_illegal_03_n01() {
    _apply(N_01, 0, 47);
}

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn empty_board_illegal_04_n01() {
    _apply(N_01, 19, 20);
}

// ---------------- Scenario 3

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn dense_board_illegal_01_n03() {
    _apply(N_03, 42, 59);
}

#[test(should_fail_with = "Piece in army does NOT EXIST at given index")]
fn dense_board_illegal_02_n03() {
    _apply(N_03, 21, 31);
}

#[test(should_fail_with = "KNIGHT move pattern invalid")]
fn dense_board_illegal_03_n03() {
    _apply(N_03, 13, 32);
}

#[test(should_fail_with = "KNIGHT move pattern invalid")]
fn dense_board_illegal_04_n03() {
    _apply(N_03, 50, 2);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- ILLEGAL (BLOCKED)

// ---------------- Scenario 2

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn empty_board_blocked_01_n02() {
    _apply(N_02, 35, 52);
}

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn empty_board_blocked_02_n02() {
    _apply(N_02, 35, 50);
}

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn empty_board_blocked_03_n02() {
    _apply(N_02, 35, 20);
}

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn empty_board_blocked_04_n02() {
    _apply(N_02, 35, 18);
}

// ---------------- Scenario 3

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn dense_board_blocked_01_n03() {
    _apply(N_03, 44, 27);
}

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn dense_board_blocked_02_n03() {
    _apply(N_03, 44, 50);
}

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn dense_board_blocked_03_n03() {
    _apply(N_03, 10, 27);
}

#[test(should_fail_with = "KNIGHT cannot capture friendly pieces")]
fn dense_board_blocked_04_n03() {
    _apply(N_03, 17, 27);
}
