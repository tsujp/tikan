use dep::std::println;
use dep::std::collections::vec::Vec;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Game, Turn, Piece};

fn main(
    // [GAME] Current before-turn gamestate.
    game: pub Game,
    // [MOVE] Players private turn to alter that gamestate and return new
    //   gamestate.
    turn: Turn,
    turn_salt: pub Field,
    turn_commitment: pub Field
) -> pub Game {
    // `Game` has assertions that check a `Move` is valid against the current
    //   gamestate (which `Game` represents); so this will fail if invalid.
    let new_gamestate = game.apply(turn);

    // XXX: Concatenating Field arrays is currently cancer, so do multiple
    //      commitment steps.
    let game_hash = pedersen_commitment(game.decompose()).x;
    let turn_hash = pedersen_commitment(turn.decompose()).x;
    let computed_commitment = pedersen_commitment([game_hash, turn_hash, turn_salt]).x;

    // Verify no tampering by checking commitments against prior state and the
    //   turn made against that state.
    assert(computed_commitment == turn_commitment);

    new_gamestate
}

#[test]
fn valid_turn_advances_game() {
    println(f"");

    // Precomputed commitment for these values:
    // 0x069efdc4c6fb2aa94f6febdf5e8839df2ec8834270792c150698bc039fa50899

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

    let turn = Turn { piece: Piece::PAWN, from: 35, to: 44, promotion_piece: 0 };
    let turn_salt = 1337;

    // An invalid turn would cause `main` to fail assertion.
    let _ = main(
        w1,
        turn,
        turn_salt,
        0x069efdc4c6fb2aa94f6febdf5e8839df2ec8834270792c150698bc039fa50899
    );
}

// TODO:
// #[test(should_fail)]
// fn invalid_turn_fails_proving() {

// }
