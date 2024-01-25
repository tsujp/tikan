use dep::std::println;

use dep::state::game::Game;
use dep::state::turn::Turn;
use dep::state::types::{Piece, Bitboard, BitboardIndex};

use crate::test::util::dump_gamestate;

// BOARD_SCENARIOS: Rook boards.

// Rook movement is very limited; can move west and south two squres, and north
//   and east one square.
//
// [RANK]                        [INDICES]
//
//    8      . 56   . 57   . 58   . 59  bP 60   . 61   . 62   . 63
//    7      . 48   . 49   . 50   . 51  bP 52   . 53   . 54   . 55
//    6      . 40   . 41   . 42   . 43  wN 44   . 45   . 46   . 47
//    5      . 32   . 33   . 34   . 35   . 36   . 37   . 38   . 39
//    4     bP 24   . 25  bP 26   . 27  wR 28  bP 29   . 30   . 31
//    3      . 16   . 17   . 18   . 19   . 20   . 21   . 22   . 23
//    2      .  8   .  9   . 10   . 11  bP 12   . 13   . 14   . 15
//    1      .  0   .  1   .  2   .  3   .  4   .  5   .  6   .  7
//
//           a      b      c      d      e      f      g      h      [FILE]
global R_S_03: Game = Game {
    bbs: [ 0x100030000000, 0x1010000025001000, 0x100020000000, 0, 0x10000000, 0, 0, 0x1010000025001000 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
};

// Rook movement is very limited; cannot move west at all, can move north and east
//   one square and south two squares.
//
// [RANK]                        [INDICES]
//
//    8      . 56   . 57   . 58   . 59  bP 60   . 61   . 62   . 63
//    7      . 48   . 49   . 50   . 51  bP 52   . 53   . 54   . 55
//    6      . 40   . 41   . 42   . 43  wN 44   . 45   . 46   . 47
//    5      . 32   . 33   . 34   . 35   . 36   . 37   . 38   . 39
//    4      . 24   . 25   . 26  wN 27  wR 28  bP 29  wN 30   . 31
//    3      . 16   . 17   . 18   . 19   . 20   . 21   . 22   . 23
//    2      .  8   .  9   . 10   . 11  bP 12   . 13   . 14   . 15
//    1      .  0   .  1   .  2   .  3  wN  4   .  5   .  6   .  7
//
//           a      b      c      d      e      f      g      h      [FILE]
global R_S_04: Game = Game {
    bbs: [ 0x100058000010, 0x1010000020001000, 0x100048000010, 0, 0x10000000, 0, 0, 0x1010000020001000 ],
    army: 0, castle_rights: 0x0000, en_passant: 0, halfmove: 0, fullmove: 1,
};

// GLOSSARY: Rook tests.

// ROOK_BL_03: Rook at e4 (28) tries to move west through enemy piece (not directly
//             next to it).
// ROOK_BL_04: Rook at e4 (28) tries to move west through a friendly knight directly
//             next to it.
// ROOK_BL_
// ROOK_BL_
// ROOK_BL_
// ROOK_BL_
// ROOK_BL_

// Test helper only.
fn _rom(rook_bb: Bitboard, from: BitboardIndex, to: BitboardIndex, check_bb: Bitboard) {
    let board = Game {
        bbs: [rook_bb, 0, 0, 0, rook_bb, 0, 0, 0],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    let new_board = board.apply(Turn { piece: Piece::ROOK, from, to, promotion_piece: 0 });

    let expected_bbs = [check_bb, 0, 0, 0, check_bb, 0, 0, 0];

    let mut does_match = true;

    for bb in 0..expected_bbs.len() {
        does_match &= (expected_bbs[bb] == new_board.bbs[bb]);
    }

    assert(does_match, "Invalid ROOK movement on empty board");
}

#[test(should_fail)]
fn rook__empty_board__illegal() {
    // Rook on a8 should not be able to "move" onto it's own square.
    _rom(0x0100000000000000, 56, 56, 0x0100000000000000); // a8

    // Rook on a8 should not be able to "move" diagonally like a bishop.
    _rom(0x0100000000000000, 56, 49, 0x02000000000000); // b7
    // TODO: Rest of that diagonal, c6, d5 etc.

    _rom(0x01, 0, 0, 0x01); // a1
}

// Rook on a8 can move VERTICALLY SOUTH on file (a7 - a1) at WEST-EDGE of board.
#[test]
fn empty_board__vertical__west_edge__south() {
    _rom(0x0100000000000000, 56, 48, 0x01000000000000); // a7
    _rom(0x0100000000000000, 56, 40, 0x010000000000); // a6
    _rom(0x0100000000000000, 56, 32, 0x0100000000); // a5
    _rom(0x0100000000000000, 56, 24, 0x01000000); // a4
    _rom(0x0100000000000000, 56, 16, 0x010000); // a3
    _rom(0x0100000000000000, 56, 8, 0x0100); // a2
    _rom(0x0100000000000000, 56, 0, 0x01); // a1
}

#[test]
fn empty_board__vertical__west_edge__north() {
    // Rook on a1 can move VERTICALLY NORTH on file (a2 - a8) at WEST-EDGE of board.
    _rom(0x01, 0, 8, 0x0100); // a2
    _rom(0x01, 0, 16, 0x010000); // a3
    _rom(0x01, 0, 24, 0x01000000); // a4
    _rom(0x01, 0, 32, 0x0100000000); // a5
    _rom(0x01, 0, 40, 0x010000000000); // a6
    _rom(0x01, 0, 48, 0x01000000000000); // a7
    _rom(0x01, 0, 56, 0x0100000000000000); // a8
}

#[test]
fn empty_board__vertical__east_edge__south() {
    // Rook on h8 can move VERTICALLY SOUTH on file (h7 - h1) at EAST-EDGE of board.
    _rom(0x8000000000000000, 63, 55, 0x80000000000000); // h7
    _rom(0x8000000000000000, 63, 47, 0x800000000000); // h6
    _rom(0x8000000000000000, 63, 39, 0x8000000000); // h5
    _rom(0x8000000000000000, 63, 31, 0x80000000); // h4
    _rom(0x8000000000000000, 63, 23, 0x800000); // h3
    _rom(0x8000000000000000, 63, 15, 0x8000); // h2
    _rom(0x8000000000000000, 63, 7, 0x80); // h1
}

#[test]
fn empty_board__vertical__east_edge__north() {
    // Rook on h1 can move VERTICALLY NORTH on file (h2 - h8) at EAST-EDGE of board.
    _rom(0x80, 7, 15, 0x8000); // h2
    _rom(0x80, 7, 23, 0x800000); // h3
    _rom(0x80, 7, 31, 0x80000000); // h4
    _rom(0x80, 7, 39, 0x8000000000); // h5
    _rom(0x80, 7, 47, 0x800000000000); // h6
    _rom(0x80, 7, 55, 0x80000000000000); // h7
    _rom(0x80, 7, 63, 0x8000000000000000); // h8
    // Rook on XX can move VERTICALLY NORTH AND SOUTH on file (xx - xx) in the MIDDLE
    //   of the board.
    // TODO
}

// #[test]
// fn empty_board__horizontal__north_edge__east () {
//     // Rook on a8 can move HORIZONTALLY EAST on rank (b8 - h8) at NORTH-EDGE of board.
//     _rom(0x0100000000000000, 56, 57, 0x0200000000000000); // b8
//     _rom(0x0100000000000000, 56, 58, 0x0400000000000000); // c8
//     _rom(0x0100000000000000, 56, 59, 0x0800000000000000); // d8
//     _rom(0x0100000000000000, 56, 60, 0x1000000000000000); // e8
//     _rom(0x0100000000000000, 56, 61, 0x2000000000000000); // f8
//     _rom(0x0100000000000000, 56, 62, 0x4000000000000000); // g8
//     _rom(0x0100000000000000, 56, 63, 0x8000000000000000); // h8

//     // Rook on h8 can move HORIZONTALL WEST on rank (g8 - a8) NORTH-EDGE top of board.
//     // TODO

//     // Rook on a1 can move HORIZONTALLY EAST on rank (b1 - h1) at SOUTH-EDGE of board.
//     // TODO

//     // Rook on h1 can move HORIZONTALLY WEST on rank (g1 - a1) at SOUTH-EDGE of board.
//     // TODO

//     // Rook on d5 can move HORIZONTALLY EAST AND WEST on rank (a5 - c5; e5 - h5) in
//     //   the MIDDLE of the board.
//     _rom(0x0800000000, 35, 32, 0x0100000000); // a5
//     _rom(0x0800000000, 35, 33, 0x0200000000); // b5
//     _rom(0x0800000000, 35, 34, 0x0400000000); // c5
//     _rom(0x0800000000, 35, 36, 0x1000000000); // e5
//     _rom(0x0800000000, 35, 37, 0x2000000000); // f5
//     _rom(0x0800000000, 35, 38, 0x4000000000); // g5
//     _rom(0x0800000000, 35, 39, 0x8000000000); // h5

//     // TODO: Unobstructed movement.
//     // TODO: Turn north-south.
//     // TODO: Turn east-west.
//     // TODO: Castling.
// }

// XXX: Expected failure tests must be in individual functions, after the first
//      (expected) failure subsequent logic does not execute.
#[test(should_fail_with = "ROOK move HORIZONTAL is INVALID")]
fn test_rook_blocked_1() {
    let block_1 = Game {
        bbs: [
            0x20000021000000,
            0x200020000a002020,
            0x20000001000000,
            0,
            0x20000000,
            0,
            0,
            0x200020000a002020
        ],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };
    // Rook tries to move west through enemy piece (some gap between them) v1.
    let _ = block_1.apply(
        Turn {
            piece: Piece::ROOK,
            from: 29, // f4
            to: 24, // a4
            promotion_piece: 0
        }
    );
}

#[test(should_fail_with = "ROOK move HORIZONTAL is INVALID")]
fn test_rook_blocked_2() {
    let block_2 = Game {
        bbs: [
            0x25000000,
            0x2000200082002020,
            0x05000000,
            0,
            0x20000000,
            0,
            0,
            0x2000200082002020
        ],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };
    // Rook tries to move west through friendly piece (some gap between them) v1.
    let _ = block_2.apply(
        Turn {
            piece: Piece::ROOK,
            from: 29, // f4
            to: 24, // a4
            promotion_piece: 0
        }
    );
}

#[test(should_fail_with = "ROOK move HORIZONTAL is INVALID")]
fn test_rook_blocked_3() {
    // ROOK_BL_03
    let _ = R_S_03.apply(
        Turn {
            piece: Piece::ROOK,
            from: 28, // e4
            to: 24, // a4
            promotion_piece: 0
        }
    );
}

#[test(should_fail_with = "ROOK move HORIZONTAL is INVALID")]
fn test_rook_blocked_4() {
    // ROOK_BL_04
    let _ = R_S_04.apply(
        Turn {
            piece: Piece::ROOK,
            from: 28, // e4
            to: 24, // a4
            promotion_piece: 0
        }
    );
}

// TODO: This currently passes when it should fail as vertical isnt done.
// #[test(should_fail_with = "ROOK move is INVALID")]
// fn test_rook_blocked_5() {
//     let block_5 = Game {
//         bbs: [
//             0x100000100000,
//             0,
//             0x100000,
//             0,
//             0x100000000000,
//             0,
//             0,
//             0
//         ],
//         army: 0,
//         castle_rights: 0x0000,
//         en_passant: 0,
//         halfmove: 0,
//         fullmove: 1,
//     };
//     // Rook tries to move vertically through friendly piece.
//     let rb5 = block_5.apply(Turn {
//         piece: Piece::ROOK,
//         from: 44,
//         to: 20,
//         promotion_piece: 0,
//     });
// }

// TODO: Whatever this is
// #[test(should_fail_with = "ROOK move is INVALID")]
// fn test_rook_blocked_5() {
// let w6 = Game {
//     bbs: [
//         0x100000000000,
//         0,
//         0,
//         0,
//         0x100000000000,
//         0,
//         0,
//         0
//     ],
//     army: 0,
//     castle_rights: 0x0000,
//     en_passant: 0,
//     halfmove: 0,
//     fullmove: 1,
// };
// Rook should be prevented from moving through enemy pieces.
// let rb6 = w6.apply(Turn {
//     piece: Piece::ROOK,
//     // from: 28, // e4
//     // to: 24,   // a4
//     from: 44,
//     to: 40,
//     promotion_piece: 0,
// });
// }
