use dep::std::println;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Turn, Game, Piece};

fn main(game: Game, turn: Turn, turn_salt: Field) -> pub Field {
    let game_hash = pedersen_commitment(game.decompose()).x;
    let turn_hash = pedersen_commitment(turn.decompose()).x;

    let computed_commitment = pedersen_commitment([game_hash, turn_hash, turn_salt]).x;

    computed_commitment
}

#[test]
fn example_move_commitment() {
    let w1 = Game {
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

    // From white performs en passant capture ep1 w1
    let move = Turn { piece: Piece::PAWN, from: 35, to: 44, promotion_piece: 0 };

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
