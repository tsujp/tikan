use dep::std::println;
use dep::std::collections::vec::Vec;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Board, Move, Piece};

// XXX: While we can use structs as _input_ to main we cannot use them as output
//      so while we take structs in (much easier) we can only return the
//      decomposed version of Board as output for now.
fn main(
    // [BOARD] Current before-move gamestate.
    board: pub Board,
    // [MOVE] Players private move to alter that gamestate and return new
    //   gamestate.
    move: Move,
    move_salt: pub Field,
    move_commitment: pub Field
) -> pub [Field; 13] {
    // `Board` has assertions that check a `Move` is valid against the current
    //   gamestate (which `Board` represents); so this will fail if invalid.
    let new_board = board.apply(move);

    // XXX: Concatenating Field arrays is currently cancer, so do multiple
    //      commitment steps.
    let board_hash = pedersen_commitment(board.decompose()).x;
    let move_hash = pedersen_commitment(move.decompose()).x;
    let computed_commitment = pedersen_commitment(
        [board_hash, move_hash, move_salt]
    ).x;

    // Verify tampering by checking commitments against prior state and the
    //   move made against that state.
    assert(computed_commitment == move_commitment);

    new_board.decompose()
}

#[test]
fn valid_move_advances_game() {
    println(f"");

    // Precomputed commitment for these values:
    // 0x069efdc4c6fb2aa94f6febdf5e8839df2ec8834270792c150698bc039fa50899

    let w1 = Board {
        bbs: [
            0x080000f7ff,
            0xffef001000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xef00180000f700
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 44, // e6
        halfmove: 0,
        fullmove: 1
    };

    let move = Move {
        piece: Piece::PAWN,
        from: 35,
        to: 44,
        promotion_piece: 0
    };
    let move_salt = 1337;

    main(
        w1,
        move,
        move_salt,
        0x069efdc4c6fb2aa94f6febdf5e8839df2ec8834270792c150698bc039fa50899
    );
}

// TODO:
// #[test(should_fail)]
// fn invalid_move_fails_proving() {
    
// }
