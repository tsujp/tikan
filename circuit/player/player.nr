use dep::std::println;
use dep::std::collections::vec::Vec;
use dep::std::hash::pedersen_commitment;

use dep::lib::{Game, Turn, Piece};

// TODO: Both players compute fog, if they verify the others' proof then the fog must be
//       good and so we can then say "where you fog overlaps, your piece is revealed."

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
    // let game_hash = pedersen_commitment(game.decompose()).x;
    // let turn_hash = pedersen_commitment(turn.decompose()).x;
    // let computed_commitment = pedersen_commitment([game_hash, turn_hash, turn_salt]).x;

    // Verify no tampering by checking commitments against prior state and the
    //   turn made against that state.
    // assert(computed_commitment == turn_commitment);

    new_gamestate
}

// TODO: Another bitboard `lights` tracking which pieces have their
//       lights turned on.
// TODO: White array and black array with state commitments for square indices
//       if those pieces are hidden, so for X piece its on this square and its lights are on/off.
// TODO: This means game starts with bitboards functionally empty and all
//       pieces as state commitments.
// TODO: When a player plays a move (e.g. white first move) they can provide their secret input to
//       the circuit which is their pieces and their lights, this may the move validation logic can
//       check for a valid move. They do have to provide the commitments still because those need to
//       be sent to black with the circuit output for them to verify. 
// TOOD: Where an opponents light area intersects (i.e. overlaps) the square a piece
//       of yours is on you must open your commitment, revealing the piece. This opening can be
//       checked against your prior commitments to see if you're lying or not.

#[test]
fn valid_turn_advances_game() {
    // println(f"");

    // Precomputed commitment for these values:
    // 0x0ce7455bc1f72a29c691ead1751bc866d7d34bf8c46a7778038ca1ddaaf362a0

    let w1 = Game {
        bbs: [
            0x080000f7ff,
            0xffef001000000000,
            0x4200000000000042,
            0x2400000000000024,
            0x8100000000000081,
            0x0800000000000008,
            0x1000000000000010,
            0xef00180000f700,
            0xeeffff6f0000
        ],
        army: 0,
        castle_rights: 15,
        en_passant: 44, // e6
        halfmove: 0,
        fullmove: 1,
        has_fog: true
    };

    let turn = Turn { piece: Piece::PAWN, from: 35, to: 44, promotion_piece: 0 };
    let turn_salt = 1337;

    // An invalid turn would cause `main` to fail assertion.
    let _ = main(
        w1,
        turn,
        turn_salt,
        0x0ce7455bc1f72a29c691ead1751bc866d7d34bf8c46a7778038ca1ddaaf362a0
    );
}

// TODO:
// #[test(should_fail)]
// fn invalid_turn_fails_proving() {

// }
