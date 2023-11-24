use dep::std::println;

use dep::state::board::Board;
use dep::state::move::Move;
use dep::state::types::{Piece, Bitboard, BitboardIndex};

use crate::test::util::dump_gamestate;


#[test]
fn empty_board__diagonal__north_edge__south () {
    println("foo");
    // 0x10708c48548eaa21

    let board = Board {
        // bbs: [ 0x10708c48548eaa21, 0, 0, 0x10708c48548eaa21, 0, 0, 0, 0 ],
        bbs: [ 0x107080405086a221, 0, 0, 0x107080405086a221, 0, 0, 0, 0 ],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    let new_board = board.apply(Move {
        piece: Piece::BISHOP,
        // from: 17,
        from: 52,
        to: 10,
        promotion_piece: 0
    });
}


// #[test]
// fn empty_board__anti_diagonal__north_edge__south () {

// }

// Test helper only.
fn _rom (
    bishop_bb: Bitboard,
    from: BitboardIndex,
    to: BitboardIndex,
    check_bb: Bitboard
) {   
    let board = Board {
        bbs: [ bishop_bb, 0, 0, bishop_bb, 0, 0, 0, 0 ],
        army: 0,
        castle_rights: 0x0000,
        en_passant: 0,
        halfmove: 0,
        fullmove: 1
    };

    let new_board = board.apply(Move {
        piece: Piece::BISHOP,
        from: from,
        to: to,
        promotion_piece: 0
    });

    let expected_bbs = [ check_bb, 0, 0, check_bb, 0, 0, 0, 0 ];

    let mut does_match = true;

    for bb in 0 .. expected_bbs.len() {
        does_match &= (expected_bbs[bb] == new_board.bbs[bb]);
    }

    assert(does_match, "Invalid BISHOP movement on empty board");
}

// TODO: Rename this, test upward mask has no overflow.
#[test]
fn no_positive_overflow () {
    // Along anti-diagonal.
    _rom(0x01, 0, 63, 0x8000000000000000);
    _rom(0x0200, 9, 63, 0x8000000000000000);
    _rom(0x040000, 18, 63, 0x8000000000000000);
    _rom(0x08000000, 27, 63, 0x8000000000000000);
    _rom(0x1000000000, 36, 63, 0x8000000000000000);
    _rom(0x200000000000, 45, 63, 0x8000000000000000);
    _rom(0x40000000000000, 54, 63, 0x8000000000000000);

    // TODO: Move this one to a should fail (it's only here to visualise for now and should fail later on).
    _rom(0x8000000000000000, 63, 63, 0x8000000000000000);
}
