use dep::std::println;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Move, Board, Piece};

fn main(
    board: Board,
    move: Move,
    move_salt: Field
) -> pub Field {
    let board_hash = pedersen_commitment(board.decompose()).x;
    let move_hash = pedersen_commitment(move.decompose()).x;

    let computed_commitment = pedersen_commitment([board_hash, move_hash, move_salt]).x;

    computed_commitment
}

#[test]
fn example_move_commitment() {
    let w1 = Board {
        bbs: [0x080000f7ff,
            0xffef001000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xef00180000f700],
        army: 0,
        castle_rights: 15,
        en_passant: 44, // e6
        halfmove: 0,
        fullmove: 1
    };

    // From white performs en passant capture ep1 w1
    let move = Move { piece: Piece::PAWN, from: 35, to: 44, promotion_piece: 0 };

    let move_salt = 1337;

    let mc = main(w1, move, move_salt);
    println(mc);
}

// #[test]
// fn black_initiate_commitment() {
//     let move_salt = 0;
//     let mc = pedersen_commitment([0, 0, 0]);
//     println(mc);
// }
