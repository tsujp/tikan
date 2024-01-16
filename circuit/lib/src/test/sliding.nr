use dep::std::println;
use crate::test::util::assert_bbs;
use dep::state::types::{Game, Turn, Move, Piece, Promote, Bitboard, BitboardIndex, Sliding};

//
// Tests for sliding pieces (rook, bishop, queen, king). All these pieces share
//   the same move-check logic so a test on one is a test for all with the
//   exception of the king which requires an additional small mask to create the
//   correct 1-chebyshev distance move restriction.
//

// ---------------------------------------------------------------------------

// BOARD_SCENARIOS: Diag-slider boards.

// TODO: SL_01 and SL_02 from a generic/helper itself etc?

global PAWN_START_RANKS: [BitboardIndex; 16] = [
    8, 9, 10, 11, 12, 13, 14, 15,
    48, 49, 50, 51, 52, 53, 54, 55
];

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

// Pawn starting ranks for white and black.
global SL_P_01: Game = Game {
    bbs: [ 0xFF00, 0xFF000000000000, 0, 0, 0, 0, 0, 0xFF00000000FF00 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// Same as SL_P_01 except black's turn.
// TODO: A way to make games more easily, generic.
global SL_P_02: Game = Game {
    bbs: [ 0xFF00, 0xFF000000000000, 0, 0, 0, 0, 0, 0xFF00000000FF00 ],
    army: 1, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// Pawns for both sides have all made a single push.
global SL_P_03: Game = Game {
    bbs: [ 0xFF0000, 0xFF0000000000, 0, 0, 0, 0, 0, 0xFF0000FF0000 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// Same as SL_P_03 except black's turn.
global SL_P_04: Game = Game {
    bbs: [ 0xFF0000, 0xFF0000000000, 0, 0, 0, 0, 0, 0xFF0000FF0000 ],
    army: 1, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

// XXX: Test helper only.
fn slp03(from: BitboardIndex, to: BitboardIndex) {
    let _ = SL_P_03.apply(Turn { piece: Piece::PAWN, from, to, promotion_piece: 0 });
}

// XXX: Test helper only.
fn slp04(from: BitboardIndex, to: BitboardIndex) {
    let _ = SL_P_04.apply(Turn { piece: Piece::PAWN, from, to, promotion_piece: 0 });
}

// ---------------- SL_P_07

// [RANK]                        [INDICES]

//    8     bR 56  bN 57  bB 58  bQ 59  bK 60  bB 61  bN 62  bR 63
//    7      . 48   . 49   . 50   . 51  bP 52   . 53   . 54   . 55
//    6      . 40  bP 41  bP 42  bP 43   . 44   . 45   . 46   . 47
//    5     wP 32   . 33  wP 34  wP 35   . 36  bP 37  wP 38  bP 39
//    4      . 24  wP 25   . 26   . 27  wP 28   . 29   . 30  wP 31
//    3      . 16   . 17   . 18   . 19   . 20   . 21   . 22   . 23
//    2      .  8   .  9   . 10   . 11   . 12   . 13   . 14   . 15
//    1     wR  0  wN  1  wB  2  wQ  3  wK  4  wB  5  wN  6  wR  7

//           a      b      c      d      e      f      g      h      [FILE]

// Pawn diag capture scenarios; white to move.
global SL_P_07: Game = Game {
    bbs: [ 0x4D920000FF, 0xFF100EA000000000, 0x4200000000000042, 0x2400000000000024, 0x8100000000000081, 0x0800000000000008, 0x1000000000000010, 0x100EED92000000 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1
};

fn slp07(from: BitboardIndex, to: BitboardIndex) -> Game {
    SL_P_07.apply(Turn { piece: Piece::PAWN, from, to, promotion_piece: 0 })
}

// Curry a game and a piece for further (simple) tests.
// fn _cur<Env>(game: Game, piece: u3) {}
// fn _ting(wat: Field) -> fn[(Field, Field, Field)](Field) -> Field {
//     let a = 0;
//     let b = 0;
//     let c = wat; // `c` is arg to `_ting`

//     // `foo` is arg to returned lambda `x`.
//     |foo| a + b + foo + blah
// }
// let x = _ting(3);
// let y = x(1);
// println(y);

// Immutable `C`urried `C`losure.
// Curried parameters `game` and `piece` are always the same for each call to the
//   lambda returned by this function; meaning many test cases can be made
//   against the same base state.
// If the new state is desired one can bind the return value and invoke `.apply`.
fn _cc(game: Game, piece: u3) -> fn[(Game, u3)](BitboardIndex, BitboardIndex) -> Game {
    |from, to| game.apply(Turn { piece, from, to, promotion_piece: 0 })
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
// #[test]
// fn empty_board__diagonal__north_edge__south() {
//     println("foo");
//     // 0x10708c48548eaa21

//     // Omega dense all pawns: 9077c276d3f29635

//     let board = Game {
//         // bbs: [ 0x10708c48548eaa21, 0, 0, 0x10708c48548eaa21, 0, 0, 0, 0 ],
//         bbs: [0x9077c276d3f29635, 0, 0, 0x9077c276d3f29635, 0, 0, 0, 0],
//         army: 0,
//         castle_rights: 0x0000,
//         en_passant: 0,
//         halfmove: 0,
//         fullmove: 1
//     };

//     let new_board = board.apply(
//         Turn {
//         piece: Piece::BISHOP,
//         //
//         // from: 52,
//         // to: 10,
//         //
//         // from: 23,
//         // to: 0,
//         //
//         // from: 22,
//         // to: 4,
//         // diagonal
//         // from: 4,
//         // to: 31,
//         // anti-diagonal
//         // from: 50,
//         // to: 16,
//         // diagonal
//         from: 20,
//         to: 27,
//         promotion_piece: 0
//     }
//     );
// }

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
// ---------------------------------------------- PAWN EMPTY BOARD

// ---------------- White and black diagonal captures.
#[test]
fn pawn_empty_01() {
    let g = Game {
        bbs: [
            0x8000000,
            0x1000000000,
            0,
            0,
            0,
            0,
            0,
            0x1008000000
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    let c1 = g.apply(
        Turn {
        piece: Piece::PAWN,
        from: 27, // d4
        to: 36, // e5
        promotion_piece: 0
    }
    );
}

// #[test]
// fn pawxn_xx() {
//     let game = SL_P_01;
//     let piece = Piece::PAWN;

//     println(f"");

//     // White sut.
//     let sut_white = _cc(game, piece);
//     // println("----------- WHITE DOUBLE HOME");
//     // let w_double = sut_white(9, 25); // b2 -> b4.
//     // println(w_double);

//     let sut_black = _cc(SL_P_02, piece);
//     println("----------- BLACK DOUBLE HOME");
//     let b_double = sut_black(54, 38); // g7 -> g5.
//     println(b_double);
//     println("----------- BLACK SINGLE HOME");
//     let b_single = sut_black(50, 42); // c7 -> c6.
//     println(b_single);
//     println("----------- WHITE DOUBLE HOME"); // b2 -> b4.
//     let w_double_home = b_single.apply(Turn { piece, from: 9, to: 25, promotion_piece: 0 });
//     println(w_double_home);
//     println("----------- BLACK SINGLE AWAY");
//     let b_single_away = w_double_home.apply(Turn { piece, from: 42, to: 34, promotion_piece: 0 });
//     // let b_single_away = sut_black(44, 36); // e6 -> e5.
//     println(b_single_away);
// }

// ---------------------------------------------------------------------------
// ---------------------------------------------- PAWN DENSE BOARD

// ---------------- White and black diagonal captures.
#[test]
fn pawn_dense_01() {
    let c1 = slp07(34, 43);
}

// ---------------- White and black anti-diagonal captures.
// TODO:

// ---------------------------------------------------------------------------
// ---------------------------------------------- KING ILLEGAL (MOVE PATTERN)

// ---------------- Scenario 2

#[test(should_fail_with = "KING move DIAGONAL PATTERN")]
fn king_dense_pattern_03_s02() {
    // Attempt to move two squares north-east.
    sl02(34, 52);
}

// TODO: More dense tests?

// ---------------- Scenario 3

#[test(should_fail_with = "KING move VERTICAL PATTERN")]
fn king_empty_pattern_01_s03() {
    sl03(20, 36); // n (e3 -> e5)
}

#[test(should_fail_with = "KING move DIAGONAL PATTERN")]
fn king_empty_pattern_02_s03() {
    sl03(20, 38); // ne
}

#[test(should_fail_with = "KING move HORIZONTAL PATTERN")]
fn king_empty_pattern_03_s03() {
    sl03(20, 22); // e
}

#[test(should_fail_with = "KING move ANTI DIAGONAL PATTERN")]
fn king_empty_pattern_04_s03() {
    sl03(20, 6); // se
}

#[test(should_fail_with = "KING move VERTICAL PATTERN")]
fn king_empty_pattern_05_s03() {
    sl03(20, 4); // s
}

#[test(should_fail_with = "KING move DIAGONAL PATTERN")]
fn king_empty_pattern_06_s03() {
    sl03(20, 2); // sw
}

#[test(should_fail_with = "KING move HORIZONTAL PATTERN")]
fn king_empty_pattern_07_s03() {
    sl03(20, 18); // w
}

#[test(should_fail_with = "KING move ANTI DIAGONAL PATTERN")]
fn king_empty_pattern_08_s03() {
    sl03(20, 34); // nw
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- KING ILLEGAL (BLOCKED)

#[test(should_fail_with = "SLIDER move HORIZONTAL BLOCKED")]
fn king_dense_blocked_01_s02() {
    sl02(49, 48);
}

#[test(should_fail_with = "SLIDER move HORIZONTAL BLOCKED")]
fn king_dense_blocked_02_s02() {
    sl02(49, 50);
}

// TODO: Moar king dense?
// TODO: King minimal blocked.

// ---------------------------------------------------------------------------
// ---------------------------------------------- PAWN ILLEGAL (MOVE PATTERN)

// ---------------- Scenario P 3

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_01_slp03() {
    slp03(16, 32); // Double vertical.
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_02_slp03() {
    slp03(16, 40); // Triple vertical.
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_03_slp03() {
    slp03(16, 48); // Quadruple vertical.
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_04_slp03() {
    slp03(16, 56); // Quintuple vertical.
}

#[test(should_fail_with = "PAWN move DIRECTION PATTERN")]
fn pawn_empty_pattern_05_slp03() {
    slp03(16, 8); // Backwards single vertical.
}

#[test(should_fail_with = "PAWN move DIRECTION PATTERN")]
fn pawn_empty_pattern_06_slp03() {
    slp03(16, 0); // Backwards double vertical.
}

#[test(should_fail_with = "PAWN move DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_07_slp03() {
    slp03(16, 25); // Diagonal (no capture) single.
}

#[test(should_fail_with = "PAWN move DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_08_slp03() {
    slp03(16, 34); // Diagonal (no capture) double.
}

#[test(should_fail_with = "PAWN move ANTI-DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_09_slp03() {
    slp03(18, 25); // Anti-diagonal (no capture) single.
}

#[test(should_fail_with = "PAWN move ANTI-DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_10_slp03() {
    slp03(18, 32); // Anti-diagonal (no capture) double.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN")]
fn pawn_empty_pattern_11_slp03() {
    slp03(16, 17); // Purely horizontal eastwards single.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN)]
fn pawn_empty_pattern_12_slp03() {
    slp03(17, 16); // Purely horizontal westwards single.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN")]
fn pawn_empty_pattern_13_slp03() {
    slp03(16, 23); // Purely horizontal eastwards septuple.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN")]
fn pawn_empty_pattern_14_slp03() {
    slp03(23, 16); // Purely horizontal westwards septuple.
}

// ---------------- Scenario P 4

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_01_slp04() {
    slp04(40, 24); // Double vertical.
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_02_slp04() {
    slp04(40, 16); // Triple vertical.
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_03_slp04() {
    slp04(40, 8); // Quadruple vertical.
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_empty_pattern_04_slp04() {
    slp04(40, 0); // Quintuple vertical.
}

#[test(should_fail_with = "PAWN move DIRECTION PATTERN")]
fn pawn_empty_pattern_05_slp04() {
    slp04(40, 48); // Backwards single vertical.
}

#[test(should_fail_with = "PAWN move DIRECTION PATTERN")]
fn pawn_empty_pattern_06_slp04() {
    slp04(40, 56); // Backwards double vertical.
}

#[test(should_fail_with = "PAWN move DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_07_slp04() {
    slp04(47, 38); // Diagonal (no capture) single.
}

#[test(should_fail_with = "PAWN move DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_08_slp04() {
    slp04(47, 29); // Diagonal (no capture) double.
}

#[test(should_fail_with = "PAWN move ANTI-DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_09_slp04() {
    slp04(40, 33); // Anti-diagonal (no capture) single.
}

#[test(should_fail_with = "PAWN move ANTI-DIAGONAL CAPTURE PATTERN")]
fn pawn_empty_pattern_10_slp04() {
    slp04(40, 26); // Anti-diagonal (no capture) double.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN")]
fn pawn_empty_pattern_11_slp04() {
    slp04(40, 41); // Purely horizontal eastwards single.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN)]
fn pawn_empty_pattern_12_slp04() {
    slp04(41, 40); // Purely horizontal westwards single.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN")]
fn pawn_empty_pattern_13_slp04() {
    slp04(40, 47); // Purely horizontal eastwards septuple.
}

#[test(should_fail_with = "PAWN move HORIZONTAL PATTERN")]
fn pawn_empty_pattern_14_slp04() {
    slp04(47, 40); // Purely horizontal westwards septuple.
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- GENERAL ILLEGAL (BLOCKED)

#[test(should_fail_with = "SLIDER move ANTI DIAGONAL BLOCKED")]
fn general_dense_blocked_s01() {
    sl01(49, 21);
}

#[test(should_fail_with = "PAWN move MULTI-PUSH PATTERN")]
fn pawn_en_passant_pattern_07() {
    // White has just double pushed a pawn etc etc same as the scenarios
    //   immediately above.
    let g = Game {
        bbs: [
            0x55AA00FF,
            0xFF00AA5500000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xFF00AA5555AA00FF
        ],
        army: 1,
        castle_rights: 15,
        en_passant: 18, // c3
        halfmove: 0,
        fullmove: 1
    };

    // Black illegal en-passant capture (slides through same file to en-passant
    //   target square).
    let _ = g.apply(
        Turn {
        piece: Piece::PAWN,
        from: 34, // c5
        to: 18, // c3
        promotion_piece: 0
    }
    );
}

// ---------------------------------------------------------------------------
// ---------------------------------------------- PAWN SPECIAL (EP TARGET)

// ---------------------------------------------------------------------------
// ---------------------------------------------- KING / ROOK SPECIAL (CASTLE)

#[test]
fn king_side_castle_TODO() {
    // TODO: White and black.
}

#[test]
fn queen_side_castle_TODO() {
    // TODO: White and black.
}
